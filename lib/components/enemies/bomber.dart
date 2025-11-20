import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
import '../sound_manager.dart';
import 'projectile.dart';

class Bomber extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 40.0; // Slow but dangerous
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('bomber') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 50.0; // Tanky
  double maxHealth = 50.0;
  bool isDead = false;
  
  // Sprite component for image rendering
  SpriteComponent? spriteComponent;
  bool hasSprite = false;
  
  // Bombing behavior - now using config
  double get explosionRadius => EnemyConfigManager.instance.getEnemyProperty('bomber', 'explosion_radius', 100.0);
  double get explosionDamage => EnemyConfigManager.instance.getEnemyProperty('bomber', 'explosion_damage', 30.0);
  double get fuseTime => EnemyConfigManager.instance.getEnemyProperty('bomber', 'fuse_time', 3.0);
  double fuseTimer = 0.0;
  bool fuseActive = false;
  
  // Visual effects
  double pulseTimer = 0.0;
  double pulseIntensity = 0.0;
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  Bomber({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 32.0 * DisplayConfig.instance.scaleFactor, // Larger than basic enemies
    paint: Paint()..color = const Color(0xFFFF5722), // Orange-red color
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
    
    // Try to load sprite image
    final imagePath = EnemyConfigManager.instance.getEnemyImagePath('bomber');
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
        print('Could not load enemy image for bomber: $e');
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
    
    // Draw pulsing effect when fuse is active
    if (fuseActive) {
      final center = Offset(size.x / 2, size.y / 2);
      final pulseRadius = radius * (1.0 + pulseIntensity * 0.5);
      
      final pulsePaint = Paint()
        ..color = Colors.red.withOpacity(0.3 * pulseIntensity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, pulseRadius, pulsePaint);
      
      // Draw warning ring
      final ringPaint = Paint()
        ..color = Colors.red.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawCircle(center, explosionRadius * DisplayConfig.instance.scaleFactor, ringPaint);
    }
  }
  
  void _initializeHealth() {
    // Get base health from enemy config
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('bomber', 100.0);
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
    
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final distanceToHero = position.distanceTo(hero.position);
      
      // Activate fuse when close to hero
      if (distanceToHero <= explosionRadius * DisplayConfig.instance.scaleFactor && !fuseActive) {
        fuseActive = true;
        fuseTimer = fuseTime;
      }
      
      // Handle fuse countdown
      if (fuseActive) {
        fuseTimer -= dt;
        pulseTimer += dt;
        
        // Increase pulse intensity as explosion approaches
        final timeProgress = 1.0 - (fuseTimer / fuseTime);
        pulseIntensity = sin(pulseTimer * 10.0) * timeProgress;
        
        if (fuseTimer <= 0.0) {
          _explode();
          return;
        }
      }
      
      // Move toward hero (slower when fuse is active)
      final direction = (hero.position - position).normalized();
      final noStayForce = gameRef.getNoStayZoneForce(position);
      final finalDirection = (direction + noStayForce * dt).normalized();
      
      final effectiveSpeed = fuseActive ? speed * 0.5 : speed; // Slow down when about to explode
      position += finalDirection * effectiveSpeed * dt * speedMultiplier;
      
      // Check collision with hero (only if not exploding)
      if (!fuseActive && distanceToHero <= radius + hero.collisionRadius) {
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('bomber', 7.5);
        hero.takeDamage(contactDamage, sourceType: 'bomber');
        takeDamage(health); // Die on contact
      }
    }
  }
  
  void _explode() {
    // Play bomber explosion sound
    SoundManager().playBomberExplodeSound();
    
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final distanceToHero = position.distanceTo(hero.position);
      final explosionRange = explosionRadius * DisplayConfig.instance.scaleFactor;
      
      if (distanceToHero <= explosionRange) {
        // Damage falls off with distance
        final damageFalloff = 1.0 - (distanceToHero / explosionRange);
        final actualDamage = explosionDamage * damageFalloff;
        hero.takeDamage(actualDamage, sourceType: 'bomber');
      }
    }
    
    // Create explosion visual effect (multiple projectiles in all directions)
    _createExplosionEffect();
    
    // Remove self
    gameRef.onEnemyDestroyed(this);
    removeFromParent();
  }
  
  void _createExplosionEffect() {
    // Get projectile count and speed from config
    final numProjectiles = EnemyConfigManager.instance.getEnemyIntProperty('bomber', 'explosion_projectiles', 6);
    final projectileSpeed = EnemyConfigManager.instance.getEnemyProperty('bomber', 'explosion_projectile_speed', 150.0);
    
    for (int i = 0; i < numProjectiles; i++) {
      final angle = (i * 360.0 / numProjectiles) * (pi / 180.0);
      final direction = Vector2(cos(angle), sin(angle));
      
      final projectileDamage = EnemyConfigManager.instance.getEnemyProperty('bomber', 'explosion_projectile_damage', 8.0);
      final projectile = Projectile(
        startPosition: position.clone(),
        direction: direction,
        speed: projectileSpeed * DisplayConfig.instance.scaleFactor,
        damage: projectileDamage,
        isEnemyProjectile: true,
        ownerEnemyType: 'bomber',
      );
      
      gameRef.add(projectile);
      
      // Explosion projectiles will auto-destroy via their normal lifetime mechanism
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
  
  void takeDamage(double damageAmount) {
    health -= damageAmount;
    
    if (health <= 0) {
      // Explode immediately when killed
      _explode();
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
