import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
import '../sound_manager.dart';
// Item drop imports removed - now handled by ConsumableDropManager

class ShieldedChaser extends PositionComponent with HasGameRef<CircleRougeGame> {
  // Visual properties
  late Paint bodyPaint;
  late Paint shieldPaint;
  late double radius;
  
  // Sprite component for image rendering
  SpriteComponent? spriteComponent;
  bool hasSprite = false;
  
  // Movement speed configuration
  static const double baseSpeed = 60.0; // Default fallback speed
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('shielded_chaser') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  // Shield system
  double shieldHealth = 60.0; // Separate shield health
  double maxShieldHealth = 60.0;
  bool hasShield = true;
  
  // Combat properties
  double health = 30.0;
  double maxHealth = 30.0;
  bool isDead = false;
  
  // AI behavior
  double lastDirectionChange = 0.0;
  Vector2 currentDirection = Vector2.zero();
  
  // Visual effects
  double shieldRotation = 0.0;
  
  // Stun mechanics
  bool isStunned = false;
  double stunTimer = 0.0;
  
  // Slow effect mechanics
  bool isSlowed = false;
  double speedMultiplier = 1.0;
  
  ShieldedChaser({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    size: Vector2.all(60.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    radius = 30.0 * DisplayConfig.instance.scaleFactor;
    bodyPaint = Paint()..color = const Color(0xFF795548); // Brown color for armored look
    
    // Shield paint with transparency based on shield health
    _updateShieldVisuals();
  }
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
    
    // Try to load sprite image
    final imagePath = EnemyConfigManager.instance.getEnemyImagePath('shielded_chaser');
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
        print('Could not load enemy image for shielded_chaser: $e');
        hasSprite = false;
      }
    }
  }
  
  void _initializeHealth() {
    // Get base health from enemy config
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('shielded_chaser', 45.0);
    // Apply wave-based scaling
    final scaledHealth = WaveConfig.instance.getScaledHealth(baseHealth, gameRef.currentWave);
    health = scaledHealth;
    maxHealth = scaledHealth;
    
    // Also scale shield health
    final baseShieldHealth = EnemyConfigManager.instance.getEnemyProperty('shielded_chaser', 'shield_health', 20.0);
    final scaledShieldHealth = WaveConfig.instance.getScaledHealth(baseShieldHealth, gameRef.currentWave);
    shieldHealth = scaledShieldHealth;
    maxShieldHealth = scaledShieldHealth;
  }
  
  void _updateShieldVisuals() {
    if (hasShield) {
      final alpha = (shieldHealth / maxShieldHealth * 0.8 + 0.2).clamp(0.2, 1.0);
      shieldPaint = Paint()
        ..color = const Color(0xFF2196F3).withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Draw main enemy body (sprite or circle)
    if (!hasSprite || spriteComponent == null) {
      canvas.drawCircle(center, radius, bodyPaint);
    }
    // Sprite component will render itself if present
    
    // Draw shield overlay if active (always on top)
    if (hasShield) {
      _drawHexagonalShield(canvas, center);
    }
  }
  
  void _drawHexagonalShield(Canvas canvas, Offset center) {
    final path = Path();
    final shieldRadius = radius + 16.0; // Shield is larger than the body
    
    // Create hexagonal shield shape
    for (int i = 0; i < 6; i++) {
      final angle = (shieldRotation + i * 60) * (pi / 180); // Convert to radians
      final x = center.dx + shieldRadius * cos(angle);
      final y = center.dy + shieldRadius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    // Draw shield with glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFF4169E1).withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, shieldPaint);
    
    // Draw shield health bar if shield is damaged
    if (shieldHealth < maxShieldHealth) {
      _drawShieldHealthBar(canvas, center);
    }
  }
  
  void _drawShieldHealthBar(Canvas canvas, Offset center) {
    final barWidth = radius * 2;
    final barHeight = 4.0;
    final barY = center.dy - radius - 15.0;
    
    // Background
    final backgroundRect = Rect.fromLTWH(
      center.dx - barWidth / 2,
      barY,
      barWidth,
      barHeight,
    );
    canvas.drawRect(backgroundRect, Paint()..color = Colors.black.withOpacity(0.5));
    
    // Shield health fill
    final shieldPercent = shieldHealth / maxShieldHealth;
    final shieldRect = Rect.fromLTWH(
      center.dx - barWidth / 2,
      barY,
      barWidth * shieldPercent,
      barHeight,
    );
    canvas.drawRect(shieldRect, Paint()..color = const Color(0xFF4169E1));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    if (isDead) return;
    
    // Update shield rotation for visual effect
    shieldRotation += 45.0 * dt; // Rotate 45 degrees per second
    if (shieldRotation >= 360.0) {
      shieldRotation -= 360.0;
    }
    
    // Update shield visuals
    if (hasShield) {
      _updateShieldVisuals();
    }
    
    // Handle stun
    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
      }
      return; // Don't move while stunned
    }
    
    // Move towards hero
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final directionToHero = (hero.position - position).normalized();
      
      // Apply no-stay zone force to keep enemies away from edges
      final noStayForce = gameRef.getNoStayZoneForce(position);
      
      // Add some randomness to movement to avoid clustering
      final random = Random();
      if (DateTime.now().millisecondsSinceEpoch / 1000.0 - lastDirectionChange > 1.0) {
        currentDirection = directionToHero + Vector2(
          (random.nextDouble() - 0.5) * 0.5,
          (random.nextDouble() - 0.5) * 0.5,
        );
        currentDirection.normalize();
        lastDirectionChange = DateTime.now().millisecondsSinceEpoch / 1000.0;
      }
      
      // Combine current direction with no-stay force
      final finalDirection = currentDirection + (noStayForce * dt);
      if (finalDirection.length > 0) {
        finalDirection.normalize();
      }
      
      // Apply speed multiplier for slow effects
      final effectiveSpeed = speed * speedMultiplier;
      position += finalDirection * effectiveSpeed * dt;
      
      // Keep within arena bounds
      _constrainToArena();
      
      // Check collision with hero
      final distanceToHero = position.distanceTo(hero.position);
      if (distanceToHero < radius + hero.collisionRadius) {
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('shielded_chaser', 10.0);
        hero.takeDamage(contactDamage, sourceType: 'shielded_chaser');
      }
    }
  }
  
  void takeDamage(double damage, {bool isAbility = false}) {
    if (hasShield) {
      if (isAbility) {
        // Hero abilities instantly break shields
        _breakShield();
      } else {
        // Regular damage affects shield health
        shieldHealth -= damage;
        if (shieldHealth <= 0) {
          _breakShield();
        }
      }
    } else {
      // No shield - damage goes to health
      health -= damage;
      if (health <= 0) {
        _destroyEnemy();
      }
    }
  }
  
  void _breakShield() {
    hasShield = false;
    shieldHealth = 0;
    
    // Play shield break sound
    SoundManager().playShieldBreakSound();
    print('Shield broken!');
  }
  
  void _destroyEnemy() {
    // Item drops are now handled by the unified ConsumableDropManager
    // via gameRef.onEnemyDestroyed(this)
    
    // Enemy destroyed
    if (parent != null) {
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
    }
  }
  
  void stun(double duration) {
    isStunned = true;
    stunTimer = duration;
  }
  
  double get totalHealth => health + (hasShield ? shieldHealth : 0);
  
  void _constrainToArena() {
    position.x = position.x.clamp(radius, DisplayConfig.instance.arenaWidth - radius);
    position.y = position.y.clamp(radius, DisplayConfig.instance.arenaHeight - radius);
  }

  void applySlowEffect(double multiplier) {
    if (!isSlowed) {
      isSlowed = true;
      speedMultiplier = multiplier;
      // Change color to indicate slowed state
      bodyPaint.color = const Color(0xFF4A4A4A); // Darker gray when slowed
    }
  }
} 