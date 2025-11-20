import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import 'enemy_chaser.dart';
import 'enemy_shooter.dart';
import 'shielded_chaser.dart';
import 'swarmer.dart';
import 'bomber.dart';
import 'sniper.dart';
import 'splitter.dart';
import 'mine_layer.dart';

class TriangleProjectile extends PositionComponent with HasGameRef<CircleRougeGame> {
  Vector2 direction;
  double speed;
  double damage;
  bool isEnemyProjectile;
  
  // Visual properties
  late Paint trianglePaint;
  late Paint glowPaint;
  late double triangleSize;
  
  double lifeTime = 0.0;
  static const double maxLifeTime = 5.0; // 5 seconds max lifetime
  final Set<Component> hitEnemies = {}; // Track hit enemies to avoid multiple hits
  
  TriangleProjectile({
    required Vector2 startPosition,
    required this.direction,
    required this.speed,
    required this.damage,
    this.isEnemyProjectile = false,
    Color? heroColor,
    double rangeMultiplier = 1.0,
    double? projectileSize,
  }) : super(
    position: startPosition,
    anchor: Anchor.center,
  ) {
    // Use projectileSize from config if provided, otherwise use default calculation
    triangleSize = (projectileSize ?? 20.0) * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    size = Vector2.all(triangleSize * 2);
    
    // Different colors for different projectile types - make hero triangle bright
    final color = isEnemyProjectile 
        ? const Color(0xFFFF4444) // Red for enemy projectiles
        : (heroColor ?? const Color(0xFFFF9800)); // Use hero color or bright orange
    
    trianglePaint = Paint()..color = color;
    glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    final radius = triangleSize; // Use triangleSize directly for larger appearance
    
    // Draw bright glow effect
    final glowPaint = Paint()
      ..color = trianglePaint.color.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    
    final trianglePath = _createTrianglePath(center, radius + 12);
    canvas.drawPath(trianglePath, glowPaint);
    
    // Draw main triangle - bright and solid
    final mainPaint = Paint()
      ..color = trianglePaint.color
      ..style = PaintingStyle.fill;
    
    final mainTrianglePath = _createTrianglePath(center, radius);
    canvas.drawPath(mainTrianglePath, mainPaint);
    
    // Add inner highlight for extra visibility
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    final highlightPath = _createTrianglePath(center, radius * 0.7);
    canvas.drawPath(highlightPath, highlightPaint);
  }
  
  Path _createTrianglePath(Offset center, double radius) {
    final path = Path();
    
    // Create triangle points - pointing in direction of travel
    path.moveTo(center.dx, center.dy - radius); // Top point
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius / 2); // Bottom left
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius / 2); // Bottom right
    path.close();
    
    return path;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move projectile
    final movement = direction * speed * dt;
    position += movement;
    
    // Update lifetime
    lifeTime += dt;
    
    // Check collision with enemies
    final enemiesCopy = List<Component>.from(gameRef.currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy is PositionComponent && !hitEnemies.contains(enemy)) {
        // Check if enemy is within triangle bounds
        if (_isEnemyInTriangle(enemy)) {
          // Hit enemy - eliminate immediately
          hitEnemies.add(enemy);
          if (enemy is EnemyChaser) {
            enemy.takeDamage(damage); // High damage to eliminate instantly
          } else if (enemy is EnemyShooter) {
            enemy.takeDamage(damage); // High damage to eliminate instantly
          } else if (enemy is ShieldedChaser) {
            enemy.takeDamage(damage, isAbility: true); // Instantly break shield and eliminate
          } else if (enemy is Swarmer) {
            enemy.takeDamage(damage);
          } else if (enemy is Bomber) {
            enemy.takeDamage(damage);
          } else if (enemy is Sniper) {
            enemy.takeDamage(damage);
          } else if (enemy is Splitter) {
            enemy.takeDamage(damage);
          } else if (enemy is MineLayer) {
            enemy.takeDamage(damage);
          }
          // Don't remove projectile - it continues through
        }
      }
    }
    
    // Remove if too old or out of bounds (removed travel distance constraint)
    if (lifeTime > maxLifeTime || _isOutOfBounds()) {
      removeFromParent();
    }
  }
  
  bool _isEnemyInTriangle(PositionComponent enemy) {
    // Larger collision detection for better hit registration
    final distance = position.distanceTo(enemy.position);
    final collisionRadius = triangleSize * 0.8; // Generous collision radius
    return distance < collisionRadius;
  }
  
  bool _isOutOfBounds() {
    final margin = triangleSize * 2;
    return position.x < -margin || 
           position.x > DisplayConfig.instance.arenaWidth + margin ||
           position.y < -margin || 
           position.y > DisplayConfig.instance.arenaHeight + margin;
  }
} 