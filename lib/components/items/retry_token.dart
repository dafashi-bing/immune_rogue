import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../hero.dart';
import '../sound_manager.dart';
import 'item_pickup.dart';

class RetryToken extends ItemPickup {
  RetryToken({required Vector2 position}) : super(
    position: position,
    color: const Color(0xFFFFD700), // Gold color for retry token
  );
  
  @override
  void renderItem(Canvas canvas, Offset center) {
    // Draw coin-like shape with inner details
    final coinSize = radius * 0.9;
    
    // Outer ring
    final outerPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, coinSize, outerPaint);
    
    // Inner ring (darker gold)
    final innerPaint = Paint()
      ..color = const Color(0xFFDAA520)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, coinSize * 0.8, innerPaint);
    
    // Center symbol (plus sign for "extra life")
    final symbolPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    final symbolSize = coinSize * 0.4;
    
    // Horizontal line of plus
    canvas.drawLine(
      Offset(center.dx - symbolSize, center.dy),
      Offset(center.dx + symbolSize, center.dy),
      symbolPaint,
    );
    
    // Vertical line of plus
    canvas.drawLine(
      Offset(center.dx, center.dy - symbolSize),
      Offset(center.dx, center.dy + symbolSize),
      symbolPaint,
    );
    
    // Add shine effect
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - coinSize * 0.3, center.dy - coinSize * 0.3),
      coinSize * 0.2,
      shinePaint,
    );
  }
  
  @override
  void applyEffect(Hero hero, CircleRougeGame game) {
    game.addRetryToken();
    
    // Play retry token collect sound
    SoundManager().playRetryTokenCollectSound();
    
    print('Retry Token collected! Can revive once in 1HP Challenge mode');
  }
} 