import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
import '../sound_manager.dart';

class MineLayer extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 45.0;
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('mine_layer') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 150.0;
  double maxHealth = 150.0;
  bool isDead = false;
  
  // Mine laying behavior - now using config
  double get mineLayInterval => EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'mine_lay_interval', 3.0);
  double get minDistanceFromMines => EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'min_distance_from_mines', 80.0);
  double lastMineTime = 0.0;
  List<Vector2> minePositions = [];
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  MineLayer({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 15.0 * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = const Color(0xFF607D8B), // Blue-grey color
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
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('mine_layer', 150.0);
    // Apply wave-based scaling
    final scaledHealth = WaveConfig.instance.getScaledHealth(baseHealth, gameRef.currentWave);
    health = scaledHealth;
    maxHealth = scaledHealth;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw mine layer indicator (small dots around the enemy)
    final center = Offset(size.x / 2, size.y / 2);
    final dotPaint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60.0) * (pi / 180.0);
      final dotRadius = 2.0;
      final distance = radius + 8.0;
      
      final dotX = center.dx + cos(angle) * distance;
      final dotY = center.dy + sin(angle) * distance;
      
      canvas.drawCircle(Offset(dotX, dotY), dotRadius, dotPaint);
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
      final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      
      // Try to lay mine
      if (currentTime - lastMineTime >= mineLayInterval) {
        _tryLayMine();
      }
      
      // Always move around when not laying mines - more aggressive movement
      final distanceToHero = position.distanceTo(hero.position);
      Vector2 movementDirection = Vector2.zero();
      
      // Always be moving - combine defensive positioning with random movement
      final defensiveDistanceMin = EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'defensive_distance_min', 150.0) * DisplayConfig.instance.scaleFactor;
      final defensiveDistanceMax = EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'defensive_distance_max', 250.0) * DisplayConfig.instance.scaleFactor;
      
      if (distanceToHero < defensiveDistanceMin) {
        // Too close to hero - retreat
        movementDirection = (position - hero.position).normalized();
      } else if (distanceToHero > defensiveDistanceMax) {
        // Too far from hero - advance
        movementDirection = (hero.position - position).normalized();
      } else {
        // Good distance - move perpendicular to hero for defensive positioning
        final perpendicular = Vector2(
          -(hero.position - position).normalized().y,
          (hero.position - position).normalized().x,
        );
        final random = Random();
        movementDirection = perpendicular * (random.nextBool() ? 1.0 : -1.0);
      }
      
      // Add random movement component to keep miner active
      final random = Random();
      final randomMovement = Vector2(
        (random.nextDouble() - 0.5) * 2.0,
        (random.nextDouble() - 0.5) * 2.0,
      );
      movementDirection = (movementDirection + randomMovement * 0.3).normalized();
      
      // Apply no-stay zone force
      final noStayForce = gameRef.getNoStayZoneForce(position);
      final finalDirection = (movementDirection + noStayForce * dt).normalized();
      
      position += finalDirection * speed * dt * speedMultiplier;
      
      // Check collision with hero
      if (distanceToHero <= radius + hero.collisionRadius) {
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('mine_layer', 7.5);
        hero.takeDamage(contactDamage, sourceType: 'mine_layer');
        takeDamage(health); // Die on contact
      }
    }
  }
  
  void _tryLayMine() {
    // Check if current position is far enough from existing mines
    bool canLayMine = true;
    final minDistance = minDistanceFromMines * DisplayConfig.instance.scaleFactor;
    
    for (final minePos in minePositions) {
      if (position.distanceTo(minePos) < minDistance) {
        canLayMine = false;
        break;
      }
    }
    
    if (canLayMine) {
      _layMine();
    }
  }
  
  void _layMine() {
    // Play mine deployment sound
    SoundManager().playMineDeploySound();
    
    final mine = Mine(position: position.clone());
    gameRef.add(mine);
    
    minePositions.add(position.clone());
    lastMineTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Limit number of tracked mine positions to prevent memory buildup
    if (minePositions.length > 10) {
      minePositions.removeAt(0);
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

class Mine extends CircleComponent with HasGameRef<CircleRougeGame> {
  double get explosionRadius => EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'mine_explosion_radius', 60.0);
  double get damagePercent => EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'mine_damage_percent', 0.5);
  double get armTime => EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'mine_arm_time', 1.0);
  
  double armTimer = 0.0;
  bool isArmed = false;
  double pulseTimer = 0.0;
  
  Mine({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 8.0 * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = const Color(0xFF795548), // Brown color
    anchor: Anchor.center,
  );
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    if (!isArmed) {
      // Draw arming indicator
      final armProgress = armTimer / armTime;
      final armPaint = Paint()
        ..color = Colors.orange.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 5.0),
        -pi / 2,
        2 * pi * armProgress,
        false,
        armPaint,
      );
    } else {
      // Draw pulsing armed indicator
      final pulseIntensity = (sin(pulseTimer * 6.0) + 1.0) / 2.0;
      final pulsePaint = Paint()
        ..color = Colors.red.withOpacity(0.3 + 0.3 * pulseIntensity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, radius + 3.0, pulsePaint);
      
      // Draw danger zone indicator (faint)
      final dangerPaint = Paint()
        ..color = Colors.red.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawCircle(center, explosionRadius * DisplayConfig.instance.scaleFactor, dangerPaint);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    pulseTimer += dt;
    
    // Handle arming
    if (!isArmed) {
      armTimer += dt;
      if (armTimer >= armTime) {
        isArmed = true;
      }
      return;
    }
    
    // Check for hero proximity
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final distanceToHero = position.distanceTo(hero.position);
      final triggerDistance = explosionRadius * DisplayConfig.instance.scaleFactor;
      
      if (distanceToHero <= triggerDistance) {
        _explode();
      }
    }
  }
  
  void _explode() {
    // Play mine explosion sound
    SoundManager().playMineExplodeSound();
    
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final distanceToHero = position.distanceTo(hero.position);
      final explosionRange = explosionRadius * DisplayConfig.instance.scaleFactor;
      
      if (distanceToHero <= explosionRange) {
        // Deal direct damage as percentage of player's max HP
        final directDamage = hero.maxHealth * damagePercent;
        hero.takeDamage(directDamage, sourceType: 'mine_layer');
        print('Mine explosion! Dealt ${directDamage.toStringAsFixed(1)} damage (${(damagePercent * 100).toStringAsFixed(0)}% of max HP)');
      }
    }
    
    // Create visual explosion effect
    _createExplosionEffect();
    
    removeFromParent();
  }
  
  void _createExplosionEffect() {
    // Create a simple explosion effect with multiple small projectiles
    const numFragments = 8;
    
    for (int i = 0; i < numFragments; i++) {
      final angle = (i * 360.0 / numFragments) * (pi / 180.0);
      final direction = Vector2(cos(angle), sin(angle));
      
      // Create small visual fragments (could be simple components)
      final fragment = CircleComponent(
        position: position.clone(),
        radius: 3.0,
        paint: Paint()..color = Colors.orange,
      );
      
      gameRef.add(fragment);
      
      // Remove fragment after short time
      fragment.add(RemoveEffect(delay: 0.5));
      
      // Add movement to fragment
      fragment.add(MoveByEffect(
        direction * 40.0 * DisplayConfig.instance.scaleFactor,
        EffectController(duration: 0.5),
      ));
    }
  }
}
