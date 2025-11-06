import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/circle_rouge_game.dart';
import 'ui/responsive_layout.dart';
import 'sound_manager.dart';

class WaveAnnouncement extends PositionComponent with HasGameRef<CircleRougeGame> {
  late TextComponent waveTitle;
  late TextComponent countdownText;
  
  bool _isVisible = false;
  double _animationTime = 0.0;
  double _displayDuration = 2.0; // 2 seconds for start/end messages
  bool _isCountdown = false;
  bool _countdownEnabled = false; // Flag to control when countdown can start
  
  // Message types
  static const String _waveStartMessage = 'starts';
  static const String _waveSurvivedMessage = 'survived!';
  
  @override
  void render(Canvas canvas) {
    if (!_isVisible) return;
    
    // Render text components directly without background
    super.render(canvas);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    final screenSize = gameRef.size;
    
    // Create main wave title (large text, higher opacity)
    waveTitle = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFF4A9EFF).withAlpha(150), // Increased opacity
          fontSize: ResponsiveLayout.getResponsiveFontSize(80.0, screenSize), // Bigger text
          fontWeight: FontWeight.w900,
          letterSpacing: 8,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 6,
              offset: Offset(3, 3),
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(screenSize.x / 2, screenSize.y * 0.5), // Center of screen
    );
    add(waveTitle);
    
    // Create countdown text (positioned below wave title)
    countdownText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white.withAlpha(25), // Increased opacity
          fontSize: ResponsiveLayout.getResponsiveFontSize(64.0, screenSize), // Bigger text
          fontWeight: FontWeight.w700,
          letterSpacing: 6,
          // shadows: const [
          //   Shadow(
          //     color: Colors.black,
          //     blurRadius: 4,
          //     offset: Offset(2, 2),
          //   ),
          // ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(screenSize.x / 2, screenSize.y * 0.50), // Just below center
    );
    add(countdownText);
    
    // Initially hidden
    _isVisible = false;
  }
  
  void showWaveStart(int waveNumber) {
    _isVisible = true;
    _animationTime = 0.0;
    _isCountdown = false;
    _countdownEnabled = false; // Disable countdown initially
    _displayDuration = 2.0;
    
    final seconds = gameRef.waveDuration.ceil();
    waveTitle.text = 'WAVE $waveNumber $_waveStartMessage\nSURVIVE ${seconds}s';
    countdownText.text = '';
    
    print('DEBUG: Showing wave start for wave $waveNumber: ${waveTitle.text}'); // Debug
    
    // Enable countdown after message duration
    Future.delayed(const Duration(seconds: 2), () {
      _countdownEnabled = true;
      print('DEBUG: Countdown enabled for wave $waveNumber');
    });
    
    // Play wave start sound
    SoundManager().playWaveStartSound();
  }
  
  void showWaveSurvived(int waveNumber) {
    _isVisible = true;
    _animationTime = 0.0;
    _isCountdown = false;
    _displayDuration = 2.0;
    
    waveTitle.text = 'WAVE $waveNumber $_waveSurvivedMessage';
    countdownText.text = '';
    
    print('DEBUG: Showing wave survived for wave $waveNumber: ${waveTitle.text}'); // Debug
    
    // Play wave complete sound
    SoundManager().playWaveCompleteSound();
  }
  
  void showCountdown(double remainingTime) {
    // Only show countdown if enabled (after wave start message)
    if (!_countdownEnabled) return;
    
    if (!_isCountdown) {
      _isVisible = true;
      _isCountdown = true;
      waveTitle.text = '';
    }
    
    final seconds = remainingTime.ceil();
    countdownText.text = '${seconds}s';
    
    // Change color and style for last 10 seconds
    if (remainingTime <= 10.0) {
      countdownText.textRenderer = TextPaint(
        style: TextStyle(
          color: const Color(0xFFF44336).withAlpha(100), // Red with higher opacity
          fontSize: ResponsiveLayout.getResponsiveFontSize(72.0, gameRef.size), // Much larger
          fontWeight: FontWeight.w900,
          letterSpacing: 6,
          // shadows: const [
          //   Shadow(
          //     color: Color(0xFFF44336),
          //     blurRadius: 10,
          //     offset: Offset(3, 3),
          //   ),
          //   Shadow(
          //     color: Colors.black,
          //     blurRadius: 6,
          //     offset: Offset(2, 2),
          //   ),
          // ],
        ),
      );
    } else {
      countdownText.textRenderer = TextPaint(
        style: TextStyle(
          color: Colors.white.withAlpha(25), // Higher opacity
          fontSize: ResponsiveLayout.getResponsiveFontSize(64.0, gameRef.size), // Bigger
          fontWeight: FontWeight.w700,
          letterSpacing: 6,
          // shadows: const [
          //   Shadow(
          //     color: Colors.black,
          //     blurRadius: 4,
          //     offset: Offset(2, 2),
          //   ),
          // ],
        ),
      );
    }
  }
  
  void hideCountdown() {
    if (_isCountdown) {
      _isCountdown = false;
      countdownText.text = '';
      // Don't hide _isVisible here - let showWaveSurvived control visibility
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Only handle timing for non-countdown messages
    if (!_isVisible || _isCountdown) return;
    
    _animationTime += dt;
    
    // Hide message after display duration
    if (_animationTime >= _displayDuration) {
      _isVisible = false;
      _animationTime = 0.0;
      waveTitle.text = '';
      countdownText.text = '';
    }
  }
  
  bool get isVisible => _isVisible;
}
