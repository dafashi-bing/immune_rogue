import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
import '../sound_manager.dart';
import 'projectile.dart';

class Sniper extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 30.0; // Very slow movement
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('sniper') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 125.0; // Moderate health
  double maxHealth = 125.0;
  bool isDead = false;
  
  // Sniper behavior - now configurable
  double get attackRange => EnemyConfigManager.instance.getEnemyProperty('sniper', 'attack_range', 400.0);
  double get chargeTime => EnemyConfigManager.instance.getEnemyProperty('sniper', 'charge_time', 2.0);
  double get damagePercent => EnemyConfigManager.instance.getEnemyProperty('sniper', 'damage_percent', 0.5);
  double get aimTime => EnemyConfigManager.instance.getEnemyProperty('sniper', 'aim_time', 0.5);
  
  double lastShotTime = 0.0;
  double get shotCooldown => EnemyConfigManager.instance.getEnemyProperty('sniper', 'shot_cooldown', 4.0);
  bool isCharging = false;
  bool isAiming = false;
  double chargeTimer = 0.0;
  double aimTimer = 0.0;
  Vector2 targetPosition = Vector2.zero();
  
  // Visual effects
  double laserAlpha = 0.0;
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  Sniper({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 14.0 * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = const Color(0xFF4CAF50), // Green color
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
  }
  
  void _initializeHealth() {
    // Get base health from enemy config
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('sniper', 125.0);
    // Apply wave-based scaling
    final scaledHealth = WaveConfig.instance.getScaledHealth(baseHealth, gameRef.currentWave);
    health = scaledHealth;
    maxHealth = scaledHealth;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw charging laser sight
    if ((isAiming || isCharging) && laserAlpha > 0) {
      final start = Offset(size.x / 2, size.y / 2);
      final end = Offset(
        start.dx + (targetPosition.x - position.x),
        start.dy + (targetPosition.y - position.y),
      );
      
      final laserPaint = Paint()
        ..color = Colors.red.withOpacity(laserAlpha)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(start, end, laserPaint);
      
      // Draw target indicator
      final targetPaint = Paint()
        ..color = Colors.red.withOpacity(laserAlpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawCircle(end, 10.0, targetPaint);
    }
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
        _cancelShot();
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
      final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      
      // Check if can start aiming
      if (distanceToHero <= attackRange * DisplayConfig.instance.scaleFactor && 
          !isAiming && !isCharging && 
          currentTime - lastShotTime >= shotCooldown) {
        _startAiming(hero.position);
      }
      
      // Handle aiming phase
      if (isAiming) {
        aimTimer += dt;
        laserAlpha = min(1.0, aimTimer / aimTime);
        
        if (aimTimer >= aimTime) {
          _startCharging();
        }
      }
      
      // Handle charging phase
      if (isCharging) {
        chargeTimer += dt;
        
        // Intensify laser during charge
        laserAlpha = 0.5 + 0.5 * sin(chargeTimer * 20.0);
        
        if (chargeTimer >= chargeTime) {
          _fireShot();
        }
      }
      
      // Move very slowly toward hero when not shooting
      if (!isAiming && !isCharging) {
        final direction = (hero.position - position).normalized();
        final noStayForce = gameRef.getNoStayZoneForce(position);
        final finalDirection = (direction + noStayForce * dt).normalized();
        
        position += finalDirection * speed * dt * speedMultiplier;
      }
      
      // Check collision with hero (only when not shooting)
      if (!isAiming && !isCharging && distanceToHero <= radius + hero.collisionRadius) {
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('sniper', 7.5);
        hero.takeDamage(contactDamage, sourceType: 'sniper');
        takeDamage(health); // Die on contact
      }
    }
  }
  
  void _startAiming(Vector2 heroPosition) {
    isAiming = true;
    aimTimer = 0.0;
    targetPosition = heroPosition.clone();
    laserAlpha = 0.0;
  }
  
  void _startCharging() {
    isAiming = false;
    isCharging = true;
    chargeTimer = 0.0;
    aimTimer = 0.0;
  }
  
  void _fireShot() {
    // Play sniper shot sound
    SoundManager().playSniperSnipeSound();
    
    final direction = (targetPosition - position).normalized();
    
    // Calculate damage as 50% of player's current HP
    final playerDamage = gameRef.hero.maxHealth * damagePercent;
    
    final projectileSpeed = EnemyConfigManager.instance.getEnemyProperty('sniper', 'projectile_speed', 600.0);
    final projectile = Projectile(
      startPosition: position.clone(),
      direction: direction,
      speed: projectileSpeed * DisplayConfig.instance.scaleFactor,
      damage: playerDamage,
      isEnemyProjectile: true,
      ownerEnemyType: 'sniper',
    );
    
    gameRef.add(projectile);
    
    _resetShotState();
  }
  
  void _cancelShot() {
    _resetShotState();
  }
  
  void _resetShotState() {
    isAiming = false;
    isCharging = false;
    chargeTimer = 0.0;
    aimTimer = 0.0;
    laserAlpha = 0.0;
    lastShotTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
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
    
    // Cancel shot when taking damage
    if (isAiming || isCharging) {
      _cancelShot();
    }
    
    if (health <= 0) {
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
    }
  }
  
  void stun(double duration) {
    isStunned = true;
    stunDuration = duration;
    stunTimer = duration;
    _cancelShot();
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
}
