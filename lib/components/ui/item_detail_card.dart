import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/item_config.dart';
import '../shop_panel.dart';

class ItemDetailCard extends RectangleComponent with HasGameRef<CircleRougeGame>, TapCallbacks {
  final ShopItem item;
  final VoidCallback onClose;
  
  // Visual components
  late RectangleComponent background;
  late RectangleComponent border;
  late TextComponent titleText;
  late TextComponent descriptionText;
  late TextComponent costText;
  late TextComponent stackInfoText;
  late TextComponent instructionText;
  
  // Animation properties
  double animationTime = 0.0;
  static const double animationDuration = 0.3;
  bool isClosing = false;
  
  ItemDetailCard({
    required this.item,
    required this.onClose,
  }) : super(
    anchor: Anchor.center,
  ) {
    final screenWidth = DisplayConfig.instance.settings?.windowWidth ?? 800.0;
    final screenHeight = DisplayConfig.instance.settings?.windowHeight ?? 600.0;
    
    // Card dimensions
    final cardWidth = (screenWidth * 0.6).clamp(300.0, 500.0);
    final cardHeight = (screenHeight * 0.4).clamp(200.0, 300.0);
    
    size = Vector2(cardWidth, cardHeight);
    position = Vector2(screenWidth / 2, screenHeight / 2);
    
    _setupVisualComponents();
  }
  
  void _setupVisualComponents() {
    // Background with semi-transparent overlay
    background = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFF1A1A1A).withOpacity(0.95)
        ..style = PaintingStyle.fill,
    );
    add(background);
    
    // Border with item category color
    final borderColor = _getItemCategoryColor();
    border = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    add(border);
    
    // Title text
    titleText = TextComponent(
      text: item.name.toUpperCase(),
      textRenderer: TextPaint(
        style: TextStyle(
          color: borderColor,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      position: Vector2(size.x / 2, 40),
      anchor: Anchor.center,
    );
    add(titleText);
    
    // Cost text
    costText = TextComponent(
      text: '${item.cost} 🪙',
      textRenderer: TextPaint(
        style: TextStyle(
          color: borderColor, // Match border color
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: borderColor.withOpacity(0.8),
              blurRadius: 6,
            ),
          ],
        ),
      ),
      position: Vector2(size.x / 2, 70),
      anchor: Anchor.center,
    );
    add(costText);
    
    // Description text (word-wrapped)
    final wrappedDescription = _wrapText(item.description, 45);
    descriptionText = TextComponent(
      text: wrappedDescription,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Color.lerp(Colors.white, borderColor, 0.3) ?? Colors.white, // Subtle tint matching border
          fontSize: 16,
          height: 1.4,
        ),
      ),
      position: Vector2(size.x / 2, 110),
      anchor: Anchor.center,
    );
    add(descriptionText);
    
    // Stack information (if applicable)
    final stackInfo = _getStackInfo();
    if (stackInfo.isNotEmpty) {
      stackInfoText = TextComponent(
        text: stackInfo,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFF88FF88), // Light green
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        position: Vector2(size.x / 2, size.y - 70),
        anchor: Anchor.center,
      );
      add(stackInfoText);
    }
    
    // Instruction text
    instructionText = TextComponent(
      text: 'TAP ANYWHERE TO CLOSE',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
      position: Vector2(size.x / 2, size.y - 30),
      anchor: Anchor.center,
    );
    add(instructionText);
  }
  
  Color _getItemCategoryColor() {
    // Get item data to check its type
    final itemData = ItemConfig.instance.getItemById(item.id);
    final itemType = itemData?.type ?? 'other';
    
    // Determine color based on item type
    switch (itemType) {
      case 'health':
        return const Color(0xFF4CAF50); // Green
      case 'attack':
        return const Color(0xFFF44336); // Red
      case 'ability':
        // Use hero color for ability items
        return gameRef.hero.heroData.color;
      case 'other':
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }
  
  String _getStackInfo() {
    final hero = gameRef.hero;
    
    switch (item.id) {
      case 'spread_master':
        final current = hero.getPassiveEffectStacks('projectile_count');
        return 'Current: +$current projectiles (Max: +9)';
      
      case 'bouncing_bullets':
        final current = hero.getPassiveEffectStacks('projectile_bounces');
        return 'Current: +$current bounces (Max: +3)';
      
      case 'drone_wingman':
        final current = hero.getPassiveEffectStacks('drone_count');
        return 'Current: $current drones (Max: 3)';
      
      case 'enlarged_caliber':
        final current = hero.getPassiveEffectStacks('projectile_size');
        final percentage = (current * 10);
        return 'Current: +$percentage% size (Max: +100%)';
      
      case 'vampiric_coating':
        final current = hero.getPassiveEffectStacks('life_steal');
        final percentage = (current * 5);
        return 'Current: +$percentage% life steal (Max: +20%)';
      
      case 'armor_plating':
        final current = hero.getPassiveEffectStacks('shield_hp');
        final shieldHP = current * 5;
        return 'Current: +$shieldHP shield HP (Max: +100)';
      
      case 'coin_magnet':
        final current = hero.getPassiveEffectStacks('coin_multiplier');
        final percentage = (current * 20);
        return 'Current: +$percentage% coin earn (Max: +100%)';
      
      case 'auto_injector':
        final current = hero.getPassiveEffectStacks('heal_per_kill');
        final healAmount = current * 2;
        return 'Current: +$healAmount HP per kill (Max: +10)';
      
      case 'critical_striker':
        final current = hero.getPassiveEffectStacks('crit_chance');
        final percentage = (current * 2);
        return 'Current: +$percentage% crit chance (Max: +10%)';
      
      case 'clone_projection':
        final hasClone = hero.hasCloneProjection;
        return hasClone ? 'Clone Projection: Available (Press C)' : 'Not owned';
      
      default:
        return '';
    }
  }
  
  String _wrapText(String text, int maxLineLength) {
    final words = text.split(' ');
    final lines = <String>[];
    String currentLine = '';
    
    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine + ' ' + word).length <= maxLineLength) {
        currentLine += ' ' + word;
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    
    return lines.join('\n');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Handle animation
    if (!isClosing) {
      animationTime += dt;
      if (animationTime < animationDuration) {
        final progress = animationTime / animationDuration;
        final easeProgress = _easeOutCubic(progress);
        
        // Scale animation
        scale = Vector2.all(easeProgress);
        
        // Fade in
        final opacity = easeProgress;
        background.paint.color = const Color(0xFF1A1A1A).withOpacity(0.95 * opacity);
        border.paint.color = _getItemCategoryColor().withOpacity(opacity);
      } else {
        scale = Vector2.all(1.0);
      }
    } else {
      animationTime -= dt * 3; // Faster closing animation
      if (animationTime <= 0) {
        removeFromParent();
        return;
      }
      
      final progress = animationTime / animationDuration;
      scale = Vector2.all(progress);
      
      // Fade out
      final opacity = progress;
      background.paint.color = const Color(0xFF1A1A1A).withOpacity(0.95 * opacity);
      border.paint.color = _getItemCategoryColor().withOpacity(opacity);
    }
  }
  
  double _easeOutCubic(double t) {
    return 1 - pow(1 - t, 3);
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    close();
    return true;
  }
  
  void close() {
    if (!isClosing) {
      isClosing = true;
      onClose();
    }
  }
  
  double pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
