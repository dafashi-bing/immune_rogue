# Replace text with golden coin
_Exported on 9/26/2025 at 22:14:25 PDT from Cursor (1.6.45)_

---

**User**

Let's replace "XXX COINS"'s "COINS" into a golden coin, either an emoji or just a gold shining circle would work

---

**Cursor**

I'll look for where "COINS" is rendered in the UI so I can replace it with a coin symbol or emoji.

I'll create a short todo list for the UI text changes and start by updating the three places where "COINS" is rendered. Then I'll read those files and implement the edits.

I'll open the three files where "COINS" text is set to confirm the exact code around those lines, then update stats overlay first.

I'll update the stats overlay coin text first. Then I'll check for linter issues and proceed to the item detail card and shop panel edits.

```dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/circle_rouge_game.dart';
import '../config/display_config.dart';
import '../config/wave_config.dart';
import '../config/game_mode_config.dart';

class StatsOverlay extends PositionComponent with HasGameRef<CircleRougeGame> {
  late TextComponent coinCounter;
  
  // Main stats panel
  late RectangleComponent mainPanel;
  late RectangleComponent panelBorder;
  late RectangleComponent panelGlow;
  
  // Stats text components
  late TextComponent heroNameText;
  late TextComponent healthStatsText;
  late TextComponent combatStatsText;
  late TextComponent waveInfoText;
  late TextComponent activeEffectText;
  late TextComponent passiveEffectText;
  
  late TextComponent instructionText;
  
  bool isVisible = false;
  
  static const double margin = 20.0;
  
  // Dynamic sizing properties
  double currentPanelWidth = 0.0;
  double currentPanelHeight = 0.0;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Set high priority to ensure this overlay renders on top
    priority = 1000;
    
    // Coin counter with enhanced styling
    coinCounter = TextComponent(
      text: '0 🪙',
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFFFFD700),
          fontSize: 20.0 * DisplayConfig.instance.scaleFactor,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          shadows: const [
            Shadow(
              color: Color(0xFFFF8F00),
              blurRadius: 12,
            ),
            Shadow(
              color: Color(0xFFFFD700),
              blurRadius: 6,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 3,
            ),
          ],
        ),
      ),
      anchor: Anchor.topRight,
      position: Vector2(DisplayConfig.instance.arenaWidth - margin, margin),
    );
    add(coinCounter);
    
    // Main panel dimensions - will be calculated dynamically
    final basePanelWidth = 200.0 * DisplayConfig.instance.scaleFactor;
    final basePanelHeight = 280.0 * DisplayConfig.instance.scaleFactor;
    currentPanelWidth = basePanelWidth;
    currentPanelHeight = basePanelHeight;
    final panelX = DisplayConfig.instance.arenaWidth - margin - currentPanelWidth;
    final panelY = margin + 35 * DisplayConfig.instance.scaleFactor;
    
    // Panel glow (outermost)
    panelGlow = RectangleComponent(
      size: Vector2(currentPanelWidth + 8, currentPanelHeight + 8),
      paint: Paint()
        ..color = const Color(0xFF4A9EFF).withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      position: Vector2(panelX - 4, panelY - 4),
    );
    add(panelGlow);
    
    // Main panel background
    mainPanel = RectangleComponent(
      size: Vector2(currentPanelWidth, currentPanelHeight),
      paint: Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0x90000000),
            const Color(0xA0101010),
            const Color(0x90000000),
          ],
        ).createShader(Rect.fromLTWH(0, 0, currentPanelWidth, currentPanelHeight)),
      position: Vector2(panelX, panelY),
    );
    add(mainPanel);
    
    // Panel border with animated gradient
    panelBorder = RectangleComponent(
      size: Vector2(currentPanelWidth, currentPanelHeight),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF4A9EFF),
            const Color(0xFF9C27B0),
            const Color(0xFF4A9EFF),
          ],
        ).createShader(Rect.fromLTWH(0, 0, currentPanelWidth, currentPanelHeight)),
      position: Vector2(panelX, panelY),
    );
    add(panelBorder);
    
    // Hero name text
    heroNameText = TextComponent(
      text: 'CIRCLE HERO',
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF4A9EFF),
          fontSize: 14.0 * DisplayConfig.instance.scaleFactor,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: const [
            Shadow(
              color: Color(0xFF4A9EFF),
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
      position: Vector2(panelX + currentPanelWidth / 2, panelY + 12 * DisplayConfig.instance.scaleFactor),
    );
    add(heroNameText);
    
    // Health stats text
    healthStatsText = TextComponent(
      text: '100/100 HP | Ability Ready',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.0 * DisplayConfig.instance.scaleFactor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 3,
            ),
            Shadow(
              color: Color(0xFF4A9EFF),
              blurRadius: 1,
            ),
          ],
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(panelX + 12, panelY + 35 * DisplayConfig.instance.scaleFactor),
    );
    add(healthStatsText);
    
    // Combat stats text
    combatStatsText = TextComponent(
      text: '''ATK: 100%    SPD: 100%
RNG: 100%    ABL: 0%''',
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFFFFC107),
          fontSize: 11.0 * DisplayConfig.instance.scaleFactor,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 0.5,
          shadows: const [
            Shadow(
              color: Color(0xFFFF8F00),
              blurRadius: 4,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(panelX + 12, panelY + 55 * DisplayConfig.instance.scaleFactor),
    );
    add(combatStatsText);
    
    // Wave information text
    waveInfoText = TextComponent(
      text: '''WAVE 1/5
Enemies: C+S+SC
Spawn: 2.0s''',
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF9C27B0),
          fontSize: 10.0 * DisplayConfig.instance.scaleFactor,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 0.5,
          shadows: const [
            Shadow(
              color: Color(0xFF9C27B0),
              blurRadius: 6,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(panelX + 12, panelY + 95 * DisplayConfig.instance.scaleFactor),
    );
    add(waveInfoText);
    
    // Active effect text
    activeEffectText = TextComponent(
      text: '''ACTIVE EFFECT
None''',
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF4CAF50),
          fontSize: 10.0 * DisplayConfig.instance.scaleFactor,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 0.5,
          shadows: const [
            Shadow(
              color: Color(0xFF4CAF50),
              blurRadius: 6,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(panelX + 12, panelY + 135 * DisplayConfig.instance.scaleFactor),
    );
    add(activeEffectText);
    
    // Passive effects text
    passiveEffectText = TextComponent(
      text: '''PASSIVE EFFECTS
None''',
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF9C27B0),
          fontSize: 10.0 * DisplayConfig.instance.scaleFactor,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 0.5,
          shadows: const [
            Shadow(
              color: Color(0xFF9C27B0),
              blurRadius: 6,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(panelX + 12, panelY + 185 * DisplayConfig.instance.scaleFactor),
    );
    add(passiveEffectText);
    
    // Instruction text for toggling stats
    instructionText = TextComponent(
      text: 'Press [I] to toggle',
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFFAAAAAA),
          fontSize: 8.0 * DisplayConfig.instance.scaleFactor,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 3,
            ),
            Shadow(
              color: Color(0xFF4A9EFF),
              blurRadius: 1,
            ),
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(panelX + currentPanelWidth / 2, panelY + currentPanelHeight + 8),
    );
    add(instructionText);
    
    // Initially hidden
    hide();
  }
  
  void show() {
    isVisible = true;
    // Show all components except coin counter (which should always be visible)
    for (final child in children) {
      if (child is PositionComponent && child != coinCounter) {
        child.scale = Vector2.all(1.0);
      }
    }
    // Ensure coin counter is always visible
    coinCounter.scale = Vector2.all(1.0);
    updateStats();
  }
  
  void hide() {
    isVisible = false;
    // Hide all child components except coin counter
    for (final child in children) {
      if (child is PositionComponent && child != coinCounter) {
        child.scale = Vector2.all(0.0);
      }
    }
    // Keep coin counter visible
    coinCounter.scale = Vector2.all(1.0);
  }
  
  void updateCoins(int coins) {
    coinCounter.text = '$coins 🪙';
  }
  
  void _recalculatePanelSize() {
    // Calculate required width and height based on content
    final baseWidth = 200.0 * DisplayConfig.instance.scaleFactor;
    final baseHeight = 280.0 * DisplayConfig.instance.scaleFactor;
    
    // Get content lengths to estimate size
    final hero = gameRef.hero;
    
    // Count passive effects to determine height
    int passiveEffectCount = 0;
    final passiveStacks = hero.passiveEffectStacks;
    for (final entry in passiveStacks.entries) {
      if (entry.value > 0) {
        passiveEffectCount++;
      }
    }
    
    // Calculate height based on content
    // Base sections: hero name, health, combat stats, wave info, active effect header = ~120px
    // Each passive effect adds ~15px
    // Minimum padding = 40px
    final estimatedHeight = (120 + (passiveEffectCount * 15) + 40) * DisplayConfig.instance.scaleFactor;
    
    // Use larger of base height or estimated height, with reasonable limits
    currentPanelHeight = estimatedHeight.clamp(baseHeight, baseHeight * 1.8);
    
    // Width can expand slightly based on longest text line
    // For now, keep it fixed but could be enhanced to measure actual text width
    currentPanelWidth = baseWidth;
    
    // Update panel components with new size
    _updatePanelSize();
  }
  
  void _updatePanelSize() {
    final panelX = DisplayConfig.instance.arenaWidth - margin - currentPanelWidth;
    final panelY = margin + 35 * DisplayConfig.instance.scaleFactor;
    
    // Update panel glow
    panelGlow.size = Vector2(currentPanelWidth + 8, currentPanelHeight + 8);
    panelGlow.position = Vector2(panelX - 4, panelY - 4);
    
    // Update main panel
    mainPanel.size = Vector2(currentPanelWidth, currentPanelHeight);
    mainPanel.position = Vector2(panelX, panelY);
    mainPanel.paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0x90000000),
          const Color(0xA0101010),
          const Color(0x90000000),
        ],
      ).createShader(Rect.fromLTWH(0, 0, currentPanelWidth, currentPanelHeight));
    
    // Update panel border
    panelBorder.size = Vector2(currentPanelWidth, currentPanelHeight);
    panelBorder.position = Vector2(panelX, panelY);
    panelBorder.paint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF4A9EFF),
          const Color(0xFF9C27B0),
          const Color(0xFF4A9EFF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, currentPanelWidth, currentPanelHeight));
    
    // Update hero name text position
    heroNameText.position = Vector2(panelX + currentPanelWidth / 2, panelY + 12 * DisplayConfig.instance.scaleFactor);
    
    // Update instruction text position (at bottom of panel)
    instructionText.position = Vector2(panelX + currentPanelWidth / 2, panelY + currentPanelHeight + 8);
  }

  void updateStats() {
    if (!isVisible) return;
    
    // Recalculate panel size first
    _recalculatePanelSize();
    
    final hero = gameRef.hero;
    final game = gameRef;
    
    // Update coins
    updateCoins(hero.coins);
    
    // Update hero name with current hero
    heroNameText.text = '${hero.heroData.name.toUpperCase()} HERO';
    
    // Update hero name color to match hero color
    final heroColor = hero.heroData.color;
    heroNameText.textRenderer = TextPaint(
      style: TextStyle(
        color: heroColor,
        fontSize: 14.0 * DisplayConfig.instance.scaleFactor,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        shadows: [
          Shadow(
            color: heroColor.withOpacity(0.8),
            blurRadius: 8,
          ),
          Shadow(
            color: Colors.black,
            blurRadius: 4,
          ),
        ],
      ),
    );
    
    // Health and ability status
    final healthText = '${hero.health.round()}/${hero.maxHealth.round()}';
    
    // Calculate ability status
    final baseCooldown = hero.heroData.ability.cooldown;
    final effectiveCooldown = baseCooldown * hero.abilityCooldownMultiplier;
    final timeSinceLastAbility = (DateTime.now().millisecondsSinceEpoch / 1000.0) - (hero.lastAbilityTime == -double.infinity ? 0 : hero.lastAbilityTime);
    final abilityProgress = (timeSinceLastAbility / effectiveCooldown).clamp(0.0, 1.0);
    
    String abilityStatus;
    if (abilityProgress >= 1.0) {
      abilityStatus = 'Ability Ready';
    } else {
      final remainingTime = effectiveCooldown - timeSinceLastAbility;
      abilityStatus = 'Ability: ${remainingTime.toStringAsFixed(1)}s';
    }
    
    healthStatsText.text = '$healthText HP | $abilityStatus';
    
    // Combat stats
    final attackText = '${(hero.attackSpeedMultiplier * 100).round()}%';
    final speedText = '${(hero.speedMultiplier * 100).round()}%';
    final rangeText = '${(hero.rangeMultiplier * 100).round()}%';
    final reductionPercent = ((baseCooldown - effectiveCooldown) / baseCooldown * 100).round();
    final abilityReductionText = reductionPercent > 0 ? '-${reductionPercent}%' : '0%';
    
    combatStatsText.text = '''ATK: $attackText    SPD: $speedText
RNG: $rangeText    ABL: $abilityReductionText''';
    
    // Wave information
    final currentWaveData = game.currentGameMode == GameMode.endless && game.currentWave > 5
        ? WaveConfig.instance.getWaveData(5) // Use wave 5 data for endless 6+
        : WaveConfig.instance.getWaveData(game.currentWave);
    
    String waveInfo;
    if (game.currentGameMode.name == 'endless') {
      waveInfo = 'WAVE ${game.currentWave} (∞)';
    } else {
      waveInfo = 'WAVE ${game.currentWave}/${game.maxWaves}';
    }
    
    // Enemy types information
    String enemyTypesText = '';
    if (currentWaveData != null) {
      final enemyTypes = currentWaveData.enemyTypes.map((type) {
        switch (type) {
          case 'chaser': return 'C';
          case 'shooter': return 'S';
          case 'shielded_chaser': return 'SC';
          case 'swarmer': return 'SW';
          case 'bomber': return 'B';
          case 'sniper': return 'SN';
          case 'splitter': return 'SP';
          case 'mine_layer': return 'ML';
          default: return type.substring(0, 1).toUpperCase();
        }
      }).join('+');
      enemyTypesText = enemyTypes;
    }
    
    final spawnInterval = game.enemySpawnInterval;
    final spawnIntervalText = '${spawnInterval.toStringAsFixed(1)}s';
    
    waveInfoText.text = '''$waveInfo
Enemies: $enemyTypesText
Spawn: $spawnIntervalText''';

    // Active effect display
    final activeEffectDisplay = hero.activeEffectDisplay;
    final activeEffect = hero.currentActiveEffect;
    
    // Change color based on effect type
    Color effectColor = const Color(0xFF4CAF50); // Default green
    if (activeEffect != null) {
      switch (activeEffect.type) {
        case 'speed_boost':
          effectColor = const Color(0xFF2196F3); // Blue
          break;
        case 'damage_boost':
          effectColor = const Color(0xFFF44336); // Red
          break;
        case 'health_regen':
          effectColor = const Color(0xFF4CAF50); // Green
          break;
        case 'shield':
          effectColor = const Color(0xFFFF9800); // Orange
          break;
        case 'invincibility':
          effectColor = const Color(0xFF9C27B0); // Purple
          break;
        case 'weapon_overclock':
          effectColor = const Color(0xFFFF8C00); // Orange
          break;
      }
    }
    
    // Update text color
    activeEffectText.textRenderer = TextPaint(
      style: TextStyle(
        color: effectColor,
        fontSize: 10.0 * DisplayConfig.instance.scaleFactor,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: effectColor,
            blurRadius: 6,
          ),
          const Shadow(
            color: Colors.black,
            blurRadius: 2,
          ),
        ],
      ),
    );
    
    activeEffectText.text = '''ACTIVE EFFECT
$activeEffectDisplay''';

    // Passive effects display
    List<String> passiveEffects = [];
    
    // Check all passive effect types and their stacks
    final passiveStacks = hero.passiveEffectStacks;
    if (passiveStacks.isNotEmpty) {
      for (final entry in passiveStacks.entries) {
        final effectType = entry.key;
        final stacks = entry.value;
        if (stacks > 0) {
          String itemName = _getItemNameByEffectType(effectType);
          passiveEffects.add('$itemName x$stacks');
        }
      }
    }
    
    String passiveEffectDisplay = passiveEffects.isEmpty ? 'None' : passiveEffects.join('\n');
    passiveEffectText.text = '''PASSIVE EFFECTS
$passiveEffectDisplay''';
  }
  
  String _getItemNameByEffectType(String effectType) {
    // Map effect types to actual item names
    switch (effectType) {
      case 'projectile_count': return 'Spread Master';
      case 'projectile_bounces': return 'Bouncing Bullets';
      case 'projectile_size': return 'Enlarged Caliber';
      case 'drone_count': return 'Drone Wingman';
      case 'life_steal': return 'Vampiric Coating';
      case 'shield_hp': return 'Armor Plating';
      case 'coin_multiplier': return 'Coin Magnet';
      case 'heal_per_kill': return 'Heal/Kill';
      case 'crit_chance': return 'Critical Striker';
      case 'clone_spawn': return 'Clone Projection';
      case 'max_health_boost': return 'Auto-Injector';
      default: return effectType;
    }
  }
  
  
  /// Rebuild the stats overlay layout when screen size changes
  void rebuildLayout() {
    // Clear existing components
    removeAll(children);
    
    // Reload the overlay with new dimensions
    onLoad();
    
    // Restore visibility state
    if (isVisible) {
      show();
    } else {
      hide();
    }
  }
} 
```

```dart
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

```

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
  static const double baseSlotHeight = 320.0;
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
      position: Vector2(size.x / 2, 115.5),
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
    // add(descriptionText);
    
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
      position: Vector2(size.x / 2, 192.5),
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
      position: Vector2((size.x - 143) / 2, size.y - 60),
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
      position: Vector2((size.x - 143) / 2, size.y - 60),
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
    costText.text = '${item.cost} 🪙';
    
    // Replace the current icon with a sprite-based icon
    if (itemIcon?.isMounted == true) {
      itemIcon!.removeFromParent();
    }

    final itemIconSize = 66.0;
    
    try {
      // Try to load the actual item icon sprite
      final sprite = await Sprite.load(item.icon);
      itemIcon = SpriteComponent(
        sprite: sprite,
        size: Vector2(itemIconSize, itemIconSize),
        position: Vector2((size.x - itemIconSize) / 2, itemIconSize / 2),
        anchor: Anchor.topLeft,
      );
    } catch (e) {
      print('Could not load item icon: ${item.icon}, using colored rectangle fallback');
      // Fallback to colored rectangle with category color
      itemIcon = RectangleComponent(
        size: Vector2(itemIconSize, itemIconSize),
        position: Vector2((size.x - itemIconSize) / 2, itemIconSize / 2),
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
      border.paint.color = colors['primary']!.withOpacity(0.6);
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
      // descriptionText.text = 'Item purchased successfully!';
      // descriptionText.textRenderer = TextPaint(
      //   style: const TextStyle(
      //     color: Color(0xFF4CAF50),
      //     fontSize: 13.2,
      //     fontWeight: FontWeight.w500,
      //     height: 1.4,
      //   ),
      // );
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
        size: Vector2(66, 66),
        position: Vector2((size.x - 66) / 2, 33),
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
      border.paint.color = colors['primary']!.withOpacity(0.6);
      
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

I replaced the visible "COINS" labels with a gold coin emoji.

- Updated `stats_overlay.dart` coin counter from "0 COINS" to "0 🪙" and dynamic updates to use "🪙".
- Updated `item_detail_card.dart` cost text to show "<cost> 🪙".
- Updated `shop_panel.dart` item slot cost text to show "<cost> 🪙".
- Lints on changed files are clean.

Please build and test to confirm the emoji renders well on your target platforms. If you prefer a simple gold circle instead of the emoji, I can swap to "●" and rely on the existing gold styling.

- I finished replacing the coin label in the overlay, item detail card, and shop panel.

---

**User**

ok not bad. let's also add this after the cost of REROLL. Also I found that the reroll cost got reset after every wave, this is not correct. It should only get reset after a full game. 

---

**Cursor**

I'll locate where the reroll button text is set to add the coin emoji, and find where the reroll count gets reset each wave so I can change it to only reset on full game restarts. Then I'll implement both edits.

I'll open the relevant area in `circle_rouge_game.dart` to find all calls to reset the roll count and then implement changes to stop resetting per wave. In parallel, I'll update the REROLL button labels to include the coin emoji in all numeric-cost cases and run lints.

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
  static const double baseSlotHeight = 320.0;
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
      text: 'REROLL (10 🪙)',
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
    rollButtonText.text = 'REROLL ($nextRollCost 🪙)';
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
      position: Vector2(size.x / 2, 115.5),
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
    // add(descriptionText);
    
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
      position: Vector2(size.x / 2, 192.5),
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
      position: Vector2((size.x - 143) / 2, size.y - 60),
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
      position: Vector2((size.x - 143) / 2, size.y - 60),
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
    costText.text = '${item.cost} 🪙';
    
    // Replace the current icon with a sprite-based icon
    if (itemIcon?.isMounted == true) {
      itemIcon!.removeFromParent();
    }

    final itemIconSize = 66.0;
    
    try {
      // Try to load the actual item icon sprite
      final sprite = await Sprite.load(item.icon);
      itemIcon = SpriteComponent(
        sprite: sprite,
        size: Vector2(itemIconSize, itemIconSize),
        position: Vector2((size.x - itemIconSize) / 2, itemIconSize / 2),
        anchor: Anchor.topLeft,
      );
    } catch (e) {
      print('Could not load item icon: ${item.icon}, using colored rectangle fallback');
      // Fallback to colored rectangle with category color
      itemIcon = RectangleComponent(
        size: Vector2(itemIconSize, itemIconSize),
        position: Vector2((size.x - itemIconSize) / 2, itemIconSize / 2),
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
      border.paint.color = colors['primary']!.withOpacity(0.6);
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
      // descriptionText.text = 'Item purchased successfully!';
      // descriptionText.textRenderer = TextPaint(
      //   style: const TextStyle(
      //     color: Color(0xFF4CAF50),
      //     fontSize: 13.2,
      //     fontWeight: FontWeight.w500,
      //     height: 1.4,
      //   ),
      // );
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
        size: Vector2(66, 66),
        position: Vector2((size.x - 66) / 2, 33),
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
      border.paint.color = colors['primary']!.withOpacity(0.6);
      
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

I'll update the REROLL button to show the coin emoji next to numeric costs, and stop resetting the roll count between waves by removing the wave-based reset call. Then I'll lint the changed files.

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
  static const double baseSlotHeight = 320.0;
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
      text: 'REROLL (10 🪙)',
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
    rollButtonText.text = 'REROLL ($nextRollCost 🪙)';
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
    rollButtonText.text = rollCost == 0 ? 'REROLL (FREE)' : 'REROLL ($rollCost 🪙)';
    
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
      position: Vector2(size.x / 2, 115.5),
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
    // add(descriptionText);
    
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
      position: Vector2(size.x / 2, 192.5),
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
      position: Vector2((size.x - 143) / 2, size.y - 60),
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
      position: Vector2((size.x - 143) / 2, size.y - 60),
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
    costText.text = '${item.cost} 🪙';
    
    // Replace the current icon with a sprite-based icon
    if (itemIcon?.isMounted == true) {
      itemIcon!.removeFromParent();
    }

    final itemIconSize = 66.0;
    
    try {
      // Try to load the actual item icon sprite
      final sprite = await Sprite.load(item.icon);
      itemIcon = SpriteComponent(
        sprite: sprite,
        size: Vector2(itemIconSize, itemIconSize),
        position: Vector2((size.x - itemIconSize) / 2, itemIconSize / 2),
        anchor: Anchor.topLeft,
      );
    } catch (e) {
      print('Could not load item icon: ${item.icon}, using colored rectangle fallback');
      // Fallback to colored rectangle with category color
      itemIcon = RectangleComponent(
        size: Vector2(itemIconSize, itemIconSize),
        position: Vector2((size.x - itemIconSize) / 2, itemIconSize / 2),
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
      border.paint.color = colors['primary']!.withOpacity(0.6);
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
      // descriptionText.text = 'Item purchased successfully!';
      // descriptionText.textRenderer = TextPaint(
      //   style: const TextStyle(
      //     color: Color(0xFF4CAF50),
      //     fontSize: 13.2,
      //     fontWeight: FontWeight.w500,
      //     height: 1.4,
      //   ),
      // );
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
        size: Vector2(66, 66),
        position: Vector2((size.x - 66) / 2, 33),
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
      border.paint.color = colors['primary']!.withOpacity(0.6);
      
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

```dart
import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Hero;

import '../components/hero.dart';
import '../components/enemies/enemy_chaser.dart';
import '../components/enemies/enemy_shooter.dart';
import '../components/enemies/shielded_chaser.dart';
import '../components/enemies/swarmer.dart';
import '../components/enemies/bomber.dart';
import '../components/enemies/sniper.dart';
import '../components/enemies/splitter.dart';
import '../components/enemies/mine_layer.dart';
import '../components/hud.dart';
import '../components/shop_panel.dart';
import '../components/stats_overlay.dart';
import '../components/sound_manager.dart';
import '../components/wave_announcement.dart';
// Removed wave_timer.dart - now using wave_announcement.dart instead
import '../components/consumable_drop_manager.dart';
import '../config/item_config.dart';
import '../config/wave_config.dart';
import '../config/hero_config.dart';
import '../config/game_mode_config.dart';
import '../config/display_config.dart';
import '../config/enemy_config.dart';

enum GameState { startMenu, gameModeSelection, heroSelection, playing, shopping, gameOver, victory, paused }

class CircleRougeGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Hero hero;
  late HudComponent hud;
  late ShopPanel shopPanel;
  late StatsOverlay statsOverlay;
  late SpriteComponent backgroundArena; // Reference to background
  late WaveAnnouncement waveAnnouncement;
  // WaveTimer removed - now using WaveAnnouncement instead
  late ConsumableDropManager consumableDropManager;
  
  GameState gameState = GameState.startMenu;
  
  // Game Mode System
  GameMode currentGameMode = GameMode.normal;
  GameModeData? currentGameModeData;
  int retryTokens = 0;
  
  int currentWave = 1;
  int get maxWaves {
    if (currentGameModeData != null && currentGameModeData!.maxWaves != -1) {
      return currentGameModeData!.maxWaves;
    }
    return WaveConfig.instance.settings?.maxWaves ?? 5;
  }
  List<Component> currentEnemies = [];
  List<Component> currentProjectiles = [];
  
  // Time-based wave system - values from config
  double waveTime = 0.0;
  double get waveDuration => WaveConfig.instance.settings?.effectiveWaveDuration ?? 30.0;
  double enemySpawnTimer = 0.0;
  double enemySpawnInterval = 2.0; // Will be calculated dynamically
  
  // Arena bounds - now using display config
  double get arenaWidth => DisplayConfig.instance.arenaWidth;
  double get arenaHeight => DisplayConfig.instance.arenaHeight;
  double get safeAreaMargin => DisplayConfig.instance.safeAreaMargin;
  
  // Scaling factor based on display config
  double get scaleFactor => DisplayConfig.instance.scaleFactor;
  
  String selectedHeroId = 'circle'; // Default hero selection
  
  // Game over flag to prevent multiple sounds
  bool gameOverSoundPlayed = false;
  
  // Track what killed the hero for customized Game Over messaging
  String? lastKillerType; // e.g., 'chaser', 'shooter', 'sniper', 'bomber', 'mine_layer', etc.
  
  // Wave completion flag to prevent multiple calls
  bool waveCompletionInProgress = false;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Load configurations first
    await DisplayConfig.instance.loadConfig();
    
    // Create arena background with background image
    try {
      final backgroundSprite = await Sprite.load('background1.png');
      backgroundArena = SpriteComponent(
        sprite: backgroundSprite,
        size: Vector2(arenaWidth, arenaHeight),
        position: Vector2(arenaWidth / 2, arenaHeight / 2),
        anchor: Anchor.center, // Center the background
      );
      add(backgroundArena);
    } catch (e) {
      print('Could not load background image: $e');
      // Create a simple colored background as fallback
      final rect = RectangleComponent(
        size: Vector2(arenaWidth, arenaHeight),
        position: Vector2(arenaWidth / 2, arenaHeight / 2),
        paint: Paint()..color = const Color(0xFF1A1A1A),
        anchor: Anchor.center, // Center the background
      );
      add(rect);
    }
    
    // Set up dynamic background scaling listener
    DisplayConfig.instance.addListener(_onDisplayConfigChanged);
    
    // Load other configurations
    await ItemConfig.instance.loadConfig();
    await WaveConfig.instance.loadConfig();
    await HeroConfig.instance.loadConfig();
    await GameModeConfig.instance.loadConfig();
    await EnemyConfigManager.instance.loadConfig();
    
    // Initialize sound manager and preload sounds
    await SoundManager().preloadSounds();
    
    // Set default game mode
    currentGameModeData = GameModeConfig.instance.defaultGameMode;
    
    // Set up camera using display config
    camera.viewfinder.visibleGameSize = Vector2(arenaWidth, arenaHeight);
    
    // Create hero at center (will be added when game starts)
    hero = Hero(position: Vector2(arenaWidth / 2, arenaHeight / 2), heroId: selectedHeroId);
    
    // Create HUD (will be added when game starts)
    hud = HudComponent();
    
    // Create shop panel (will be added when needed)
    shopPanel = ShopPanel();
    
    // Create stats overlay (will be added when needed)
    statsOverlay = StatsOverlay();
    
    // Create wave announcement system (add early for proper z-order)
    waveAnnouncement = WaveAnnouncement();
    add(waveAnnouncement);
    
    // Create wave timer
    // WaveTimer initialization removed - now using WaveAnnouncement
    
    // Create consumable drop manager
    consumableDropManager = ConsumableDropManager();
    
    // Show start menu overlay
    overlays.add('StartMenu');
  }
  
  void startGame() {
    gameState = GameState.gameModeSelection;
    overlays.remove('StartMenu');
    overlays.add('GameModeSelection');
  }
  
  void setGameMode(String modeId) {
    switch (modeId) {
      case 'normal':
        currentGameMode = GameMode.normal;
        break;
      case 'endless':
        currentGameMode = GameMode.endless;
        break;
      case 'oneHpChallenge':
        currentGameMode = GameMode.oneHpChallenge;
        break;
      default:
        currentGameMode = GameMode.normal;
    }
    
    currentGameModeData = GameModeConfig.instance.getGameModeById(modeId);
    if (currentGameModeData == null) {
      currentGameModeData = GameModeConfig.instance.defaultGameMode;
    }
    
    // Reset retry tokens when setting game mode
    retryTokens = 0;
  }
  
  void proceedToHeroSelection() {
    gameState = GameState.heroSelection;
    overlays.remove('GameModeSelection');
    overlays.add('HeroSelection');
  }
  
  void startGameWithHero(String heroId) {
    selectedHeroId = heroId;
    gameState = GameState.playing;
    currentWave = 1;
    gameOverSoundPlayed = false; // Reset game over sound flag
    lastKillerType = null; // Clear last killer info
    
    // Remove all overlays
    overlays.remove('HeroSelection');
    overlays.remove('GameOver');
    overlays.remove('Victory');
    overlays.remove('PauseMenu');
    
    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.removeFromParent();
    }
    
    // Create hero with selected type
    hero = Hero(position: Vector2(arenaWidth / 2, arenaHeight / 2), heroId: selectedHeroId);
    
    // Reset all upgrade multipliers
    hero.attackSpeedMultiplier = 1.0;
    hero.speedMultiplier = 1.0;
    hero.abilityCooldownMultiplier = 1.0;
    
    // Add game components
    add(hero);
    if (!hud.isMounted) {
      add(hud);
    }
    
    // Update HUD to reflect new hero's ability
    hud.updateAbilityName();
    
    // Add stats overlay for coin and stats display during gameplay
    if (!statsOverlay.isMounted) {
      add(statsOverlay);
    }
    statsOverlay.show();
    
    // Set health based on game mode
    if (currentGameModeData != null) {
      if (currentGameMode == GameMode.oneHpChallenge) {
        hero.health = 1;
        hero.maxHealth = 1;
      } else {
        hero.health = hero.maxHealth;
      }
    } else {
      // Reset hero stats to default
      hero.health = hero.maxHealth;
    }
    
    hero.energy = hero.maxEnergy;
    hero.coins = 0;
    hero.position = Vector2(arenaWidth / 2, arenaHeight / 2);
    
    // Reset retry tokens
    retryTokens = 0;
    
    // Reset shop roll count for new game
    shopPanel.resetForNewWave();
    
    // Start first wave
    startWave(currentWave);
  }
  
  void restartGame() {
    // Reset game over sound flag
    gameOverSoundPlayed = false;
    lastKillerType = null;
    
    // Remove all overlays
    overlays.remove('GameOver');
    overlays.remove('Victory');
    overlays.remove('PauseMenu');
    
    // Clear enemies
    final enemiesCopy = List<Component>.from(currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy.isMounted) {
        enemy.removeFromParent();
      }
    }
    currentEnemies.clear();
    
    // Clear projectiles
    final projectilesCopy = List<Component>.from(currentProjectiles);
    for (final projectile in projectilesCopy) {
      if (projectile.isMounted) {
        projectile.removeFromParent();
      }
    }
    currentProjectiles.clear();
    
    // Clear all item drops
    clearAllItems();
    
    // Clear companion components (drones, clones) before removing hero
    if (hero.isMounted) {
      hero.resetPassiveEffects(); // This clears drones and clones
      hero.removeFromParent();
    }
    
    // Recreate hero with selected type and reset stats
    hero = Hero(position: Vector2(arenaWidth / 2, arenaHeight / 2), heroId: selectedHeroId);
    
    // Reset all upgrade multipliers
    hero.attackSpeedMultiplier = 1.0;
    hero.speedMultiplier = 1.0;
    hero.abilityCooldownMultiplier = 1.0;
    
    add(hero);
    
    // Reset game state
    gameState = GameState.playing;
    currentWave = 1;
    waveTime = 0.0;
    enemySpawnTimer = 0.0;
    
    // Ensure HUD is added and properly updated
    if (!hud.isMounted) {
      add(hud);
    }
    hud.updateHealth(hero.health);
    hud.updateAbilityName(); // Update ability name for current hero
    
    // Add stats overlay for coin and stats display during gameplay
    if (!statsOverlay.isMounted) {
      add(statsOverlay);
    }
    statsOverlay.show();
    
    // Reset shop roll count for new game
    shopPanel.resetForNewWave();
    
    // Start first wave (which will start BGM)
    startWave(currentWave);
  }
  
  void showStartMenu() {
    // Clear all game entities like restartGame() does
    // Clear enemies
    final enemiesCopy = List<Component>.from(currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy.isMounted) {
        enemy.removeFromParent();
      }
    }
    currentEnemies.clear();
    
    // Clear projectiles
    final projectilesCopy = List<Component>.from(currentProjectiles);
    for (final projectile in projectilesCopy) {
      if (projectile.isMounted) {
        projectile.removeFromParent();
      }
    }
    currentProjectiles.clear();
    
    // Clear all item drops
    clearAllItems();
    
    // Clear companion components (drones, clones) if hero exists
    if (hero.isMounted) {
      hero.resetPassiveEffects(); // This clears drones and clones
      hero.removeFromParent();
    }
    
    // Remove shop panel if mounted
    if (shopPanel.isMounted) {
      shopPanel.removeFromParent();
    }
    
    // Remove stats overlay if mounted
    if (statsOverlay.isMounted) {
      statsOverlay.removeFromParent();
    }
    
    // Remove HUD if mounted
    if (hud.isMounted) {
      hud.removeFromParent();
    }
    
    gameState = GameState.startMenu;
    lastKillerType = null;
    overlays.remove('GameModeSelection');
    overlays.remove('HeroSelection');
    overlays.remove('GameOver');
    overlays.remove('Victory');
    overlays.remove('PauseMenu');
    overlays.add('StartMenu');
  }
  
  void startWave(int waveNumber) {
    gameState = GameState.playing;
    currentWave = waveNumber;
    waveCompletionInProgress = false; // Reset flag for new wave
    
    // Reset wave timer
    waveTime = 0.0;
    enemySpawnTimer = 0.0;
    
    // Set spawn interval from wave config with endless mode scaling
    double baseSpawnInterval;
    if (currentGameMode == GameMode.endless && waveNumber > 5) {
      // For endless mode waves 6+, use wave 5 as base and apply scaling
      baseSpawnInterval = WaveConfig.instance.getSpawnInterval(5);
      final wavesFromBaseline = waveNumber - 5; // Waves beyond wave 5
      final reductionFactor = pow(0.9, wavesFromBaseline).toDouble(); // 10% faster each wave
      baseSpawnInterval *= reductionFactor;
      // Cap minimum spawn interval to prevent it from becoming too fast
      baseSpawnInterval = baseSpawnInterval.clamp(0.2, double.infinity);
    } else {
      // For normal mode or endless mode waves 1-5, use normal wave configuration
      baseSpawnInterval = WaveConfig.instance.getSpawnInterval(currentWave);
    }
    
    enemySpawnInterval = baseSpawnInterval;
    
    // Make sure shop is removed during gameplay
    if (shopPanel.isMounted) {
      shopPanel.removeFromParent();
    }
    // Keep stats overlay visible during gameplay - don't remove it
    
    // Ensure stats overlay is visible during gameplay
    if (!statsOverlay.isMounted) {
      add(statsOverlay);
    }
    statsOverlay.show();
    
    // Clear existing enemies
    for (final enemy in currentEnemies) {
      enemy.removeFromParent();
    }
    currentEnemies.clear();
    
    // Show wave start announcement
    waveAnnouncement.showWaveStart(waveNumber);
    
    // Delay countdown start to let "Wave X starts" show for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (gameState == GameState.playing && currentWave == waveNumber) {
        // Start showing countdown after wave start message
        print('DEBUG: Starting countdown for wave $waveNumber');
      }
    });
    
    // Note: Wave timer now integrated into wave announcement
    
    // Add consumable drop manager
    if (!consumableDropManager.isMounted) {
      add(consumableDropManager);
    }
    
    // Start battle music for the wave
    SoundManager().playBattleBGM();
    
    // Update HUD
    hud.updateWave(waveNumber);
  }
  
  void _spawnEnemyAtRandomEdge(Component Function() enemyFactory, Random random) {
    Vector2 spawnPosition;
    
    // Calculate no-stay zone boundaries (10% of arena dimensions)
    final noStayMarginX = arenaWidth * 0.1;
    final noStayMarginY = arenaHeight * 0.1;
    
    // Spawn at random edge of the no-stay zone inner border instead of arena edge
    final edge = random.nextInt(4);
    switch (edge) {
      case 0: // Top edge of no-stay zone
        spawnPosition = Vector2(
          noStayMarginX + random.nextDouble() * (arenaWidth - 2 * noStayMarginX), 
          noStayMarginY
        );
        break;
      case 1: // Right edge of no-stay zone
        spawnPosition = Vector2(
          arenaWidth - noStayMarginX, 
          noStayMarginY + random.nextDouble() * (arenaHeight - 2 * noStayMarginY)
        );
        break;
      case 2: // Bottom edge of no-stay zone
        spawnPosition = Vector2(
          noStayMarginX + random.nextDouble() * (arenaWidth - 2 * noStayMarginX), 
          arenaHeight - noStayMarginY
        );
        break;
      case 3: // Left edge of no-stay zone
        spawnPosition = Vector2(
          noStayMarginX, 
          noStayMarginY + random.nextDouble() * (arenaHeight - 2 * noStayMarginY)
        );
        break;
      default:
        spawnPosition = Vector2.zero();
    }
    
    final enemy = enemyFactory();
    if (enemy is PositionComponent) {
      enemy.position = spawnPosition;
    }
    
    add(enemy);
    currentEnemies.add(enemy);
    
    // Special handling for swarmers - spawn additional ones nearby
    if (enemy is Swarmer) {
      const swarmCount = 5; // Spawn 5 more (total 6)
      const swarmSpread = 40.0; // Distance between swarmers
      
      for (int i = 0; i < swarmCount; i++) {
        final angle = (i * 2 * pi / swarmCount);
        final offset = Vector2(
          cos(angle) * swarmSpread * DisplayConfig.instance.scaleFactor,
          sin(angle) * swarmSpread * DisplayConfig.instance.scaleFactor,
        );
        
        final additionalSwarmer = Swarmer(position: spawnPosition + offset);
        add(additionalSwarmer);
        currentEnemies.add(additionalSwarmer);
      }
    }
  }
  
  void onEnemyDestroyed(Component enemy) {
    currentEnemies.remove(enemy);
    
    // Award coins based on enemy type from config
    String enemyType = 'chaser'; // Default
    if (enemy is EnemyChaser) {
      enemyType = 'chaser';
    } else if (enemy is EnemyShooter) {
      enemyType = 'shooter';
    } else if (enemy is ShieldedChaser) {
      enemyType = 'shielded_chaser';
    } else if (enemy is Swarmer) {
      enemyType = 'swarmer';
    } else if (enemy is Bomber) {
      enemyType = 'bomber';
    } else if (enemy is Sniper) {
      enemyType = 'sniper';
    } else if (enemy is Splitter) {
      enemyType = 'splitter';
    } else if (enemy is MineLayer) {
      enemyType = 'mine_layer';
    }
    
    final reward = WaveConfig.instance.getEnemyReward(enemyType);
    final coins = reward?.coins ?? 10; // Fallback to 10 if config not found
    
    hero.addCoins(coins);
    
    // Try to drop item (unified system) with enemy-specific drop chance
    if (enemy is PositionComponent) {
      consumableDropManager.tryDropItem(enemy.position, enemyType: enemyType);
    }
    
    // No longer check for wave completion here - waves are time-based now
  }
  
  void addProjectile(Component projectile) {
    currentProjectiles.add(projectile);
  }
  
  void onProjectileDestroyed(Component projectile) {
    currentProjectiles.remove(projectile);
  }
  
  void onWaveComplete() {
    // Prevent multiple calls
    if (waveCompletionInProgress) return;
    waveCompletionInProgress = true;
    
    print('DEBUG: Wave $currentWave completing...');
    
    // Stop battle music when wave ends
    SoundManager().stopBGM();
    
    // Play wave clear sound
    SoundManager().playClearSound();
    
    // Clear all remaining enemies at wave end
    final enemiesCopy = List<Component>.from(currentEnemies);
    for (final enemy in enemiesCopy) {
      enemy.removeFromParent();
    }
    currentEnemies.clear();
    
    // Clear all remaining projectiles at wave end
    final projectilesCopy = List<Component>.from(currentProjectiles);
    for (final projectile in projectilesCopy) {
      projectile.removeFromParent();
    }
    currentProjectiles.clear();
    
    // Clear all consumable drops at wave end
    consumableDropManager.clearAllDrops();
    
    // Hide countdown and show wave survived announcement
    waveAnnouncement.hideCountdown();
    waveAnnouncement.showWaveSurvived(currentWave);
    
    // Activate hero invincibility
    hero.activateInvincibility();
    
    // Regenerate shields between waves
    hero.regenerateShields();
    
    // Check if we should continue (endless mode or normal wave limit)
    final shouldShowVictory = (currentGameMode != GameMode.endless && currentWave >= maxWaves);
    
    if (shouldShowVictory) {
      // Game complete - show victory screen
      gameState = GameState.victory;
      
      // Clear all item drops when game ends
      clearAllItems();
      
      // Play victory sound (BGM already stopped above)
      SoundManager().playVictorySound();
      overlays.add('Victory');
    } else {
      // Delay shop opening until after "Wave X survived!" message (2 seconds)
      Future.delayed(const Duration(seconds: 2), () {
        if (gameState != GameState.gameOver && gameState != GameState.victory) {
          // Show shop
          gameState = GameState.shopping;
          if (!shopPanel.isMounted) {
            add(shopPanel);
          }
          // Do not reset roll count between waves; only reset on full game restart
          shopPanel.show();
          
          // Ensure stats overlay is on top by adding it after the shop panel
          if (statsOverlay.isMounted) {
            statsOverlay.removeFromParent();
          }
          add(statsOverlay);
          statsOverlay.show();
          
          // Auto refresh shop items (this counts as the first roll, so cost will be base + 1 for next roll)
          shopPanel.rollShopItems();
        }
      });
    }
  }
  
  void onShopClosed() {
    gameState = GameState.playing;
    if (shopPanel.isMounted) {
      shopPanel.removeFromParent();
    }
    // Keep stats overlay visible during gameplay - don't remove it
    startWave(currentWave + 1);
  }
  
  void onHeroDeath({String? killerType}) {
    if (gameOverSoundPlayed) return; // Prevent multiple fail sounds
    
    // Handle 1HP Challenge mode retry tokens
    if (currentGameMode == GameMode.oneHpChallenge && retryTokens > 0) {
      consumeRetryToken();
      revivePlayer();
      return;
    }
    
    gameState = GameState.gameOver;
    gameOverSoundPlayed = true;
    lastKillerType = killerType;
    
    // Clear all item drops when game ends
    clearAllItems();
    
    // Stop battle music and play fail sound
    SoundManager().stopBGM();
    SoundManager().playFailSound();
    overlays.add('GameOver');
  }
  
  void consumeRetryToken() {
    if (retryTokens > 0) {
      retryTokens--;
      // TODO: Play retry token use sound
      print('Retry token consumed! Tokens remaining: $retryTokens');
    }
  }
  
  void addRetryToken() {
    if (currentGameMode == GameMode.oneHpChallenge && retryTokens == 0) {
      retryTokens = 1; // Max one token at a time
      // TODO: Play retry token collect sound
      print('Retry token collected!');
    }
  }
  
  void revivePlayer() {
    // Restore full health
    hero.health = hero.maxHealth;
    
    // Clear nearby enemies to give player breathing room
    final heroCenterX = hero.position.x;
    final heroCenterY = hero.position.y;
    final clearRadius = 150.0; // Clear enemies within this radius
    
    final enemiesToRemove = <Component>[];
    for (final enemy in currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = (enemy.position - Vector2(heroCenterX, heroCenterY)).length;
        if (distance <= clearRadius) {
          enemiesToRemove.add(enemy);
        }
      }
    }
    
    for (final enemy in enemiesToRemove) {
      enemy.removeFromParent();
      currentEnemies.remove(enemy);
    }
    
    // Brief invincibility
    hero.activateInvincibility();
  }
  
  void pauseGame() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
      overlays.add('PauseMenu');
    }
  }
  
  void resumeGame() {
    if (gameState == GameState.paused) {
      gameState = GameState.playing;
      overlays.remove('PauseMenu');
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip game logic when paused
    if (gameState == GameState.paused) {
      return;
    }
    
    // Only update HUD during gameplay
    if (gameState == GameState.playing || gameState == GameState.shopping) {
      hud.updateHealth(hero.health);
      // hud.updateArmor(hero.shield, hero.totalShieldHP);
    }
    
    // Update stats overlay during gameplay and shopping
    if ((gameState == GameState.playing || gameState == GameState.shopping) && statsOverlay.isVisible) {
      statsOverlay.updateStats();
    }
    
    // Handle wave timing during gameplay
    if (gameState == GameState.playing && !waveCompletionInProgress) {
      waveTime += dt;
      enemySpawnTimer += dt;
      
      // Update wave timer display
      final remainingTime = (waveDuration - waveTime).clamp(0.0, waveDuration);
      // Wave timer moved to background announcement
      
      // Wave timer component removed - now integrated into wave announcement
      
      // Update wave announcement countdown
      waveAnnouncement.showCountdown(remainingTime);
      
      // Update consumable drop manager
      if (consumableDropManager.isMounted) {
        consumableDropManager.update(dt);
      }
      
      // Spawn enemies periodically using new system
      if (enemySpawnTimer >= enemySpawnInterval) {
        _spawnEnemyGroup();
        enemySpawnTimer = 0.0;
      }
      
      // Check if wave is complete
      if (waveTime >= waveDuration) {
        onWaveComplete();
      }
    }
  }
  
  void _spawnEnemyGroup() {
    int spawnCount;
    
    if (currentGameMode == GameMode.endless && currentWave > 5) {
      // For endless mode waves 6+, use wave 5 spawn count plus scaling
      spawnCount = WaveConfig.instance.getSpawnCount(5);
      // Add 1 extra enemy per spawn every 5 waves beyond wave 5
      final extraWaveGroups = (currentWave - 5) ~/ 5; // Every 5 waves
      spawnCount += extraWaveGroups;
    } else {
      // For normal mode or endless mode waves 1-5, use normal wave configuration
      spawnCount = WaveConfig.instance.getSpawnCount(currentWave);
    }
    
    // Spawn multiple enemies based on spawn_count
    for (int i = 0; i < spawnCount; i++) {
      _spawnRandomEnemy();
    }
  }
  
  void _spawnRandomEnemy() {
    final random = Random();
    WaveData? waveData;
    List<String> availableEnemyTypes = [];
    
    if (currentGameMode == GameMode.endless && currentWave > 5) {
      // For endless mode waves 6+, use wave 5 configuration as base
      waveData = WaveConfig.instance.getWaveData(5);
      
      // Add new enemy types based on infinite mode spawn thresholds
      final infiniteSpawns = WaveConfig.instance.infiniteSpawns;
      if (infiniteSpawns != null) {
        final newEnemyTypes = infiniteSpawns.getAvailableEnemyTypes(currentWave);
        
        // Combine base wave 5 enemies with new infinite mode enemies
        availableEnemyTypes = [...(waveData?.enemyTypes ?? []), ...newEnemyTypes];
      } else {
        availableEnemyTypes = waveData?.enemyTypes ?? [];
      }
    } else {
      // For normal mode or endless mode waves 1-5, use normal wave configuration
      waveData = WaveConfig.instance.getWaveData(currentWave);
      availableEnemyTypes = waveData?.enemyTypes ?? [];
    }
    
    Component Function() enemyFactory;
    
    if (availableEnemyTypes.isNotEmpty) {
      String selectedEnemyType;
      
      if (currentGameMode == GameMode.endless && currentWave > 5) {
        // For infinite mode, use equal weights for all available enemies
        selectedEnemyType = availableEnemyTypes[random.nextInt(availableEnemyTypes.length)];
      } else {
        // Use wave configuration weights for normal mode
        final totalWeight = waveData!.spawnWeights.values.fold(0.0, (sum, weight) => sum + weight);
        final randomValue = random.nextDouble() * totalWeight;
        
        double currentWeight = 0.0;
        selectedEnemyType = availableEnemyTypes.first;
        
        for (final enemyType in availableEnemyTypes) {
          currentWeight += waveData.spawnWeights[enemyType] ?? 0.0;
          if (randomValue <= currentWeight) {
            selectedEnemyType = enemyType;
            break;
          }
        }
      }
      
      // Create enemy based on selected type
      enemyFactory = _createEnemyFactory(selectedEnemyType);
    } else {
      // Fallback to old logic if config not available
      enemyFactory = _createFallbackEnemy(random);
    }
    
    _spawnEnemyAtRandomEdge(enemyFactory, random);
  }
  
  Component Function() _createEnemyFactory(String enemyType) {
    switch (enemyType) {
      case 'chaser':
        return EnemyChaser.new;
      case 'shooter':
        return EnemyShooter.new;
      case 'shielded_chaser':
        return ShieldedChaser.new;
      case 'swarmer':
        return Swarmer.new;
      case 'bomber':
        return Bomber.new;
      case 'sniper':
        return Sniper.new;
      case 'splitter':
        return Splitter.new;
      case 'mine_layer':
        return MineLayer.new;
      default:
        return EnemyChaser.new; // Fallback
    }
  }
  
  Component Function() _createFallbackEnemy(Random random) {
    switch (currentWave) {
      case 1:
        return EnemyChaser.new;
      case 2:
        return EnemyShooter.new;
      case 3:
        return ShieldedChaser.new;
      default:
        final enemyType = random.nextInt(3);
        switch (enemyType) {
          case 0:
            return EnemyChaser.new;
          case 1:
            return EnemyShooter.new;
          case 2:
            return ShieldedChaser.new;
          default:
            return EnemyChaser.new;
        }
    }
  }
  
  void _updateArenaDimensions(double screenWidth, double screenHeight) {
    // Update display config with new dimensions
    DisplayConfig.instance.updateArenaDimensions(screenWidth, screenHeight);
    
    // Update camera if needed
    if (isMounted) {
      camera.viewfinder.visibleGameSize = Vector2(arenaWidth, arenaHeight);
      
      // Update background size and position if it exists
      if (backgroundArena.isMounted) {
        backgroundArena.size = Vector2(arenaWidth, arenaHeight);
        backgroundArena.position = Vector2(arenaWidth / 2, arenaHeight / 2);
      }
    }
  }
  
  /// Handle display configuration changes for dynamic responsiveness
  void _onDisplayConfigChanged(DisplaySettings oldSettings, DisplaySettings newSettings) {
    print('Game responding to display config change: ${newSettings.arenaWidth.toInt()}x${newSettings.arenaHeight.toInt()}');
    
    // Update background
    if (backgroundArena.isMounted) {
      backgroundArena.size = Vector2(newSettings.arenaWidth, newSettings.arenaHeight);
      backgroundArena.position = Vector2(newSettings.arenaWidth / 2, newSettings.arenaHeight / 2);
    }
    
    // Update camera
    camera.viewfinder.visibleGameSize = Vector2(newSettings.arenaWidth, newSettings.arenaHeight);
    
    // Update HUD layout for new screen size
    if (hud.isMounted) {
      hud.rebuildHudLayout();
    }
    
    // Update stats overlay layout for new screen size
    if (statsOverlay.isMounted) {
      statsOverlay.rebuildLayout();
    }
  }

  // Method to be called from main app when screen size is known
  void updateScreenDimensions(double screenWidth, double screenHeight) {
    _updateArenaDimensions(screenWidth, screenHeight);
  }
  
  // No-stay zone utility - pushes enemies away from edges (10% margin)
  Vector2 getNoStayZoneForce(Vector2 position) {
    final noStayMargin = 0.1; // 10% of arena dimensions
    final marginX = arenaWidth * noStayMargin;
    final marginY = arenaHeight * noStayMargin;
    
    Vector2 force = Vector2.zero();
    
    // Left edge push
    if (position.x < marginX) {
      final pushStrength = (marginX - position.x) / marginX;
      force.x += pushStrength * 200.0; // Base push force
    }
    
    // Right edge push
    if (position.x > arenaWidth - marginX) {
      final pushStrength = (position.x - (arenaWidth - marginX)) / marginX;
      force.x -= pushStrength * 200.0;
    }
    
    // Top edge push
    if (position.y < marginY) {
      final pushStrength = (marginY - position.y) / marginY;
      force.y += pushStrength * 200.0;
    }
    
    // Bottom edge push
    if (position.y > arenaHeight - marginY) {
      final pushStrength = (position.y - (arenaHeight - marginY)) / marginY;
      force.y -= pushStrength * 200.0;
    }
    
    return force;
  }
  
  void clearAllItems() {
    // Remove all item drops from the game
    final componentsToRemove = <Component>[];
    
    // Find all ItemPickup components in the game
    for (final component in children) {
      if (component.runtimeType.toString().contains('ItemPickup') || 
          component.runtimeType.toString().contains('HealthShard') ||
          component.runtimeType.toString().contains('RetryToken')) {
        componentsToRemove.add(component);
      }
    }
    
    // Remove all found item components
    for (final component in componentsToRemove) {
      if (component.isMounted) {
        component.removeFromParent();
      }
    }
  }
  
  void showEffectNotification(String effectType, double value, double duration) {
    // Simple console output for now - could be enhanced with UI notifications
    print('Effect applied: $effectType (${value.toStringAsFixed(1)}) for ${duration.toStringAsFixed(1)}s');
  }

  // Map last killer type to a flavorful death message
  String get lastDeathMessage {
    final type = lastKillerType;
    switch (type) {
      case 'chaser':
        return '💥 A Chaser rammed you down.';
      case 'shooter':
        return '🔫 A Shooter\'s bullet found its mark.';
      case 'shielded_chaser':
        return '🛡️ A Shielded Chaser broke through your defenses.';
      case 'swarmer':
        return '🐝 A Swarmer swarmed the last of your HP.';
      case 'bomber':
        return '💣 A Bomber\'s explosion ended your run.';
      case 'sniper':
        return '🎯 A Sniper\'s shot was lethal.';
      case 'splitter':
        return '🧩 A Splitter crashed into you for the final blow.';
      case 'mine_layer':
        return '🧨 A Mine exploded beneath you.';
      default:
        return '💀 The shapes have claimed another hero...';
    }
  }
} 
```

```dart
import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Hero;

import '../components/hero.dart';
import '../components/enemies/enemy_chaser.dart';
import '../components/enemies/enemy_shooter.dart';
import '../components/enemies/shielded_chaser.dart';
import '../components/enemies/swarmer.dart';
import '../components/enemies/bomber.dart';
import '../components/enemies/sniper.dart';
import '../components/enemies/splitter.dart';
import '../components/enemies/mine_layer.dart';
import '../components/hud.dart';
import '../components/shop_panel.dart';
import '../components/stats_overlay.dart';
import '../components/sound_manager.dart';
import '../components/wave_announcement.dart';
// Removed wave_timer.dart - now using wave_announcement.dart instead
import '../components/consumable_drop_manager.dart';
import '../config/item_config.dart';
import '../config/wave_config.dart';
import '../config/hero_config.dart';
import '../config/game_mode_config.dart';
import '../config/display_config.dart';
import '../config/enemy_config.dart';

enum GameState { startMenu, gameModeSelection, heroSelection, playing, shopping, gameOver, victory, paused }

class CircleRougeGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Hero hero;
  late HudComponent hud;
  late ShopPanel shopPanel;
  late StatsOverlay statsOverlay;
  late SpriteComponent backgroundArena; // Reference to background
  late WaveAnnouncement waveAnnouncement;
  // WaveTimer removed - now using WaveAnnouncement instead
  late ConsumableDropManager consumableDropManager;
  
  GameState gameState = GameState.startMenu;
  
  // Game Mode System
  GameMode currentGameMode = GameMode.normal;
  GameModeData? currentGameModeData;
  int retryTokens = 0;
  
  int currentWave = 1;
  int get maxWaves {
    if (currentGameModeData != null && currentGameModeData!.maxWaves != -1) {
      return currentGameModeData!.maxWaves;
    }
    return WaveConfig.instance.settings?.maxWaves ?? 5;
  }
  List<Component> currentEnemies = [];
  List<Component> currentProjectiles = [];
  
  // Time-based wave system - values from config
  double waveTime = 0.0;
  double get waveDuration => WaveConfig.instance.settings?.effectiveWaveDuration ?? 30.0;
  double enemySpawnTimer = 0.0;
  double enemySpawnInterval = 2.0; // Will be calculated dynamically
  
  // Arena bounds - now using display config
  double get arenaWidth => DisplayConfig.instance.arenaWidth;
  double get arenaHeight => DisplayConfig.instance.arenaHeight;
  double get safeAreaMargin => DisplayConfig.instance.safeAreaMargin;
  
  // Scaling factor based on display config
  double get scaleFactor => DisplayConfig.instance.scaleFactor;
  
  String selectedHeroId = 'circle'; // Default hero selection
  
  // Game over flag to prevent multiple sounds
  bool gameOverSoundPlayed = false;
  
  // Track what killed the hero for customized Game Over messaging
  String? lastKillerType; // e.g., 'chaser', 'shooter', 'sniper', 'bomber', 'mine_layer', etc.
  
  // Wave completion flag to prevent multiple calls
  bool waveCompletionInProgress = false;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Load configurations first
    await DisplayConfig.instance.loadConfig();
    
    // Create arena background with background image
    try {
      final backgroundSprite = await Sprite.load('background1.png');
      backgroundArena = SpriteComponent(
        sprite: backgroundSprite,
        size: Vector2(arenaWidth, arenaHeight),
        position: Vector2(arenaWidth / 2, arenaHeight / 2),
        anchor: Anchor.center, // Center the background
      );
      add(backgroundArena);
    } catch (e) {
      print('Could not load background image: $e');
      // Create a simple colored background as fallback
      final rect = RectangleComponent(
        size: Vector2(arenaWidth, arenaHeight),
        position: Vector2(arenaWidth / 2, arenaHeight / 2),
        paint: Paint()..color = const Color(0xFF1A1A1A),
        anchor: Anchor.center, // Center the background
      );
      add(rect);
    }
    
    // Set up dynamic background scaling listener
    DisplayConfig.instance.addListener(_onDisplayConfigChanged);
    
    // Load other configurations
    await ItemConfig.instance.loadConfig();
    await WaveConfig.instance.loadConfig();
    await HeroConfig.instance.loadConfig();
    await GameModeConfig.instance.loadConfig();
    await EnemyConfigManager.instance.loadConfig();
    
    // Initialize sound manager and preload sounds
    await SoundManager().preloadSounds();
    
    // Set default game mode
    currentGameModeData = GameModeConfig.instance.defaultGameMode;
    
    // Set up camera using display config
    camera.viewfinder.visibleGameSize = Vector2(arenaWidth, arenaHeight);
    
    // Create hero at center (will be added when game starts)
    hero = Hero(position: Vector2(arenaWidth / 2, arenaHeight / 2), heroId: selectedHeroId);
    
    // Create HUD (will be added when game starts)
    hud = HudComponent();
    
    // Create shop panel (will be added when needed)
    shopPanel = ShopPanel();
    
    // Create stats overlay (will be added when needed)
    statsOverlay = StatsOverlay();
    
    // Create wave announcement system (add early for proper z-order)
    waveAnnouncement = WaveAnnouncement();
    add(waveAnnouncement);
    
    // Create wave timer
    // WaveTimer initialization removed - now using WaveAnnouncement
    
    // Create consumable drop manager
    consumableDropManager = ConsumableDropManager();
    
    // Show start menu overlay
    overlays.add('StartMenu');
  }
  
  void startGame() {
    gameState = GameState.gameModeSelection;
    overlays.remove('StartMenu');
    overlays.add('GameModeSelection');
  }
  
  void setGameMode(String modeId) {
    switch (modeId) {
      case 'normal':
        currentGameMode = GameMode.normal;
        break;
      case 'endless':
        currentGameMode = GameMode.endless;
        break;
      case 'oneHpChallenge':
        currentGameMode = GameMode.oneHpChallenge;
        break;
      default:
        currentGameMode = GameMode.normal;
    }
    
    currentGameModeData = GameModeConfig.instance.getGameModeById(modeId);
    if (currentGameModeData == null) {
      currentGameModeData = GameModeConfig.instance.defaultGameMode;
    }
    
    // Reset retry tokens when setting game mode
    retryTokens = 0;
  }
  
  void proceedToHeroSelection() {
    gameState = GameState.heroSelection;
    overlays.remove('GameModeSelection');
    overlays.add('HeroSelection');
  }
  
  void startGameWithHero(String heroId) {
    selectedHeroId = heroId;
    gameState = GameState.playing;
    currentWave = 1;
    gameOverSoundPlayed = false; // Reset game over sound flag
    lastKillerType = null; // Clear last killer info
    
    // Remove all overlays
    overlays.remove('HeroSelection');
    overlays.remove('GameOver');
    overlays.remove('Victory');
    overlays.remove('PauseMenu');
    
    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.removeFromParent();
    }
    
    // Create hero with selected type
    hero = Hero(position: Vector2(arenaWidth / 2, arenaHeight / 2), heroId: selectedHeroId);
    
    // Reset all upgrade multipliers
    hero.attackSpeedMultiplier = 1.0;
    hero.speedMultiplier = 1.0;
    hero.abilityCooldownMultiplier = 1.0;
    
    // Add game components
    add(hero);
    if (!hud.isMounted) {
      add(hud);
    }
    
    // Update HUD to reflect new hero's ability
    hud.updateAbilityName();
    
    // Add stats overlay for coin and stats display during gameplay
    if (!statsOverlay.isMounted) {
      add(statsOverlay);
    }
    statsOverlay.show();
    
    // Set health based on game mode
    if (currentGameModeData != null) {
      if (currentGameMode == GameMode.oneHpChallenge) {
        hero.health = 1;
        hero.maxHealth = 1;
      } else {
        hero.health = hero.maxHealth;
      }
    } else {
      // Reset hero stats to default
      hero.health = hero.maxHealth;
    }
    
    hero.energy = hero.maxEnergy;
    hero.coins = 0;
    hero.position = Vector2(arenaWidth / 2, arenaHeight / 2);
    
    // Reset retry tokens
    retryTokens = 0;
    
    // Reset shop roll count for new game
    shopPanel.resetForNewWave();
    
    // Start first wave
    startWave(currentWave);
  }
  
  void restartGame() {
    // Reset game over sound flag
    gameOverSoundPlayed = false;
    lastKillerType = null;
    
    // Remove all overlays
    overlays.remove('GameOver');
    overlays.remove('Victory');
    overlays.remove('PauseMenu');
    
    // Clear enemies
    final enemiesCopy = List<Component>.from(currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy.isMounted) {
        enemy.removeFromParent();
      }
    }
    currentEnemies.clear();
    
    // Clear projectiles
    final projectilesCopy = List<Component>.from(currentProjectiles);
    for (final projectile in projectilesCopy) {
      if (projectile.isMounted) {
        projectile.removeFromParent();
      }
    }
    currentProjectiles.clear();
    
    // Clear all item drops
    clearAllItems();
    
    // Clear companion components (drones, clones) before removing hero
    if (hero.isMounted) {
      hero.resetPassiveEffects(); // This clears drones and clones
      hero.removeFromParent();
    }
    
    // Recreate hero with selected type and reset stats
    hero = Hero(position: Vector2(arenaWidth / 2, arenaHeight / 2), heroId: selectedHeroId);
    
    // Reset all upgrade multipliers
    hero.attackSpeedMultiplier = 1.0;
    hero.speedMultiplier = 1.0;
    hero.abilityCooldownMultiplier = 1.0;
    
    add(hero);
    
    // Reset game state
    gameState = GameState.playing;
    currentWave = 1;
    waveTime = 0.0;
    enemySpawnTimer = 0.0;
    
    // Ensure HUD is added and properly updated
    if (!hud.isMounted) {
      add(hud);
    }
    hud.updateHealth(hero.health);
    hud.updateAbilityName(); // Update ability name for current hero
    
    // Add stats overlay for coin and stats display during gameplay
    if (!statsOverlay.isMounted) {
      add(statsOverlay);
    }
    statsOverlay.show();
    
    // Reset shop roll count for new game
    shopPanel.resetForNewWave();
    
    // Start first wave (which will start BGM)
    startWave(currentWave);
  }
  
  void showStartMenu() {
    // Clear all game entities like restartGame() does
    // Clear enemies
    final enemiesCopy = List<Component>.from(currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy.isMounted) {
        enemy.removeFromParent();
      }
    }
    currentEnemies.clear();
    
    // Clear projectiles
    final projectilesCopy = List<Component>.from(currentProjectiles);
    for (final projectile in projectilesCopy) {
      if (projectile.isMounted) {
        projectile.removeFromParent();
      }
    }
    currentProjectiles.clear();
    
    // Clear all item drops
    clearAllItems();
    
    // Clear companion components (drones, clones) if hero exists
    if (hero.isMounted) {
      hero.resetPassiveEffects(); // This clears drones and clones
      hero.removeFromParent();
    }
    
    // Remove shop panel if mounted
    if (shopPanel.isMounted) {
      shopPanel.removeFromParent();
    }
    
    // Remove stats overlay if mounted
    if (statsOverlay.isMounted) {
      statsOverlay.removeFromParent();
    }
    
    // Remove HUD if mounted
    if (hud.isMounted) {
      hud.removeFromParent();
    }
    
    gameState = GameState.startMenu;
    lastKillerType = null;
    overlays.remove('GameModeSelection');
    overlays.remove('HeroSelection');
    overlays.remove('GameOver');
    overlays.remove('Victory');
    overlays.remove('PauseMenu');
    overlays.add('StartMenu');
  }
  
  void startWave(int waveNumber) {
    gameState = GameState.playing;
    currentWave = waveNumber;
    waveCompletionInProgress = false; // Reset flag for new wave
    
    // Reset wave timer
    waveTime = 0.0;
    enemySpawnTimer = 0.0;
    
    // Set spawn interval from wave config with endless mode scaling
    double baseSpawnInterval;
    if (currentGameMode == GameMode.endless && waveNumber > 5) {
      // For endless mode waves 6+, use wave 5 as base and apply scaling
      baseSpawnInterval = WaveConfig.instance.getSpawnInterval(5);
      final wavesFromBaseline = waveNumber - 5; // Waves beyond wave 5
      final reductionFactor = pow(0.9, wavesFromBaseline).toDouble(); // 10% faster each wave
      baseSpawnInterval *= reductionFactor;
      // Cap minimum spawn interval to prevent it from becoming too fast
      baseSpawnInterval = baseSpawnInterval.clamp(0.2, double.infinity);
    } else {
      // For normal mode or endless mode waves 1-5, use normal wave configuration
      baseSpawnInterval = WaveConfig.instance.getSpawnInterval(currentWave);
    }
    
    enemySpawnInterval = baseSpawnInterval;
    
    // Make sure shop is removed during gameplay
    if (shopPanel.isMounted) {
      shopPanel.removeFromParent();
    }
    // Keep stats overlay visible during gameplay - don't remove it
    
    // Ensure stats overlay is visible during gameplay
    if (!statsOverlay.isMounted) {
      add(statsOverlay);
    }
    statsOverlay.show();
    
    // Clear existing enemies
    for (final enemy in currentEnemies) {
      enemy.removeFromParent();
    }
    currentEnemies.clear();
    
    // Show wave start announcement
    waveAnnouncement.showWaveStart(waveNumber);
    
    // Delay countdown start to let "Wave X starts" show for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (gameState == GameState.playing && currentWave == waveNumber) {
        // Start showing countdown after wave start message
        print('DEBUG: Starting countdown for wave $waveNumber');
      }
    });
    
    // Note: Wave timer now integrated into wave announcement
    
    // Add consumable drop manager
    if (!consumableDropManager.isMounted) {
      add(consumableDropManager);
    }
    
    // Start battle music for the wave
    SoundManager().playBattleBGM();
    
    // Update HUD
    hud.updateWave(waveNumber);
  }
  
  void _spawnEnemyAtRandomEdge(Component Function() enemyFactory, Random random) {
    Vector2 spawnPosition;
    
    // Calculate no-stay zone boundaries (10% of arena dimensions)
    final noStayMarginX = arenaWidth * 0.1;
    final noStayMarginY = arenaHeight * 0.1;
    
    // Spawn at random edge of the no-stay zone inner border instead of arena edge
    final edge = random.nextInt(4);
    switch (edge) {
      case 0: // Top edge of no-stay zone
        spawnPosition = Vector2(
          noStayMarginX + random.nextDouble() * (arenaWidth - 2 * noStayMarginX), 
          noStayMarginY
        );
        break;
      case 1: // Right edge of no-stay zone
        spawnPosition = Vector2(
          arenaWidth - noStayMarginX, 
          noStayMarginY + random.nextDouble() * (arenaHeight - 2 * noStayMarginY)
        );
        break;
      case 2: // Bottom edge of no-stay zone
        spawnPosition = Vector2(
          noStayMarginX + random.nextDouble() * (arenaWidth - 2 * noStayMarginX), 
          arenaHeight - noStayMarginY
        );
        break;
      case 3: // Left edge of no-stay zone
        spawnPosition = Vector2(
          noStayMarginX, 
          noStayMarginY + random.nextDouble() * (arenaHeight - 2 * noStayMarginY)
        );
        break;
      default:
        spawnPosition = Vector2.zero();
    }
    
    final enemy = enemyFactory();
    if (enemy is PositionComponent) {
      enemy.position = spawnPosition;
    }
    
    add(enemy);
    currentEnemies.add(enemy);
    
    // Special handling for swarmers - spawn additional ones nearby
    if (enemy is Swarmer) {
      const swarmCount = 5; // Spawn 5 more (total 6)
      const swarmSpread = 40.0; // Distance between swarmers
      
      for (int i = 0; i < swarmCount; i++) {
        final angle = (i * 2 * pi / swarmCount);
        final offset = Vector2(
          cos(angle) * swarmSpread * DisplayConfig.instance.scaleFactor,
          sin(angle) * swarmSpread * DisplayConfig.instance.scaleFactor,
        );
        
        final additionalSwarmer = Swarmer(position: spawnPosition + offset);
        add(additionalSwarmer);
        currentEnemies.add(additionalSwarmer);
      }
    }
  }
  
  void onEnemyDestroyed(Component enemy) {
    currentEnemies.remove(enemy);
    
    // Award coins based on enemy type from config
    String enemyType = 'chaser'; // Default
    if (enemy is EnemyChaser) {
      enemyType = 'chaser';
    } else if (enemy is EnemyShooter) {
      enemyType = 'shooter';
    } else if (enemy is ShieldedChaser) {
      enemyType = 'shielded_chaser';
    } else if (enemy is Swarmer) {
      enemyType = 'swarmer';
    } else if (enemy is Bomber) {
      enemyType = 'bomber';
    } else if (enemy is Sniper) {
      enemyType = 'sniper';
    } else if (enemy is Splitter) {
      enemyType = 'splitter';
    } else if (enemy is MineLayer) {
      enemyType = 'mine_layer';
    }
    
    final reward = WaveConfig.instance.getEnemyReward(enemyType);
    final coins = reward?.coins ?? 10; // Fallback to 10 if config not found
    
    hero.addCoins(coins);
    
    // Try to drop item (unified system) with enemy-specific drop chance
    if (enemy is PositionComponent) {
      consumableDropManager.tryDropItem(enemy.position, enemyType: enemyType);
    }
    
    // No longer check for wave completion here - waves are time-based now
  }
  
  void addProjectile(Component projectile) {
    currentProjectiles.add(projectile);
  }
  
  void onProjectileDestroyed(Component projectile) {
    currentProjectiles.remove(projectile);
  }
  
  void onWaveComplete() {
    // Prevent multiple calls
    if (waveCompletionInProgress) return;
    waveCompletionInProgress = true;
    
    print('DEBUG: Wave $currentWave completing...');
    
    // Stop battle music when wave ends
    SoundManager().stopBGM();
    
    // Play wave clear sound
    SoundManager().playClearSound();
    
    // Clear all remaining enemies at wave end
    final enemiesCopy = List<Component>.from(currentEnemies);
    for (final enemy in enemiesCopy) {
      enemy.removeFromParent();
    }
    currentEnemies.clear();
    
    // Clear all remaining projectiles at wave end
    final projectilesCopy = List<Component>.from(currentProjectiles);
    for (final projectile in projectilesCopy) {
      projectile.removeFromParent();
    }
    currentProjectiles.clear();
    
    // Clear all consumable drops at wave end
    consumableDropManager.clearAllDrops();
    
    // Hide countdown and show wave survived announcement
    waveAnnouncement.hideCountdown();
    waveAnnouncement.showWaveSurvived(currentWave);
    
    // Activate hero invincibility
    hero.activateInvincibility();
    
    // Regenerate shields between waves
    hero.regenerateShields();
    
    // Check if we should continue (endless mode or normal wave limit)
    final shouldShowVictory = (currentGameMode != GameMode.endless && currentWave >= maxWaves);
    
    if (shouldShowVictory) {
      // Game complete - show victory screen
      gameState = GameState.victory;
      
      // Clear all item drops when game ends
      clearAllItems();
      
      // Play victory sound (BGM already stopped above)
      SoundManager().playVictorySound();
      overlays.add('Victory');
    } else {
      // Delay shop opening until after "Wave X survived!" message (2 seconds)
      Future.delayed(const Duration(seconds: 2), () {
        if (gameState != GameState.gameOver && gameState != GameState.victory) {
          // Show shop
          gameState = GameState.shopping;
          if (!shopPanel.isMounted) {
            add(shopPanel);
          }
          // Do not reset roll count between waves; only reset on full game restart
          shopPanel.show();
          
          // Ensure stats overlay is on top by adding it after the shop panel
          if (statsOverlay.isMounted) {
            statsOverlay.removeFromParent();
          }
          add(statsOverlay);
          statsOverlay.show();
          
          // Auto refresh shop items (this counts as the first roll, so cost will be base + 1 for next roll)
          shopPanel.rollShopItems();
        }
      });
    }
  }
  
  void onShopClosed() {
    gameState = GameState.playing;
    if (shopPanel.isMounted) {
      shopPanel.removeFromParent();
    }
    // Keep stats overlay visible during gameplay - don't remove it
    startWave(currentWave + 1);
  }
  
  void onHeroDeath({String? killerType}) {
    if (gameOverSoundPlayed) return; // Prevent multiple fail sounds
    
    // Handle 1HP Challenge mode retry tokens
    if (currentGameMode == GameMode.oneHpChallenge && retryTokens > 0) {
      consumeRetryToken();
      revivePlayer();
      return;
    }
    
    gameState = GameState.gameOver;
    gameOverSoundPlayed = true;
    lastKillerType = killerType;
    
    // Clear all item drops when game ends
    clearAllItems();
    
    // Stop battle music and play fail sound
    SoundManager().stopBGM();
    SoundManager().playFailSound();
    overlays.add('GameOver');
  }
  
  void consumeRetryToken() {
    if (retryTokens > 0) {
      retryTokens--;
      // TODO: Play retry token use sound
      print('Retry token consumed! Tokens remaining: $retryTokens');
    }
  }
  
  void addRetryToken() {
    if (currentGameMode == GameMode.oneHpChallenge && retryTokens == 0) {
      retryTokens = 1; // Max one token at a time
      // TODO: Play retry token collect sound
      print('Retry token collected!');
    }
  }
  
  void revivePlayer() {
    // Restore full health
    hero.health = hero.maxHealth;
    
    // Clear nearby enemies to give player breathing room
    final heroCenterX = hero.position.x;
    final heroCenterY = hero.position.y;
    final clearRadius = 150.0; // Clear enemies within this radius
    
    final enemiesToRemove = <Component>[];
    for (final enemy in currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = (enemy.position - Vector2(heroCenterX, heroCenterY)).length;
        if (distance <= clearRadius) {
          enemiesToRemove.add(enemy);
        }
      }
    }
    
    for (final enemy in enemiesToRemove) {
      enemy.removeFromParent();
      currentEnemies.remove(enemy);
    }
    
    // Brief invincibility
    hero.activateInvincibility();
  }
  
  void pauseGame() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
      overlays.add('PauseMenu');
    }
  }
  
  void resumeGame() {
    if (gameState == GameState.paused) {
      gameState = GameState.playing;
      overlays.remove('PauseMenu');
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip game logic when paused
    if (gameState == GameState.paused) {
      return;
    }
    
    // Only update HUD during gameplay
    if (gameState == GameState.playing || gameState == GameState.shopping) {
      hud.updateHealth(hero.health);
      // hud.updateArmor(hero.shield, hero.totalShieldHP);
    }
    
    // Update stats overlay during gameplay and shopping
    if ((gameState == GameState.playing || gameState == GameState.shopping) && statsOverlay.isVisible) {
      statsOverlay.updateStats();
    }
    
    // Handle wave timing during gameplay
    if (gameState == GameState.playing && !waveCompletionInProgress) {
      waveTime += dt;
      enemySpawnTimer += dt;
      
      // Update wave timer display
      final remainingTime = (waveDuration - waveTime).clamp(0.0, waveDuration);
      // Wave timer moved to background announcement
      
      // Wave timer component removed - now integrated into wave announcement
      
      // Update wave announcement countdown
      waveAnnouncement.showCountdown(remainingTime);
      
      // Update consumable drop manager
      if (consumableDropManager.isMounted) {
        consumableDropManager.update(dt);
      }
      
      // Spawn enemies periodically using new system
      if (enemySpawnTimer >= enemySpawnInterval) {
        _spawnEnemyGroup();
        enemySpawnTimer = 0.0;
      }
      
      // Check if wave is complete
      if (waveTime >= waveDuration) {
        onWaveComplete();
      }
    }
  }
  
  void _spawnEnemyGroup() {
    int spawnCount;
    
    if (currentGameMode == GameMode.endless && currentWave > 5) {
      // For endless mode waves 6+, use wave 5 spawn count plus scaling
      spawnCount = WaveConfig.instance.getSpawnCount(5);
      // Add 1 extra enemy per spawn every 5 waves beyond wave 5
      final extraWaveGroups = (currentWave - 5) ~/ 5; // Every 5 waves
      spawnCount += extraWaveGroups;
    } else {
      // For normal mode or endless mode waves 1-5, use normal wave configuration
      spawnCount = WaveConfig.instance.getSpawnCount(currentWave);
    }
    
    // Spawn multiple enemies based on spawn_count
    for (int i = 0; i < spawnCount; i++) {
      _spawnRandomEnemy();
    }
  }
  
  void _spawnRandomEnemy() {
    final random = Random();
    WaveData? waveData;
    List<String> availableEnemyTypes = [];
    
    if (currentGameMode == GameMode.endless && currentWave > 5) {
      // For endless mode waves 6+, use wave 5 configuration as base
      waveData = WaveConfig.instance.getWaveData(5);
      
      // Add new enemy types based on infinite mode spawn thresholds
      final infiniteSpawns = WaveConfig.instance.infiniteSpawns;
      if (infiniteSpawns != null) {
        final newEnemyTypes = infiniteSpawns.getAvailableEnemyTypes(currentWave);
        
        // Combine base wave 5 enemies with new infinite mode enemies
        availableEnemyTypes = [...(waveData?.enemyTypes ?? []), ...newEnemyTypes];
      } else {
        availableEnemyTypes = waveData?.enemyTypes ?? [];
      }
    } else {
      // For normal mode or endless mode waves 1-5, use normal wave configuration
      waveData = WaveConfig.instance.getWaveData(currentWave);
      availableEnemyTypes = waveData?.enemyTypes ?? [];
    }
    
    Component Function() enemyFactory;
    
    if (availableEnemyTypes.isNotEmpty) {
      String selectedEnemyType;
      
      if (currentGameMode == GameMode.endless && currentWave > 5) {
        // For infinite mode, use equal weights for all available enemies
        selectedEnemyType = availableEnemyTypes[random.nextInt(availableEnemyTypes.length)];
      } else {
        // Use wave configuration weights for normal mode
        final totalWeight = waveData!.spawnWeights.values.fold(0.0, (sum, weight) => sum + weight);
        final randomValue = random.nextDouble() * totalWeight;
        
        double currentWeight = 0.0;
        selectedEnemyType = availableEnemyTypes.first;
        
        for (final enemyType in availableEnemyTypes) {
          currentWeight += waveData.spawnWeights[enemyType] ?? 0.0;
          if (randomValue <= currentWeight) {
            selectedEnemyType = enemyType;
            break;
          }
        }
      }
      
      // Create enemy based on selected type
      enemyFactory = _createEnemyFactory(selectedEnemyType);
    } else {
      // Fallback to old logic if config not available
      enemyFactory = _createFallbackEnemy(random);
    }
    
    _spawnEnemyAtRandomEdge(enemyFactory, random);
  }
  
  Component Function() _createEnemyFactory(String enemyType) {
    switch (enemyType) {
      case 'chaser':
        return EnemyChaser.new;
      case 'shooter':
        return EnemyShooter.new;
      case 'shielded_chaser':
        return ShieldedChaser.new;
      case 'swarmer':
        return Swarmer.new;
      case 'bomber':
        return Bomber.new;
      case 'sniper':
        return Sniper.new;
      case 'splitter':
        return Splitter.new;
      case 'mine_layer':
        return MineLayer.new;
      default:
        return EnemyChaser.new; // Fallback
    }
  }
  
  Component Function() _createFallbackEnemy(Random random) {
    switch (currentWave) {
      case 1:
        return EnemyChaser.new;
      case 2:
        return EnemyShooter.new;
      case 3:
        return ShieldedChaser.new;
      default:
        final enemyType = random.nextInt(3);
        switch (enemyType) {
          case 0:
            return EnemyChaser.new;
          case 1:
            return EnemyShooter.new;
          case 2:
            return ShieldedChaser.new;
          default:
            return EnemyChaser.new;
        }
    }
  }
  
  void _updateArenaDimensions(double screenWidth, double screenHeight) {
    // Update display config with new dimensions
    DisplayConfig.instance.updateArenaDimensions(screenWidth, screenHeight);
    
    // Update camera if needed
    if (isMounted) {
      camera.viewfinder.visibleGameSize = Vector2(arenaWidth, arenaHeight);
      
      // Update background size and position if it exists
      if (backgroundArena.isMounted) {
        backgroundArena.size = Vector2(arenaWidth, arenaHeight);
        backgroundArena.position = Vector2(arenaWidth / 2, arenaHeight / 2);
      }
    }
  }
  
  /// Handle display configuration changes for dynamic responsiveness
  void _onDisplayConfigChanged(DisplaySettings oldSettings, DisplaySettings newSettings) {
    print('Game responding to display config change: ${newSettings.arenaWidth.toInt()}x${newSettings.arenaHeight.toInt()}');
    
    // Update background
    if (backgroundArena.isMounted) {
      backgroundArena.size = Vector2(newSettings.arenaWidth, newSettings.arenaHeight);
      backgroundArena.position = Vector2(newSettings.arenaWidth / 2, newSettings.arenaHeight / 2);
    }
    
    // Update camera
    camera.viewfinder.visibleGameSize = Vector2(newSettings.arenaWidth, newSettings.arenaHeight);
    
    // Update HUD layout for new screen size
    if (hud.isMounted) {
      hud.rebuildHudLayout();
    }
    
    // Update stats overlay layout for new screen size
    if (statsOverlay.isMounted) {
      statsOverlay.rebuildLayout();
    }
  }

  // Method to be called from main app when screen size is known
  void updateScreenDimensions(double screenWidth, double screenHeight) {
    _updateArenaDimensions(screenWidth, screenHeight);
  }
  
  // No-stay zone utility - pushes enemies away from edges (10% margin)
  Vector2 getNoStayZoneForce(Vector2 position) {
    final noStayMargin = 0.1; // 10% of arena dimensions
    final marginX = arenaWidth * noStayMargin;
    final marginY = arenaHeight * noStayMargin;
    
    Vector2 force = Vector2.zero();
    
    // Left edge push
    if (position.x < marginX) {
      final pushStrength = (marginX - position.x) / marginX;
      force.x += pushStrength * 200.0; // Base push force
    }
    
    // Right edge push
    if (position.x > arenaWidth - marginX) {
      final pushStrength = (position.x - (arenaWidth - marginX)) / marginX;
      force.x -= pushStrength * 200.0;
    }
    
    // Top edge push
    if (position.y < marginY) {
      final pushStrength = (marginY - position.y) / marginY;
      force.y += pushStrength * 200.0;
    }
    
    // Bottom edge push
    if (position.y > arenaHeight - marginY) {
      final pushStrength = (position.y - (arenaHeight - marginY)) / marginY;
      force.y -= pushStrength * 200.0;
    }
    
    return force;
  }
  
  void clearAllItems() {
    // Remove all item drops from the game
    final componentsToRemove = <Component>[];
    
    // Find all ItemPickup components in the game
    for (final component in children) {
      if (component.runtimeType.toString().contains('ItemPickup') || 
          component.runtimeType.toString().contains('HealthShard') ||
          component.runtimeType.toString().contains('RetryToken')) {
        componentsToRemove.add(component);
      }
    }
    
    // Remove all found item components
    for (final component in componentsToRemove) {
      if (component.isMounted) {
        component.removeFromParent();
      }
    }
  }
  
  void showEffectNotification(String effectType, double value, double duration) {
    // Simple console output for now - could be enhanced with UI notifications
    print('Effect applied: $effectType (${value.toStringAsFixed(1)}) for ${duration.toStringAsFixed(1)}s');
  }

  // Map last killer type to a flavorful death message
  String get lastDeathMessage {
    final type = lastKillerType;
    switch (type) {
      case 'chaser':
        return '💥 A Chaser rammed you down.';
      case 'shooter':
        return '🔫 A Shooter\'s bullet found its mark.';
      case 'shielded_chaser':
        return '🛡️ A Shielded Chaser broke through your defenses.';
      case 'swarmer':
        return '🐝 A Swarmer swarmed the last of your HP.';
      case 'bomber':
        return '💣 A Bomber\'s explosion ended your run.';
      case 'sniper':
        return '🎯 A Sniper\'s shot was lethal.';
      case 'splitter':
        return '🧩 A Splitter crashed into you for the final blow.';
      case 'mine_layer':
        return '🧨 A Mine exploded beneath you.';
      default:
        return '💀 The shapes have claimed another hero...';
    }
  }
} 
```

I'll make sure the lints are clean for the game file, then mark the persistence task complete.

- I added the coin emoji to the REROLL button:
  - Initial: `REROLL (10 🪙)`
  - Dynamic updates: `REROLL ($nextRollCost 🪙)` and on purchase `REROLL ($rollCost 🪙)`. Free rolls still show `REROLL (FREE)`.

- I stopped the reroll cost from resetting after each wave:
  - Removed the per-wave reset call in `onWaveComplete` before showing the shop.
  - Reroll count now resets only on full game start/restart paths where it already calls `resetForNewWave()`.

Please build and test:
- Verify REROLL shows the emoji and increments cost across waves.
- Ensure the cost resets only when starting a brand-new run.

- I finished adding the emoji to REROLL and made reroll cost persist across waves.

