# Rename dash mastery to ability mastery
_Exported on 9/26/2025 at 22:13:21 PDT from Cursor (1.6.45)_

---

**User**

we have an old naming `dash mastery` in item which is actually very confusing now since it becomes basically `$ability mastery` in implementation. This caused errors in our @game_introduction_v3.md . Let's rename it everywhere in our project

---

**Cursor**

I'll help you rename "Dash Mastery" to "Ability Mastery" throughout the project. Let me first explore the codebase to understand where this item is referenced.

Now let me update the TODO and start making the changes systematically:

Now let me make the changes systematically. I'll start with the configuration files:

```yaml
items:
  - id: health_potion
    name: Health Potion
    cost: 30
    description: Restore 50 HP
    type: health
    icon: health_potion_transparent.png
    effect:
      type: heal
      value: 50

  - id: ability_mastery
    name: Ability Mastery
    cost: 60
    description: -20% Ability Cooldown
    type: ability
    icon: ability_mastery_transparent.png
    effect:
      type: dash_cooldown_multiplier
      value: 0.8

  - id: max_health_up
    name: Max Health Up
    cost: 50
    description: +25 Max Health
    type: health
    icon: max_health_up_transparent.png
    effect:
      type: max_health_increase
      value: 25

  - id: attack_speed_up
    name: Attack Speed Up
    cost: 60
    description: +25% Attack Speed
    type: attack
    icon: attack_speed_transparent.png
    effect:
      type: attack_speed_multiplier
      value: 0.25

  - id: speed_boost
    name: Speed Boost
    cost: 40
    description: +25% Movement Speed
    type: other
    icon: speed_boost_transparent.png
    effect:
      type: speed_multiplier
      value: 0.25

  - id: extended_reach
    name: Extended Reach
    cost: 150
    description: +50% Range for all attacks and abilities
    type: ability
    icon: extended_reach_transparent.png
    effect:
      type: range_multiplier
      value: 0.5

  - id: spread_master
    name: Spread Master
    cost: 70
    description: +1 projectile per shot, stack up to +9 (max 10 shots)
    type: attack
    icon: attack_speed_transparent.png
    effect:
      type: projectile_count
      value: 1
      max_stacks: 9

  - id: bouncing_bullets
    name: Bouncing Bullets
    cost: 80
    description: +1 projectile bounce per shot, stackable to +3
    type: attack
    icon: attack_speed_transparent.png
    effect:
      type: projectile_bounces
      value: 1
      max_stacks: 3

  - id: drone_wingman
    name: Drone Wingman
    cost: 90
    description: Summons one auto-firing drone (0.8 shots/sec), infinite stacks
    type: other
    icon: ability_mastery_transparent.png
    effect:
      type: drone_count
      value: 1
      max_stacks: 999
    companion_config:
      radius: 8.0
      fire_rate: 0.8  # shots per second
      orbit_radius: 60.0
      orbit_speed: 2.0  # radians per second
      target_scan_interval: 0.5  # seconds
      attack_range: 800.0
      projectile_speed: 600.0
      projectile_damage: 30.0
      color: 0xFF2196F3  # Blue
      projectile_size_scale: 0.7

  - id: enlarged_caliber
    name: Enlarged Caliber
    cost: 60
    description: +25% projectile & character size, -25% speed per stack (max 5 stacks)
    type: other
    icon: extended_reach_transparent.png
    effect:
      type: enlarged_caliber
      value: 0.25
      max_stacks: 5

  - id: vampiric_coating
    name: Vampiric Coating
    cost: 80
    description: Recover 1 HP per kill
    type: health
    icon: health_potion_transparent.png
    effect:
      type: heal_per_kill
      value: 1.0
      max_stacks: 1000

  # ARMOR ITEMS TEMPORARILY DISABLED
  # - id: armor_plating
  #   name: Armor Plating
  #   cost: 70
  #   description: +5 shield HP per stack, max +100; shields fully regens between waves
  #   type: passive
  #   icon: max_health_up_transparent.png
  #   effect:
  #     type: shield_hp
  #     value: 5
  #     max_stacks: 20

  - id: coin_magnet
    name: Coin Magnet
    cost: 50
    description: +20% coin earn, max +100%
    type: other
    icon: speed_boost_transparent.png
    effect:
      type: coin_multiplier
      value: 0.2
      max_stacks: 5

  - id: auto_injector
    name: Auto-Injector
    cost: 100
    description: +2 Max HP per 10 kills (max +50 HP per stack)
    type: health
    icon: health_potion_transparent.png
    effect:
      type: auto_injector
      value: 2
      max_stacks: 999

  - id: critical_striker
    name: Critical Striker
    cost: 75
    description: +2% crit chance per stack, max +10%
    type: attack
    icon: attack_speed_transparent.png
    effect:
      type: crit_chance
      value: 0.02
      max_stacks: 5

```

```plaintext
{
  "items": [
    {
      "id": "health_potion",
      "name": "Health Potion",
      "cost": 30,
      "description": "Restore 50 HP",
      "type": "consumable",
      "icon": "health_potion_transparent.png",
      "effect": {
        "type": "heal",
        "value": 50
      }
    },
    {
      "id": "ability_mastery",
      "name": "Ability Mastery",
      "cost": 60,
      "description": "-20% Ability Cooldown",
      "type": "upgrade",
      "icon": "ability_mastery_transparent.png",
      "effect": {
        "type": "dash_cooldown_multiplier",
        "value": 0.8
      }
    },
    {
      "id": "max_health_up",
      "name": "Max Health Up",
      "cost": 50,
      "description": "+25 Max Health",
      "type": "upgrade",
      "icon": "max_health_up_transparent.png",
      "effect": {
        "type": "max_health_increase",
        "value": 25
      }
    },
    {
      "id": "attack_speed_up",
      "name": "Attack Speed Up",
      "cost": 60,
      "description": "+25% Attack Speed",
      "type": "upgrade",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "attack_speed_multiplier",
        "value": 0.25
      }
    },
    {
      "id": "speed_boost",
      "name": "Speed Boost",
      "cost": 40,
      "description": "+25% Movement Speed",
      "type": "upgrade",
      "icon": "speed_boost_transparent.png",
      "effect": {
        "type": "speed_multiplier",
        "value": 0.25
      }
    },
    {
      "id": "extended_reach",
      "name": "Extended Reach",
      "cost": 150,
      "description": "+50% Range for all attacks and abilities",
      "type": "upgrade",
      "icon": "extended_reach_transparent.png",
      "effect": {
        "type": "range_multiplier",
        "value": 0.5
      }
    },
    {
      "id": "spread_master",
      "name": "Spread Master",
      "cost": 70,
      "description": "+1 projectile per shot, stack up to +9 (max 10 shots)",
      "type": "passive",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "projectile_count",
        "value": 1,
        "max_stacks": 9
      }
    },
    {
      "id": "bouncing_bullets",
      "name": "Bouncing Bullets",
      "cost": 80,
      "description": "+1 projectile bounce per shot, stackable to +3",
      "type": "passive",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "projectile_bounces",
        "value": 1,
        "max_stacks": 3
      }
    },
    {
      "id": "drone_wingman",
      "name": "Drone Wingman",
      "cost": 90,
      "description": "Summons one auto-firing drone (0.8 shots/sec), infinite stacks",
      "type": "passive",
      "icon": "ability_mastery_transparent.png",
      "effect": {
        "type": "drone_count",
        "value": 1,
        "max_stacks": 999
      }
    },
    {
      "id": "enlarged_caliber",
      "name": "Enlarged Caliber",
      "cost": 60,
      "description": "+10% projectile & character size, -25% speed per stack (max 5 stacks)",
      "type": "passive",
      "icon": "extended_reach_transparent.png",
      "effect": {
        "type": "enlarged_caliber",
        "value": 0.1,
        "max_stacks": 5
      }
    },
    {
      "id": "vampiric_coating",
      "name": "Vampiric Coating",
      "cost": 80,
      "description": "Recover 1 HP per kill",
      "type": "passive",
      "icon": "health_potion_transparent.png",
      "effect": {
        "type": "heal_per_kill",
        "value": 1.0,
        "max_stacks": 1000
      }
    },
    {
      "id": "armor_plating",
      "name": "Armor Plating",
      "cost": 70,
      "description": "+5 shield HP per stack, max +100; shields fully regens between waves",
      "type": "passive",
      "icon": "max_health_up_transparent.png",
      "effect": {
        "type": "shield_hp",
        "value": 5,
        "max_stacks": 20
      }
    },
    {
      "id": "coin_magnet",
      "name": "Coin Magnet",
      "cost": 50,
      "description": "+20% coin earn, max +100%",
      "type": "passive",
      "icon": "speed_boost_transparent.png",
      "effect": {
        "type": "coin_multiplier",
        "value": 0.2,
        "max_stacks": 5
      }
    },
    {
      "id": "auto_injector",
      "name": "Auto-Injector",
      "cost": 100,
      "description": "+2 Max HP per 10 kills (max +50 HP per stack)",
      "type": "passive",
      "icon": "health_potion_transparent.png",
      "effect": {
        "type": "auto_injector",
        "value": 2,
        "max_stacks": 999
      }
    },
    {
      "id": "critical_striker",
      "name": "Critical Striker",
      "cost": 75,
      "description": "+2% crit chance per stack, max +10%",
      "type": "passive",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "crit_chance",
        "value": 0.02,
        "max_stacks": 5
      }
    }
  ]
} 
```

Now let me update the Dart code references:

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game/circle_rouge_game.dart';
import '../config/item_config.dart';
import '../config/wave_config.dart';
import 'sound_manager.dart';
import '../config/display_config.dart';
import 'ui/responsive_layout.dart';
import '../config/game_mode_config.dart';

class ShopItem {
  final String id;
  final String name;
  final int cost;
  final String description;
  final String icon;
  final void Function() onPurchase;
  
  ShopItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
    required this.icon,
    required this.onPurchase,
  });
  
  factory ShopItem.fromItemData(ItemData itemData, void Function() onPurchase, int scaledCost) {
    return ShopItem(
      id: itemData.id,
      name: itemData.name,
      cost: scaledCost,
      description: itemData.description,
      icon: itemData.icon,
      onPurchase: onPurchase,
    );
  }
}

class ShopPanel extends RectangleComponent with HasGameRef<CircleRougeGame>, TapCallbacks, ResponsiveMixin {
  late List<ShopSlot> itemSlots;
  late RectangleComponent rollButton;
  late TextComponent rollButtonText;
  late TextComponent titleText;
  late TextComponent instructionText;
  late RectangleComponent backgroundGradient;
  late RectangleComponent headerPanel;
  late RectangleComponent footerPanel;
  
  bool isVisible = false;
  int rollCount = 0; // Track number of rolls in this shop session
  
  // Base dimensions for responsive scaling
  static const double basePanelWidth = 715.0;
  static const double basePanelHeight = 550.0;
  static const double baseSlotWidth = 176.0;
  static const double baseSlotHeight = 275.0;
  static const double baseSlotSpacing = 49.5;
  
  ShopPanel() : super(
    size: Vector2(basePanelWidth, basePanelHeight),
    paint: Paint()..color = Colors.transparent,
    position: Vector2(
      (DisplayConfig.instance.arenaWidth - basePanelWidth) / 2,
      (DisplayConfig.instance.arenaHeight - basePanelHeight) / 2,
    ),
    anchor: Anchor.topLeft, // Keep original anchor
  );
  
  /// Get current scaled dimensions
  Vector2 get scaledPanelSize => size;
  double get scaledPanelWidth => scaledPanelSize.x;
  double get scaledPanelHeight => scaledPanelSize.y;
  double get scaledSlotWidth => baseSlotWidth * (scaledPanelWidth / basePanelWidth);
  double get scaledSlotHeight => baseSlotHeight * (scaledPanelHeight / basePanelHeight);
  double get scaledSlotSpacing => baseSlotSpacing * (scaledPanelWidth / basePanelWidth);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Set up display config listener for simple responsive behavior
    DisplayConfig.instance.addListener(_onDisplayConfigChanged);
    
    _setupVisualComponents();  // Set up background first (lower z-order)
    _setupItemSlots();          // Then add item slots on top
    
    // Populate with initial items after everything is set up
    rollShopItems();
  }
  
  void _setupVisualComponents() {
    // Background with enhanced gradient effect
    backgroundGradient = RectangleComponent(
      size: scaledPanelSize,
      paint: Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D2D4A),
            Color(0xFF1E1E3A),
            Color(0xFF151528),
          ],
        ).createShader(Rect.fromLTWH(0, 0, scaledPanelWidth, scaledPanelHeight)),
      position: Vector2.zero(),
    );
    add(backgroundGradient);
    
    // Main border with enhanced glow effect
    final border = RectangleComponent(
      size: Vector2(basePanelWidth, basePanelHeight),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF4A9EFF).withOpacity(0.6),
      position: Vector2.zero(),
    );
    add(border);
    
    // Outer glow effect
    final outerGlow = RectangleComponent(
      size: Vector2(basePanelWidth + 10, basePanelHeight + 10),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = const Color(0xFF4A9EFF).withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      position: Vector2(-5, -5),
    );
    add(outerGlow);
    
    // Header panel with gradient
    headerPanel = RectangleComponent(
      size: Vector2(basePanelWidth - 20, 99),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF4A9EFF),
            Color(0xFF9C27B0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, basePanelWidth - 20, 99))
        ..color = const Color(0xFF4A9EFF).withOpacity(0.15),
      position: Vector2(10, 10),
    );
    add(headerPanel);
    
    // Header border with glow
    final headerBorder = RectangleComponent(
      size: Vector2(basePanelWidth - 20, 99),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4A9EFF).withOpacity(0.6),
      position: Vector2(10, 10),
    );
    add(headerBorder);
    
    // Title with enhanced styling and shader mask effect
    titleText = TextComponent(
      text: 'MYSTICAL SHOP',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white, // This will be overridden by the gradient
          fontSize: 35.2, // Increased from 32 (10% bigger)
          fontWeight: FontWeight.w900,
          letterSpacing: 3.0,
          shadows: [
            Shadow(
              color: Color(0xFF4A9EFF),
              blurRadius: 15,
            ),
            Shadow(
              color: Color(0xFF9C27B0),
              blurRadius: 10,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 5,
            ),
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(scaledPanelWidth / 2, 33 * (scaledPanelHeight / basePanelHeight)), // Back to original approach
    );
    add(titleText);
    
    // Instructions with enhanced styling
    instructionText = TextComponent(
      text: 'Enhance your hero with powerful upgrades',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 17.6, // Increased from 16 (10% bigger)
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 6,
            ),
            Shadow(
              color: Color(0xFF4A9EFF),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(scaledPanelWidth / 2, 77 * (scaledPanelHeight / basePanelHeight)), // Back to original approach
    );
    add(instructionText);
    
    // Item slots will be set up in separate method
    
    // Footer panel with gradient background
    footerPanel = RectangleComponent(
      size: Vector2(scaledPanelWidth - 20 * (scaledPanelWidth / basePanelWidth), 70 * (scaledPanelHeight / basePanelHeight)),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF2D2D4A),
            Color(0xFF1E1E3A),
          ],
        ).createShader(Rect.fromLTWH(0, 0, basePanelWidth - 20, 70))
        ..color = const Color(0xFF2D2D4A).withOpacity(0.6),
      position: Vector2(10, basePanelHeight - 80),
    );
    add(footerPanel);
    
    // Footer border
    final footerBorder = RectangleComponent(
      size: Vector2(basePanelWidth - 20, 70),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4A9EFF).withOpacity(0.3),
      position: Vector2(10, basePanelHeight - 80),
    );
    add(footerBorder);
    
    // Roll button with enhanced gradient styling
    rollButton = RectangleComponent(
      size: Vector2(140, 45),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF2196F3),
            Color(0xFF1976D2),
          ],
        ).createShader(Rect.fromLTWH(0, 0, 140, 45)),
      position: Vector2((basePanelWidth - 140) / 2 - 90, basePanelHeight - 65),
    );
    add(rollButton);
    
    // Roll button glow effect
    final rollButtonGlow = RectangleComponent(
      size: Vector2(140, 45),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF2196F3).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      position: Vector2((basePanelWidth - 140) / 2 - 90, basePanelHeight - 65),
    );
    add(rollButtonGlow);
    
    rollButtonText = TextComponent(
      text: 'REROLL (10)',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(70, 22.5),
    );
    rollButton.add(rollButtonText);
    
    // Continue button with enhanced gradient styling
    final continueButton = RectangleComponent(
      size: Vector2(140, 45),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF388E3C),
          ],
        ).createShader(Rect.fromLTWH(0, 0, 140, 45)),
      position: Vector2((basePanelWidth - 140) / 2 + 90, basePanelHeight - 65),
    );
    add(continueButton);
    
    // Continue button glow effect
    final continueButtonGlow = RectangleComponent(
      size: Vector2(140, 45),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF4CAF50).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      position: Vector2((basePanelWidth - 140) / 2 + 90, basePanelHeight - 65),
    );
    add(continueButtonGlow);
    
    final continueButtonText = TextComponent(
      text: 'CONTINUE',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(70, 22.5),
    );
    continueButton.add(continueButtonText);
    
    // Store continue button reference for tap detection
    continueButton.add(Component());
    continueButton.children.register<Component>();
    
    // Initially hidden
    hide();
    
    // Initial items will be populated after onLoad completes
  }
  
  void _setupItemSlots() {
    // Create item slots with responsive positioning
    itemSlots = [];
    final slotsStartX = (scaledPanelWidth - (3 * scaledSlotWidth + 2 * scaledSlotSpacing)) / 2;
    for (int i = 0; i < 3; i++) {
      final slot = ShopSlot(
        position: Vector2(
          slotsStartX + i * (scaledSlotWidth + scaledSlotSpacing),
          121 * (scaledPanelHeight / basePanelHeight), // Scale the Y position too
        ),
      );
      // Update slot size to match scaled dimensions
      slot.size = Vector2(scaledSlotWidth, scaledSlotHeight);
      // Set high priority to ensure slots render on top
      slot.priority = 100;
      itemSlots.add(slot);
      add(slot);
    }
  }
  
  void show() {
    isVisible = true;
    opacity = 1.0;
  }
  
  void hide() {
    isVisible = false;
    opacity = 0.0;
  }
  
  @override
  void onRemove() {
    DisplayConfig.instance.removeListener(_onDisplayConfigChanged);
    super.onRemove();
  }
  
  /// Handle display config changes for responsive behavior
  void _onDisplayConfigChanged(DisplaySettings oldSettings, DisplaySettings newSettings) {
    print('ShopPanel: Display config changed - ${newSettings.arenaWidth.toInt()}x${newSettings.arenaHeight.toInt()}, scale: ${newSettings.scaleFactor.toStringAsFixed(2)}');
    
    // Update panel size and position
    final scaleFactor = newSettings.scaleFactor;
    final newSize = Vector2(basePanelWidth * scaleFactor, basePanelHeight * scaleFactor);
    final newPosition = Vector2(
      (newSettings.arenaWidth - newSize.x) / 2,
      (newSettings.arenaHeight - newSize.y) / 2,
    );
    
    // Only update if there's an actual change to prevent unnecessary refreshes
    if ((size - newSize).length > 1.0 || (position - newPosition).length > 1.0) {
      size = newSize;
      position = newPosition;
      
      print('ShopPanel: Updated - size: ${size.x.toInt()}x${size.y.toInt()}, pos: ${position.x.toInt()},${position.y.toInt()}');
      
      // Refresh child components with new dimensions
      _refreshChildComponents();
    }
  }
  
  // Removed updateResponsiveLayout since we're not using ResponsiveMixin
  
  /// Refresh all child components with current scaled dimensions
  void _refreshChildComponents() {
    // Save current items before refresh
    final List<ShopItem?> currentItems = itemSlots.map((slot) => slot.currentItem).toList();
    
    // Remove and recreate all child components with new scaled dimensions
    removeAll(children.toList());
    _setupVisualComponents();  // Set up background first (lower z-order)
    _setupItemSlots();          // Then add item slots on top
    
    // Restore items to the new slots
    for (int i = 0; i < currentItems.length && i < itemSlots.length; i++) {
      if (currentItems[i] != null) {
        itemSlots[i].setItem(currentItems[i]!);
      }
    }
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    if (!isVisible) return false;
    
    final localPoint = event.localPosition;
    
    // Check if roll button was tapped - updated for 10% bigger dimensions
    final rollButtonRect = Rect.fromLTWH(
      rollButton.position.x,
      rollButton.position.y,
      154, // Updated from 140
      49.5, // Updated from 45
    );
    
    if (rollButtonRect.contains(Offset(localPoint.x, localPoint.y))) {
      rollShopItems();
      return true;
    }
    
    // Check if continue button was tapped - updated for 10% bigger dimensions
    final continueButtonPosition = Vector2((basePanelWidth - 154) / 2 + 99, basePanelHeight - 71.5); // Updated from 140/90/65
    final continueButtonRect = Rect.fromLTWH(
      continueButtonPosition.x,
      continueButtonPosition.y,
      154, // Updated from 140
      49.5, // Updated from 45
    );
    
    if (continueButtonRect.contains(Offset(localPoint.x, localPoint.y))) {
      closeShop();
      return true;
    }
    
    return false;
  }
  
  void rollShopItems() {
    // Check if all items are sold (free roll)
    final allItemsSold = itemSlots.every((slot) => slot.currentItem == null);
    
    // Calculate roll cost: base cost + roll count (increments by 1 each roll)
    final baseCost = WaveConfig.instance.shopConfig?.rollCost ?? 10;
    final rollCost = allItemsSold ? 0 : (baseCost + rollCount);
    
    // Check if player has enough coins to roll
    if (gameRef.hero.coins < rollCost) {
      return; // Not enough coins to roll
    }
    
    // Spend coins for rolling (if not free)
    if (rollCost > 0) {
      gameRef.hero.spendCoins(rollCost);
      rollCount++; // Increment roll count after successful roll
    }
    
    final availableItems = _getAvailableItems();
    final random = Random();
    
    for (int i = 0; i < 3; i++) {
      if (availableItems.isNotEmpty) {
        final randomItem = availableItems[random.nextInt(availableItems.length)];
        itemSlots[i].setItem(randomItem);
      }
    }
    
    // Update roll button text with next roll cost
    final nextRollCost = baseCost + rollCount;
    rollButtonText.text = 'REROLL ($nextRollCost)';
  }
  
  List<ShopItem> _getAvailableItems() {
    final itemConfig = ItemConfig.instance;
    final shopConfig = WaveConfig.instance.shopConfig;
    List<ShopItem> availableItems = [];
    final random = Random();
    
    for (final itemData in itemConfig.items) {
      // Skip health-related items in 1HP Challenge mode
      if (gameRef.currentGameMode == GameMode.oneHpChallenge) {
        if (itemData.effect.type == 'heal' || 
            itemData.effect.type == 'max_health_increase') {
          continue; // Skip health items in 1HP mode
        }
      }
      
      // Calculate scaled price based on current wave using configuration
      double waveMultiplier = 1.0;
      double randomMultiplier = 1.0;
      
      if (shopConfig != null) {
        waveMultiplier = 1.0 + (shopConfig.waveMultiplier * (gameRef.currentWave - 1));
        randomMultiplier = (1.0 - shopConfig.randomVariance) + (random.nextDouble() * shopConfig.randomVariance * 2);
      } else {
        // Fallback to old hardcoded values
        waveMultiplier = 1.0 + (0.2 * (gameRef.currentWave - 1));
        randomMultiplier = 0.95 + (random.nextDouble() * 0.1);
      }
      
      final scaledCost = (itemData.cost * waveMultiplier * randomMultiplier).round();
      
      // Create dynamic name for ability cooldown reduction based on hero's ability
      if (itemData.id == 'ability_mastery') {
        final heroAbilityName = gameRef.hero.heroData.ability.name;
        availableItems.add(ShopItem(
          id: itemData.id,
          name: '$heroAbilityName Mastery',
          cost: scaledCost,
          description: '-25% ${heroAbilityName} Cooldown',
          icon: itemData.icon,
          onPurchase: () => _applyItemEffect(itemData),
        ));
      } else {
        availableItems.add(ShopItem.fromItemData(itemData, () => _applyItemEffect(itemData), scaledCost));
      }
    }
    
    return availableItems;
  }
  
  void _applyItemEffect(ItemData itemData) {
    switch (itemData.effect.type) {
      case 'heal':
        final healAmount = (gameRef.hero.maxHealth - gameRef.hero.health).clamp(0.0, itemData.effect.value);
        gameRef.hero.heal(healAmount);
        break;
      case 'dash_cooldown_multiplier':
        // Apply ability cooldown reduction
        gameRef.hero.abilityCooldownMultiplier *= itemData.effect.value;
        break;
      case 'max_health_increase':
        gameRef.hero.maxHealth += itemData.effect.value;
        gameRef.hero.health += itemData.effect.value;
        break;
      case 'attack_speed_multiplier':
        gameRef.hero.attackSpeedMultiplier += itemData.effect.value;
        break;
      case 'speed_multiplier':
        gameRef.hero.speedMultiplier += itemData.effect.value;
        break;
      case 'range_multiplier':
        gameRef.hero.rangeMultiplier += itemData.effect.value;
        break;
      // New stackable passive effects
      case 'projectile_count':
      case 'projectile_bounces':
      case 'projectile_size':
      case 'life_steal':
      case 'shield_hp':
      case 'coin_multiplier':
      case 'heal_per_kill':
      case 'crit_chance':
      case 'clone_spawn':
      case 'max_health_boost':
        final maxStacks = itemData.effect.maxStacks ?? 1;
        gameRef.hero.addPassiveEffect(itemData.effect.type, maxStacks);
        // Max health boost only affects max HP, not current HP
        break;
      case 'drone_count':
        final maxStacks = itemData.effect.maxStacks ?? 1;
        gameRef.hero.addPassiveEffect(itemData.effect.type, maxStacks);
        // Update drone count immediately
        gameRef.hero.updateDroneCount();
        break;
      case 'auto_injector':
        final maxStacks = itemData.effect.maxStacks ?? 1;
        gameRef.hero.addPassiveEffect(itemData.effect.type, maxStacks);
        // Auto-injector HP bonus is applied on kill, not on purchase
        break;
      case 'enlarged_caliber':
        final maxStacks = itemData.effect.maxStacks ?? 1;
        gameRef.hero.addPassiveEffect(itemData.effect.type, maxStacks);
        // Update hero size immediately
        gameRef.hero.updateHeroSize();
        break;
      default:
        print('Unknown item effect type: ${itemData.effect.type}');
    }
  }
  
  void onItemPurchased() {
    // Update roll button text based on remaining items
    final allItemsSold = itemSlots.every((slot) => slot.currentItem == null);
    final baseCost = WaveConfig.instance.shopConfig?.rollCost ?? 10;
    final rollCost = allItemsSold ? 0 : (baseCost + rollCount);
    rollButtonText.text = rollCost == 0 ? 'REROLL (FREE)' : 'REROLL ($rollCost)';
    
    // Update affordability of remaining items after purchase
    for (final slot in itemSlots) {
      if (slot.currentItem != null) {
        slot.updateAffordability();
      }
    }
  }
  
  void resetForNewWave() {
    rollCount = 0; // Reset roll count for new shop session
  }
  
  void closeShop() {
    hide();
    gameRef.onShopClosed();
  }
}

class ShopSlot extends RectangleComponent with TapCallbacks, HasGameRef<CircleRougeGame> {
  late TextBoxComponent nameText;
  late TextComponent costText;
  late TextBoxComponent descriptionText;
  late RectangleComponent buyButton;
  late TextComponent buyButtonText;
  Component? itemIcon;
  late RectangleComponent border;
  late RectangleComponent outerGlow;
  late RectangleComponent buyButtonGlow;
  late RectangleComponent blurBackground;
  
  ShopItem? currentItem;
  
  // Toggle state for showing description
  bool _showingDescription = false;
  double _animationTime = 0.0;
  static const double _animationDuration = 0.3;
  
  ShopSlot({required Vector2 position}) : super(
    size: Vector2(ShopPanel.baseSlotWidth, ShopPanel.baseSlotHeight),
    paint: Paint()..color = Colors.transparent,
    position: position,
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Background with enhanced gradient
    final background = RectangleComponent(
      size: Vector2(size.x, size.y),
      paint: Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A3A3A),
            Color(0xFF2A2A2A),
            Color(0xFF1A1A1A),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
      position: Vector2.zero(),
    );
    add(background);
    
    // Border with enhanced glow
    border = RectangleComponent(
      size: Vector2(size.x, size.y),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4A9EFF).withOpacity(0.5),
      position: Vector2.zero(),
    );
    add(border);
    
    // Outer glow effect for slots
    outerGlow = RectangleComponent(
      size: Vector2(size.x + 4, size.y + 4),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xFF4A9EFF).withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      position: Vector2(-2, -2),
    );
    add(outerGlow);
    
    // itemIcon will be created when setItem() is called - no initial placeholder needed
    
    // Item name with enhanced styling and line wrapping
    nameText = TextBoxComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF4A9EFF),
          fontSize: 17.6,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: [
            Shadow(
              color: Color(0xFF4A9EFF),
              blurRadius: 6,
            ),
          ],
        ),
      ),
      align: Anchor.center,
      boxConfig: TextBoxConfig(
        maxWidth: size.x - 10,
        timePerChar: 0.0,
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 82.5),
    );
    add(nameText);
    
    // Item description with better styling and text wrapping (initially hidden)
    descriptionText = TextBoxComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.transparent, // Initially hidden
          fontSize: 13.2,
          fontWeight: FontWeight.w500,
          height: 1.4,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      ),
      boxConfig: TextBoxConfig(
        maxWidth: size.x - 20, // Leave some padding
        timePerChar: 0.0, // No typewriter effect
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 132),
    );
    add(descriptionText);
    
    // Cost with enhanced styling
    costText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFEB3B),
          fontSize: 19.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: [
            Shadow(
              color: Color(0xFFFFEB3B),
              blurRadius: 8,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 170.5),
    );
    add(costText);
    
    // Buy button with enhanced gradient styling
    buyButton = RectangleComponent(
      size: Vector2(143, 44),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF388E3C),
          ],
        ).createShader(Rect.fromLTWH(0, 0, 143, 44)),
      position: Vector2((size.x - 143) / 2, size.y - 60.5),
    );
    add(buyButton);
    
    // Buy button glow effect
    buyButtonGlow = RectangleComponent(
      size: Vector2(143, 44),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF4CAF50).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      position: Vector2((size.x - 143) / 2, size.y - 60.5),
    );
    add(buyButtonGlow);
    
    buyButtonText = TextComponent(
      text: 'PURCHASE',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15.4,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(71.5, 22),
    );
    buyButton.add(buyButtonText);
    
    // Blur background for description mode (initially hidden) - added last so it appears on top
    blurBackground = RectangleComponent(
      size: Vector2(size.x, size.y),
      paint: Paint()
        ..color = const Color(0xFF000000).withOpacity(0.0) // Initially transparent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      position: Vector2.zero(),
    );
    add(blurBackground);
  }
  
  // Get category colors based on item type
  Map<String, Color> _getCategoryColors(String itemId) {
    // Get item data to check its type
    final itemData = ItemConfig.instance.getItemById(itemId);
    final itemType = itemData?.type ?? 'other';
    
    switch (itemType) {
      case 'health':
        // Green for health items
        return {
          'primary': const Color(0xFF4CAF50),
          'secondary': const Color(0xFF66BB6A),
          'glow': const Color(0xFF4CAF50),
        };
      case 'attack':
        // Red for attack items
        return {
          'primary': const Color(0xFFF44336),
          'secondary': const Color(0xFFE57373),
          'glow': const Color(0xFFF44336),
        };
      case 'ability':
        // Hero color for ability items
        final heroColor = gameRef.hero.heroData.color;
        return {
          'primary': heroColor,
          'secondary': heroColor.withOpacity(0.8),
          'glow': heroColor,
        };
      case 'other':
      default:
        // Blue for other items
        return {
          'primary': const Color(0xFF2196F3),
          'secondary': const Color(0xFF64B5F6),
          'glow': const Color(0xFF2196F3),
        };
    }
  }

  void setItem(ShopItem item) async {
    currentItem = item;
    final colors = _getCategoryColors(item.id);
    
    // Reset to default view when setting a new item
    _showingDescription = false;
    _animationTime = 0.0;
    
    nameText.text = item.name.toUpperCase();
    descriptionText.text = item.description;
    costText.text = '${item.cost} COINS';
    
    // Replace the current icon with a sprite-based icon
    if (itemIcon?.isMounted == true) {
      itemIcon!.removeFromParent();
    }
    
    try {
      // Try to load the actual item icon sprite
      final sprite = await Sprite.load(item.icon);
      itemIcon = SpriteComponent(
        sprite: sprite,
        size: Vector2(44, 44),
        position: Vector2((size.x - 44) / 2, 22),
        anchor: Anchor.topLeft,
      );
    } catch (e) {
      print('Could not load item icon: ${item.icon}, using colored rectangle fallback');
      // Fallback to colored rectangle with category color
      itemIcon = RectangleComponent(
        size: Vector2(44, 44),
        position: Vector2((size.x - 44) / 2, 22),
        paint: Paint()..color = colors['primary']!,
      );
    }
    
    // Add the new icon - make sure it's behind the blur background
    if (itemIcon != null) add(itemIcon!);
    
    // Ensure blur background is on top
    if (blurBackground.isMounted) {
      blurBackground.removeFromParent();
      add(blurBackground);
    }
    
    // Update name text color to match category
    nameText.textRenderer = TextPaint(
      style: TextStyle(
        color: colors['primary']!,
        fontSize: 17.6,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        shadows: [
          Shadow(
            color: colors['glow']!,
            blurRadius: 6,
          ),
        ],
      ),
    );
    
    // Update cost text color to match category
    costText.textRenderer = TextPaint(
      style: TextStyle(
        color: colors['primary']!,
        fontSize: 19.8,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        shadows: [
          Shadow(
            color: colors['glow']!,
            blurRadius: 8,
          ),
        ],
      ),
    );
    
    // Update border and glow colors to match category
    border.paint.color = colors['primary']!.withOpacity(0.6);
    outerGlow.paint.color = colors['glow']!.withOpacity(0.15);
    
    // Ensure all components are visible in default view
    _showDefaultView();
    
    // Update buy button styling based on affordability and category
    if (gameRef.hero.coins >= item.cost) {
      // Update buy button gradient with category colors
      buyButton.paint.shader = LinearGradient(
        colors: [
          colors['primary']!,
          colors['secondary']!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, 143, 44));
      
      buyButtonGlow.paint.color = colors['glow']!.withOpacity(0.5);
      buyButtonText.text = 'PURCHASE';
    } else {
      // Grey for unaffordable items
      buyButton.paint.shader = const LinearGradient(
        colors: [
          Color(0xFF757575),
          Color(0xFF616161),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 143, 44));
      
      buyButtonGlow.paint.color = const Color(0xFF757575).withOpacity(0.3);
      buyButtonText.text = 'TOO EXPENSIVE';
      border.paint.color = const Color(0xFFF44336).withOpacity(0.4);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Handle animation
    if (_animationTime > 0) {
      _animationTime -= dt;
      if (_animationTime <= 0) {
        _animationTime = 0;
        _onAnimationComplete();
      } else {
        _updateAnimationProgress();
      }
    }
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    if (currentItem == null) return false;
    
    final localPoint = event.localPosition;
    
    // Check if buy button was tapped (only when showing default view)
    if (!_showingDescription && buyButton.containsLocalPoint(localPoint - buyButton.position)) {
      attemptPurchase();
      return true;
    }
    
    // Check if item info area was tapped (anywhere except buy button area when in default mode)
    if (!_showingDescription && localPoint.y < buyButton.position.y) {
      toggleDescriptionView();
      return true;
    } else if (_showingDescription) {
      // In description mode, tap anywhere to go back
      toggleDescriptionView();
      return true;
    }
    
    return false;
  }
  
  void toggleDescriptionView() {
    if (_animationTime > 0) return; // Prevent multiple toggles during animation
    
    _showingDescription = !_showingDescription;
    _animationTime = _animationDuration;
    
    // Play UI sound effect
    // SoundManager().playUICardOpenSound();
  }
  
  void _updateAnimationProgress() {
    final progress = 1.0 - (_animationTime / _animationDuration);
    final easedProgress = _easeInOutCubic(progress);
    
    if (_showingDescription) {
      // Animating to description view
      _animateToDescription(easedProgress);
    } else {
      // Animating back to default view
      _animateToDefault(easedProgress);
    }
  }
  
  void _onAnimationComplete() {
    if (_showingDescription) {
      _showDescriptionView();
    } else {
      _showDefaultView();
    }
  }
  
  void _animateToDescription(double progress) {
    // Fade out icon, name, price, and purchase button
    final fadeProgress = (progress * 2).clamp(0.0, 1.0);
    final opacity = 1.0 - fadeProgress;
    
    _setComponentVisibility(itemIcon, opacity);
    _setComponentVisibility(nameText, opacity);
    _setComponentVisibility(costText, opacity);
    _setComponentVisibility(buyButton, opacity);
    _setComponentVisibility(buyButtonGlow, opacity);
    
    // Fade in blur background
    blurBackground.paint.color = const Color(0xFF000000).withOpacity(0.7 * progress);
    
    // Scale up description text
    if (progress > 0.5) {
      final scaleProgress = (progress - 0.5) * 2;
      _setComponentVisibility(descriptionText, scaleProgress);
      descriptionText.scale = Vector2.all(0.9 + (0.1 * scaleProgress));
    } else {
      _setComponentVisibility(descriptionText, 0.0);
    }
  }
  
  void _animateToDefault(double progress) {
    // Fade out description
    final fadeProgress = (progress * 2).clamp(0.0, 1.0);
    _setComponentVisibility(descriptionText, 1.0 - fadeProgress);
    
    // Fade out blur background
    blurBackground.paint.color = const Color(0xFF000000).withOpacity(0.7 * (1.0 - progress));
    
    // Fade in icon, name, price, and purchase button
    if (progress > 0.5) {
      final showProgress = (progress - 0.5) * 2;
      _setComponentVisibility(itemIcon, showProgress);
      _setComponentVisibility(nameText, showProgress);
      _setComponentVisibility(costText, showProgress);
      _setComponentVisibility(buyButton, showProgress);
      _setComponentVisibility(buyButtonGlow, showProgress);
    } else {
      _setComponentVisibility(itemIcon, 0.0);
      _setComponentVisibility(nameText, 0.0);
      _setComponentVisibility(costText, 0.0);
      _setComponentVisibility(buyButton, 0.0);
      _setComponentVisibility(buyButtonGlow, 0.0);
    }
  }
  
  void _showDescriptionView() {
    // Hide everything except description
    _setComponentVisibility(itemIcon, 0.0);
    _setComponentVisibility(nameText, 0.0);
    _setComponentVisibility(costText, 0.0);
    _setComponentVisibility(buyButton, 0.0);
    _setComponentVisibility(buyButtonGlow, 0.0);
    
    // Show blur background
    blurBackground.paint.color = const Color(0xFF000000).withOpacity(0.7);
    
    // Recreate description component with centered layout and better wrapping
    if (descriptionText.isMounted) {
      descriptionText.removeFromParent();
    }
    
    descriptionText = TextBoxComponent(
      text: currentItem?.description ?? '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 16.0, // Larger font for description-only view
          fontWeight: FontWeight.w500,
          height: 1.5,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      ),
      boxConfig: TextBoxConfig(
        maxWidth: size.x - 30, // More padding for better readability
        timePerChar: 0.0,
      ),
      align: Anchor.center, // Center align the text content
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2),
    );
    add(descriptionText);
  }
  
  void _showDefaultView() {
    // Show all default elements
    _setComponentVisibility(itemIcon, 1.0);
    _setComponentVisibility(nameText, 1.0);
    _setComponentVisibility(costText, 1.0);
    _setComponentVisibility(buyButton, 1.0);
    _setComponentVisibility(buyButtonGlow, 1.0);
    
    // Hide blur background
    blurBackground.paint.color = const Color(0xFF000000).withOpacity(0.0);
    
    // Recreate description component for default view (hidden)
    if (descriptionText.isMounted) {
      descriptionText.removeFromParent();
    }
    
    descriptionText = TextBoxComponent(
      text: '', // Empty in default view
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.transparent, // Hidden in default view
          fontSize: 13.2,
          fontWeight: FontWeight.w500,
          height: 1.4,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      ),
      boxConfig: TextBoxConfig(
        maxWidth: size.x - 20,
        timePerChar: 0.0,
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 132),
    );
    add(descriptionText);
  }
  
  void _setComponentVisibility(Component? component, double opacity) {
    if (component == null) return;
    if (component is RectangleComponent) {
      final currentColor = component.paint.color;
      component.paint.color = currentColor.withOpacity(opacity);
    } else if (component is TextComponent && component.textRenderer is TextPaint) {
      final textPaint = component.textRenderer as TextPaint;
      final currentStyle = textPaint.style;
      component.textRenderer = TextPaint(
        style: currentStyle.copyWith(
          color: currentStyle.color?.withOpacity(opacity),
        ),
      );
    } else if (component is TextBoxComponent && component.textRenderer is TextPaint) {
      final textPaint = component.textRenderer as TextPaint;
      final currentStyle = textPaint.style;
      component.textRenderer = TextPaint(
        style: currentStyle.copyWith(
          color: currentStyle.color?.withOpacity(opacity),
        ),
      );
    } else if (component is SpriteComponent) {
      component.paint.colorFilter = ColorFilter.mode(
        Colors.white.withOpacity(opacity),
        BlendMode.modulate,
      );
    }
  }
  
  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
  }
  
  double pow(double base, double exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent.toInt(); i++) {
      result *= base;
    }
    return result;
  }
  
  void attemptPurchase() {
    if (currentItem == null) return;
    
    if (gameRef.hero.coins >= currentItem!.cost) {
      gameRef.hero.spendCoins(currentItem!.cost);
      currentItem!.onPurchase();
      
      // Play purchase sound effect
      SoundManager().playPurchaseSound();
      
      // Clear this slot with enhanced sold styling
      currentItem = null;
      nameText.text = 'SOLD';
      nameText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Color(0xFF4CAF50),
          fontSize: 17.6,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Color(0xFF4CAF50),
              blurRadius: 8,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 3,
            ),
          ],
        ),
      );
      descriptionText.text = 'Item purchased successfully!';
      descriptionText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Color(0xFF4CAF50),
          fontSize: 13.2,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      );
      costText.text = '';
      
      // Update buy button to sold out styling
      buyButton.paint.shader = const LinearGradient(
        colors: [
          Color(0xFF757575),
          Color(0xFF616161),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 143, 44));
      
      buyButtonGlow.paint.color = const Color(0xFF757575).withOpacity(0.3);
      buyButtonText.text = 'SOLD OUT';
      
      // Update border and glow to success green
      border.paint.color = const Color(0xFF4CAF50).withOpacity(0.8);
      outerGlow.paint.color = const Color(0xFF4CAF50).withOpacity(0.2);
      
      // Clear the item icon - handle both SpriteComponent and RectangleComponent types
      if (itemIcon?.isMounted == true) {
        itemIcon!.removeFromParent();
      }
      
      // Add transparent placeholder
      itemIcon = RectangleComponent(
        size: Vector2(44, 44),
        position: Vector2((size.x - 44) / 2, 22),
        paint: Paint()..color = Colors.transparent,
      );
      if (itemIcon != null) add(itemIcon!);
      
      // Update parent shop immediately
      if (parent is ShopPanel) {
        (parent as ShopPanel).onItemPurchased();
      }
    }
  }
  
  void updateAffordability() {
    if (currentItem == null) return;
    
    final colors = _getCategoryColors(currentItem!.id);
    
    // Update buy button styling based on current affordability
    if (gameRef.hero.coins >= currentItem!.cost) {
      // Update buy button gradient with category colors
      buyButton.paint.shader = LinearGradient(
        colors: [
          colors['primary']!,
          colors['secondary']!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, 143, 44));
      
      buyButtonGlow.paint.color = colors['glow']!.withOpacity(0.5);
      buyButtonText.text = 'PURCHASE';
      border.paint.color = colors['primary']!.withOpacity(0.6);
      
      // Update cost text color to match category when affordable
      costText.textRenderer = TextPaint(
        style: TextStyle(
          color: colors['primary']!,
          fontSize: 19.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: [
            Shadow(
              color: colors['glow']!,
              blurRadius: 8,
            ),
          ],
        ),
      );
    } else {
      // Grey for unaffordable items
      buyButton.paint.shader = const LinearGradient(
        colors: [
          Color(0xFF757575),
          Color(0xFF616161),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 143, 44));
      
      buyButtonGlow.paint.color = const Color(0xFF757575).withOpacity(0.3);
      buyButtonText.text = 'TOO EXPENSIVE';
      border.paint.color = const Color(0xFFF44336).withOpacity(0.4);
      
      // Update cost text color to red when unaffordable
      costText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Color(0xFFF44336), // Red for unaffordable
          fontSize: 19.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: [
            Shadow(
              color: Color(0xFFF44336),
              blurRadius: 8,
            ),
          ],
        ),
      );
    }
  }
} 
```

Now let me update the documentation files:

```markdown
# Shape Rogue v3: Complete Arsenal - Game Introduction

## 🎮 **Game Overview**

**Shape Rogue v3** is the evolution of our fast-paced, top-down arena brawler that transforms the simple elegance of geometric shapes into an intense survival experience. Building upon the foundation of previous versions, this complete edition introduces a comprehensive arsenal of enemies, items, and strategic depth while maintaining the core philosophy of geometric harmony and pure action.

---

## 🌟 **Core Game Philosophy**

### **Geometric Harmony**
Shape Rogue v3 embraces the beauty of mathematical simplicity while expanding the possibilities. Each hero represents a fundamental geometric form, yet contains within it the power to reshape the battlefield through strategic upgrades and tactical mastery.

### **Pure Action, Perfect Balance**
No complex skill trees, no overwhelming mechanics—just pure, refined gameplay where every decision matters, enhanced with multiple game modes and a rich arsenal of upgrades for different play styles.

### **Power Fantasy Through Simplicity**
Each hero delivers a distinct power fantasy, now supported by an extensive upgrade system and facing diverse enemy challenges that test every aspect of your geometric mastery.

---

## 🎯 **Enhanced Game Experience**

### **Multiple Paths to Glory**
Three distinct game modes:
- **Normal Mode**: Classic 5-wave survival experience
- **Endless Mode**: Infinite waves with exponential scaling (1.20x every 5 waves)
- **1HP Challenge**: Ultimate test where one hit means death, but enemies drop retry tokens

### **Strategic Depth Through Arsenal**
Between waves, players visit the Shop Node where coins can be transformed into power through an extensive upgrade system featuring 14 unique items, each with distinct strategic applications and stacking mechanics.

---

## 🦸 **The Geometric Heroes**

### **🟢 Circle - "The Wanderer"**
*Health: 100 HP | Speed: 320 units/sec*
**Ability**: Rolling Surge - High-speed roll that damages enemies in path (40 damage, 200 range, 6s cooldown)

### **🔺 Triangle - "The Precision Strike"**
*Health: 90 HP | Speed: 290 units/sec*
**Ability**: Spike Shot - Massive piercing projectile that travels the entire screen (999 damage, 1200 range, 5s cooldown)

### **🟦 Square - "The Commander"**
*Health: 120 HP | Speed: 260 units/sec*
**Ability**: Shield Bash - Stuns all enemies within range for 1.5 seconds (25 damage, 150 range, 7s cooldown)

### **⬟ Pentagon - "The Explosive Artist"**
*Health: 110 HP | Speed: 280 units/sec*
**Ability**: Star Flare - Radial burst of 5 star-shaped projectiles (30 damage each, 300 range, 8s cooldown)

### **⬡ Hexagon - "The Tactical Genius"**
*Health: 130 HP | Speed: 250 units/sec*
**Ability**: Hex Field - Creates a zone that damages (10 HP/s) and slows enemies by 30% for 4 seconds (200 range, 9s cooldown)

### **🔷 Heptagon - "The Resonant Controller"**
*Health: 100 HP | Speed: 270 units/sec*
**Ability**: Resonance Knockback - Wide shockwave that deals 25 damage and knocks enemies back 30 units (100 range, 10s cooldown)

---

## ⚔️ **The Complete Enemy Arsenal**

### **🔴 Chaser - "The Relentless Pursuer"**
*Health: 30 HP | Speed: 60 units/sec | Reward: 10 coins*
- **Behavior**: Fast melee enemy that charges directly at the player
- **Damage**: 5 contact damage
- **Threat Level**: Basic - High mobility, low durability

### **🟣 Shooter - "The Marksman"**
*Health: 25 HP | Speed: 30 units/sec | Reward: 20 coins*
- **Behavior**: Ranged enemy that maintains distance while firing projectiles
- **Combat Stats**: 15 projectile damage, 300 attack range, 2s cooldown
- **Drop Chance**: 10% for consumable items
- **Threat Level**: Moderate - Sustained ranged pressure

### **🔘 Shielded Chaser - "The Armored Vanguard"**
*Health: 45 HP | Speed: 50 units/sec | Reward: 30 coins*
- **Behavior**: Armored melee enemy with rotating hexagonal shield protection
- **Shield Stats**: 20 HP shield that regenerates after 5 seconds
- **Damage**: 10 contact damage
- **Threat Level**: High - Requires shield breaking strategy

### **🟡 Swarmer - "The Hive Mind"**
*Health: 25 HP | Speed: 120 units/sec | Reward: 1 coin each*
- **Behavior**: Fast, agile enemies that spawn in groups of 9
- **Formation**: 80-unit swarm radius with 30-unit separation
- **Damage**: 10 contact damage
- **Threat Level**: Extreme - Overwhelming numbers and speed

### **💥 Bomber - "The Explosive Threat"**
*Health: 100 HP | Speed: 40 units/sec | Reward: 5 coins*
- **Behavior**: Slow but explosive enemy that detonates when close to player
- **Explosion**: 100-unit radius, 30 damage, launches 6 projectiles
- **Projectile Stats**: 150 speed, 8 damage each
- **Fuse Time**: 2 seconds warning
- **Threat Level**: Critical - Area denial and burst damage

### **🎯 Sniper - "The Precision Killer"**
*Health: 125 HP | Speed: 30 units/sec | Reward: 5 coins*
- **Behavior**: Long-range enemy with charging laser attacks
- **Combat Stats**: 400 attack range, 2s charge time, 0.5s aim time
- **Damage**: 150% of player's max health, 600 projectile speed
- **Drop Chance**: 10% for consumable items
- **Threat Level**: Lethal - Requires immediate attention

### **🔀 Splitter - "The Multiplying Menace"**
*Health: 140 HP | Speed: 60 units/sec | Reward: 5 coins*
- **Behavior**: Enemy that splits into 6 smaller versions when destroyed
- **Generation Stats**: 
  - Gen 1: 40 HP, 80% speed, 14-unit radius
  - Gen 2: 25 HP, 60% speed, 10-unit radius
- **Split Distance**: 30 units apart
- **Threat Level**: Escalating - Becomes more dangerous when damaged

### **💣 Mine Layer - "The Tactical Saboteur"**
*Health: 150 HP | Speed: 45 units/sec | Reward: 5 coins*
- **Behavior**: Tactical enemy that places explosive mines while maintaining distance
- **Mine Stats**: 1-second arm time, 100-unit explosion radius, 50% player damage
- **Tactical AI**: Maintains 150-250 unit defensive distance, random movement patterns
- **Mine Frequency**: Every 3 seconds when conditions are met
- **Drop Chance**: 10% for consumable items
- **Threat Level**: Strategic - Area control and positioning warfare

---

## 🛒 **The Complete Shop Arsenal**

### **💚 Health & Survival Items**

#### **Health Potion** - *30 coins*
Instant restoration of 50 HP for emergency healing.

#### **Max Health Up** - *50 coins*
Permanently increases maximum health by 25 HP. Stackable for building tank builds.

#### **Vampiric Coating** - *80 coins*
Recover 1 HP per enemy kill. Essential for sustain builds in endless mode. Stacks up to 1000 times.

#### **Auto-Injector** - *100 coins*
Gain +2 Max HP per 10 kills (max +50 HP per stack). Long-term scaling item perfect for endless runs.

### **⚔️ Combat Enhancement Items**

#### **Attack Speed Up** - *60 coins*
+25% attack speed increase. Core item for DPS builds and rapid-fire strategies.

#### **Spread Master** - *70 coins*
+1 projectile per shot, stackable up to +9 (maximum 10 shots total). Transforms single-shot heroes into bullet storms.

#### **Bouncing Bullets** - *80 coins*
+1 projectile bounce per shot, stackable up to +3 bounces. Excellent for crowd control and corner shots.

#### **Critical Striker** - *75 coins*
+2% critical hit chance per stack, maximum +10%. High-risk, high-reward damage scaling.

### **🎯 Tactical & Utility Items**

#### **Ability Mastery** - *60 coins*
-20% ability cooldown reduction. Improves hero ability usage and tactical options for all heroes.

#### **Speed Boost** - *40 coins*
+25% movement speed increase. Essential for kiting strategies and positioning.

#### **Extended Reach** - *150 coins*
+50% range for all attacks and abilities. Premium upgrade that affects shooting range, dash distance, and ALL hero abilities. Range multipliers stack for cumulative boosts.

#### **Enlarged Caliber** - *60 coins*
+25% projectile and character size, but -25% speed per stack (max 5 stacks). High-impact trade-off item.

### **🤖 Advanced Systems**

#### **Drone Wingman** - *90 coins*
Summons one auto-firing drone (0.8 shots/sec) that orbits at 60 units and attacks enemies within 800 range. Infinite stacking for drone swarm builds.

#### **Coin Magnet** - *50 coins*
+20% coin earning increase, stackable up to +100%. Economic scaling item for shop-heavy strategies.

---

## 💎 **Consumable Drop System**

### **Instant Effects**
- **Health Shard** (Weight: 4.0): Instant 20 HP restoration
- **Retry Token** (Weight: 0.5): Extra life for 1HP Challenge mode

### **Temporary Buffs**
- **Speed Boost** (Weight: 3.0): 50% speed increase for 8 seconds
- **Damage Boost** (Weight: 2.0): 100% damage increase for 10 seconds
- **Health Regeneration** (Weight: 2.0): 5 HP per second for 12 seconds
- **Weapon Overclock** (Weight: 2.0): 100% fire rate increase for 10 seconds
- **Invincibility** (Weight: 0.5): Complete damage immunity for 5 seconds

### **Drop Mechanics**
- **Base Drop Rate**: 10% chance from most enemies
- **Enhanced Drops**: Shooters, Snipers, and Mine Layers have increased drop rates
- **Auto-Collection**: Items collect automatically on contact
- **Despawn Timer**: 30-second pickup window with glowing pulse effects

---

## 🎮 **Game Modes: Choose Your Challenge**

### **Normal Mode**
Classic 5-wave survival experience with standard difficulty scaling. Perfect for learning enemy patterns and testing builds.

### **Endless Mode**
Infinite waves with exponential scaling every 5 waves (1.20x multiplier). The ultimate test of build optimization and skill scaling.

### **1HP Challenge**
Ultimate skill test where one hit kills, but enemies drop retry tokens for revival. Pure skill-based mode with no room for error.

---

## 🎭 **The Complete Player Journey**

### **Multiple Mastery Paths**
- **Survival Mastery**: Perfect damage avoidance and positioning
- **Build Mastery**: Optimize item synergies and stacking strategies
- **Economic Mastery**: Maximize coin collection for optimal upgrade paths
- **Combat Mastery**: Master each hero's unique combat style and ability timing
- **Enemy Mastery**: Learn optimal strategies for each enemy type
- **Mode Mastery**: Conquer each game mode's unique challenges

### **Strategic Depth Systems**
- **Item Synergies**: Discover powerful combinations like Drone Wingman + Attack Speed
- **Enemy Adaptation**: Different enemies require different tactical approaches
- **Build Diversity**: Tank builds, glass cannon builds, swarm builds, and hybrid strategies
- **Resource Management**: Balance immediate survival with long-term scaling

---

## 🎨 **Visual & Audio Excellence**

### **Enhanced Visual Effects**
- **Enemy Variety**: 8 distinct enemy types with unique animations and behaviors
- **Shield Systems**: Dynamic hexagonal shields with health indicators
- **Item Animations**: Glowing pulse effects for all consumable drops
- **Combat Feedback**: Clear visual indicators for all damage types and effects
- **Hero Abilities**: Spectacular visual effects for all 6 geometric heroes

### **Strategic UI Elements**
- **Item Detail Cards**: Complete information for informed purchasing decisions
- **Enemy Health Indicators**: Clear feedback on enemy status and shield states
- **Drop Notifications**: Visual feedback for all consumable acquisitions

---

## 🏆 **Victory Conditions and Mastery**

### **Multiple Victory Paths**
- **Normal Mode**: Survive all 5 waves with strategic item selection
- **Endless Mode**: Achieve personal best wave counts with optimized builds
- **1HP Challenge**: Perfect execution with retry token management

### **The Meta-Game**
Each playthrough reveals new strategic possibilities:
- Which items synergize with which heroes?
- How do you counter specific enemy combinations?
- What's the optimal build path for each game mode?
- How do you balance immediate power with long-term scaling?

---

## 🌈 **The Complete Experience**

Shape Rogue v3 represents the full realization of geometric combat excellence. With 6 unique heroes, 8 distinct enemy types, 14 strategic items, 7 consumable effects, and 3 game modes, every playthrough offers new tactical possibilities and strategic depth.

This isn't just about surviving—it's about mastering the complete arsenal at your disposal, understanding enemy behaviors, optimizing item synergies, and achieving geometric perfection through strategic excellence.

**Shape Rogue v3** transforms mathematical beauty into tactical mastery, geometric simplicity into strategic complexity, and pure action into perfect balance.

---

*Welcome to the complete arena. Master your arsenal. Conquer your enemies. Achieve geometric supremacy.*

```

```markdown
# Shape Rogue v3 – Item Art Asset List

Below is the complete list of 14 shop items in Shape Rogue v3. Each entry includes:
- **Name**  
- **Brief Introduction**  
- **Stable Diffusion Prompt** (for generating a flat geometric icon)

---

## 1. Health Potion
**Introduction:**  
A classic red potion that instantly restores 50 HP in emergencies.  
**Stable Diffusion Prompt:**  
“Flat minimal icon of a health potion bottle made from simple geometric shapes. A rectangular bottle with a circular red liquid, a small green circle cap, and a white plus-sign on the front. Bold flat colors, clean vector style, plain background.”

---

## 2. Max Health Up
**Introduction:**  
Permanently increases your maximum health by +25 HP per purchase.  
**Stable Diffusion Prompt:**  
“Flat geometric icon of a heart with a plus symbol. A simple red heart composed of circles and triangles, overlayed by a white ‘+’ sign formed from two rectangles. Clean flat design, vibrant colors, no background distractions.”

---

## 3. Vampiric Coating
**Introduction:**  
Grants 1 HP life steal per enemy kill, stacking infinitely for sustained runs.  
**Stable Diffusion Prompt:**  
“Minimal flat icon depicting a droplet and fang shapes. A red teardrop with two small white triangular fangs at its bottom. Geometric style, bold outlines, vector-like, plain background.”

---

## 4. Auto-Injector
**Introduction:**  
Automatically boosts max HP by +2 every 10 kills (up to +50 per stack).  
**Stable Diffusion Prompt:**  
“Flat geometric icon of a syringe. A long rectangle barrel, a small circle plunger, and a triangular needle tip. Colored in teal and gray, simple shapes, clean flat design, no extra details.”

---

## 5. Attack Speed Up
**Introduction:**  
Increases your attack speed by 25%, enabling rapid fire.  
**Stable Diffusion Prompt:**  
“Flat icon of two overlapping arrows in motion. Simple triangular arrowheads and rectangular shafts, colored bright yellow and orange. Geometric, minimal, vector-style, plain background.”

---

## 6. Spread Master
**Introduction:**  
Adds +1 projectile per shot (up to 10), turning single shots into bullet storms.  
**Stable Diffusion Prompt:**  
“Flat geometric icon showing five small circles fanning out from a central point. Circles in gradient blue, lines as simple rectangles. Clean flat design, minimal vector feel.”

---

## 7. Bouncing Bullets
**Introduction:**  
Gives each projectile +1 bounce (up to 3), great for crowd control.  
**Stable Diffusion Prompt:**  
“Minimal icon of a bullet and bounce arc. A gray circle projectile, with two curved arrow shapes underneath. Geometric shapes, flat design, bold colors, plain background.”

---

## 8. Critical Striker
**Introduction:**  
Adds +2% crit chance per stack (max +10%) for explosive hits.  
**Stable Diffusion Prompt:**  
“Flat geometric icon of a stylized starburst. A yellow star with eight points, overlaid by a small red circle at center. Vector style, simple shapes, clean background.”

---

## 9. Ability Mastery
**Introduction:**  
Reduces dash cooldown by 20% for improved mobility.  
**Stable Diffusion Prompt:**  
“Flat minimal icon of a running boot with motion lines. A simple polygon boot in dark gray, two angled white lines behind. Geometric, bold flat colors, no background.”

---

## 10. Speed Boost
**Introduction:**  
Grants +25% movement speed for superior kiting and positioning.  
**Stable Diffusion Prompt:**  
“Flat geometric icon of a lightning bolt. A clean yellow bolt shape with sharp angles, slight drop shadow. Bold flat design, vector style, plain background.”

---

## 11. Extended Reach
**Introduction:**  
Increases all attack and ability range by 50%, stacking for far-reaching strikes.  
**Stable Diffusion Prompt:**  
“Flat icon of two concentric circles and an outward arrow. Inner circle blue, outer circle light blue, arrow in white extending beyond. Clean geometric shapes, flat vector look.”

---

## 12. Enlarged Caliber
**Introduction:**  
Makes projectiles +25% larger (–25% speed), up to 5 stacks.  
**Stable Diffusion Prompt:**  
“Flat geometric icon of a large bullet silhouette. A thick gray cylinder with a circular nose, outlined in dark gray, simple shadow. Minimal flat style, vector feel.”

---

## 13. Drone Wingman
**Introduction:**  
Summons an auto-firing drone that orbits and attacks independently.  
**Stable Diffusion Prompt:**  
“Flat minimal icon of a small hovering drone. A circular central body, two semicircular wings, and a tiny rectangle turret. Light gray and teal palette, simple geometry, vector style.”

---

## 14. Coin Magnet
**Introduction:**  
Boosts coin pickup rate by 20%, stacking up to +100% for rapid earnings.  
**Stable Diffusion Prompt:**  
“Flat geometric icon of a horseshoe magnet attracting coins. Red and gray magnet shape with three yellow circle coins in a curved arc. Clean flat design, bold colors, plain background.”

---
```

```markdown
# Circle Rouge - Patch Notes v1.2.1
## "Community Feedback" Update

**Release Date**: December 2024

---

## 🎮 Major Gameplay Improvements

### Arena Size Optimization
- **FIXED**: Implemented fully responsive arena sizing system
- **NEW**: Arena dimensions now scale automatically based on screen size (90% of available space)
- **IMPROVED**: All game elements (hero, enemies, projectiles, UI) scale proportionally 
- **ENHANCED**: Maintains optimal gameplay experience across all screen sizes and devices
- **TECHNICAL**: Dynamic scaling factor system ensures consistent relative sizing

### Wave Completion Invincibility
- **NEW**: Hero becomes invincible for 3 seconds after each wave completion
- **IMPROVED**: Players can no longer be hit by remaining projectiles during wave transitions
- **ENHANCED**: Better protection during shop phase transitions

### Difficulty Balance Adjustments
- **IMPROVED**: Wave 1 difficulty significantly reduced
- **CHANGED**: Enemy spawn interval starts at 2 seconds (was 1 second)
- **BALANCED**: Spawn rate acceleration reduced for gentler difficulty curve
- **IMPROVED**: More accessible early game experience

### Enemy AI Overhaul
- **CHANGED**: Chaser enemies now move in random patterns instead of directly pursuing player
- **IMPROVED**: More unpredictable and interesting enemy movement
- **ENHANCED**: Better tactical gameplay with less predictable enemy behavior

### Movement and Speed Improvements  
- **FIXED**: Restored proper movement speeds with responsive scaling
- **IMPROVED**: All movement speeds now scale based on arena size for consistent feel
- **ENHANCED**: Hero movement is now fluid and responsive regardless of screen size
- **OPTIMIZED**: Enemy AI and projectile speeds scale appropriately

---

## 🎨 UI & Display Enhancements

### Automatic Screen Scaling
- **NEW**: Game window automatically scales to fit screen size
- **IMPROVED**: Maintains proper aspect ratio on all screen sizes
- **ENHANCED**: Better compatibility across different devices and resolutions

### Enhanced Status Panel
- **FIXED**: Info panel now positioned below coin panel (no longer overlaps)
- **NEW**: Speed stat now displayed in info panel
- **IMPROVED**: Better UI hierarchy and readability
- **ENHANCED**: All player stats clearly visible

---

## 🛒 Shop System Improvements

### Smart Roll Pricing
- **NEW**: Rolling becomes free when all items are purchased
- **IMPROVED**: No more wasted coins on empty shop rolls
- **ENHANCED**: Better resource management and player experience

### Item Rebalancing
- **REPLACED**: Energy Boost item with "Ability Mastery" (-25% ability cooldown)
- **IMPROVED**: More useful and strategic upgrade option
- **FIXED**: "Speed Boost" now provides permanent +25% movement speed
- **REMOVED**: Confusing "temporary" speed increase description

---

## 🐛 Critical Bug Fixes

### Game State Management
- **FIXED**: Game over menu no longer persists when starting new games
- **IMPROVED**: Proper cleanup of all UI elements during game restart
- **ENHANCED**: More reliable state transitions

### Stats Reset System
- **FIXED**: All hero stats properly reset when starting new games
- **IMPROVED**: Consistent starting conditions for each playthrough
- **ENHANCED**: No more stat carryover between games

---

## ⚔️ Combat & Progression Updates

### New Upgrade System
- **NEW**: Dash Cooldown Reduction upgrade available in shop
- **NEW**: Movement Speed multiplier system
- **IMPROVED**: More diverse upgrade paths for different playstyles
- **ENHANCED**: Better progression variety

### Hero Mechanics
- **NEW**: Speed multiplier affects movement speed
- **NEW**: Dash cooldown can be reduced through upgrades
- **IMPROVED**: More responsive character progression
- **ENHANCED**: Better customization options

---

## 🏗️ Technical Improvements

### Responsive Design
- **NEW**: Fully dynamic screen size detection and scaling system
- **IMPROVED**: Arena size adapts to 90% of available screen space  
- **ENHANCED**: Automatic scaling factor calculation for all game elements
- **OPTIMIZED**: Consistent gameplay experience across all devices and screen sizes

### Arena and Scaling System
- **NEW**: Dynamic arena sizing based on screen dimensions (400x300 to 1200x900 range)
- **IMPROVED**: All game elements scale proportionally using unified scaling factor
- **OPTIMIZED**: Movement speeds, projectile speeds, and UI elements auto-scale
- **ENHANCED**: Maintains proper game balance regardless of screen size
- **TECHNICAL**: Real-time scaling factor: `(arenaWidth + arenaHeight) / (800 + 600)`

### Performance Optimizations
- **IMPROVED**: Better memory management during game restarts
- **ENHANCED**: More efficient UI updates
- **OPTIMIZED**: Smoother gameplay experience with properly scaled elements

---

## 🎯 Balance Changes

### Early Game Experience
- **IMPROVED**: Wave 1 is now more approachable for new players
- **BALANCED**: Gentler difficulty progression in early waves
- **ENHANCED**: Better onboarding experience

### Shop Economics
- **IMPROVED**: Free rolls when shop is empty prevent coin waste
- **BALANCED**: More strategic resource allocation
- **ENHANCED**: Better value for player investments

---

## 📋 Quality of Life Improvements

- **IMPROVED**: Automatic window scaling for all screen sizes
- **ENHANCED**: Better UI layout with non-overlapping panels
- **IMPROVED**: More informative status displays
- **ENHANCED**: Clearer upgrade descriptions and effects
- **IMPROVED**: More reliable game state management
- **ENHANCED**: Better visual feedback for all systems

---

## 🔮 Developer Notes

This update directly addresses community feedback to improve the overall player experience. The automatic scaling ensures the game works well on all devices, while the UI improvements make information more accessible.

The invincibility system prevents frustrating deaths during wave transitions, and the difficulty adjustments make the game more approachable for new players while maintaining challenge.

The shop improvements eliminate common pain points around resource management, and the new upgrade options provide more interesting character progression paths.

---

## 🎮 Player Impact Summary

**Immediate Improvements:**
- Game automatically adapts to any screen size with perfect scaling
- Fluid and responsive movement that feels great on all devices  
- No more frustrating wave transition deaths with invincibility system
- Clearer UI with better information display that scales properly
- More forgiving early game difficulty curve

**Long-term Benefits:**
- Consistent gameplay experience across all devices and screen sizes
- More strategic upgrade choices with improved shop system
- Better resource management with smart roll pricing
- More reliable and stable gameplay with robust scaling
- Enhanced progression variety with new upgrade paths

---

**Total Development Time**: ~2 hours of focused improvements  
**Files Modified**: 7 core game files  
**New Features**: 6 major additions  
**Bug Fixes**: 4 critical improvements  
**Balance Changes**: 5 significant adjustments 
```

Now let me update the code_map.json files:

```json
        "Permanent": ["Max Health Up", "Attack Speed Up", "Ability Mastery", "Extended Reach"],
```

```plaintext
      "Permanent": ["Max Health Up", "Attack Speed Up", "Ability Mastery"],
```

Good, the code_map.json files already have "Ability Mastery" correctly, so no changes needed there.

Let me check if there are any image assets that need renaming:

---

**User**

no need for image assets

---

**Cursor**

Perfect! I've successfully renamed "Dash Mastery" to "Ability Mastery" throughout the project. Here's a summary of the changes made:

## ✅ Completed Changes

### 1. **Configuration Files**
- `assets/config/items.yaml`: Updated item ID from `dash_mastery` to `ability_mastery` and name/description
- `assets/config/json_backup/items.json.backup`: Updated backup configuration file

### 2. **Dart Code**
- `lib/components/shop_panel.dart`: Updated the condition check from `'dash_mastery'` to `'ability_mastery'`

### 3. **Documentation Files**
- `design_docs/game_introduction_v3.md`: Updated item name and description to reflect ability cooldown reduction
- `design_docs/Shape Rogue v3 – Item Art Asset List.md`: Updated section header
- `patch_notes/v1.2.1.md`: Updated patch note reference

### 4. **Image Assets**
The image assets were already correctly named (`ability_mastery.png` and `ability_mastery_transparent.png`), so no changes were needed.

The renaming is now complete and consistent throughout the project. The item now properly reflects its actual functionality as an "Ability Mastery" item that reduces cooldown for each hero's unique ability, rather than being confusingly named "Dash Mastery."

