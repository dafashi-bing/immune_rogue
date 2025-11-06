import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../hero.dart' as game_hero;
import '../sound_manager.dart';
import 'item_pickup.dart';

class ConsumableItem extends ItemPickup {
  final String effectType;
  final double effectValue;
  final double duration; // Duration in seconds for temporary effects
  
  ConsumableItem({
    required Vector2 position,
    required this.effectType,
    required this.effectValue,
    this.duration = 10.0, // Default 10 seconds
  }) : super(
    position: position,
    color: _getColorForEffectType(effectType),
  );
  
  static Color _getColorForEffectType(String effectType) {
    switch (effectType) {
      case 'speed_boost':
        return const Color(0xFF4CAF50); // Green
      case 'damage_boost':
        return const Color(0xFFF44336); // Red
      case 'health_regen':
        return const Color(0xFF2196F3); // Blue
      case 'shield':
        return const Color(0xFF9C27B0); // Purple
      case 'invincibility':
        return const Color(0xFFFFD700); // Gold
      case 'weapon_overclock':
        return const Color(0xFFFF8C00); // Orange (different from shield)
      default:
        return const Color(0xFF4CAF50); // Default green
    }
  }
  
  @override
  void renderItem(Canvas canvas, Offset center) {
    // Draw a diamond shape for consumables
    final path = Path();
    final diamondSize = radius * 0.8;
    
    // Create diamond points
    path.moveTo(center.dx, center.dy - diamondSize); // Top
    path.lineTo(center.dx + diamondSize, center.dy); // Right
    path.lineTo(center.dx, center.dy + diamondSize); // Bottom
    path.lineTo(center.dx - diamondSize, center.dy); // Left
    path.close();
    
    // Draw diamond with gradient
    final gradient = RadialGradient(
      colors: [
        itemPaint.color,
        itemPaint.color.withOpacity(0.7),
        itemPaint.color.withOpacity(0.3),
      ],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: diamondSize));
    
    canvas.drawPath(path, paint);
    
    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawPath(path, borderPaint);
    
    // Draw effect icon in center
    _drawEffectIcon(canvas, center);
  }
  
  void _drawEffectIcon(Canvas canvas, Offset center) {
    final iconSize = radius * 0.4;
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    switch (effectType) {
      case 'speed_boost':
        // Draw arrow pointing up-right
        final path = Path();
        path.moveTo(center.dx - iconSize/2, center.dy + iconSize/2);
        path.lineTo(center.dx + iconSize/2, center.dy - iconSize/2);
        path.lineTo(center.dx - iconSize/4, center.dy - iconSize/2);
        path.lineTo(center.dx - iconSize/4, center.dy + iconSize/4);
        path.lineTo(center.dx + iconSize/2, center.dy + iconSize/4);
        path.close();
        canvas.drawPath(path, iconPaint);
        break;
        
      case 'damage_boost':
        // Draw lightning bolt
        final path = Path();
        path.moveTo(center.dx - iconSize/3, center.dy - iconSize/2);
        path.lineTo(center.dx + iconSize/6, center.dy - iconSize/6);
        path.lineTo(center.dx - iconSize/6, center.dy + iconSize/6);
        path.lineTo(center.dx + iconSize/3, center.dy + iconSize/2);
        path.lineTo(center.dx - iconSize/6, center.dy + iconSize/6);
        path.lineTo(center.dx + iconSize/6, center.dy - iconSize/6);
        path.close();
        canvas.drawPath(path, iconPaint);
        break;
        
      case 'health_regen':
        // Draw plus sign
        final rect1 = Rect.fromCenter(
          center: center,
          width: iconSize * 0.6,
          height: iconSize * 0.2,
        );
        final rect2 = Rect.fromCenter(
          center: center,
          width: iconSize * 0.2,
          height: iconSize * 0.6,
        );
        canvas.drawRect(rect1, iconPaint);
        canvas.drawRect(rect2, iconPaint);
        break;
        
      case 'shield':
        // Draw shield shape
        final path = Path();
        path.moveTo(center.dx, center.dy - iconSize/2);
        path.quadraticBezierTo(
          center.dx + iconSize/2, center.dy - iconSize/4,
          center.dx + iconSize/2, center.dy + iconSize/4,
        );
        path.quadraticBezierTo(
          center.dx + iconSize/2, center.dy + iconSize/2,
          center.dx, center.dy + iconSize/2,
        );
        path.quadraticBezierTo(
          center.dx - iconSize/2, center.dy + iconSize/2,
          center.dx - iconSize/2, center.dy + iconSize/4,
        );
        path.quadraticBezierTo(
          center.dx - iconSize/2, center.dy - iconSize/4,
          center.dx, center.dy - iconSize/2,
        );
        path.close();
        canvas.drawPath(path, iconPaint);
        break;
        
      case 'invincibility':
        // Draw star
        final path = Path();
        for (int i = 0; i < 5; i++) {
          final angle = (i * 2 * pi / 5) - pi/2;
          final x = center.dx + cos(angle) * iconSize/2;
          final y = center.dy + sin(angle) * iconSize/2;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, iconPaint);
        break;
        
      case 'weapon_overclock':
        // Draw lightning bolt (similar to WeaponOverclock)
        final path = Path();
        path.moveTo(center.dx - iconSize * 0.3, center.dy - iconSize * 0.4);
        path.lineTo(center.dx + iconSize * 0.1, center.dy - iconSize * 0.1);
        path.lineTo(center.dx - iconSize * 0.1, center.dy - iconSize * 0.1);
        path.lineTo(center.dx + iconSize * 0.3, center.dy + iconSize * 0.4);
        path.lineTo(center.dx - iconSize * 0.1, center.dy + iconSize * 0.1);
        path.lineTo(center.dx + iconSize * 0.1, center.dy + iconSize * 0.1);
        path.close();
        canvas.drawPath(path, iconPaint);
        break;
        
      default:
        // Draw circle
        canvas.drawCircle(center, iconSize/2, iconPaint);
        break;
    }
  }
  
  @override
  void applyEffect(game_hero.Hero hero, CircleRougeGame game) {
    switch (effectType) {
      case 'speed_boost':
        hero.applyTemporaryEffect('speed_boost', effectValue, duration);
        break;
      case 'damage_boost':
        hero.applyTemporaryEffect('damage_boost', effectValue, duration);
        break;
      case 'health_regen':
        hero.applyTemporaryEffect('health_regen', effectValue, duration);
        break;
      case 'shield':
        // Calculate shield as percentage of max HP
        final shieldAmount = hero.maxHealth * effectValue;
        hero.applyTemporaryEffect('shield', shieldAmount, duration);
        break;
      case 'invincibility':
        hero.applyTemporaryEffect('invincibility', 1.0, duration);
        break;
      case 'weapon_overclock':
        hero.applyTemporaryEffect('weapon_overclock', effectValue, duration);
        break;
    }
    
    // Play collection sound
    SoundManager().playPurchaseSound();
    
    // Show effect notification
    game.showEffectNotification(effectType, effectValue, duration);
  }
}
