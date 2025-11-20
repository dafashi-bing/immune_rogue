import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';

class Swarmer extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 120.0; // Fast and agile
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('swarmer') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 25.0; // Low health but fast
  double maxHealth = 25.0;
  bool isDead = false;
  
  // Sprite component for image rendering
  SpriteComponent? spriteComponent;
  bool hasSprite = false;
  
  // Swarming behavior - now using config
  late Vector2 swarmTarget;
  double get swarmRadius => EnemyConfigManager.instance.getEnemyProperty('swarmer', 'swarm_radius', 80.0);
  double get separationRadius => EnemyConfigManager.instance.getEnemyProperty('swarmer', 'separation_radius', 30.0);
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  Swarmer({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 16.0 * DisplayConfig.instance.scaleFactor, // Smaller than other enemies
    paint: Paint()..color = const Color(0xFFFFEB3B), // Yellow color
    anchor: Anchor.center,
  ) {
    swarmTarget = position ?? Vector2.zero();
  }
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
    
    // Try to load sprite image
    final imagePath = EnemyConfigManager.instance.getEnemyImagePath('swarmer');
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
        print('Could not load enemy image for swarmer: $e');
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
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('swarmer', 25.0);
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
    
    if (isDead) return;
    
    // Handle stun
    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
      }
      return;
    }
    
    // Remove if too far from arena center (cleanup)
    final arenaCenter = Vector2(DisplayConfig.instance.arenaWidth / 2, DisplayConfig.instance.arenaHeight / 2);
    final maxDistance = (DisplayConfig.instance.arenaWidth + DisplayConfig.instance.arenaHeight) / 3;
    if (position.distanceTo(arenaCenter) > maxDistance) {
      removeFromParent();
      return;
    }
    
    // Stay within safe area
    _constrainToSafeArea();
    
    // Swarming AI behavior
    final hero = gameRef.hero;
    if (hero.isMounted) {
      Vector2 swarmDirection = _calculateSwarmDirection();
      Vector2 heroDirection = (hero.position - position).normalized();
      
      // Combine swarming behavior with hero chasing (weighted toward hero)
      Vector2 finalDirection = (heroDirection * 0.7 + swarmDirection * 0.3).normalized();
      
      // Apply no-stay zone force
      final noStayForce = gameRef.getNoStayZoneForce(position);
      finalDirection = (finalDirection + noStayForce * dt).normalized();
      
      position += finalDirection * speed * dt * speedMultiplier;
      
      // Check collision with hero
      final distanceToHero = position.distanceTo(hero.position);
      if (distanceToHero <= radius + hero.collisionRadius) {
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('swarmer', 10.0);
        hero.takeDamage(contactDamage, sourceType: 'swarmer');
        takeDamage(health); // Die on contact
      }
    }
  }
  
  Vector2 _calculateSwarmDirection() {
    Vector2 swarmForce = Vector2.zero();
    Vector2 separationForce = Vector2.zero();
    int nearbyCount = 0;
    
    // Find other swarmers nearby
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is Swarmer && enemy != this) {
        final distance = position.distanceTo(enemy.position);
        
        if (distance < swarmRadius) {
          // Attraction to nearby swarmers
          swarmForce += (enemy.position - position).normalized() * 0.3;
          nearbyCount++;
        }
        
        if (distance < separationRadius) {
          // Separation from too-close swarmers
          separationForce += (position - enemy.position).normalized() * 0.5;
        }
      }
    }
    
    if (nearbyCount > 0) {
      swarmForce = swarmForce / nearbyCount.toDouble();
    }
    
    return (swarmForce + separationForce).normalized();
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
  
  void takeDamage(double damageAmount) {
    health -= damageAmount;
    
    if (health <= 0) {
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
    }
  }
  
  void stun(double duration) {
    isStunned = true;
    stunDuration = duration;
    stunTimer = duration;
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
}
