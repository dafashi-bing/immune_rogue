import 'dart:math';
import 'package:flame/components.dart';
import '../../config/display_config.dart';
import '../enemies/enemy_chaser.dart';
import '../enemies/enemy_shooter.dart';
import '../enemies/shielded_chaser.dart';
import '../enemies/swarmer.dart';
import '../enemies/bomber.dart';
import '../enemies/sniper.dart';
import '../enemies/splitter.dart';
import '../enemies/mine_layer.dart';
import 'ultimate_ability.dart';

/// Circle's ultimate ability: Engulf Rampage
/// For 3 seconds, dash continuously at 400 units/sec, bouncing off battlefield edges.
/// Any enemy collided with is instantly devoured (instant kill).
class EngulfRampage extends UltimateAbility {
  static const double duration = 3.0; // 3 seconds
  static const double speed = 2000.0; // 400 units/sec
  
  double timer = 0.0;
  Vector2 direction = Vector2(0, -1); // Start moving up by default
  
  EngulfRampage(super.hero);
  
  @override
  String get name => 'Engulf Rampage';
  
  @override
  void activate() {
    print('[ENGLUF_RAMPAGE] Step 1: activate() called');
    
    // Hero is already invulnerable (set when castUltimate() was called)
    // Just ensure it's still set
    print('[ENGLUF_RAMPAGE] Step 2: Ensuring hero invulnerability (already set during cast)');
    hero.isInvincible = true;
    hero.invincibilityTimer = 0.0;
    hero.isDamageInvincible = true;
    hero.damageInvincibilityTimer = 0.0;
    print('[ENGLUF_RAMPAGE] Hero invulnerability confirmed: isInvincible=${hero.isInvincible}, isDamageInvincible=${hero.isDamageInvincible}');
    
    hero.isUsingUltimate = true;
    timer = 0.0;
    print('[ENGLUF_RAMPAGE] Step 3: Ultimate state set, timer reset');
    
    // Generate a random direction that's not perpendicular to any edge
    // This ensures more variety in bouncing patterns
    print('[ENGLUF_RAMPAGE] Step 4: Generating random non-perpendicular direction');
    final random = Random();
    
    // Generate random angle, but avoid angles that are too close to perpendicular (0°, 90°, 180°, 270°)
    // We'll avoid angles within 15° of perpendicular directions
    double angle = pi / 4; // Default to 45° (safe fallback)
    bool isValidAngle = false;
    int attempts = 0;
    
    while (!isValidAngle && attempts < 50) {
      angle = random.nextDouble() * 2 * pi; // Random angle 0 to 2π
      
      // Convert to degrees for easier checking
      double angleDegrees = (angle * 180 / pi) % 360;
      
      // Check if angle is NOT too close to perpendicular directions
      // Avoid: 0° (up), 90° (right), 180° (down), 270° (left)
      // With a tolerance of ±15°
      bool tooCloseToPerpendicular = 
          (angleDegrees >= 345 || angleDegrees <= 15) ||  // Near 0°/360°
          (angleDegrees >= 75 && angleDegrees <= 105) ||  // Near 90°
          (angleDegrees >= 165 && angleDegrees <= 195) || // Near 180°
          (angleDegrees >= 255 && angleDegrees <= 285);   // Near 270°
      
      if (!tooCloseToPerpendicular) {
        isValidAngle = true;
      }
      attempts++;
    }
    
    // If we couldn't find a good angle after 50 attempts, use the default (45°)
    if (!isValidAngle) {
      angle = pi / 4; // 45 degrees
      print('[ENGLUF_RAMPAGE] Using fallback angle: 45°');
    }
    
    direction = Vector2(cos(angle), sin(angle));
    print('[ENGLUF_RAMPAGE] Random direction generated: ($direction)');
    print('[ENGLUF_RAMPAGE] Angle: ${(angle * 180 / pi).toStringAsFixed(1)}°');
    
    // Disable ability usage during ultimate
    hero.isUsingAbility = false;
    hero.abilityTarget = null;
    print('[ENGLUF_RAMPAGE] Step 5: Disabled regular ability usage');
    
    print('[ENGLUF_RAMPAGE] ✅ Engulf Rampage activated! Duration: ${duration}s, Speed: ${speed} units/sec');
  }
  
  @override
  void update(double dt) {
    timer += dt;
    
    // Check if ultimate duration has ended
    if (timer >= duration) {
      print('[ENGLUF_RAMPAGE] Timer reached duration (${timer.toStringAsFixed(2)}s >= ${duration}s), deactivating');
      deactivate();
      return;
    }
    
    // Calculate movement with scaled speed
    final scaledSpeed = speed * DisplayConfig.instance.scaleFactor;
    final movement = direction * scaledSpeed * dt;
    final newPosition = hero.position + movement;
    
    // Check for edge collisions and bounce
    final arenaWidth = DisplayConfig.instance.arenaWidth;
    final arenaHeight = DisplayConfig.instance.arenaHeight;
    final heroRadius = hero.heroRadius;
    bool bounced = false;
    
    // Check left/right edges
    if (newPosition.x - heroRadius <= 0) {
      direction.x = -direction.x; // Flip X direction (bounce right)
      bounced = true;
      hero.position.x = heroRadius;
    } else if (newPosition.x + heroRadius >= arenaWidth) {
      direction.x = -direction.x; // Flip X direction (bounce left)
      bounced = true;
      hero.position.x = arenaWidth - heroRadius;
    } else {
      hero.position.x = newPosition.x;
    }
    
    // Check top/bottom edges
    if (newPosition.y - heroRadius <= 0) {
      direction.y = -direction.y; // Flip Y direction (bounce down)
      bounced = true;
      hero.position.y = heroRadius;
    } else if (newPosition.y + heroRadius >= arenaHeight) {
      direction.y = -direction.y; // Flip Y direction (bounce up)
      bounced = true;
      hero.position.y = arenaHeight - heroRadius;
    } else {
      hero.position.y = newPosition.y;
    }
    
    // Normalize direction after bouncing to maintain speed
    if (bounced) {
      direction.normalize();
      // TODO: Add bounce particle effect here
    }
    
    // Check for enemy collisions and instant kill
    _checkCollisions();
  }
  
  void _checkCollisions() {
    // Create a copy to avoid ConcurrentModificationError
    final enemiesCopy = List<Component>.from(gameRef.currentEnemies);
    
    for (final enemy in enemiesCopy) {
      if (enemy is PositionComponent) {
        final distanceToEnemy = hero.position.distanceTo(enemy.position);
        
        // Get enemy radius
        double enemyRadius = 15.0 * DisplayConfig.instance.scaleFactor; // Default radius
        
        if (enemy is EnemyChaser) {
          enemyRadius = enemy.radius;
        } else if (enemy is EnemyShooter) {
          enemyRadius = enemy.radius;
        } else if (enemy is ShieldedChaser) {
          enemyRadius = enemy.radius;
        } else if (enemy is Swarmer) {
          enemyRadius = enemy.radius;
        } else if (enemy is Bomber) {
          enemyRadius = enemy.radius;
        } else if (enemy is Sniper) {
          enemyRadius = enemy.radius;
        } else if (enemy is Splitter) {
          enemyRadius = enemy.radius;
        } else if (enemy is MineLayer) {
          enemyRadius = enemy.radius;
        } else {
          // Try to get radius for other enemy types
          try {
            if (enemy is CircleComponent) {
              enemyRadius = enemy.radius;
            }
          } catch (e) {
            // Fallback to default
          }
        }
        
        // Check collision
        if (distanceToEnemy < hero.heroRadius + enemyRadius) {
          // Instant kill - devour the enemy
          bool enemyKilled = false;
          
          if (enemy is EnemyChaser) {
            enemy.takeDamage(enemy.health); // Deal exactly their current health
            enemyKilled = true;
          } else if (enemy is EnemyShooter) {
            enemy.takeDamage(enemy.health);
            enemyKilled = true;
          } else if (enemy is ShieldedChaser) {
            enemy.takeDamage(enemy.health, isAbility: true);
            enemyKilled = true;
          } else if (enemy is Swarmer) {
            enemy.takeDamage(enemy.health);
            enemyKilled = true;
          } else if (enemy is Bomber) {
            enemy.takeDamage(enemy.health);
            enemyKilled = true;
          } else if (enemy is Sniper) {
            enemy.takeDamage(enemy.health);
            enemyKilled = true;
          } else if (enemy is Splitter) {
            enemy.takeDamage(enemy.health);
            enemyKilled = true;
          } else if (enemy is MineLayer) {
            enemy.takeDamage(enemy.health);
            enemyKilled = true;
          } else {
            // Fallback for unknown enemy types - remove them directly
            if (enemy.parent != null) {
              gameRef.onEnemyDestroyed(enemy);
              enemyKilled = true;
            }
          }
          
          // Trigger kill effects if enemy was killed
          if (enemyKilled) {
            // Check if enemy actually died (health <= 0)
            try {
              if ((enemy as dynamic).health <= 0) {
                hero.onEnemyKilled();
              }
            } catch (e) {
              // If we can't check health, assume it was killed
              hero.onEnemyKilled();
            }
          }
        }
      }
    }
  }
  
  @override
  void deactivate() {
    print('[ENGLUF_RAMPAGE] Step 1: deactivate() called');
    
    hero.isUsingUltimate = false;
    timer = 0.0;
    print('[ENGLUF_RAMPAGE] Step 2: Ultimate state cleared');
    
    // Remove invulnerability when ultimate ends
    hero.isInvincible = false;
    hero.invincibilityTimer = 0.0;
    hero.isDamageInvincible = false;
    hero.damageInvincibilityTimer = 0.0;
    print('[ENGLUF_RAMPAGE] Step 3: Hero invulnerability removed');
    
    print('[ENGLUF_RAMPAGE] ✅ Engulf Rampage ended');
  }
}

