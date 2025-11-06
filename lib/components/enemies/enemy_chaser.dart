import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
// Item drop imports removed - now handled by ConsumableDropManager

class EnemyChaser extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 50.0; // Default fallback speed
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('chaser') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  double health = 30.0;
  double maxHealth = 30.0;
  bool isDead = false;
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0; // Slow lasts 3 seconds
  double speedMultiplier = 1.0;
  
  EnemyChaser({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 12.0 * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = const Color(0xFFFF5722),
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
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('chaser', 30.0);
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
      return; // Don't move or do anything while stunned
    }
    
    // Remove if too far from arena center (cleanup)
    final arenaCenter = Vector2(DisplayConfig.instance.arenaWidth / 2, DisplayConfig.instance.arenaHeight / 2);
    final maxDistance = (DisplayConfig.instance.arenaWidth + DisplayConfig.instance.arenaHeight) / 3;
    if (position.distanceTo(arenaCenter) > maxDistance) {
      removeFromParent();
    }
    
    // Stay within safe area to prevent getting stuck at edges
    _constrainToSafeArea();
    
    // Chase hero
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final direction = (hero.position - position).normalized();
      
      // Apply no-stay zone force to keep enemies away from edges
      final noStayForce = gameRef.getNoStayZoneForce(position);
      
      // Combine chase direction with no-stay force
      final finalDirection = direction + (noStayForce * dt);
      if (finalDirection.length > 0) {
        finalDirection.normalize();
      }
      
      position += finalDirection * speed * dt * speedMultiplier;
      
      // Check collision with hero
      final distanceToHero = position.distanceTo(hero.position);
      if (distanceToHero <= radius + hero.collisionRadius) {
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('chaser', 5.0);
        hero.takeDamage(contactDamage, sourceType: 'chaser');
        takeDamage(health); // Die on contact
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
    stunTimer = duration;
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
} 