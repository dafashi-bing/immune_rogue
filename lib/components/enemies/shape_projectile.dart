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

class ShapeProjectile extends PositionComponent with HasGameRef<CircleRougeGame> {
  Vector2 direction;
  double speed;
  double damage;
  bool isEnemyProjectile;
  String? ownerEnemyType;
  String shapeType;
  
  // Visual properties
  late Paint projectilePaint;
  late Paint glowPaint;
  late double projectileSize;
  
  double lifeTime = 0.0;
  static const double maxLifeTime = 3.0; // Seconds before auto-destroy
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0; // Slow lasts 3 seconds
  double speedMultiplier = 1.0;
  
  // Bouncing system
  int remainingBounces;
  
  // Enhanced visual effects
  final double sizeScale;
  final bool isCritical;
  
  ShapeProjectile({
    required Vector2 startPosition,
    required this.direction,
    required this.speed,
    required this.damage,
    this.isEnemyProjectile = false,
    this.ownerEnemyType,
    this.shapeType = 'square',
    Color? heroColor,
    int bounces = 0,
    this.sizeScale = 1.0,
    this.isCritical = false,
  }) : remainingBounces = bounces,
       super(
    position: startPosition,
    anchor: Anchor.center,
  ) {
    projectileSize = 16.0 * DisplayConfig.instance.scaleFactor * sizeScale;
    size = Vector2.all(projectileSize);
    
    // Different colors for different projectile types
    Color color;
    if (isEnemyProjectile) {
      color = const Color(0xFFFF4444); // Red for enemy projectiles
    } else if (isCritical) {
      color = const Color(0xFFFFD700); // Gold for critical hits
    } else {
      color = heroColor ?? const Color(0xFF44FF44); // Use hero color or default green
    }
    
    projectilePaint = Paint()..color = color;
    glowPaint = Paint()
      ..color = color.withOpacity(isCritical ? 0.8 : 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isCritical ? 12 : 4);
    
    // Add extra glow for critical hits
    if (isCritical) {
      print('💥 CRITICAL HIT PROJECTILE CREATED!');
    }
  }
  
  @override
  void onMount() {
    super.onMount();
    // Register projectile with game
    gameRef.addProjectile(this);
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Add glow effect
    final glowPaint = Paint()
      ..color = projectilePaint.color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    switch (shapeType) {
      case 'circle':
        // Draw glow
        canvas.drawCircle(center, projectileSize + 2, glowPaint);
        // Draw shape
        canvas.drawCircle(center, projectileSize, projectilePaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, center, glowPaint);
        _drawTriangle(canvas, center, projectilePaint);
        break;
      case 'square':
        _drawSquare(canvas, center, glowPaint);
        _drawSquare(canvas, center, projectilePaint);
        break;
      case 'pentagon':
        _drawPentagon(canvas, center, glowPaint);
        _drawPentagon(canvas, center, projectilePaint);
        break;
      case 'hexagon':
        _drawHexagon(canvas, center, glowPaint);
        _drawHexagon(canvas, center, projectilePaint);
        break;
      default:
        // Default to circle
        canvas.drawCircle(center, projectileSize + 2, glowPaint);
        canvas.drawCircle(center, projectileSize, projectilePaint);
    }
    
    // Add sparkle effect for critical hits
    if (isCritical) {
      final sparkleTime = DateTime.now().millisecondsSinceEpoch / 100.0;
      for (int i = 0; i < 4; i++) {
        final angle = (sparkleTime + i * pi / 2) % (2 * pi);
        final sparkleDistance = projectileSize + 8;
        final sparkleX = center.dx + cos(angle) * sparkleDistance;
        final sparkleY = center.dy + sin(angle) * sparkleDistance;
        
        final sparklePaint = Paint()
          ..color = const Color(0xFFFFFFFF).withOpacity(0.8)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(Offset(sparkleX, sparkleY), 2.0, sparklePaint);
      }
    }
  }
  
  void _drawTriangle(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final radius = paint == projectilePaint ? projectileSize : projectileSize + 2;
    
    path.moveTo(center.dx, center.dy - radius); // Top point
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius / 2); // Bottom left
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius / 2); // Bottom right
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSquare(Canvas canvas, Offset center, Paint paint) {
    final radius = paint == projectilePaint ? projectileSize : projectileSize + 2;
    final size = radius * 1.4; // Make square a bit larger than circle
    
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      ),
      paint,
    );
  }
  
  void _drawPentagon(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final radius = paint == projectilePaint ? projectileSize : projectileSize + 2;
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
    final radius = paint == projectilePaint ? projectileSize : projectileSize + 2;
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
        projectilePaint.color = projectilePaint.color;
      } else {
        // Blink transparency between 70% and 100% while slowed
        final blinkTime = (slowTimer * 3) % 1.0; // 3 blinks per second
        final alpha = (0.7 + 0.3 * sin(blinkTime * 2 * pi)).clamp(0.7, 1.0);
        projectilePaint.color = Color.fromRGBO(
          projectilePaint.color.red, 
          projectilePaint.color.green, 
          projectilePaint.color.blue, 
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
      if (distanceToHero < projectileSize + gameRef.hero.collisionRadius) {
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
            if (distanceToEnemy < projectileSize + enemyRadius) {
              // Hit enemy
              if (enemy is EnemyChaser) {
                // Critical strike = instant kill
                if (isCritical) {
                  enemy.takeDamage(enemy.health); // Deal exactly their current health
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                // Apply life steal if hero has it
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                // Trigger heal per kill if enemy dies
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              } else if (enemy is EnemyShooter) {
                // Critical strike = instant kill
                if (isCritical) {
                  enemy.takeDamage(enemy.health); // Deal exactly their current health
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                // Apply life steal if hero has it
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                // Trigger heal per kill if enemy dies
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              } else if (enemy is Swarmer) {
                if (isCritical) {
                  enemy.takeDamage(enemy.health);
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              } else if (enemy is Bomber) {
                if (isCritical) {
                  enemy.takeDamage(enemy.health);
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              } else if (enemy is Sniper) {
                if (isCritical) {
                  enemy.takeDamage(enemy.health);
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              } else if (enemy is Splitter) {
                if (isCritical) {
                  enemy.takeDamage(enemy.health);
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              } else if (enemy is MineLayer) {
                if (isCritical) {
                  enemy.takeDamage(enemy.health);
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              }
              
              // Handle bouncing or destruction
              if (remainingBounces > 0 && !isEnemyProjectile) {
                _handleBounce(enemy.position);
              } else {
                _destroyProjectile();
              }
              return;
            }
          } else if (enemy is ShieldedChaser) {
            // ShieldedChaser has its own radius property
            if (distanceToEnemy < projectileSize + enemy.radius) {
              // Critical strike = instant kill (but only after shield is broken)
              if (isCritical && !enemy.hasShield) {
                enemy.takeDamage(enemy.health); // Deal exactly their current health
                print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
              } else {
                enemy.takeDamage(damage); // Regular damage to shield or health
              }
              // Apply life steal if hero has it
              final lifeSteal = gameRef.hero.totalLifeSteal;
              if (lifeSteal > 0 && !isEnemyProjectile) {
                final healAmount = damage * lifeSteal;
                gameRef.hero.heal(healAmount);
              }
              // Trigger heal per kill if enemy dies
              if (!isEnemyProjectile && enemy.health <= 0) {
                gameRef.hero.onEnemyKilled();
              }
              
              // Handle bouncing or destruction
              if (remainingBounces > 0 && !isEnemyProjectile) {
                _handleBounce(enemy.position);
              } else {
                _destroyProjectile();
              }
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
  
  void _handleBounce(Vector2 hitPosition) {
    remainingBounces--;
    
    // Find the nearest enemy to bounce to
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent && enemy.position != hitPosition) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    // If we found an enemy to bounce to, redirect towards it
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      direction = (nearestEnemy.position - position).normalized();
      
      // Visual feedback for bounce
      final bounceGlow = Paint()
        ..color = projectilePaint.color.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      glowPaint = bounceGlow;
      
      // Play bounce sound (if available)
      // SoundManager().playBulletBounceSound();
      
      print('Projectile bounced! Remaining bounces: $remainingBounces');
    } else {
      // No enemy to bounce to, destroy projectile
      _destroyProjectile();
    }
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
    return position.x < -projectileSize || 
           position.x > DisplayConfig.instance.arenaWidth + projectileSize ||
           position.y < -projectileSize || 
           position.y > DisplayConfig.instance.arenaHeight + projectileSize;
  }
} 