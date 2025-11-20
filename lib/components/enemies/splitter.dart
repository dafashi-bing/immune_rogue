import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
import '../sound_manager.dart';

class Splitter extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 60.0;
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('splitter') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 140.0;
  double maxHealth = 140.0;
  bool isDead = false;
  
  // Sprite component for image rendering
  SpriteComponent? spriteComponent;
  bool hasSprite = false;
  
  // Splitter behavior
  final int generation; // 0 = original, 1 = first split, 2 = second split
  int get maxGenerations => EnemyConfigManager.instance.getEnemyIntProperty('splitter', 'max_generations', 2);
  int get splitsPerGeneration => EnemyConfigManager.instance.getEnemyIntProperty('splitter', 'split_count', 6);
  
  // Visual effects
  double pulseTimer = 0.0;
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  Splitter({Vector2? position, this.generation = 0}) : super(
    position: position ?? Vector2.zero(),
    radius: _getRadiusForGeneration(generation) * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = _getColorForGeneration(generation),
    anchor: Anchor.center,
  ) {
    // Adjust health based on generation using config
    final healthList = EnemyConfigManager.instance.getEnemyListProperty('splitter', 'generation_health', [40.0, 25.0, 15.0]);
    health = generation < healthList.length ? healthList[generation] : 15.0;
    maxHealth = health;
  }
  
  static double _getRadiusForGeneration(int generation) {
    final radiusList = EnemyConfigManager.instance.getEnemyListProperty('splitter', 'generation_radius', [18.0, 14.0, 10.0]);
    return generation < radiusList.length ? radiusList[generation] : 10.0;
  }
  
  static Color _getColorForGeneration(int generation) {
    switch (generation) {
      case 0: return const Color(0xFF9C27B0); // Purple
      case 1: return const Color(0xFFE91E63); // Pink
      case 2: return const Color(0xFFF44336); // Red
      default: return const Color(0xFFF44336);
    }
  }
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Try to load sprite image (only for generation 0, splits use fallback)
    if (generation == 0) {
      final imagePath = EnemyConfigManager.instance.getEnemyImagePath('splitter');
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
          print('Could not load enemy image for splitter: $e');
          hasSprite = false;
        }
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (hasSprite && spriteComponent != null) {
      // Don't render circle if we have a sprite
      // The sprite component will render itself
    } else {
      super.render(canvas);
    }
    
    // Draw pulsing core effect
    final center = Offset(size.x / 2, size.y / 2);
    final pulseIntensity = (sin(pulseTimer * 4.0) + 1.0) / 2.0;
    final coreRadius = radius * (0.5 + 0.2 * pulseIntensity);
    
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.8 * pulseIntensity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, coreRadius, corePaint);
    
    // Draw generation indicator (rings)
    for (int i = 0; i <= generation; i++) {
      final ringPaint = Paint()
        ..color = paint.color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawCircle(center, radius + (i * 6.0), ringPaint);
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
    
    pulseTimer += dt;
    
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
    
    // Chase hero with moderate aggression
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final direction = (hero.position - position).normalized();
      final noStayForce = gameRef.getNoStayZoneForce(position);
      final finalDirection = (direction + noStayForce * dt).normalized();
      
      // Speed decreases with each generation using config
      final speedMultiplierList = EnemyConfigManager.instance.getEnemyListProperty('splitter', 'generation_speed_multiplier', [1.0, 0.8, 0.6]);
      final generationSpeedMultiplier = generation < speedMultiplierList.length ? speedMultiplierList[generation] : 0.6;
      position += finalDirection * speed * generationSpeedMultiplier * dt * speedMultiplier;
      
      // Check collision with hero
      final distanceToHero = position.distanceTo(hero.position);
      if (distanceToHero <= radius + hero.collisionRadius) {
        final baseContactDamage = EnemyConfigManager.instance.getEnemyDamage('splitter', 10.0);
        final contactDamage = baseContactDamage + (generation * 2.5); // More damage from smaller splits
        hero.takeDamage(contactDamage, sourceType: 'splitter');
        takeDamage(health); // Die on contact
      }
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
      _split();
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
    }
  }
  
  void _split() {
    // Only split if we haven't reached max generations
    if (generation < maxGenerations) {
      // Play splitter split sound
      SoundManager().playSplitterSplitSound();
      
      final random = Random();
      
      for (int i = 0; i < splitsPerGeneration; i++) {
        // Create split at random angle from current position
        final angle = random.nextDouble() * 2 * pi;
        final distance = EnemyConfigManager.instance.getEnemyProperty('splitter', 'split_distance', 30.0) * DisplayConfig.instance.scaleFactor;
        final splitPosition = Vector2(
          position.x + cos(angle) * distance,
          position.y + sin(angle) * distance,
        );
        
        // Ensure split position is within arena bounds
        splitPosition.x = splitPosition.x.clamp(
          DisplayConfig.instance.safeAreaMargin,
          DisplayConfig.instance.arenaWidth - DisplayConfig.instance.safeAreaMargin,
        );
        splitPosition.y = splitPosition.y.clamp(
          DisplayConfig.instance.safeAreaMargin,
          DisplayConfig.instance.arenaHeight - DisplayConfig.instance.safeAreaMargin,
        );
        
        final splitEnemy = Splitter(
          position: splitPosition,
          generation: generation + 1,
        );
        
        gameRef.add(splitEnemy);
        gameRef.currentEnemies.add(splitEnemy);
      }
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
