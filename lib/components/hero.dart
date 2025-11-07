import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/circle_rouge_game.dart';
import '../config/hero_config.dart';
import '../config/display_config.dart';
import '../config/wave_config.dart';
import '../config/item_config.dart';
import 'abilities/hex_field.dart';
import 'enemies/enemy_chaser.dart';
import 'enemies/enemy_shooter.dart';
import 'enemies/shielded_chaser.dart';
import 'enemies/projectile.dart';
import 'enemies/shape_projectile.dart';
import 'enemies/triangle_projectile.dart';
import 'sound_manager.dart';
import 'companions/drone_wingman.dart';
import 'companions/hero_clone.dart';
import 'ultimates/ultimate_ability.dart';
import 'ultimates/engulf_rampage.dart';

class TemporaryEffect {
  final String type;
  final double value;
  final double duration;
  double remainingTime;
  
  TemporaryEffect({
    required this.type,
    required this.value,
    required this.duration,
  }) : remainingTime = duration;
  
  void update(double dt) {
    remainingTime -= dt;
  }
  
  bool get isExpired => remainingTime <= 0;
}

class Hero extends PositionComponent with HasGameRef<CircleRougeGame>, KeyboardHandler {
  // Hero configuration
  late HeroData heroData;
  final String heroId;
  
  // Hero visual properties
  late double heroRadius;
  late Paint heroPaint;
  
  // Base movement properties - will be scaled based on arena size
  static const double baseMoveSpeed = 200.0;
  
  // Base dash properties (for heroes that don't have special abilities)
  static const double baseDashDistance = 120.0;
  static const double baseDashSpeed = 500.0;
  
  // Base shooting properties
  static const double baseShootRange = 250.0;
  static const double fireRate = 2.0; // Shots per second
  double lastShotTime = 0.0;
  
  // Get scaled values based on arena size
  double get moveSpeed => ((heroData.moveSpeed / 320.0 * baseMoveSpeed) * DisplayConfig.instance.scaleFactor) * (1.0 - enlargedCaliberSpeedReduction);
  double get dashDistance => baseDashDistance * DisplayConfig.instance.scaleFactor;
  double get dashSpeed => baseDashSpeed * DisplayConfig.instance.scaleFactor;
  double get shootRange => baseShootRange * DisplayConfig.instance.scaleFactor * rangeMultiplier;
  
  // Attack speed modifier (can be upgraded)
  double attackSpeedMultiplier = 1.0;
  
  // Movement speed modifier (can be upgraded)
  double speedMultiplier = 1.0;
  
  // Ability cooldown modifier (can be upgraded)
  double abilityCooldownMultiplier = 1.0;
  
  // Range modifier (can be upgraded)
  double rangeMultiplier = 1.0;
  
  // Weapon overclock visual effect
  // Weapon overclock now handled by temporary effect system
  
  // Ability system
  double lastAbilityTime = -double.infinity;
  bool isUsingAbility = false;
  Vector2? abilityTarget;
  
  // Hero stats
  double health = 100.0;
  double maxHealth = 100.0;
  double energy = 100.0;
  double maxEnergy = 100.0;
  int coins = 0;
  
  // Invincibility after wave completion
  bool isInvincible = false;
  double invincibilityTimer = 0.0;
  static const double invincibilityDuration = 3.0; // 3 seconds of invincibility
  
  // Damage invincibility (separate from wave completion invincibility)
  bool isDamageInvincible = false;
  double damageInvincibilityTimer = 0.0;
  static const double damageInvincibilityDuration = 0.5; // 0.5 seconds after taking damage
  
  // Temporary effects system
  final Map<String, TemporaryEffect> _temporaryEffects = {};
  
  // Stackable passive effects system
  final Map<String, int> _passiveEffectStacks = {};
  
  // Kill tracking for auto-injector
  int totalKills = 0;
  int autoInjectorBonusHP = 0; // Track bonus HP from auto-injector
  
  // Ultimate ability system
  static const int maxUltimateCharge = 10;
  int ultimateCharge = 0;
  bool isUsingUltimate = false;
  UltimateAbility? _currentUltimate;
  UltimateAbility? _pendingUltimate; // Ultimate waiting for video to complete
  
  // Drone companion system
  final List<DroneWingman> _activeDrones = [];
  
  // Clone system
  HeroClone? _activeClone;
  
  // Shield system
  double shield = 0.0;
  double maxShield = 0.0;
  
  // Input tracking
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  
  // Expose pressed keys for ultimate abilities
  Set<LogicalKeyboardKey> get pressedKeys => _pressedKeys;
  
  // Display config listener for dynamic scaling
  DisplayConfigChangeCallback? _displayConfigListener;
  
  // Base values for responsive scaling
  static const double baseHeroRadius = 15.0;
  static const double baseHeroSize = 30.0;

  Hero({required Vector2 position, required this.heroId}) : super(
    position: position,
    size: Vector2.all(baseHeroSize * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    heroRadius = baseHeroRadius * DisplayConfig.instance.scaleFactor * totalCharacterSize;
    heroPaint = Paint()..color = const Color(0xFF4CAF50);
    _initializeHero(heroId);
    _setupDynamicScaling();
  }
  
  /// Set up dynamic scaling listener
  void _setupDynamicScaling() {
    _displayConfigListener = (oldSettings, newSettings) {
      _updateHeroScale();
    };
    DisplayConfig.instance.addListener(_displayConfigListener!);
  }
  
  /// Update hero scale based on current display config
  void _updateHeroScale() {
    final scaleFactor = DisplayConfig.instance.scaleFactor;
    size = Vector2.all(baseHeroSize * scaleFactor);
    heroRadius = baseHeroRadius * scaleFactor * totalCharacterSize;
    
    // Keep hero centered in arena (don't let it drift to edges)
    final arenaWidth = DisplayConfig.instance.arenaWidth;
    final arenaHeight = DisplayConfig.instance.arenaHeight;
    position = Vector2(arenaWidth / 2, arenaHeight / 2);
    
    print('Hero scale updated: size=${size.x.toInt()}, radius=${heroRadius.toInt()}, scaleFactor=${scaleFactor.toStringAsFixed(2)}, position=${position.x.toInt()},${position.y.toInt()}');
  }
  
  void _initializeHero(String heroId) {
    final heroConfig = HeroConfig.instance.getHeroById(heroId);
    if (heroConfig != null) {
      heroData = heroConfig;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    } else {
      // Fallback to default circle hero
      heroData = HeroConfig.instance.defaultHero;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    }
  }
  
  double get effectiveMaxHealth {
    return maxHealth + totalMaxHealthBoost;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Always-on hero visibility glow (helps locate hero in crowds)
    // Stronger pulse at ~2 Hz, bright core + soft outer bloom
    final nowSeconds = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final basePulse = 0.5 + 0.5 * sin(nowSeconds * pi * 4.0); // 0..1 at 2 Hz
    final visibilityGlowRadius = 7.0 + 13.0 * basePulse; // 7..20 (tighter)
    final coreOpacity = (0.6 + 0.4 * basePulse).clamp(0.0, 0.95);
    final visibilityCenter = Offset(size.x / 2, size.y / 2);
    
    // Core bright glow
    final visibilityGlowPaint = Paint()
      ..color = heroPaint.color.withOpacity(coreOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36);
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(visibilityCenter, heroRadius + visibilityGlowRadius, visibilityGlowPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, size.x, visibilityGlowPaint, visibilityGlowRadius);
        break;
      case 'square':
        _drawSquare(canvas, visibilityCenter, visibilityGlowPaint, visibilityGlowRadius);
        break;
      case 'pentagon':
        _drawPentagon(canvas, size.x, visibilityGlowPaint, visibilityGlowRadius);
        break;
      case 'hexagon':
        _drawHexagon(canvas, size.x, visibilityGlowPaint, visibilityGlowRadius);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, size.x, visibilityGlowPaint, visibilityGlowRadius);
        break;
    }
    
    // Thin bright ring for crispness
    final ringPaint = Paint()
      ..color = heroPaint.color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(visibilityCenter, heroRadius + visibilityGlowRadius + 2.0, ringPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, size.x, ringPaint, visibilityGlowRadius + 2.0);
        break;
      case 'square':
        _drawSquare(canvas, visibilityCenter, ringPaint, visibilityGlowRadius + 2.0);
        break;
      case 'pentagon':
        _drawPentagon(canvas, size.x, ringPaint, visibilityGlowRadius + 2.0);
        break;
      case 'hexagon':
        _drawHexagon(canvas, size.x, ringPaint, visibilityGlowRadius + 2.0);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, size.x, ringPaint, visibilityGlowRadius + 2.0);
        break;
    }
    
    // Soft outer bloom to separate from enemies
    final bloomPaint = Paint()
      ..color = heroPaint.color.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(visibilityCenter, heroRadius + visibilityGlowRadius + 12.0, bloomPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, size.x, bloomPaint, visibilityGlowRadius + 12.0);
        break;
      case 'square':
        _drawSquare(canvas, visibilityCenter, bloomPaint, visibilityGlowRadius + 12.0);
        break;
      case 'pentagon':
        _drawPentagon(canvas, size.x, bloomPaint, visibilityGlowRadius + 12.0);
        break;
      case 'hexagon':
        _drawHexagon(canvas, size.x, bloomPaint, visibilityGlowRadius + 12.0);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, size.x, bloomPaint, visibilityGlowRadius + 12.0);
        break;
    }
    
    // Blinking effect during damage invincibility
    if (isDamageInvincible) {
      final blinkTime = (damageInvincibilityTimer * 8) % 1.0; // 8 blinks per second
      if (blinkTime > 0.5) {
        return; // Don't render during blink "off" phase
      }
    }
    
    final center = Offset(size.x / 2, size.y / 2);
    final shapeSize = size.x;
    
    // Old weapon overclock glow removed - now handled by active effect glow
    
    // Active effect glow
    final activeEffect = currentActiveEffect;
    if (activeEffect != null) {
      final effectTime = (DateTime.now().millisecondsSinceEpoch / 1000.0) % 1.2; // slightly faster
      final glowIntensity = (sin(effectTime * pi * 2) * 0.35 + 0.85); // 0.5..1.2 clamped by opacity
      final glowRadius = 18.0 * glowIntensity; // larger radius for visibility
      
      // Get effect color
      Color effectColor;
      switch (activeEffect.type) {
        case 'speed_boost':
          effectColor = const Color(0xFF2196F3); // Blue
          break;
        case 'damage_boost':
          effectColor = const Color(0xFFF44336); // Red
          break;
        case 'health_regen':
          effectColor = const Color(0xFF4CAF50); // Green
          break;
        case 'shield':
          effectColor = const Color(0xFFFF9800); // Orange
          break;
        case 'invincibility':
          effectColor = const Color(0xFF9C27B0); // Purple
          break;
        case 'weapon_overclock':
          effectColor = const Color(0xFFFF8C00); // Orange
          break;
        default:
          effectColor = const Color(0xFFFFFFFF); // White fallback
      }
      
      final effectGlowPaint = Paint()
        ..color = effectColor.withOpacity((0.6 * glowIntensity).clamp(0.0, 0.9))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      
      // Draw effect glow based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + glowRadius, effectGlowPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'square':
          _drawSquare(canvas, center, effectGlowPaint, glowRadius);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
      }
    }
    
    // Draw main hero shape
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(center, heroRadius, heroPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, shapeSize, heroPaint, 0);
        break;
      case 'square':
        _drawSquare(canvas, center, heroPaint, 0);
        break;
      case 'pentagon':
        _drawPentagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'hexagon':
        _drawHexagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, shapeSize, heroPaint, 0);
        break;
    }
    
    // Draw shield outline if shield effect is active
    if (hasTemporaryEffect('shield') && shield > 0) {
      final shieldOpacity = (shield / maxShield).clamp(0.3, 1.0); // Fade as shield depletes
      final shieldPaint = Paint()
        ..color = const Color(0xFFFF9800).withOpacity(0.6 * shieldOpacity) // Orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Draw shield outline based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + 4, shieldPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'square':
          _drawSquare(canvas, center, shieldPaint, 4);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, shieldPaint, 4);
          break;
      }
    }
    
  }
  
  void _drawTriangle(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius / 2);
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius / 2);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSquare(Canvas canvas, Offset center, Paint paint, double glowRadius) {
    final size = (this.size.x * 0.8) + (glowRadius * 2);
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      ),
      paint,
    );
  }
  
  void _drawPentagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 5; i++) {
      final angle = -90 + (i * 72); // Pentagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHexagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 6; i++) {
      final angle = -90 + (i * 60); // Hexagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHeptagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  // Collision detection method for other components to use
  @override
  bool containsPoint(Vector2 point) {
    final distance = position.distanceTo(point);
    return distance <= heroRadius;
  }
  
  // Get collision radius for enemy collision detection
  double get collisionRadius => heroRadius;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Weapon overclock now handled by temporary effect system
    
    // Update invincibility timer
    // Skip timer check if using ultimate or pending ultimate (ultimate manages its own invulnerability)
    if (isInvincible && !isUsingUltimate && _pendingUltimate == null) {
      invincibilityTimer += dt;
      if (invincibilityTimer >= invincibilityDuration) {
        isInvincible = false;
        invincibilityTimer = 0.0;
      }
    }
    
    // Update damage invincibility timer
    // Skip timer check if using ultimate or pending ultimate (ultimate manages its own invulnerability)
    if (isDamageInvincible && !isUsingUltimate && _pendingUltimate == null) {
      damageInvincibilityTimer += dt;
      if (damageInvincibilityTimer >= damageInvincibilityDuration) {
        isDamageInvincible = false;
        damageInvincibilityTimer = 0.0;
      }
    }
    
    // Update temporary effects
    _updateTemporaryEffects(dt);
    
    // Handle ultimate ability (takes priority over everything)
    if (isUsingUltimate && _currentUltimate != null) {
      _currentUltimate!.update(dt);
    } else if (isUsingAbility) {
      _updateAbility(dt);
    } else {
      _updateMovement(dt);
    }
    
    // Auto-shoot at enemies (disabled during ultimate)
    if (!isUsingUltimate) {
      _tryAutoShoot();
    }
    
    // Regenerate energy
    if (energy < maxEnergy) {
      energy = (energy + 50 * dt).clamp(0, maxEnergy);
    }
    
    // Keep hero within arena bounds (only if not using ultimate - ultimate handles its own bouncing)
    if (!isUsingUltimate) {
      _constrainToArena();
    }
    
    // Update ability cooldown in HUD
    _updateAbilityCooldownDisplay();
  }
  
  void _tryAutoShoot() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    if (currentTime - lastShotTime < (1.0 / (fireRate * attackSpeedMultiplier))) {
      return; // Still on cooldown
    }
    
    // Find nearest enemy
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance && distance <= shootRange) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    // Shoot at nearest enemy if found
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      final direction = (nearestEnemy.position - position).normalized();
      _fireProjectile(direction);
      lastShotTime = currentTime;
    }
  }
  
  void _fireProjectile(Vector2 direction) {
    final projectileCount = totalProjectileCount;
    final projectileBounces = totalProjectileBounces;
    final projectileScale = totalProjectileSize;
    final critChance = totalCritChance;
    
    // Calculate spread angle if multiple projectiles
    final spreadAngle = projectileCount > 1 ? pi / 6 : 0.0; // 30 degrees total spread
    final angleStep = projectileCount > 1 ? spreadAngle / (projectileCount - 1) : 0.0;
    final startAngle = projectileCount > 1 ? -spreadAngle / 2 : 0.0;
    
    for (int i = 0; i < projectileCount; i++) {
      // Calculate direction for each projectile
      Vector2 projectileDirection;
      if (projectileCount == 1) {
        projectileDirection = direction;
      } else {
        final angle = startAngle + (i * angleStep);
        final baseAngle = atan2(direction.y, direction.x);
        final newAngle = baseAngle + angle;
        projectileDirection = Vector2(cos(newAngle), sin(newAngle));
      }
      
      // Check for critical hit (now instant kill, so damage doesn't matter)
      final isCritical = Random().nextDouble() < critChance;
      final finalDamage = 25.0; // Base damage (critical = instant kill)
      
      final projectile = ShapeProjectile(
        startPosition: position.clone(),
        direction: projectileDirection,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: finalDamage,
        isEnemyProjectile: false,
        shapeType: heroData.shape,
        heroColor: heroData.color,
        bounces: projectileBounces,
        sizeScale: projectileScale,
        isCritical: isCritical,
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _updateMovement(double dt) {
    Vector2 inputDirection = Vector2.zero();
    
    // Handle WASD movement
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      inputDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      inputDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      inputDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      inputDirection.x += 1;
    }
    
    // Normalize and apply movement
    if (inputDirection.length > 0) {
      inputDirection.normalize();
      position += inputDirection * moveSpeed * effectiveSpeedMultiplier * dt;
    }
  }
  
  void _updateAbility(double dt) {
    // Handle different ability types based on hero configuration
    switch (heroData.ability.type) {
      case 'dash_damage':
        _updateDashDamage(dt);
        break;
      case 'piercing_shot':
        // Piercing shot is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_stun':
        // Area stun is instant, no update needed
        isUsingAbility = false;
        break;
      case 'radial_burst':
        // Radial burst is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_field':
        // Area field is instant placement, no update needed
        isUsingAbility = false;
        break;
      default:
        isUsingAbility = false;
    }
  }
  
  void _updateDashDamage(double dt) {
    if (abilityTarget == null) {
      isUsingAbility = false;
      return;
    }
    
    final direction = (abilityTarget! - position).normalized();
    final movement = direction * dashSpeed * dt;
    
    // Check for enemy collisions during dash
    // Create a copy to avoid ConcurrentModificationError
    final enemiesCopy = List<Component>.from(gameRef.currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy is PositionComponent) {
        final distanceToEnemy = position.distanceTo(enemy.position);
        // Use different radius checks for different enemy types
        double enemyRadius = 15.0 * DisplayConfig.instance.scaleFactor; // Default radius
        
        if (enemy is EnemyChaser) {
          enemyRadius = enemy.radius;
        } else if (enemy is EnemyShooter) {
          enemyRadius = enemy.radius;
        } else if (enemy is ShieldedChaser) {
          enemyRadius = enemy.radius;
        }
        
        if (distanceToEnemy < heroRadius + enemyRadius) {
          // Damage enemy during rolling surge
          if (enemy is EnemyChaser) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is EnemyShooter) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is ShieldedChaser) {
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          } else {
            // Handle all other enemy types using reflection-like approach
            try {
              final takeDamageMethod = enemy.runtimeType.toString();
              if (takeDamageMethod.contains('Swarmer') || 
                  takeDamageMethod.contains('Bomber') || 
                  takeDamageMethod.contains('Sniper') || 
                  takeDamageMethod.contains('Splitter') || 
                  takeDamageMethod.contains('MineLayer')) {
                (enemy as dynamic).takeDamage(heroData.ability.damage);
              } else {
                // Fallback for unknown enemy types - remove them directly
                if (enemy.parent != null) {
                  gameRef.onEnemyDestroyed(enemy);
                }
              }
            } catch (e) {
              // If dynamic call fails, fallback to direct removal
              if (enemy.parent != null) {
                gameRef.onEnemyDestroyed(enemy);
              }
            }
          }
        }
      }
    }
    
    if (position.distanceTo(abilityTarget!) <= movement.length) {
      position = abilityTarget!;
      isUsingAbility = false;
      abilityTarget = null;
    } else {
      position += movement;
    }
  }
  
  void _tryAbility() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    
    if (currentTime - lastAbilityTime < effectiveCooldown || energy < 25) {
      return; // Ability on cooldown or not enough energy
    }
    
    switch (heroData.ability.type) {
      case 'dash_damage':
        _executeDashDamage();
        break;
      case 'piercing_shot':
        _executePiercingShot();
        break;
      case 'area_stun':
        _executeAreaStun();
        break;
      case 'radial_burst':
        _executeRadialBurst();
        break;
      case 'area_field':
        _executeAreaField();
        break;
      case 'resonance_knockback':
        _executeResonanceKnockback();
        break;
    }
    
    lastAbilityTime = currentTime;
    energy -= 25; // Ability costs energy
    
    // Trigger hit effect on HUD
    gameRef.hud.triggerHitEffect();
  }
  
  void _executeDashDamage() {
    // Play sound effect for circle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Get current input direction for rolling surge
    Vector2 dashDirection = Vector2.zero();
    
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dashDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dashDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dashDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dashDirection.x += 1;
    }
    
    // If no input, dash forward (up)
    if (dashDirection.length == 0) {
      dashDirection = Vector2(0, -1);
    }
    
    dashDirection.normalize();
    // Calculate dash distance with both range and ability size scaling
    final baseRange = heroData.ability.range * DisplayConfig.instance.scaleFactor;
    final scaledRange = baseRange * rangeMultiplier * totalAbilitySize;
    abilityTarget = position + dashDirection * scaledRange;
    
    // Constrain ability target to arena
    abilityTarget!.x = abilityTarget!.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    abilityTarget!.y = abilityTarget!.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
    
    isUsingAbility = true;
  }
  
  void _executePiercingShot() {
    // Play sound effect for triangle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Find direction to nearest enemy or shoot forward
    Vector2 direction = Vector2(0, -1); // Default forward
    
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      direction = (nearestEnemy.position - position).normalized();
    }
    
    // Create massive triangle projectile with hero color and ability size scaling
    final projectile = TriangleProjectile(
      startPosition: position.clone(),
      direction: direction,
      speed: 500.0 * DisplayConfig.instance.scaleFactor,
      damage: heroData.ability.damage,
      isEnemyProjectile: false,
      heroColor: heroData.color, // Pass hero color
      rangeMultiplier: totalAbilitySize, // Scale with enlarged caliber upgrades
      projectileSize: heroData.ability.projectileSize, // Use config size
    );
    
    gameRef.add(projectile);
  }
  
  void _executeAreaStun() {
    // Play sound effect for square hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Calculate effective range with both range and ability size scaling
    final baseRange = heroData.ability.range * DisplayConfig.instance.scaleFactor;
    final effectiveRange = baseRange * rangeMultiplier * totalAbilitySize;
    final stunDuration = heroData.ability.stunDuration ?? 3.0;
    
    // Create visual effect for the ability
    _createSquareAbilityEffect(effectiveRange);
    
    // Stun enemies within range
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= effectiveRange) {
          // Apply stun effect to different enemy types
          if (enemy is EnemyChaser) {
            enemy.stun(stunDuration);
          } else if (enemy is EnemyShooter) {
            enemy.stun(stunDuration);
          } else if (enemy is ShieldedChaser) {
            enemy.stun(stunDuration);
            // Also instantly break shield with ability damage
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          } else {
            // Handle all other enemy types using reflection-like approach
            try {
              final enemyTypeName = enemy.runtimeType.toString();
              if (enemyTypeName.contains('Swarmer') || 
                  enemyTypeName.contains('Bomber') || 
                  enemyTypeName.contains('Sniper') || 
                  enemyTypeName.contains('Splitter') || 
                  enemyTypeName.contains('MineLayer')) {
                (enemy as dynamic).stun(stunDuration);
              }
            } catch (e) {
              // If dynamic call fails, ignore this enemy
              print('Failed to stun enemy: ${enemy.runtimeType}');
            }
          }
        }
      }
    }
    
    // Stun enemy projectiles within range
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= effectiveRange) {
          // Check if it's an enemy projectile and apply slow effect (stun)
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectile.applySlowEffect(0.0); // 0 speed = stunned
          }
        }
      }
    }
    
    print('Shield Bash! Stunned enemies within ${effectiveRange.toInt()} range for ${stunDuration}s');
  }
  
  void _executeRadialBurst() {
    // Play sound effect for pentagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Fire projectiles in all directions
    final projectileCount = heroData.ability.projectileCount ?? 5;
    final angleStep = (2 * pi) / projectileCount;
    
    for (int i = 0; i < projectileCount; i++) {
      final angle = i * angleStep;
      final direction = Vector2(cos(angle), sin(angle));
      
      // Create pentagon-shaped projectiles with pentagon color
      final projectile = ShapeProjectile(
        startPosition: position.clone(),
        direction: direction,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: heroData.ability.damage,
        isEnemyProjectile: false,
        shapeType: 'pentagon', // Use pentagon shape
        heroColor: heroData.color, // Use pentagon's purple color
        bounces: 0,
        sizeScale: totalAbilitySize, // Scale with enlarged caliber
        isCritical: false,
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _executeAreaField() {
    // Play sound effect for hexagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Create visual hex field effect with both range and ability size scaling
    final baseRange = heroData.ability.range * DisplayConfig.instance.scaleFactor;
    final scaledRange = baseRange * rangeMultiplier * totalAbilitySize;
    final duration = heroData.ability.duration ?? 4.0;
    
    final hexField = HexField(
      position: position.clone(),
      radius: scaledRange,
      duration: duration,
      damage: heroData.ability.damage,
      slowPercent: heroData.ability.slowPercent ?? 0.3,
    );
    
    gameRef.add(hexField);
  }
  
  void _executeResonanceKnockback() {
    // Play sound effect for heptagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Calculate range and knockback with both range and ability size scaling
    final baseRange = heroData.ability.range * DisplayConfig.instance.scaleFactor;
    final scaledRange = baseRange * rangeMultiplier * totalAbilitySize;
    final baseKnockback = (heroData.ability.knockbackDistance ?? 30.0) * DisplayConfig.instance.scaleFactor;
    final knockbackDistance = baseKnockback * rangeMultiplier * totalAbilitySize;
    
    // Create visual effect for the ability
    _createHeptagonAbilityEffect(scaledRange);
    
    // Find enemies within range and apply damage + knockback
    final enemiesToKnockback = <Component>[];
    final projectilesToPush = <Component>[];
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= scaledRange) {
          enemiesToKnockback.add(enemy);
        }
      }
    }
    
    // Find enemy projectiles within range to push away and stun them
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= scaledRange) {
          // Check if it's an enemy projectile
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectilesToPush.add(projectile);
          }
        }
      }
    }
    
    // Apply damage and knockback to all enemies in range
    for (final enemy in enemiesToKnockback) {
      if (enemy is PositionComponent) {
        // Apply damage
        if (enemy is EnemyChaser) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is EnemyShooter) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is ShieldedChaser) {
          enemy.takeDamage(heroData.ability.damage, isAbility: true);
        } else {
          // Handle all other enemy types using reflection-like approach
          try {
            final enemyTypeName = enemy.runtimeType.toString();
            if (enemyTypeName.contains('Swarmer') || 
                enemyTypeName.contains('Bomber') || 
                enemyTypeName.contains('Sniper') || 
                enemyTypeName.contains('Splitter') || 
                enemyTypeName.contains('MineLayer')) {
              (enemy as dynamic).takeDamage(heroData.ability.damage);
            }
          } catch (e) {
            // If dynamic call fails, ignore this enemy
            print('Failed to damage enemy: ${enemy.runtimeType}');
          }
        }
        
        // Apply knockback
        final directionToEnemy = (enemy.position - position).normalized();
        final knockbackTarget = enemy.position + directionToEnemy * knockbackDistance;
        
        // Constrain knockback target to arena bounds
        final constrainedTarget = Vector2(
          knockbackTarget.x.clamp(50.0, DisplayConfig.instance.arenaWidth - 50.0),
          knockbackTarget.y.clamp(50.0, DisplayConfig.instance.arenaHeight - 50.0),
        );
        
        enemy.position = constrainedTarget;
      }
    }
    
    // Push away enemy projectiles
    for (final projectile in projectilesToPush) {
      if (projectile is PositionComponent) {
        final directionToProjectile = (projectile.position - position).normalized();
        final pushTarget = projectile.position + directionToProjectile * knockbackDistance;
        
        // Constrain push target to arena bounds
        final constrainedTarget = Vector2(
          pushTarget.x.clamp(0.0, DisplayConfig.instance.arenaWidth),
          pushTarget.y.clamp(0.0, DisplayConfig.instance.arenaHeight),
        );
        
        projectile.position = constrainedTarget;
      }
    }
    
    // Visual feedback
    print('Resonance Knockback! Hit ${enemiesToKnockback.length} enemies and pushed ${projectilesToPush.length} projectiles');
  }
  
  void _updateAbilityCooldownDisplay() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final timeSinceLastAbility = currentTime - lastAbilityTime;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    final cooldownPercent = (timeSinceLastAbility / effectiveCooldown).clamp(0.0, 1.0);
    final remainingSeconds = (effectiveCooldown - timeSinceLastAbility).clamp(0.0, effectiveCooldown);
    
    if (gameRef.hud.isMounted) {
      gameRef.hud.updateAbilityCooldown(cooldownPercent, remainingSeconds);
    }
  }
  
  void _constrainToArena() {
    position.x = position.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    position.y = position.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    
    // Update HUD WASD button states
    final wasdKeys = <String>{};
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW)) wasdKeys.add('W');
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA)) wasdKeys.add('A');
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS)) wasdKeys.add('S');
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD)) wasdKeys.add('D');
    gameRef.hud.updateWASDButtons(wasdKeys);
    
    // Handle universal escape key navigation
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      // Check if stats overlay is visible and hide it first
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
        return true;
      }
      
      // Check if shop is open and close it
      if (gameRef.gameState == GameState.shopping) {
        gameRef.onShopClosed();
        return true;
      }
      
      // Handle pause/resume for playing state
      if (gameRef.gameState == GameState.playing) {
        gameRef.pauseGame();
        return true;
      } else if (gameRef.gameState == GameState.paused) {
        gameRef.resumeGame();
        return true;
      }
    }
    
    // Handle ability (K key only)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyK) {
      _tryAbility();
      return true;
    }
    
    // Handle clone activation with 'C' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (canActivateClone()) {
        activateClone();
      }
      return true;
    }
    
    // Handle stats overlay toggle with 'I' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyI) {
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
      } else {
        gameRef.statsOverlay.show();
      }
      return true;
    }
    
    // Handle ultimate ability with 'L' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyL) {
      castUltimate();
      return true;
    }
    
    return false;
  }
  
  void takeDamage(double damage, {String? sourceType}) {
    if (isInvincible || isDamageInvincible || isUsingAbility) {
      return; // No damage while invincible, damage invincible, or using ability
    }
    
    // Scale damage based on current wave
    final scaledDamage = WaveConfig.instance.getScaledDamage(damage, gameRef.currentWave);
    double remainingDamage = scaledDamage;
    
    // Shield absorbs damage first
    if (shield > 0) {
      if (shield >= remainingDamage) {
        // Shield absorbs all damage
        shield -= remainingDamage;
        remainingDamage = 0;
      } else {
        // Shield absorbs partial damage and breaks
        remainingDamage -= shield;
        shield = 0;
        
        // Remove shield effect when shield is broken
        if (hasTemporaryEffect('shield')) {
          print('Shield broken! Removing shield effect.');
          _removeEffectImmediate('shield');
          _temporaryEffects.remove('shield');
        }
      }
    }
    
    // Apply remaining damage to health
    if (remainingDamage > 0) {
      health = (health - remainingDamage).clamp(0, maxHealth);
    }
    
    // Activate damage invincibility
    isDamageInvincible = true;
    damageInvincibilityTimer = 0.0;
    
    if (health <= 0) {
      gameRef.onHeroDeath(killerType: sourceType);
    }
  }
  
  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
  
  void addCoins(int amount) {
    final multiplier = totalCoinMultiplier;
    final finalAmount = (amount * multiplier).round();
    coins = (coins + finalAmount).clamp(0, 9999); // Cap coins at 9999
    if (multiplier > 1.0) {
      print('Coin Magnet: ${amount} -> ${finalAmount} coins (${multiplier}x)');
    }
  }
  
  void spendCoins(int amount) {
    coins = max(0, coins - amount);
  }
  
  void activateInvincibility() {
    isInvincible = true;
    invincibilityTimer = invincibilityDuration;
  }
  
  void _createSquareAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'square',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  void _createHeptagonAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'heptagon',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  // Temporary effects system - only one effect at a time
  void applyTemporaryEffect(String effectType, double value, double duration) {
    // Remove any existing effect first (only one at a time)
    if (_temporaryEffects.isNotEmpty) {
      final oldEffect = _temporaryEffects.entries.first;
      _removeEffectImmediate(oldEffect.key);
      _temporaryEffects.clear();
      print('Replaced effect: ${oldEffect.key} -> $effectType');
    }
    
    // Apply new effect
    _temporaryEffects[effectType] = TemporaryEffect(
      type: effectType,
      value: value,
      duration: duration,
    );
    
    // Apply immediate effects
    _applyEffectImmediate(effectType, value);
    
    print('Applied temporary effect: $effectType (${value}, ${duration}s)');
  }
  
  void _updateTemporaryEffects(double dt) {
    final expiredEffects = <String>[];
    
    for (final entry in _temporaryEffects.entries) {
      final effect = entry.value;
      effect.update(dt);
      
      if (effect.isExpired) {
        expiredEffects.add(entry.key);
        _removeEffectImmediate(entry.key);
      } else {
        // Apply ongoing effects
        _applyEffectOngoing(effect.type, effect.value, dt);
      }
    }
    
    // Remove expired effects
    for (final effectType in expiredEffects) {
      _temporaryEffects.remove(effectType);
    }
  }
  
  void _applyEffectImmediate(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
        speedMultiplier *= (1.0 + value);
        break;
      case 'damage_boost':
        // This will be applied in damage calculations
        break;
      case 'shield':
        shield += value;
        maxShield = maxShield > shield ? maxShield : shield;
        break;
      case 'invincibility':
        isInvincible = true;
        invincibilityTimer = 0.0;
        break;
      case 'weapon_overclock':
        attackSpeedMultiplier *= (1.0 + value);
        break;
    }
  }
  
  void _applyEffectOngoing(String effectType, double value, double dt) {
    switch (effectType) {
      case 'health_regen':
        heal(value * dt);
        break;
    }
  }
  
  void _removeEffectImmediate(String effectType) {
    switch (effectType) {
      case 'speed_boost':
        // Note: This is a simplified approach. In a full implementation,
        // you'd want to track the original multiplier and restore it
        speedMultiplier = 1.0; // Reset to base
        break;
      case 'damage_boost':
        // Reset damage multiplier
        break;
      case 'shield':
        // Shield naturally decays over time
        break;
      case 'invincibility':
        // Invincibility expires naturally
        break;
      case 'weapon_overclock':
        // Reset attack speed multiplier
        attackSpeedMultiplier = 1.0; // Reset to base
        break;
    }
  }
  
  // Get effective damage multiplier including temporary effects
  double get effectiveDamageMultiplier {
    double multiplier = 1.0;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'damage_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Get effective speed multiplier including temporary effects
  double get effectiveSpeedMultiplier {
    double multiplier = speedMultiplier;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'speed_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Check if hero has a specific temporary effect
  bool hasTemporaryEffect(String effectType) {
    return _temporaryEffects.containsKey(effectType);
  }
  
  // Get remaining time for a temporary effect
  double getTemporaryEffectTime(String effectType) {
    final effect = _temporaryEffects[effectType];
    return effect?.remainingTime ?? 0.0;
  }
  
  // Get current active effect for UI display
  TemporaryEffect? get currentActiveEffect {
    return _temporaryEffects.isNotEmpty ? _temporaryEffects.values.first : null;
  }
  
  // Get current active effect info as a formatted string
  String get activeEffectDisplay {
    final effect = currentActiveEffect;
    if (effect == null) return 'None';
    
    final effectName = _getEffectDisplayName(effect.type);
    final effectValue = _getEffectDisplayValue(effect.type, effect.value);
    
    // Handle infinite duration effects (like persistent shields)
    if (effect.remainingTime.isInfinite || effect.remainingTime.isNaN) {
      return '$effectName $effectValue (∞)';
    }
    
    final timeLeft = effect.remainingTime.ceil();
    return '$effectName $effectValue (${timeLeft}s)';
  }
  
  String _getEffectDisplayName(String effectType) {
    switch (effectType) {
      case 'speed_boost': return 'Speed';
      case 'damage_boost': return 'Damage';
      case 'health_regen': return 'Regen';
      case 'shield': return 'Shield';
      case 'invincibility': return 'Invul';
      case 'weapon_overclock': return 'Overclock';
      default: return effectType;
    }
  }
  
  String _getEffectDisplayValue(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
      case 'damage_boost':
      case 'weapon_overclock':
        return '+${(value * 100).round()}%';
      case 'health_regen':
        return '+${value.round()}/s';
      case 'shield':
        return '+${value.round()}';
      case 'invincibility':
        return 'ON';
      default:
        return value.toString();
    }
  }

  // Stackable passive effects system
  void addPassiveEffect(String effectType, int maxStacks) {
    final currentStacks = _passiveEffectStacks[effectType] ?? 0;
    if (currentStacks < maxStacks) {
      _passiveEffectStacks[effectType] = currentStacks + 1;
      print('Added passive effect: $effectType (${currentStacks + 1}/$maxStacks stacks)');
    } else {
      print('Cannot add $effectType: already at max stacks ($maxStacks)');
    }
  }
  
  int getPassiveEffectStacks(String effectType) {
    return _passiveEffectStacks[effectType] ?? 0;
  }
  
  bool hasPassiveEffect(String effectType) {
    return _passiveEffectStacks.containsKey(effectType) && _passiveEffectStacks[effectType]! > 0;
  }
  
  // Get calculated values based on passive effects
  int get totalProjectileCount {
    return 1 + getPassiveEffectStacks('projectile_count');
  }
  
  int get totalProjectileBounces {
    return getPassiveEffectStacks('projectile_bounces');
  }
  
  double get totalProjectileSize {
    final enlargedCaliberValue = ItemConfig.instance.getItemById('enlarged_caliber')?.effect.value ?? 0.25;
    return 1.0 + (getPassiveEffectStacks('projectile_size') * 0.5) + (getPassiveEffectStacks('enlarged_caliber') * enlargedCaliberValue);
  }
  
  double get totalAbilitySize {
    final enlargedCaliberValue = ItemConfig.instance.getItemById('enlarged_caliber')?.effect.value ?? 0.25;
    return 1.0 + (getPassiveEffectStacks('enlarged_caliber') * enlargedCaliberValue);
  }
  
  double get totalCharacterSize {
    final enlargedCaliberValue = ItemConfig.instance.getItemById('enlarged_caliber')?.effect.value ?? 0.25;
    return 1.0 + (getPassiveEffectStacks('enlarged_caliber') * enlargedCaliberValue);
  }
  
  double get enlargedCaliberSpeedReduction {
    final enlargedCaliberValue = ItemConfig.instance.getItemById('enlarged_caliber')?.effect.value ?? 0.25;
    return getPassiveEffectStacks('enlarged_caliber') * enlargedCaliberValue;
  }
  
  int get totalDroneCount {
    return getPassiveEffectStacks('drone_count');
  }
  
  double get totalLifeSteal {
    return getPassiveEffectStacks('life_steal') * 0.05;
  }
  
  double get totalShieldHP {
    return getPassiveEffectStacks('shield_hp') * 5.0;
  }
  
  double get totalCoinMultiplier {
    return 1.0 + (getPassiveEffectStacks('coin_multiplier') * 0.2);
  }
  
  double get totalHealPerKill {
    return getPassiveEffectStacks('heal_per_kill') * 2.0;
  }
  
  double get totalCritChance {
    return getPassiveEffectStacks('crit_chance') * 0.02;
  }
  
  double get totalMaxHealthBoost {
    return getPassiveEffectStacks('max_health_boost') * 10.0;
  }
  
  bool get hasCloneProjection {
    return hasPassiveEffect('clone_spawn');
  }
  
  void resetPassiveEffects() {
    _passiveEffectStacks.clear();
    destroyAllDrones();
    destroyClone();
    ultimateCharge = 0;
    if (_currentUltimate != null) {
      _currentUltimate!.deactivate();
      _currentUltimate = null;
    }
    _pendingUltimate = null;
  }
  
  /// Factory method to create the appropriate ultimate ability for this hero
  UltimateAbility? _createUltimate() {
    switch (heroId) {
      case 'circle':
        return EngulfRampage(this);
      // Add other heroes' ultimates here as they're implemented
      // case 'triangle':
      //   return ImmunoglobulinBarrage(this);
      // case 'square':
      //   return CytokineCataclysm(this);
      // etc.
      default:
        return null;
    }
  }
  
  void castUltimate() {
    print('[ULTIMATE] Step 1: castUltimate() called');
    print('[ULTIMATE] Current charge: $ultimateCharge / $maxUltimateCharge');
    
    if (ultimateCharge >= maxUltimateCharge) {
      print('[ULTIMATE] Step 2: Charge is full, proceeding with ultimate cast');
      ultimateCharge = 0;
      print('[ULTIMATE] Step 3: Charge reset to 0');
      
      // Make hero invulnerable immediately when ultimate is cast
      // This protects the hero during video playback and ultimate execution
      // Set timer to a large value so it doesn't expire during video + ultimate (6+ seconds total)
      print('[ULTIMATE] Step 4: Making hero invulnerable for video/ultimate duration');
      isInvincible = true;
      invincibilityTimer = 0.0; // Will be managed by ultimate deactivation, not timer
      isDamageInvincible = true;
      damageInvincibilityTimer = 0.0; // Will be managed by ultimate deactivation, not timer
      print('[ULTIMATE] Hero invulnerability set: isInvincible=$isInvincible, isDamageInvincible=$isDamageInvincible');
      
      // Create the ultimate (but don't activate it yet)
      print('[ULTIMATE] Step 5: Creating ultimate ability for hero: $heroId');
      _pendingUltimate = _createUltimate();
      
      if (_pendingUltimate != null) {
        print('[ULTIMATE] Step 6: Ultimate created: ${_pendingUltimate!.name}');
        
        // Check if we should play video first
        if (heroData.ultimate?.videoPath != null) {
          print('[ULTIMATE] Step 7: Video path found, will play video first');
          print('[ULTIMATE] Video path: ${heroData.ultimate!.videoPath}');
          gameRef.ultimateVideoPath = heroData.ultimate!.videoPath;
          gameRef.onUltimateVideoComplete = () {
            print('[ULTIMATE] Step 8: Video completed callback called');
            print('[ULTIMATE] Step 9: Now activating ultimate after video');
            _activatePendingUltimate();
          };
          print('[ULTIMATE] Step 10: Adding UltimateVideo overlay');
          gameRef.overlays.add('UltimateVideo');
          print('[ULTIMATE] ✅ Video overlay added - ultimate will activate after video');
        } else {
          print('[ULTIMATE] Step 7: No video path, activating ultimate immediately');
          _activatePendingUltimate();
        }
      } else {
        print('[ULTIMATE] ❌ Ultimate not implemented for hero: $heroId');
      }
    } else {
      print('[ULTIMATE] ❌ Charge not full, cannot cast ultimate');
    }
  }
  
  void _activatePendingUltimate() {
    if (_pendingUltimate == null) {
      print('[ULTIMATE] ❌ No pending ultimate to activate');
      return;
    }
    
    print('[ULTIMATE] Step 10: Activating pending ultimate: ${_pendingUltimate!.name}');
    _currentUltimate = _pendingUltimate;
    _pendingUltimate = null;
    
    print('[ULTIMATE] Step 11: Calling ultimate.activate()');
    _currentUltimate!.activate();
    print('[ULTIMATE] ✅ Ultimate activated and executing!');
  }
  
  // Apply heal per kill effect when an enemy is defeated
  void onEnemyKilled() {
    totalKills++;
    
    // Increment ultimate charge (1 charge per kill)
    ultimateCharge = (ultimateCharge + 1).clamp(0, maxUltimateCharge);
    
    final healAmount = totalHealPerKill;
    if (healAmount > 0) {
      heal(healAmount);
      print('Healed ${healAmount} HP from kill');
    }
    
    // Auto-injector: +2 max HP per 10 kills, max 50 HP per stack
    final autoInjectorStacks = getPassiveEffectStacks('auto_injector');
    if (autoInjectorStacks > 0 && totalKills % 10 == 0) {
      final maxBonusPerStack = 50;
      final currentBonusPerStack = (totalKills ~/ 10) * 2;
      
      // Calculate how much bonus HP each stack should contribute
      final targetBonusPerStack = currentBonusPerStack.clamp(0, maxBonusPerStack);
      final totalTargetBonus = targetBonusPerStack * autoInjectorStacks;
      
      if (totalTargetBonus > autoInjectorBonusHP) {
        final hpIncrease = totalTargetBonus - autoInjectorBonusHP;
        maxHealth += hpIncrease;
        health += hpIncrease; // Also increase current health
        autoInjectorBonusHP = totalTargetBonus;
        print('Auto-Injector: +${hpIncrease} Max HP! Total kills: ${totalKills}, Max HP: ${maxHealth}');
      }
    }
  }
  
  // Regenerate shields between waves (Armor Plating effect)
  void regenerateShields() {
    final armorShields = totalShieldHP;
    if (armorShields > 0) {
      // Apply armor plating as a persistent shield effect
      applyTemporaryEffect('shield', armorShields, double.infinity);
      print('Armor plating shields regenerated to ${armorShields.toStringAsFixed(1)} HP');
    }
  }
  
  // Drone management system
  void updateDroneCount() {
    final targetDroneCount = totalDroneCount;
    final currentDroneCount = _activeDrones.length;
    
    if (targetDroneCount > currentDroneCount) {
      // Spawn new drones
      for (int i = currentDroneCount; i < targetDroneCount; i++) {
        final drone = DroneWingman(owner: this, droneIndex: i);
        _activeDrones.add(drone);
        gameRef.add(drone);
        print('Spawned drone ${i + 1}/${targetDroneCount}');
      }
    } else if (targetDroneCount < currentDroneCount) {
      // Remove excess drones
      while (_activeDrones.length > targetDroneCount) {
        final drone = _activeDrones.removeLast();
        drone.destroy();
        print('Removed drone. Remaining: ${_activeDrones.length}');
      }
    }
  }
  
  void updateHeroSize() {
    heroRadius = 15.0 * DisplayConfig.instance.scaleFactor * totalCharacterSize;
    // Update component size as well
    size = Vector2.all(heroRadius * 2);
  }
  
  void destroyAllDrones() {
    for (final drone in _activeDrones) {
      drone.destroy();
    }
    _activeDrones.clear();
    print('All drones destroyed');
  }
  
  // Clone management system
  bool canActivateClone() {
    return hasCloneProjection && _activeClone == null && health > maxHealth * 0.5;
  }
  
  void activateClone() {
    print('🤖 Attempting to activate clone...');
    print('   - Has clone projection: ${hasCloneProjection}');
    print('   - No active clone: ${_activeClone == null}');
    print('   - Current health: ${health.toStringAsFixed(1)}/${maxHealth.toStringAsFixed(1)}');
    print('   - Required health: ${(maxHealth * 0.5).toStringAsFixed(1)}');
    
    if (!canActivateClone()) {
      print('❌ Cannot activate clone: requirements not met');
      return;
    }
    
    // Pay health cost (50% of current health)
    final healthCost = health * 0.5;
    health -= healthCost;
    
    // Spawn clone directly to the right with clear gap
    final cloneOffset = Vector2(80, 0); // Simple fixed offset to the right
    final clonePosition = position + cloneOffset;
    
    print('🤖 Creating HeroClone at position: (${clonePosition.x}, ${clonePosition.y})');
    _activeClone = HeroClone(owner: this, spawnPosition: clonePosition);
    
    print('🤖 Adding clone to game...');
    gameRef.add(_activeClone!);
    
    print('✅ CLONE ACTIVATED! Health cost: ${healthCost.toStringAsFixed(1)}, Clone mounted: ${_activeClone!.isMounted}');
  }
  
  void destroyClone() {
    if (_activeClone != null) {
      _activeClone!.destroy();
      _activeClone = null;
      print('Clone destroyed');
    }
  }
  
  bool get hasActiveClone => _activeClone != null;
  
  // Getter for passive effect stacks (for stats display)
  Map<String, int> get passiveEffectStacks => Map.from(_passiveEffectStacks);
  
  void onCloneDestroyed(HeroClone clone) {
    if (_activeClone == clone) {
      _activeClone = null;
      print('Active clone reference cleared');
    }
  }
  
  @override
  void onRemove() {
    // Clean up display config listener
    if (_displayConfigListener != null) {
      DisplayConfig.instance.removeListener(_displayConfigListener!);
      _displayConfigListener = null;
    }
    super.onRemove();
  }
}

// Visual effect component for abilities
class AbilityVisualEffect extends PositionComponent with HasGameRef<CircleRougeGame> {
  final double effectRange;
  final String shape;
  final Color color;
  
  double lifetime = 0.0;
  static const double totalLifetime = 0.5; // Blink once and disappear
  static const double blinkDuration = 0.25; // Half the lifetime for one blink
  
  AbilityVisualEffect({
    required Vector2 position,
    required this.effectRange,
    required this.shape,
    required this.color,
  }) : super(
    position: position,
    size: Vector2.all(effectRange * 2),
    anchor: Anchor.center,
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    lifetime += dt;
    
    // Remove after total lifetime
    if (lifetime >= totalLifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Calculate opacity with blinking effect
    final blinkProgress = (lifetime / blinkDuration) % 1.0;
    final opacity = (sin(blinkProgress * pi * 2) * 0.15 + 0.1).clamp(0.0, 0.25); // 25% max opacity
    
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = color.withOpacity(opacity * 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Draw the shape based on type
    switch (shape) {
      case 'square':
        final rect = Rect.fromCenter(
          center: center,
          width: effectRange * 2,
          height: effectRange * 2,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;
      case 'heptagon':
        final path = _createHeptagonPath(center, effectRange);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }
  
  Path _createHeptagonPath(Offset center, double radius) {
    final path = Path();
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * pi / 180);
      final y = center.dy + radius * sin(angle * pi / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    return path;
  }
} 