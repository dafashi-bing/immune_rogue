import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/circle_rouge_game.dart';
import 'ui/responsive_layout.dart';
import 'hero.dart' as hero_lib;

class HudComponent extends Component with HasGameRef<CircleRougeGame>, ResponsiveMixin {
  late RectangleComponent healthBarBg;
  late RectangleComponent healthBarFill;
  // late RectangleComponent armorBarBg;
  // late RectangleComponent armorBarFill;
  late TextComponent waveIndicator;
  late TextComponent healthText;
  // late TextComponent armorText;
  // Circular skill button components
  late CircleComponent skillButton;
  late TextComponent skillHotkeyText;
  late TextComponent abilityNameText; // Text inside the button
  late CircularProgressComponent cooldownProgress;
  late SkillButtonGlowComponent skillButtonGlow;
  SpriteComponent? abilityIcon; // Icon for ability button
  
  // Ultimate ability button components
  late CircleComponent ultimateButton;
  late TextComponent ultimateHotkeyText;
  late TextComponent ultimateNameText; // Text inside the button
  late UltimateChargeFillComponent ultimateChargeFill;
  late UltimateReadyGlowComponent ultimateReadyGlow; // Spinning glow when ready
  late SkillButtonGlowComponent ultimateButtonGlow; // Pulsing glow when ready
  SpriteComponent? ultimateIcon; // Icon for ultimate button
  
  // WASD button components
  late Map<String, RectangleComponent> wasdButtons;
  late Map<String, TextComponent> wasdTexts;
  
  // WASD button state tracking
  final Set<String> _pressedKeys = <String>{};
  
  // Animation state for effects
  bool _isShowingHitEffect = false;
  bool _isShowingReadyEffect = false;
  double _hitEffectTimer = 0.0;
  double _readyEffectTimer = 0.0;
  bool _wasOnCooldown = false; // Track cooldown state changes
  
  // Ultimate ready effect state
  bool _isShowingUltimateReadyEffect = false;
  double _ultimateReadyEffectTimer = 0.0;
  double _ultimateSpinTimer = 0.0; // Timer for spinning glow effect
  int _previousUltimateCharge = 0; // Track previous charge to detect when it becomes ready
  
  static const double hitEffectDuration = 0.2; // 200ms hit effect
  static const double readyEffectDuration = 1.2; // 1200ms ready effect for multiple flashes
  // waveTimerText removed - using centered countdown instead
  // Background components removed
  
  // Base sizes for responsive scaling - ZZZ style compact bars
  static const double baseBarWidth = 120.0; // Much shorter, just enough for HP text
  static const double baseHealthBarHeight = 20; // Keep height reasonable
  static const double baseMargin = 20.0; // Increased from 12
  
  // Percentage-based positioning constants - increased margins
  static const double hudLeftMarginPercent = 3.5; // Increased from 2.0
  static const double hudTopMarginPercent = 3.5;  // Increased from 2.0
  static const double centerPanelWidthPercent = 25.0; // Reduced from 27.5 for cleaner look
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Initialize responsive behavior
    initializeResponsive();
    
    // Initialize animation state
    _wasOnCooldown = false;
    
    // Get responsive sizes
    final barWidth = ResponsiveLayout.getScaledWidth(baseBarWidth, null);
    final healthBarHeight = ResponsiveLayout.getScaledHeight(baseHealthBarHeight, null);
    
    // Calculate positions using percentage-based layout
    final hudPosition = ResponsiveLayout.getPercentagePosition(
      hudLeftMarginPercent, 
      hudTopMarginPercent, 
      screenSize
    );
    
    // HUD backgrounds removed to fix scaling issues
    
    // Health bar background with enhanced styling
    healthBarBg = RectangleComponent(
      size: Vector2(barWidth, healthBarHeight),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ).createShader(Rect.fromLTWH(0, 0, barWidth, healthBarHeight)),
      position: Vector2(hudPosition.x, hudPosition.y),
    );
    add(healthBarBg);
    
    // Health bar border
    final healthBarBorder = RectangleComponent(
      size: Vector2(barWidth, healthBarHeight),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4A9EFF).withValues(alpha: 0.4),
      position: Vector2(hudPosition.x, hudPosition.y),
    );
    add(healthBarBorder);
    
    // Health bar fill with enhanced gradient effect
    healthBarFill = RectangleComponent(
      size: Vector2(barWidth, healthBarHeight),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF66BB6A),
          ],
        ).createShader(Rect.fromLTWH(0, 0, barWidth, healthBarHeight)),
      position: Vector2(hudPosition.x, hudPosition.y),
    );
    add(healthBarFill);
    
    // Health text with enhanced styling - removed emoji, added cool effects
    healthText = TextComponent(
      text: '100/100 HP',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: ResponsiveLayout.getResponsiveFontSize(16.0, screenSize),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 6,
            ),
            Shadow(
              color: Color(0xFF4CAF50),
              blurRadius: 3,
            ),
            Shadow(
              color: Color(0xFFFFFFFF),
              blurRadius: 1,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(hudPosition.x + barWidth / 2, hudPosition.y + healthBarHeight / 2),
    );
    add(healthText);
    
    // Armor bar background (positioned below health bar with increased spacing)
    // final armorBarHeight = ResponsiveLayout.getScaledHeight(12.8, null); // Reduced by 20% from 16.0
    // final armorBarSpacing = 5.0; // Increased spacing between health and armor bars
    // armorBarBg = RectangleComponent(
    //   size: Vector2(barWidth, armorBarHeight),
    //   paint: Paint()
    //     ..shader = const LinearGradient(
    //       colors: [
    //         Color(0xFF2A1A2A),
    //         Color(0xFF3A2A3A),
    //       ],
    //     ).createShader(Rect.fromLTWH(0, 0, barWidth, armorBarHeight)),
    //   position: Vector2(hudPosition.x, hudPosition.y + healthBarHeight + armorBarSpacing),
    // );
    // add(armorBarBg);
    
    // // Armor bar border
    // final armorBarBorder = RectangleComponent(
    //   size: Vector2(barWidth, armorBarHeight),
    //   paint: Paint()
    //     ..color = Colors.transparent
    //     ..style = PaintingStyle.stroke
    //     ..strokeWidth = 2
    //     ..color = const Color(0xFF9C27B0).withValues(alpha: 0.4),
    //   position: Vector2(hudPosition.x, hudPosition.y + healthBarHeight + armorBarSpacing),
    // );
    // add(armorBarBorder);
    
    // // Armor bar fill
    // armorBarFill = RectangleComponent(
    //   size: Vector2(0, armorBarHeight), // Start with 0 width
    //   paint: Paint()
    //     ..shader = const LinearGradient(
    //       colors: [
    //         Color(0xFF9C27B0),
    //         Color(0xFFBA68C8),
    //       ],
    //     ).createShader(Rect.fromLTWH(0, 0, barWidth, armorBarHeight)),
    //   position: Vector2(hudPosition.x, hudPosition.y + healthBarHeight + armorBarSpacing),
    // );
    // add(armorBarFill);
    
    // // Armor text
    // armorText = TextComponent(
    //   text: '0/0 Armor',
    //   textRenderer: TextPaint(
    //     style: TextStyle(
    //       color: Colors.white,
    //       fontSize: ResponsiveLayout.getResponsiveFontSize(12.0, screenSize),
    //       fontWeight: FontWeight.w700,
    //       letterSpacing: 0.5,
    //       shadows: const [
    //         Shadow(
    //           color: Colors.black,
    //           blurRadius: 4,
    //         ),
    //         Shadow(
    //           color: Color(0xFF9C27B0),
    //           blurRadius: 2,
    //         ),
    //       ],
    //     ),
    //   ),
    //   anchor: Anchor.center,
    //   position: Vector2(hudPosition.x + barWidth / 2, hudPosition.y + healthBarHeight + armorBarSpacing + armorBarHeight / 2),
    // );
    // add(armorText);
    
    // Circular skill button (ZZZ style) - positioned at bottom right with responsive margins
    final skillButtonRadius = ResponsiveLayout.getScaledWidth(25.0, null); // Responsive button radius
    final marginX = ResponsiveLayout.getScaledWidth(130.0, null); // Responsive horizontal margin (30 + 100 extra)
    final marginY = ResponsiveLayout.getScaledHeight(60.0, null); // Responsive vertical margin for hotkey text
    final skillButtonX = screenSize.x - skillButtonRadius - marginX; // Bottom right with responsive margin
    final skillButtonY = screenSize.y - skillButtonRadius - marginY; // Bottom with responsive margin
    
    skillButton = CircleComponent(
      radius: skillButtonRadius,
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF4A9EFF),
      position: Vector2(skillButtonX, skillButtonY),
      anchor: Anchor.center,
    );
    add(skillButton);
    
    // Hotkey text below the circular button
    skillHotkeyText = TextComponent(
      text: 'K',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: ResponsiveLayout.getResponsiveFontSize(14.0, screenSize),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 3,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(skillButtonX, skillButtonY + skillButtonRadius + ResponsiveLayout.getScaledHeight(15.0, null)),
    );
    add(skillHotkeyText);
    
    // Ability name text inside the button
    abilityNameText = TextComponent(
      text: 'DASH', // Default, will be updated based on hero
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF4A9EFF),
          fontSize: ResponsiveLayout.getResponsiveFontSize(10.0, screenSize),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(skillButtonX, skillButtonY),
    );
    add(abilityNameText);
    
    // Circular progress bar for cooldown (initially invisible)
    cooldownProgress = CircularProgressComponent(
      radius: skillButtonRadius,
      position: Vector2(skillButtonX, skillButtonY),
      anchor: Anchor.center,
    );
    add(cooldownProgress);
    
    // Glow effect for ready state (initially invisible)
    skillButtonGlow = SkillButtonGlowComponent(
      radius: skillButtonRadius,
      position: Vector2(skillButtonX, skillButtonY),
      anchor: Anchor.center,
    );
    add(skillButtonGlow);
    
    // Load ability icon if available
    _loadAbilityIcon(skillButtonX, skillButtonY, skillButtonRadius);
    
    // Ultimate ability button - positioned to the right of K button
    final buttonSpacing = ResponsiveLayout.getScaledWidth(15.0, null); // Spacing between buttons
    final ultimateButtonX = skillButtonX + (skillButtonRadius * 2) + buttonSpacing;
    final ultimateButtonY = skillButtonY; // Same Y position as skill button
    
    ultimateButton = CircleComponent(
      radius: skillButtonRadius,
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.grey.withValues(alpha: 0.5),
      position: Vector2(ultimateButtonX, ultimateButtonY),
      anchor: Anchor.center,
    );
    add(ultimateButton);
    
    // Ultimate name text inside the button
    ultimateNameText = TextComponent(
      text: 'ULT', // Default, will be updated based on hero
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF4A9EFF),
          fontSize: ResponsiveLayout.getResponsiveFontSize(10.0, screenSize),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(ultimateButtonX, ultimateButtonY),
    );
    add(ultimateNameText);
    
    // Hotkey text below the ultimate button
    ultimateHotkeyText = TextComponent(
      text: 'L',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: ResponsiveLayout.getResponsiveFontSize(14.0, screenSize),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 3,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(ultimateButtonX, ultimateButtonY + skillButtonRadius + ResponsiveLayout.getScaledHeight(15.0, null)),
    );
    add(ultimateHotkeyText);
    
    // Charge fill component for ultimate (shows progressive fill)
    ultimateChargeFill = UltimateChargeFillComponent(
      radius: skillButtonRadius,
      position: Vector2(ultimateButtonX, ultimateButtonY),
      anchor: Anchor.center,
    );
    add(ultimateChargeFill);
    
    // Spinning glow effect for ultimate when ready (similar to cooldown progress but continuous)
    ultimateReadyGlow = UltimateReadyGlowComponent(
      radius: skillButtonRadius,
      position: Vector2(ultimateButtonX, ultimateButtonY),
      anchor: Anchor.center,
    );
    add(ultimateReadyGlow);
    
    // Glow effect for ultimate ready state (similar to skill button glow)
    ultimateButtonGlow = SkillButtonGlowComponent(
      radius: skillButtonRadius,
      position: Vector2(ultimateButtonX, ultimateButtonY),
      anchor: Anchor.center,
    );
    add(ultimateButtonGlow);
    
    // Load ultimate icon if available
    _loadUltimateIcon(ultimateButtonX, ultimateButtonY, skillButtonRadius);
    
    // Old ability cooldown components removed - now using circular button
    
    // Update ability name based on hero
    updateAbilityName();
    updateUltimateName();
    
    // Create WASD button layout on the left side
    _createWASDButtons();
    
    // Center panel backgrounds removed to fix scaling issues
    
    // Wave indicator with enhanced styling - removed emoji, added cool effects
    waveIndicator = TextComponent(
      text: 'WAVE 1',
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF4A9EFF),
          fontSize: ResponsiveLayout.getResponsiveFontSize(22.0, screenSize),
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          shadows: const [
            Shadow(
              color: Color(0xFF4A9EFF),
              blurRadius: 12,
            ),
            Shadow(
              color: Color(0xFF9C27B0),
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
      position: ResponsiveLayout.getAnchoredPosition(
        AnchorType.topCenter, 
        Vector2(0, hudPosition.y + 8), 
        screenSize
      ),
    );
    add(waveIndicator);
    
    // Wave timer removed - using centered countdown in background instead
  }
  
  void updateHealth(double health) {
    final maxHealth = gameRef.hero.maxHealth;
    final healthPercent = health / maxHealth;
    final barWidth = ResponsiveLayout.getScaledWidth(baseBarWidth, null);
    healthBarFill.size.x = barWidth * healthPercent;
    healthText.text = '${health.round()}/${maxHealth.round()} HP';
    
    // Change color based on health
    if (healthPercent > 0.6) {
      healthBarFill.paint.color = const Color(0xFF4CAF50); // Green
    } else if (healthPercent > 0.3) {
      healthBarFill.paint.color = const Color(0xFFFF9800); // Orange
    } else {
      healthBarFill.paint.color = const Color(0xFFF44336); // Red
    }
  }
  
  // void updateArmor(double currentArmor, double maxArmor) {
  //   final barWidth = ResponsiveLayout.getScaledWidth(baseBarWidth, null);
    
  //   if (maxArmor > 0) {
  //     final armorPercent = (currentArmor / maxArmor).clamp(0.0, 1.0);
  //     armorBarFill.size.x = barWidth * armorPercent;
  //     armorText.text = '${currentArmor.round()}/${maxArmor.round()} Armor';
      
  //     // Show armor components
  //     armorBarBg.opacity = 1.0;
  //     armorBarFill.opacity = 1.0;
  //     // armorText.opacity = 1.0;
  //   } else {
  //     // Hide armor components when no armor
  //     armorBarFill.size.x = 0;
  //     armorText.text = '';
  //     armorBarBg.opacity = 0.0;
  //     armorBarFill.opacity = 0.0;
  //     // armorText.opacity = 0.0;
  //   }
  // }
  
  void updateDashCooldown(double cooldownPercent) {
    // Delegate to the main ability cooldown method
    // Since we only have one circular skill button, we'll use it for both dash and ability
    updateAbilityCooldown(cooldownPercent, 0.0);
  }
  
  // Method to trigger hit effect when ability is used
  void triggerHitEffect() {
    _isShowingHitEffect = true;
    _hitEffectTimer = 0.0;
  }
  
  // Enhanced method to update circular skill button cooldown
  void updateAbilityCooldown(double cooldownPercent, double remainingSeconds) {
    // Use hero color for skill button
    final heroColor = gameRef.hero.heroData.color;
    
    // Detect when ability comes back from cooldown
    final isOnCooldown = cooldownPercent < 1.0;
    if (_wasOnCooldown && !isOnCooldown) {
      // Ability just became ready - trigger ready effect
      _isShowingReadyEffect = true;
      _readyEffectTimer = 0.0;
      skillButtonGlow.showGlow(heroColor);
    }
    _wasOnCooldown = isOnCooldown;
    
    if (cooldownPercent >= 1.0) {
      // Ability ready - filled circle with hero color, bright colored border with effects
      // Faster flashing: 24 Hz instead of 8 Hz, and multiple cycles
      final readyPulse = _isShowingReadyEffect ? (1.0 + 0.4 * sin(_readyEffectTimer * 24.0)) : 1.0;
      final readyOpacity = readyPulse.clamp(0.5, 1.0);
      
      // Fill button with hero color
      skillButton.paint = Paint()
        ..color = heroColor.withValues(alpha: readyOpacity)
        ..style = PaintingStyle.fill
        ..strokeWidth = 0;
      
      // Show hotkey text in bright color
      skillHotkeyText.textRenderer = TextPaint(
        style: TextStyle(
          color: heroColor,
          fontSize: ResponsiveLayout.getResponsiveFontSize(14.0, gameRef.size),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 3,
            ),
            Shadow(
              color: heroColor,
              blurRadius: 6,
            ),
          ],
        ),
      );
      
      // Hide progress bar when ready
      cooldownProgress.updateProgress(1.0);
      
      // Update icon opacity to match button opacity
      if (abilityIcon != null && abilityIcon!.isMounted) {
        abilityIcon!.opacity = readyOpacity;
      }
      
      // Hide ability name text when icon is present
      if (abilityIcon == null || !abilityIcon!.isMounted) {
        // Only show text if no icon
        final nameOpacity = _isShowingReadyEffect ? readyOpacity : 1.0;
        abilityNameText.textRenderer = TextPaint(
          style: TextStyle(
            color: heroColor.withValues(alpha: nameOpacity),
            fontSize: ResponsiveLayout.getResponsiveFontSize(10.0, gameRef.size),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              const Shadow(
                color: Colors.black,
                blurRadius: 2,
              ),
              if (_isShowingReadyEffect) Shadow(
                color: heroColor,
                blurRadius: 4,
              ),
            ],
          ),
        );
      } else {
        abilityNameText.text = '';
      }
    } else {
      // On cooldown - gray fill with border, progress effect and hit effect
      final hitFlash = _isShowingHitEffect ? (1.0 - _hitEffectTimer / hitEffectDuration) * 0.8 : 0.0;
      final opacity = (0.5 + hitFlash).clamp(0.0, 1.0);
      
      // Fill button with gray at reduced opacity
      skillButton.paint = Paint()
        ..color = Colors.grey.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.fill
        ..strokeWidth = 0;
      
      // Show hotkey text in gray
      skillHotkeyText.textRenderer = TextPaint(
        style: TextStyle(
          color: Colors.grey.withValues(alpha: 0.7),
          fontSize: ResponsiveLayout.getResponsiveFontSize(14.0, gameRef.size),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 3,
            ),
          ],
        ),
      );
      
      // Update circular progress bar
      cooldownProgress.updateProgress(cooldownPercent);
      
      // Update icon opacity to match button opacity
      if (abilityIcon != null && abilityIcon!.isMounted) {
        abilityIcon!.opacity = opacity * 0.5; // Match button opacity
      }
      
      // Hide ability name text when icon is present
      if (abilityIcon == null || !abilityIcon!.isMounted) {
        // Only show text if no icon
        abilityNameText.textRenderer = TextPaint(
          style: TextStyle(
            color: Colors.grey.withValues(alpha: 0.6),
            fontSize: ResponsiveLayout.getResponsiveFontSize(10.0, gameRef.size),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: const [
              Shadow(
                color: Colors.black,
                blurRadius: 2,
              ),
            ],
          ),
        );
      } else {
        abilityNameText.text = '';
      }
    }
  }
  
  // updateWaveTimer removed - using centered countdown instead
  
  void updateWave(int wave) {
    waveIndicator.text = 'WAVE $wave';
  }
  
  void updateAbilityName() {
    // Update ability name based on hero's ability type
    final abilityType = gameRef.hero.heroData.ability.type;
    String displayName;
    
    switch (abilityType) {
      case 'dash_damage':
        displayName = 'DASH';
        break;
      case 'piercing_shot':
        displayName = 'SHOT';
        break;
      case 'area_stun':
        displayName = 'STUN';
        break;
      case 'radial_burst':
        displayName = 'BURST';
        break;
      case 'area_field':
        displayName = 'FIELD';
        break;
      case 'resonance_knockback':
        displayName = 'WAVE';
        break;
      default:
        displayName = 'SKILL';
    }
    
    abilityNameText.text = displayName;
  }
  
  void updateUltimateName() {
    // Update ultimate name based on hero's ultimate
    final ultimate = gameRef.hero.heroData.ultimate;
    String displayName = 'ULT'; // Default fallback
    
    if (ultimate != null && ultimate.name.isNotEmpty) {
      // Use the ultimate name from config
      displayName = ultimate.name.toUpperCase();
    }
    
    ultimateNameText.text = displayName;
  }
  
  // Load ability icon with color replacement (black to white)
  Future<void> _loadAbilityIcon(double x, double y, double radius) async {
    try {
      final iconPath = gameRef.hero.heroData.ability.iconPath;
      if (iconPath == null || iconPath.isEmpty) {
        print('[HUD] No icon path for ability');
        return;
      }
      
      print('[HUD] Loading ability icon from: $iconPath');
      
      // Remove existing icon if present
      if (abilityIcon != null && abilityIcon!.isMounted) {
        abilityIcon!.removeFromParent();
      }
      
      final sprite = await Sprite.load(iconPath);
      final iconSize = radius * 1.6; // Icon size - make it visible
      
      abilityIcon = ColorReplacementSpriteComponent(
        sprite: sprite,
        size: Vector2(iconSize, iconSize),
        position: Vector2(x, y),
        anchor: Anchor.center,
        sourceColor: Colors.black,
        targetColor: Colors.white,
      );
      // Add icon after button so it's on top
      add(abilityIcon!);
      
      // Hide ability name text when icon is present
      abilityNameText.text = '';
      print('[HUD] Ability icon loaded successfully');
    } catch (e) {
      print('[HUD] Could not load ability icon, error: $e');
      abilityIcon = null;
    }
  }
  
  // Load ultimate icon with color replacement (black to white)
  Future<void> _loadUltimateIcon(double x, double y, double radius) async {
    try {
      final ultimate = gameRef.hero.heroData.ultimate;
      final iconPath = ultimate?.iconPath;
      if (iconPath == null || iconPath.isEmpty) {
        print('[HUD] No icon path for ultimate');
        return;
      }
      
      print('[HUD] Loading ultimate icon from: $iconPath');
      
      // Remove existing icon if present
      if (ultimateIcon != null && ultimateIcon!.isMounted) {
        ultimateIcon!.removeFromParent();
      }
      
      final sprite = await Sprite.load(iconPath);
      final iconSize = radius * 1.6; // Icon size - make it visible
      
      ultimateIcon = ColorReplacementSpriteComponent(
        sprite: sprite,
        size: Vector2(iconSize, iconSize),
        position: Vector2(x, y),
        anchor: Anchor.center,
        sourceColor: Colors.black,
        targetColor: Colors.white,
      );
      // Add icon after button so it's on top
      add(ultimateIcon!);
      
      // Hide ultimate name text when icon is present
      ultimateNameText.text = '';
      print('[HUD] Ultimate icon loaded successfully');
    } catch (e) {
      print('[HUD] Could not load ultimate icon, error: $e');
      ultimateIcon = null;
    }
  }
  
  // Public method to reload icons (called after hero is available)
  Future<void> reloadIcons() async {
    try {
      // Wait a frame to ensure hero is fully initialized
      await Future.delayed(Duration.zero);
      
      final skillButtonRadius = ResponsiveLayout.getScaledWidth(25.0, null);
      final marginX = ResponsiveLayout.getScaledWidth(130.0, null);
      final marginY = ResponsiveLayout.getScaledHeight(60.0, null);
      final skillButtonX = screenSize.x - skillButtonRadius - marginX;
      final skillButtonY = screenSize.y - skillButtonRadius - marginY;
      
      final buttonSpacing = ResponsiveLayout.getScaledWidth(15.0, null);
      final ultimateButtonX = skillButtonX + (skillButtonRadius * 2) + buttonSpacing;
      final ultimateButtonY = skillButtonY;
      
      print('[HUD] Loading ability icon...');
      await _loadAbilityIcon(skillButtonX, skillButtonY, skillButtonRadius);
      print('[HUD] Loading ultimate icon...');
      await _loadUltimateIcon(ultimateButtonX, ultimateButtonY, skillButtonRadius);
      print('[HUD] Icons loaded. abilityIcon: ${abilityIcon != null}, ultimateIcon: ${ultimateIcon != null}');
    } catch (e) {
      print('[HUD] Error in reloadIcons: $e');
    }
  }
  
  void _createWASDButtons() {
    wasdButtons = <String, RectangleComponent>{};
    wasdTexts = <String, TextComponent>{};
    
    // Button dimensions (responsive)
    final buttonSize = ResponsiveLayout.getScaledWidth(35.0, null);
    final buttonSpacing = ResponsiveLayout.getScaledWidth(5.0, null);
    
    // Position on left side with responsive margins
    final leftMargin = ResponsiveLayout.getScaledWidth(30.0, null);
    final bottomMargin = ResponsiveLayout.getScaledHeight(80.0, null);
    
    // Calculate base position (bottom-left area)
    final baseX = leftMargin;
    final baseY = screenSize.y - bottomMargin;
    
    // WASD layout positions (W on top, ASD on bottom row)
    final Map<String, Vector2> buttonPositions = {
      'W': Vector2(baseX + buttonSize + buttonSpacing, baseY - buttonSize - buttonSpacing), // Top center
      'A': Vector2(baseX, baseY), // Bottom left
      'S': Vector2(baseX + buttonSize + buttonSpacing, baseY), // Bottom center
      'D': Vector2(baseX + (buttonSize + buttonSpacing) * 2, baseY), // Bottom right
    };
    
    // Create each button
    for (final entry in buttonPositions.entries) {
      final key = entry.key;
      final position = entry.value;
      
      // Create button background
      final button = RectangleComponent(
        size: Vector2.all(buttonSize),
        paint: Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.grey.withValues(alpha: 0.4),
        position: position,
      );
      wasdButtons[key] = button;
      add(button);
      
      // Create button text
      final text = TextComponent(
        text: key,
        textRenderer: TextPaint(
          style: TextStyle(
            color: Colors.grey.withValues(alpha: 0.6),
            fontSize: ResponsiveLayout.getResponsiveFontSize(14.0, screenSize),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        anchor: Anchor.center,
        position: position + Vector2.all(buttonSize / 2), // Center in button
      );
      wasdTexts[key] = text;
      add(text);
    }
  }
  
  /// Update WASD button states based on pressed keys
  void updateWASDButtons(Set<String> pressedKeys) {
    // Update our internal state
    _pressedKeys.clear();
    _pressedKeys.addAll(pressedKeys);
    
    // Get hero color to match ability button
    final heroColor = gameRef.hero.heroData.color;
    
    // Update each button's appearance
    for (final entry in wasdButtons.entries) {
      final key = entry.key;
      final button = entry.value;
      final text = wasdTexts[key]!;
      final isPressed = _pressedKeys.contains(key);
      
      if (isPressed) {
        // Button is pressed - light up with hero color
        button.paint = Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = heroColor;
        
        text.textRenderer = TextPaint(
          style: TextStyle(
            color: heroColor,
            fontSize: ResponsiveLayout.getResponsiveFontSize(14.0, gameRef.size),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: heroColor,
                blurRadius: 4,
              ),
            ],
          ),
        );
      } else {
        // Button is not pressed - default state
        button.paint = Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.grey.withValues(alpha: 0.4);
        
        text.textRenderer = TextPaint(
          style: TextStyle(
            color: Colors.grey.withValues(alpha: 0.6),
            fontSize: ResponsiveLayout.getResponsiveFontSize(14.0, gameRef.size),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        );
      }
    }
  }
  
  void updateUltimateCharge(int charge, int maxCharge) {
    final chargePercent = charge / maxCharge;
    final heroColor = gameRef.hero.heroData.color;
    final isFullyCharged = charge >= maxCharge;
    
    // Detect when ultimate becomes ready
    if (_previousUltimateCharge < maxCharge && charge >= maxCharge) {
      // Ultimate just became ready - trigger ready effect
      _isShowingUltimateReadyEffect = true;
      _ultimateReadyEffectTimer = 0.0;
      ultimateButtonGlow.showGlow(heroColor);
    }
    _previousUltimateCharge = charge;
    
    // Update button opacity and appearance
    if (isFullyCharged) {
      // Fully charged - filled circle with hero color, blinking effect
      // Faster flashing: 24 Hz instead of 8 Hz, and multiple cycles
      final readyPulse = _isShowingUltimateReadyEffect ? (1.0 + 0.4 * sin(_ultimateReadyEffectTimer * 24.0)) : 1.0;
      final readyOpacity = readyPulse.clamp(0.5, 1.0);
      
      ultimateButton.opacity = 1.0;
      ultimateButton.paint = Paint()
        ..color = heroColor.withValues(alpha: readyOpacity)
        ..style = PaintingStyle.fill
        ..strokeWidth = 0; // No stroke, just fill
      
      // Hide charge fill (button itself is filled)
      ultimateChargeFill.updateProgress(1.0, heroColor, true);
      
      // Show spinning glow effect
      ultimateReadyGlow.isVisible = true;
      ultimateReadyGlow.updateSpin(_ultimateSpinTimer, heroColor);
      
      // Update hotkey text color with blinking effect
      ultimateHotkeyText.textRenderer = TextPaint(
        style: TextStyle(
          color: heroColor,
          fontSize: ResponsiveLayout.getResponsiveFontSize(14.0, gameRef.size),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: [
            const Shadow(
              color: Colors.black,
              blurRadius: 3,
            ),
            Shadow(
              color: heroColor,
              blurRadius: 6,
            ),
          ],
        ),
      );
      
      // Update icon opacity to match button opacity
      if (ultimateIcon != null && ultimateIcon!.isMounted) {
        ultimateIcon!.opacity = readyOpacity;
      }
      
      // Hide ultimate name text when icon is present
      if (ultimateIcon == null || !ultimateIcon!.isMounted) {
        // Only show text if no icon
        final nameOpacity = _isShowingUltimateReadyEffect ? readyOpacity : 1.0;
        ultimateNameText.textRenderer = TextPaint(
          style: TextStyle(
            color: heroColor.withValues(alpha: nameOpacity),
            fontSize: ResponsiveLayout.getResponsiveFontSize(10.0, gameRef.size),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              const Shadow(
                color: Colors.black,
                blurRadius: 2,
              ),
              if (_isShowingUltimateReadyEffect) Shadow(
                color: heroColor,
                blurRadius: 4,
              ),
            ],
          ),
        );
      } else {
        ultimateNameText.text = '';
      }
    } else {
      // Not fully charged - 50% opacity, gray fill, and progressive fill with hero color
      ultimateButton.opacity = 0.5;
      ultimateButton.paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill
        ..strokeWidth = 0;
      
      // Hide spinning glow when not ready
      ultimateReadyGlow.isVisible = false;
      ultimateButtonGlow.hideGlow();
      
      // Show progressive fill with hero color (at 50% opacity to match button)
      ultimateChargeFill.updateProgress(chargePercent, heroColor.withValues(alpha: 0.5), false);
      
      // Update hotkey text color
      ultimateHotkeyText.textRenderer = TextPaint(
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: ResponsiveLayout.getResponsiveFontSize(14.0, gameRef.size),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 3,
            ),
          ],
        ),
      );
      
      // Update icon opacity to match button opacity
      if (ultimateIcon != null && ultimateIcon!.isMounted) {
        ultimateIcon!.opacity = 0.5; // Match button opacity
      }
      
      // Hide ultimate name text when icon is present
      if (ultimateIcon == null || !ultimateIcon!.isMounted) {
        // Only show text if no icon
        ultimateNameText.textRenderer = TextPaint(
          style: TextStyle(
            color: Colors.grey.withValues(alpha: 0.6),
            fontSize: ResponsiveLayout.getResponsiveFontSize(10.0, gameRef.size),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: const [
              Shadow(
                color: Colors.black,
                blurRadius: 2,
              ),
            ],
          ),
        );
      } else {
        ultimateNameText.text = '';
      }
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update ultimate charge display
    updateUltimateCharge(gameRef.hero.ultimateCharge, hero_lib.Hero.maxUltimateCharge);
    
    // Update hit effect
    if (_isShowingHitEffect) {
      _hitEffectTimer += dt;
      if (_hitEffectTimer >= hitEffectDuration) {
        _isShowingHitEffect = false;
        _hitEffectTimer = 0.0;
      }
    }
    
    // Update ready effect
    if (_isShowingReadyEffect) {
      _readyEffectTimer += dt;
      if (_readyEffectTimer >= readyEffectDuration) {
        _isShowingReadyEffect = false;
        _readyEffectTimer = 0.0;
        skillButtonGlow.hideGlow();
      }
    }
    
    // Update ultimate ready effect
    if (_isShowingUltimateReadyEffect) {
      _ultimateReadyEffectTimer += dt;
      if (_ultimateReadyEffectTimer >= readyEffectDuration) {
        _isShowingUltimateReadyEffect = false;
        _ultimateReadyEffectTimer = 0.0;
        ultimateButtonGlow.hideGlow();
      }
    }
    
    // Update spinning glow timer (continuous)
    _ultimateSpinTimer += dt;
    
    // Update glow animations
    skillButtonGlow.updateAnimation(dt);
    ultimateButtonGlow.updateAnimation(dt);
  }
  
  @override
  void onRemove() {
    cleanupResponsive();
    super.onRemove();
  }
  
  /// Rebuild the HUD layout when screen size changes
  void rebuildHudLayout() {
    // Clear existing components
    removeAll(children);
    
    // Reload the HUD with new dimensions
    onLoad();
  }
}

/// Custom circular progress component for skill cooldown
class CircularProgressComponent extends PositionComponent {
  final double radius;
  double progress = 0.0; // 0.0 to 1.0
  bool isVisible = false;
  
  CircularProgressComponent({
    required this.radius,
    required Vector2 position,
    required Anchor anchor,
  }) : super(position: position, anchor: anchor);
  
  void updateProgress(double newProgress) {
    progress = newProgress.clamp(0.0, 1.0);
    isVisible = progress < 1.0;
  }
  
  @override
  void render(Canvas canvas) {
    if (!isVisible) return;
    
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    const startAngle = -pi / 2; // Start at top
    final sweepAngle = 2 * pi * progress; // Progress arc
    
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }
}

/// Custom component for ultimate charge fill (vertical fill from bottom to top)
class UltimateChargeFillComponent extends PositionComponent {
  final double radius;
  double progress = 0.0; // 0.0 to 1.0
  Color fillColor = Colors.grey;
  bool isFullyCharged = false;
  
  UltimateChargeFillComponent({
    required this.radius,
    required Vector2 position,
    required Anchor anchor,
  }) : super(position: position, anchor: anchor);
  
  void updateProgress(double newProgress, Color color, bool fullyCharged) {
    progress = newProgress.clamp(0.0, 1.0);
    fillColor = color;
    isFullyCharged = fullyCharged;
  }
  
  @override
  void render(Canvas canvas) {
    if (progress <= 0.0 && !isFullyCharged) return;
    
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    
    // Clip to circle bounds
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.clipPath(circlePath);
    
    // Calculate fill height from bottom to top
    // In canvas coordinates: Y=0 is center, positive Y is down, negative Y is up
    final diameter = radius * 2;
    final fillHeight = diameter * progress;
    final circleBottom = radius; // Bottom of circle (positive Y, down)
    final fillTop = circleBottom - fillHeight; // Top of fill (grows upward toward center)
    
    // Draw rectangle from bottom to top
    final fillRect = Rect.fromLTRB(
      -radius,      // Left edge of circle
      fillTop,      // Top of fill rectangle (grows upward from bottom)
      radius,       // Right edge of circle
      circleBottom, // Bottom of circle (always at bottom)
    );
    
    canvas.drawRect(fillRect, paint);
  }
}

/// Custom glow effect component for skill button ready state
class SkillButtonGlowComponent extends PositionComponent {
  final double radius;
  bool isVisible = false;
  double animationTime = 0.0;
  Color glowColor = Colors.blue;
  
  SkillButtonGlowComponent({
    required this.radius,
    required Vector2 position,
    required Anchor anchor,
  }) : super(position: position, anchor: anchor);
  
  void showGlow(Color color) {
    isVisible = true;
    glowColor = color;
    animationTime = 0.0;
  }
  
  void hideGlow() {
    isVisible = false;
    animationTime = 0.0;
  }
  
  void updateAnimation(double dt) {
    if (isVisible) {
      animationTime += dt;
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (!isVisible) return;
    
    // Pulsing glow effect
    final pulse = 0.5 + 0.5 * sin(animationTime * 4.0);
    final glowRadius = radius + 8.0 + (pulse * 4.0);
    
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.3 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawCircle(Offset.zero, glowRadius, glowPaint);
  }
}

/// Custom component for ultimate ready spinning glow effect
class UltimateReadyGlowComponent extends PositionComponent {
  final double radius;
  bool isVisible = false;
  double spinTime = 0.0;
  Color glowColor = Colors.blue;
  
  UltimateReadyGlowComponent({
    required this.radius,
    required Vector2 position,
    required Anchor anchor,
  }) : super(position: position, anchor: anchor);
  
  void updateSpin(double time, Color color) {
    spinTime = time;
    glowColor = color;
  }
  
  @override
  void render(Canvas canvas) {
    if (!isVisible) return;
    
    // Continuous spinning glow effect
    // Rotate around the circle continuously - half speed
    final spinSpeed = 1.0; // Rotations per second (half of original 2.0)
    final angle = (spinTime * spinSpeed * 2 * pi) % (2 * pi);
    const startAngle = -pi / 2; // Start at top
    final currentStartAngle = startAngle + angle;
    
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    const sweepAngle = pi / 2; // 90 degree arc
    
    // Draw multiple layers for intense glow effect
    // Outer glow layer (most blurred, largest)
    final outerGlowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawArc(rect, currentStartAngle, sweepAngle, false, outerGlowPaint);
    
    // Middle glow layer
    final middleGlowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(rect, currentStartAngle, sweepAngle, false, middleGlowPaint);
    
    // Inner bright layer (sharp, most visible)
    final innerGlowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(rect, currentStartAngle, sweepAngle, false, innerGlowPaint);
  }
}

/// Custom sprite component that replaces one color with another
class ColorReplacementSpriteComponent extends SpriteComponent {
  final Color sourceColor;
  final Color targetColor;
  
  ColorReplacementSpriteComponent({
    required super.sprite,
    required super.size,
    required super.position,
    required super.anchor,
    required this.sourceColor,
    required this.targetColor,
  });
  
  @override
  void render(Canvas canvas) {
    // Use a color filter to replace black with white
    // For black icons, we use a color filter that replaces the color while preserving alpha
    canvas.save();
    
    // Use ColorFilter.mode with srcIn to replace color with white
    // srcIn: uses source alpha, destination color
    final paint = Paint()
      ..colorFilter = ColorFilter.mode(targetColor, BlendMode.srcIn);
    
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
    super.render(canvas);
    canvas.restore();
    canvas.restore();
  }
} 