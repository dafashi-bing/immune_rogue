import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
// Item drop imports removed - now handled by ConsumableDropManager
import 'projectile.dart';

class EnemyShooter extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 30.0; // Default fallback speed
  
  // Configuration-based properties
  double get baseAttackRange => EnemyConfigManager.instance.getEnemyProperty('shooter', 'attack_range', 300.0);
  double get fireRate => 1.0 / EnemyConfigManager.instance.getEnemyProperty('shooter', 'shoot_cooldown', 2.0); // Convert cooldown to rate
  double get projectileSpeed => EnemyConfigManager.instance.getEnemyProperty('shooter', 'projectile_speed', 200.0);
  
  // Optimal distance management - derived from attack range
  double get optimalDistanceMin => baseAttackRange * 0.6; // 60% of attack range
  double get optimalDistanceMax => baseAttackRange * 0.9; // 90% of attack range
  
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('shooter') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  double get attackRange => baseAttackRange * DisplayConfig.instance.scaleFactor;
  double get optimalMinDistance => optimalDistanceMin * DisplayConfig.instance.scaleFactor;
  double get optimalMaxDistance => optimalDistanceMax * DisplayConfig.instance.scaleFactor;
  
  double health = 25.0;
  double maxHealth = 25.0;
  double lastShotTime = 0.0;
  
  // Sprite component for image rendering
  SpriteComponent? spriteComponent;
  bool hasSprite = false;
  
  // AI behavior variables
  double lastDirectionChange = 0.0;
  Vector2 currentDirection = Vector2.zero();
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0; // Slow lasts 3 seconds
  double speedMultiplier = 1.0;
  
  EnemyShooter({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 24.0 * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = const Color(0xFF9C27B0),
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
    
    // Try to load sprite image
    final imagePath = EnemyConfigManager.instance.getEnemyImagePath('shooter');
    if (imagePath != null) {
      try {
        final sprite = await Sprite.load(imagePath);
        final spriteSize = Vector2.all(radius * 2);
        spriteComponent = SpriteComponent(
          sprite: sprite,
          size: spriteSize,
          anchor: Anchor.center,
        );
        add(spriteComponent!);
        hasSprite = true;
      } catch (e) {
        print('Could not load enemy image for shooter: $e');
        hasSprite = false;
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (hasSprite && spriteComponent != null) {
      // Don't render circle if we have a sprite
      // The sprite component will render itself
    } else {
      super.render(canvas);
    }
  }
  
  void _initializeHealth() {
    // Get base health from enemy config
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('shooter', 25.0);
    // Apply wave-based scaling
    final scaledHealth = WaveConfig.instance.getScaledHealth(baseHealth, gameRef.currentWave);
    health = scaledHealth;
    maxHealth = scaledHealth;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Handle stun
    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
      }
      return; // Don't move or attack while stunned
    }
    
    // Remove if too far from arena center (cleanup)
    final arenaCenter = Vector2(DisplayConfig.instance.arenaWidth / 2, DisplayConfig.instance.arenaHeight / 2);
    final maxDistance = (DisplayConfig.instance.arenaWidth + DisplayConfig.instance.arenaHeight) / 3;
    if (position.distanceTo(arenaCenter) > maxDistance) {
      removeFromParent();
    }
    
    // Stay within safe area
    _constrainToSafeArea();
    
    // Smart AI behavior with hero
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final distanceToHero = position.distanceTo(hero.position);
      
      // Can shoot while moving - check if in range and ready to fire
      if (distanceToHero <= attackRange && _canFire()) {
        final direction = (hero.position - position).normalized();
        _fireProjectile(direction);
      }
      
      // Smart movement to maintain optimal distance
      Vector2 movementDirection = Vector2.zero();
      
      if (distanceToHero < optimalMinDistance) {
        // Too close - move away from hero
        movementDirection = (position - hero.position).normalized();
      } else if (distanceToHero > optimalMaxDistance) {
        // Too far - move towards hero
        movementDirection = (hero.position - position).normalized();
      } else {
        // In optimal range - add some side-to-side movement to make it harder to hit
        final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
        if (currentTime - lastDirectionChange > 1.5) {
          // Change direction every 1.5 seconds for unpredictable movement
          final perpendicular = Vector2(
            -(hero.position - position).normalized().y,
            (hero.position - position).normalized().x,
          );
          final random = Random();
          movementDirection = perpendicular * (random.nextBool() ? 1.0 : -1.0);
          lastDirectionChange = currentTime;
          currentDirection = movementDirection;
        } else {
          movementDirection = currentDirection;
        }
      }
      
      // Apply no-stay zone force to keep enemies away from edges
      final noStayForce = gameRef.getNoStayZoneForce(position);
      
      // Combine tactical movement with no-stay force
      final finalDirection = movementDirection + (noStayForce * dt);
      if (finalDirection.length > 0) {
        finalDirection.normalize();
        position += finalDirection * speed * dt * speedMultiplier;
      }
    }
  }
  
  void _constrainToSafeArea() {
    final margin = DisplayConfig.instance.safeAreaMargin;
    position.x = position.x.clamp(
      margin, 
      DisplayConfig.instance.arenaWidth - margin
    );
    position.y = position.y.clamp(
      margin, 
      DisplayConfig.instance.arenaHeight - margin
    );
  }
  
  bool _canFire() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    return currentTime - lastShotTime >= (1.0 / fireRate);
  }
  
  void _fireProjectile(Vector2 direction) {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    lastShotTime = currentTime;
    
    final projectileDamage = EnemyConfigManager.instance.getEnemyProperty('shooter', 'projectile_damage', 15.0);
    final projectile = Projectile(
      startPosition: position.clone(),
      direction: direction,
      speed: projectileSpeed * DisplayConfig.instance.scaleFactor,
      damage: projectileDamage,
      isEnemyProjectile: true,
      ownerEnemyType: 'shooter',
    );
    
    gameRef.add(projectile);
  }
  
  void takeDamage(double damageAmount) {
    health -= damageAmount;
    
    if (health <= 0) {
      // Item drops are now handled by the unified ConsumableDropManager
      // via gameRef.onEnemyDestroyed(this)
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
    }
  }
  
  void stun(double duration) {
    isStunned = true;
    stunDuration = duration;
    stunTimer = duration; // Fixed: should start at full duration
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
} 