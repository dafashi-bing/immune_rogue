import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../hero.dart';

abstract class ItemPickup extends PositionComponent with HasGameRef<CircleRougeGame> {
  late Paint itemPaint;
  late Paint glowPaint;
  double radius = 12.0;
  double glowPulse = 0.0;
  bool isCollected = false;
  
  // Lifetime to prevent screen clutter
  double lifetime = 30.0; // 30 seconds before auto-despawn
  double currentLifetime = 0.0;
  
  ItemPickup({required Vector2 position, required Color color}) : super(
    position: position,
    size: Vector2.all(24.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    radius = 12.0 * DisplayConfig.instance.scaleFactor;
    itemPaint = Paint()..color = color;
    glowPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    if (isCollected) return;
    
    final center = Offset(size.x / 2, size.y / 2);
    final pulseRadius = radius + (sin(glowPulse) * 3.0);
    
    // Draw stronger glow
    canvas.drawCircle(center, pulseRadius + 3.0, glowPaint);
    
    // Add subtle outer ring for visibility
    final ringPulse = 0.5 + 0.5 * sin(glowPulse * 1.5);
    final ringPaint = Paint()
      ..color = itemPaint.color.withOpacity(0.35 * ringPulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, pulseRadius + 6.0, ringPaint);
    
    // Draw main item
    renderItem(canvas, center);
    
    // Draw collection radius indicator (faint)
    if (currentLifetime > lifetime - 5.0) { // Show when about to despawn
      final indicatorPaint = Paint()
        ..color = Colors.red.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, getCollectionRadius(), indicatorPaint);
    }
  }
  
  // Abstract method for subclasses to implement their own visuals
  void renderItem(Canvas canvas, Offset center);
  
  // Abstract method for subclasses to implement their own effects
  void applyEffect(Hero hero, CircleRougeGame game);
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    if (isCollected) return;
    
    // Update glow pulse
    glowPulse += dt * 3.0; // 3 radians per second for smooth pulsing
    
    // Update lifetime
    currentLifetime += dt;
    if (currentLifetime >= lifetime) {
      removeFromParent();
      return;
    }
    
    // Check for hero collision
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final distanceToHero = position.distanceTo(hero.position);
      if (distanceToHero <= getCollectionRadius()) {
        collect(hero);
      }
    }
  }
  
  void collect(Hero hero) {
    if (isCollected) return;
    
    isCollected = true;
    applyEffect(hero, gameRef);
    
    // TODO: Play collection sound
    print('Item collected: ${runtimeType}');
    
    removeFromParent();
  }
  
  double getCollectionRadius() {
    return radius + hero.collisionRadius + 5.0; // Small extra margin
  }
  
  Hero get hero => gameRef.hero;
} 