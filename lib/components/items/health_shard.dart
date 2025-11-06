import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../hero.dart';
import 'item_pickup.dart';

class HealthShard extends ItemPickup {
  static const double healAmount = 20.0;
  
  HealthShard({required Vector2 position}) : super(
    position: position,
    color: const Color(0xFFE53E3E), // Red color for health
  );
  
  @override
  void renderItem(Canvas canvas, Offset center) {
    // Draw heart-like shape using two circles and a triangle
    final heartSize = radius * 0.8;
    
    // Left lobe of heart
    canvas.drawCircle(
      Offset(center.dx - heartSize * 0.3, center.dy - heartSize * 0.3),
      heartSize * 0.5,
      itemPaint,
    );
    
    // Right lobe of heart
    canvas.drawCircle(
      Offset(center.dx + heartSize * 0.3, center.dy - heartSize * 0.3),
      heartSize * 0.5,
      itemPaint,
    );
    
    // Bottom triangle/point of heart
    final path = Path();
    path.moveTo(center.dx - heartSize * 0.7, center.dy);
    path.lineTo(center.dx + heartSize * 0.7, center.dy);
    path.lineTo(center.dx, center.dy + heartSize * 0.8);
    path.close();
    
    canvas.drawPath(path, itemPaint);
    
    // Add small white highlight
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.6);
    canvas.drawCircle(
      Offset(center.dx - heartSize * 0.2, center.dy - heartSize * 0.4),
      heartSize * 0.2,
      highlightPaint,
    );
  }
  
  @override
  void applyEffect(Hero hero, CircleRougeGame game) {
    hero.heal(healAmount);
    print('Health restored: +$healAmount HP');
    
    // Visual feedback - could add particle effect here
  }
} 