import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../hero.dart';
import 'enemy_chaser.dart';
import 'enemy_shooter.dart';

class PiercingProjectile extends RectangleComponent with HasGameRef<CircleRougeGame> {
  Vector2 direction;
  double speed;
  double damage;
  bool isEnemyProjectile;
  
  int pierceCount = 0;
  final int maxPierceCount = 3; // Can pierce through 3 enemies
  final Set<Component> hitEnemies = {}; // Track hit enemies to avoid multiple hits
  
  PiercingProjectile({
    required Vector2 startPosition,
    required this.direction,
    required this.speed,
    required this.damage,
    this.isEnemyProjectile = false,
  }) : super(
    position: startPosition,
    size: Vector2(12.0 * DisplayConfig.instance.scaleFactor, 4.0 * DisplayConfig.instance.scaleFactor),
    paint: Paint()..color = isEnemyProjectile 
        ? const Color(0xFFFF8800) // Orange for enemy piercing projectiles
        : const Color(0xFF00FFFF), // Cyan for hero piercing projectiles
    anchor: Anchor.center,
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Move projectile
    final movement = direction * speed * dt;
    position += movement;
    
    // Check collision with enemies
    final enemiesCopy = List<Component>.from(gameRef.currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy is PositionComponent && enemy is CircleComponent && !hitEnemies.contains(enemy)) {
        final distanceToEnemy = position.distanceTo(enemy.position);
        final enemyRadius = (enemy as CircleComponent).radius;
        if (distanceToEnemy < size.x + enemyRadius) {
          // Hit enemy
          hitEnemies.add(enemy);
          if (enemy is EnemyChaser) {
            enemy.takeDamage(damage);
          } else if (enemy is EnemyShooter) {
            enemy.takeDamage(damage);
          }
          // Don't remove projectile - it pierces through
        }
      }
    }
    
    // Remove if out of bounds
    if (_isOutOfBounds()) {
      removeFromParent();
    }
  }

  bool _isOutOfBounds() {
    return position.x < -size.x || 
           position.x > DisplayConfig.instance.arenaWidth + size.x ||
           position.y < -size.y || 
           position.y > DisplayConfig.instance.arenaHeight + size.y;
  }
} 