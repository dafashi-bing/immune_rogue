import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/item_config.dart';
import '../sound_manager.dart';
import '../enemies/shape_projectile.dart';
import '../hero.dart';

class DroneWingman extends PositionComponent with HasGameRef<CircleRougeGame> {
  final Hero owner;
  final int droneIndex;
  
  // Visual properties
  late Paint dronePaint;
  late Paint glowPaint;
  late double droneRadius;
  
  // Configuration data
  late CompanionData config;
  
  // AI properties
  double lastShotTime = 0.0;
  double orbitAngle;
  
  // Target tracking
  Component? currentTarget;
  double targetScanTimer = 0.0;
  
  DroneWingman({
    required this.owner,
    required this.droneIndex,
  }) : orbitAngle = (droneIndex * 2 * pi / 3), // Distribute drones evenly around hero
       super(
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Play drone deployment sound when first spawned
    SoundManager().playDroneDeploySound();
    
    // Load configuration
    config = ItemConfig.instance.getCompanionConfigById('drone_wingman') ?? _getDefaultConfig();
    
    droneRadius = config.radius * DisplayConfig.instance.scaleFactor;
    size = Vector2.all(droneRadius * 2);
    
    // Drone visual styling using config color
    dronePaint = Paint()..color = config.color;
    glowPaint = Paint()
      ..color = config.color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  }
  
  CompanionData _getDefaultConfig() {
    // Fallback configuration if config loading fails
    return CompanionData(
      radius: 8.0,
      fireRate: 0.8,
      orbitRadius: 60.0,
      orbitSpeed: 2.0,
      targetScanInterval: 0.5,
      attackRange: 200.0,
      projectileSpeed: 350.0,
      projectileDamage: 15.0,
      color: const Color(0xFF2196F3),
      projectileSizeScale: 0.7,
    );
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Draw glow effect
    canvas.drawCircle(center, droneRadius + 3, glowPaint);
    
    // Draw main drone body (diamond shape)
    final path = Path();
    path.moveTo(center.dx, center.dy - droneRadius);
    path.lineTo(center.dx + droneRadius * 0.7, center.dy);
    path.lineTo(center.dx, center.dy + droneRadius);
    path.lineTo(center.dx - droneRadius * 0.7, center.dy);
    path.close();
    
    canvas.drawPath(path, dronePaint);
    
    // Draw targeting indicator if we have a target
    if (currentTarget != null && currentTarget is PositionComponent) {
      final targetPos = (currentTarget! as PositionComponent).position;
      final direction = (targetPos - position).normalized();
      
      // Draw targeting line
      final targetLinePaint = Paint()
        ..color = const Color(0xFF2196F3).withOpacity(0.3)
        ..strokeWidth = 2.0;
      
      final lineStart = center;
      final lineEnd = Offset(
        center.dx + direction.x * (droneRadius + 5),
        center.dy + direction.y * (droneRadius + 5),
      );
      
      canvas.drawLine(lineStart, lineEnd, targetLinePaint);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Update orbit position around hero
    orbitAngle += config.orbitSpeed * dt;
    if (orbitAngle > 2 * pi) {
      orbitAngle -= 2 * pi;
    }
    
    // Calculate orbit position
    final orbitDistance = config.orbitRadius * DisplayConfig.instance.scaleFactor;
    final orbitX = owner.position.x + cos(orbitAngle) * orbitDistance;
    final orbitY = owner.position.y + sin(orbitAngle) * orbitDistance;
    position = Vector2(orbitX, orbitY);
    
    // Update target scanning
    targetScanTimer += dt;
    if (targetScanTimer >= config.targetScanInterval) {
      _scanForTargets();
      targetScanTimer = 0.0;
    }
    
    // Auto-fire at target
    _tryAutoFire(dt);
    
    // Check for bullet blocking
    _checkBulletBlocking();
  }
  
  void _scanForTargets() {
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    final droneRange = config.attackRange * DisplayConfig.instance.scaleFactor;
    
    // Find the nearest enemy within range
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance && distance <= droneRange) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    currentTarget = nearestEnemy;
  }
  
  void _tryAutoFire(double dt) {
    if (currentTarget == null || !(currentTarget is PositionComponent)) {
      return;
    }
    
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Check fire rate cooldown
    if (currentTime - lastShotTime < (1.0 / config.fireRate)) {
      return;
    }
    
    // Verify target is still in range and alive
    final targetPos = (currentTarget! as PositionComponent).position;
    final distance = position.distanceTo(targetPos);
    final droneRange = config.attackRange * DisplayConfig.instance.scaleFactor;
    
    if (distance > droneRange) {
      currentTarget = null;
      return;
    }
    
    // Fire at target
    final direction = (targetPos - position).normalized();
    _fireProjectile(direction);
    lastShotTime = currentTime;
  }
  
  void _fireProjectile(Vector2 direction) {
    // Create drone projectile using config values
    final projectile = ShapeProjectile(
      startPosition: position.clone(),
      direction: direction,
      speed: config.projectileSpeed * DisplayConfig.instance.scaleFactor,
      damage: config.projectileDamage,
      isEnemyProjectile: false,
      shapeType: 'circle', // Always circular for drones
      heroColor: config.color,
      bounces: 0, // Drone projectiles don't bounce
      sizeScale: config.projectileSizeScale,
      isCritical: false, // Drones can't crit
    );
    
    gameRef.add(projectile);
  }
  
  void destroy() {
    removeFromParent();
  }
  
  void _checkBulletBlocking() {
    // Check for collision with enemy projectiles
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is ShapeProjectile && projectile.isEnemyProjectile) {
        final distanceToProjectile = position.distanceTo(projectile.position);
        final collisionDistance = droneRadius + projectile.projectileSize;
        
        if (distanceToProjectile <= collisionDistance) {
          // Block the bullet by destroying it
          projectile.removeFromParent();
          
          // Create visual effect for bullet blocking
          _createBlockEffect();
          
          print('🛡️ Drone blocked enemy bullet!');
          break; // Only block one bullet per frame
        }
      }
    }
  }
  
  void _createBlockEffect() {
    // This would ideally create a temporary visual effect component
    // For now, we'll just print a message and the visual feedback will be the bullet disappearing
    print('💫 Block effect at drone position');
  }
}
