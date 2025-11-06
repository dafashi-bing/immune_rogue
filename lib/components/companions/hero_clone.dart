import 'dart:math' as math;
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../enemies/shape_projectile.dart';
import '../hero.dart';

class HeroClone extends PositionComponent with HasGameRef<CircleRougeGame> {
  final Hero owner;
  
  // Visual properties
  late Paint clonePaint;
  late Paint glowPaint;
  late double cloneRadius;
  
  // AI properties
  double lastShotTime = 0.0;
  double fireRate = 2.0; // Same as hero base fire rate
  
  // Clone behavior
  double lifetime = 15.0; // Clone lasts 15 seconds
  double currentLifetime = 0.0;
  
  // Movement and positioning
  Vector2 targetPosition;
  Vector2 lastOwnerPosition;
  double followDistance = 80.0;
  
  // Target tracking (similar to drone but more aggressive)
  Component? currentTarget;
  double targetScanTimer = 0.0;
  static const double targetScanInterval = 0.3; // Scan more frequently than drones
  
  HeroClone({
    required this.owner,
    required Vector2 spawnPosition,
  }) : targetPosition = spawnPosition,
       lastOwnerPosition = owner.position.clone(),
       super(
    position: spawnPosition,
    anchor: Anchor.center,
  ) {
    cloneRadius = owner.heroRadius * 0.8; // Slightly smaller than hero
    size = Vector2.all(cloneRadius * 2);
    
    // Clone visual styling - more transparent with stronger cyan tint and glow
    final heroColor = owner.heroData.color;
    clonePaint = Paint()..color = Color.lerp(heroColor, const Color(0xFF00FFFF), 0.6)!.withOpacity(0.5);
    glowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    
    print('🤖 HeroClone created at position: (${position.x.toStringAsFixed(1)}, ${position.y.toStringAsFixed(1)}), radius: ${cloneRadius.toStringAsFixed(1)}');
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Draw stronger glow effect
    canvas.drawCircle(center, cloneRadius + 8, glowPaint);
    // Add pulsing outer glow
    final pulseGlow = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.3 + sin(currentLifetime * 4) * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, cloneRadius + 15, pulseGlow);
    
    // Draw clone shape (same as hero but semi-transparent)
    switch (owner.heroData.shape) {
      case 'circle':
        canvas.drawCircle(center, cloneRadius, clonePaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, center, clonePaint);
        break;
      case 'square':
        _drawSquare(canvas, center, clonePaint);
        break;
      case 'pentagon':
        _drawPentagon(canvas, center, clonePaint);
        break;
      case 'hexagon':
        _drawHexagon(canvas, center, clonePaint);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, center, clonePaint);
        break;
    }
    
    // Draw lifetime indicator (shrinking circle)
    final lifetimeRatio = (lifetime - currentLifetime) / lifetime;
    if (lifetimeRatio < 0.3) {
      final indicatorPaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      final indicatorRadius = cloneRadius + 10 + (sin(currentLifetime * 10) * 3);
      canvas.drawCircle(center, indicatorRadius, indicatorPaint);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Update lifetime
    currentLifetime += dt;
    if (currentLifetime >= lifetime) {
      destroy();
      return;
    }
    
    // Update AI behavior
    _updateMovement(dt);
    _updateTargeting(dt);
    _tryAutoFire();
  }
  
  void _updateMovement(double dt) {
    // Follow hero but maintain some distance and independence
    final ownerPos = owner.position;
    final distanceToOwner = position.distanceTo(ownerPos);
    final scaledFollowDistance = followDistance * DisplayConfig.instance.scaleFactor;
    
    if (distanceToOwner > scaledFollowDistance) {
      // Move towards hero if too far
      final direction = (ownerPos - position).normalized();
      final moveSpeed = owner.moveSpeed * 0.8; // Slightly slower than hero
      position += direction * moveSpeed * dt;
    } else if (currentTarget != null && currentTarget is PositionComponent) {
      // Move towards target for better positioning
      final targetPos = (currentTarget! as PositionComponent).position;
      final distanceToTarget = position.distanceTo(targetPos);
      
      if (distanceToTarget > 120 * DisplayConfig.instance.scaleFactor) {
        final direction = (targetPos - position).normalized();
        final moveSpeed = owner.moveSpeed * 0.6;
        position += direction * moveSpeed * dt;
      }
    }
    
    lastOwnerPosition = ownerPos;
  }
  
  void _updateTargeting(double dt) {
    targetScanTimer += dt;
    if (targetScanTimer >= targetScanInterval) {
      _scanForTargets();
      targetScanTimer = 0.0;
    }
  }
  
  void _scanForTargets() {
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    final cloneRange = owner.shootRange * 0.9; // Slightly shorter range than hero
    
    // Find the nearest enemy within range
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance && distance <= cloneRange) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    currentTarget = nearestEnemy;
  }
  
  void _tryAutoFire() {
    if (currentTarget == null || !(currentTarget is PositionComponent)) {
      return;
    }
    
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Use hero's attack speed but slightly reduced
    final effectiveFireRate = fireRate * (owner.attackSpeedMultiplier * 0.8);
    
    // Check fire rate cooldown
    if (currentTime - lastShotTime < (1.0 / effectiveFireRate)) {
      return;
    }
    
    // Verify target is still in range
    final targetPos = (currentTarget! as PositionComponent).position;
    final distance = position.distanceTo(targetPos);
    final cloneRange = owner.shootRange * 0.9;
    
    if (distance > cloneRange) {
      currentTarget = null;
      return;
    }
    
    // Fire at target
    final direction = (targetPos - position).normalized();
    _fireProjectile(direction);
    lastShotTime = currentTime;
  }
  
  void _fireProjectile(Vector2 direction) {
    // Clone fires similar projectiles to hero but with reduced effects
    final projectileCount = math.max(1, (owner.totalProjectileCount * 0.7).round());
    final critChance = owner.totalCritChance * 0.5; // Half crit chance
    
    // Calculate spread for multiple projectiles
    final spreadAngle = projectileCount > 1 ? pi / 8 : 0.0; // Smaller spread than hero
    final angleStep = projectileCount > 1 ? spreadAngle / (projectileCount - 1) : 0.0;
    final startAngle = projectileCount > 1 ? -spreadAngle / 2 : 0.0;
    
    for (int i = 0; i < projectileCount; i++) {
      Vector2 projectileDirection;
      if (projectileCount == 1) {
        projectileDirection = direction;
      } else {
        final angle = startAngle + (i * angleStep);
        final baseAngle = atan2(direction.y, direction.x);
        final newAngle = baseAngle + angle;
        projectileDirection = Vector2(cos(newAngle), sin(newAngle));
      }
      
      // Check for critical hit
      final isCritical = Random().nextDouble() < critChance;
      final baseDamage = 20.0; // Slightly less than hero
      final finalDamage = isCritical ? baseDamage * 2.0 : baseDamage;
      
      final projectile = ShapeProjectile(
        startPosition: position.clone(),
        direction: projectileDirection,
        speed: 380.0 * DisplayConfig.instance.scaleFactor, // Slightly slower
        damage: finalDamage,
        isEnemyProjectile: false,
        shapeType: owner.heroData.shape,
        heroColor: clonePaint.color,
        bounces: math.max(0, owner.totalProjectileBounces - 1), // One less bounce
        sizeScale: owner.totalProjectileSize * 0.9, // Slightly smaller
        isCritical: isCritical,
      );
      
      gameRef.add(projectile);
    }
  }
  
  void destroy() {
    // Visual effect when clone expires
    print('Clone expired after ${currentLifetime.toStringAsFixed(1)} seconds');
    
    // Notify owner that clone is being destroyed
    owner.onCloneDestroyed(this);
    
    removeFromParent();
  }
  
  // Helper methods for drawing shapes (copied from hero)
  void _drawTriangle(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final radius = cloneRadius;
    
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * 0.866, center.dy + radius * 0.5);
    path.lineTo(center.dx + radius * 0.866, center.dy + radius * 0.5);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSquare(Canvas canvas, Offset center, Paint paint) {
    final rect = Rect.fromCenter(center: center, width: cloneRadius * 1.4, height: cloneRadius * 1.4);
    canvas.drawRect(rect, paint);
  }
  
  void _drawPentagon(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final radius = cloneRadius;
    final angleStep = 2 * pi / 5;
    
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + i * angleStep;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHexagon(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final radius = cloneRadius;
    final angleStep = 2 * pi / 6;
    
    for (int i = 0; i < 6; i++) {
      final angle = -pi / 2 + i * angleStep;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHeptagon(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final radius = cloneRadius;
    final angleStep = 2 * pi / 7;
    
    for (int i = 0; i < 7; i++) {
      final angle = -pi / 2 + i * angleStep;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
}
