import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;
import 'dart:math';

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

class Projectile extends CircleComponent with HasGameRef<CircleRougeGame> {
  Vector2 direction;
  double speed;
  double damage;
  bool isEnemyProjectile;
  String? ownerEnemyType; // which enemy fired/owned this projectile
  final Color? heroColor; // Optional hero color for hero projectiles
  
  double lifeTime = 0.0;
  static const double maxLifeTime = 3.0; // Seconds before auto-destroy
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0; // Slow lasts 3 seconds
  double speedMultiplier = 1.0;
  
  // Visual properties
  late Paint projectilePaint;
  late Paint glowPaint;
  
  Projectile({
    required Vector2 startPosition,
    required this.direction,
    required this.speed,
    required this.damage,
    this.isEnemyProjectile = false,
    this.ownerEnemyType,
    this.heroColor,
    double? scaledRadius,
  }) : super(
    position: startPosition,
    radius: scaledRadius ?? (4.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    // Different colors for different projectile types
    final color = getProjectileColor(isEnemyProjectile, heroColor);
    
    projectilePaint = Paint()..color = color;
    glowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  }
  
  @override
  void onMount() {
    super.onMount();
    // Register projectile with game
    gameRef.addProjectile(this);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Update slow timer
    if (isSlowed) {
      slowTimer += dt;
      if (slowTimer >= slowDuration) {
        isSlowed = false;
        slowTimer = 0.0;
        speedMultiplier = 1.0;
        // Reset color
        projectilePaint.color = getProjectileColor(isEnemyProjectile, heroColor);
      } else {
        // Blink transparency between 70% and 100% while slowed
        final blinkTime = (slowTimer * 3) % 1.0; // 3 blinks per second
        final alpha = (0.7 + 0.3 * sin(blinkTime * 2 * pi)).clamp(0.7, 1.0);
        final originalColor = getProjectileColor(isEnemyProjectile, heroColor);
        projectilePaint.color = Color.fromRGBO(
          originalColor.red, 
          originalColor.green, 
          originalColor.blue, 
          alpha
        );
      }
    }
    
    // Move projectile with speed multiplier
    position += direction * speed * speedMultiplier * dt;
    
    // Update lifetime
    lifeTime += dt;
    
    // Check collision with hero (if enemy projectile)
    if (isEnemyProjectile) {
      final distanceToHero = position.distanceTo(gameRef.hero.position);
      if (distanceToHero < radius + gameRef.hero.collisionRadius) {
        gameRef.hero.takeDamage(damage, sourceType: ownerEnemyType ?? 'shooter');
        _destroyProjectile();
        return;
      }
    } else {
      // Hero projectile - check collision with enemies
      for (final enemy in gameRef.currentEnemies) {
        if (enemy is PositionComponent) {
          final distanceToEnemy = position.distanceTo(enemy.position);
          
          if (enemy is CircleComponent) {
            final enemyRadius = enemy.radius;
            if (distanceToEnemy < radius + enemyRadius) {
              // Hit enemy
              if (enemy is EnemyChaser) {
                enemy.takeDamage(damage);
              } else if (enemy is EnemyShooter) {
                enemy.takeDamage(damage);
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
              _destroyProjectile();
              return;
            }
          } else if (enemy is ShieldedChaser) {
            // ShieldedChaser has its own radius property
            if (distanceToEnemy < radius + enemy.radius) {
              enemy.takeDamage(damage); // Regular damage to shield
              _destroyProjectile();
              return;
            }
          }
        }
      }
    }
    
    // Remove if out of bounds or too old
    if (lifeTime > maxLifeTime || _isOutOfBounds()) {
      _destroyProjectile();
    }
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
  
  void _destroyProjectile() {
    gameRef.onProjectileDestroyed(this);
    removeFromParent();
  }
  
  @override
  void removeFromParent() {
    gameRef.onProjectileDestroyed(this);
    super.removeFromParent();
  }
  
  bool _isOutOfBounds() {
    return position.x < -radius || 
           position.x > DisplayConfig.instance.arenaWidth + radius ||
           position.y < -radius || 
           position.y > DisplayConfig.instance.arenaHeight + radius;
  }
  
  static Color getProjectileColor(bool isEnemyProjectile, Color? heroColor) {
    if (isEnemyProjectile) {
      return const Color(0xFFFF1744); // Red for enemy projectiles
    } else if (heroColor != null) {
      return heroColor; // Use hero's color
    } else {
      return const Color(0xFF00BCD4); // Default cyan for hero projectiles
    }
  }
} 