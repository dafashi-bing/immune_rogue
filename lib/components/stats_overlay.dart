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