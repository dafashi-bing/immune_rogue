import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/circle_rouge_game.dart';
import 'ui/responsive_layout.dart';

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
    
    // Old ability cooldown components removed - now using circular button
    
    // Update ability name based on hero
    updateAbilityName();
    
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
      // Ability ready - bright colored border with effects (faster, multiple flashes)
      final strokeWidth = _isShowingReadyEffect ? 5.0 : 3.0;
      // Faster flashing: 24 Hz instead of 8 Hz, and multiple cycles
      final readyPulse = _isShowingReadyEffect ? (1.0 + 0.4 * sin(_readyEffectTimer * 24.0)) : 1.0;
      final readyOpacity = readyPulse.clamp(0.5, 1.0);
      
      skillButton.paint = Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = heroColor.withValues(alpha: readyOpacity);
      
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
      
      // Update ability name text to match button color with flash effect
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
      // On cooldown - gray border with progress effect and hit effect
      final hitFlash = _isShowingHitEffect ? (1.0 - _hitEffectTimer / hitEffectDuration) * 0.8 : 0.0;
      final strokeWidth = _isShowingHitEffect ? 5.0 : 3.0;
      final opacity = (0.5 + hitFlash).clamp(0.0, 1.0);
      
      skillButton.paint = Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.grey.withValues(alpha: opacity);
      
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
      
      // Update ability name text for cooldown state
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
  
  @override
  void update(double dt) {
    super.update(dt);
    
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
    
    // Update glow animation
    skillButtonGlow.updateAnimation(dt);
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