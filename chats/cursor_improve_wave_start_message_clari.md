# Improve wave start message clarity
_Exported on 9/26/2025 at 22:14:42 PDT from Cursor (1.6.45)_

---

**User**

Previously we have player telling us that (s)he's not sure about the wave goal. Should we change the wave start message? or maybe add something to it?

---

**Cursor**

I'll inspect `lib/components/wave_announcement.dart`, `lib/game/circle_rouge_game.dart`, and `assets/config/game_modes.yaml` to see how wave start messaging is built and where we can inject clear goal text.

I'll update the wave start text to explicitly include the goal: "Survive Ns" using `gameRef.waveDuration` so players immediately understand the objective. I'll make the edit in `lib/components/wave_announcement.dart` where the start message is set.

```dart
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
    waveTitle.text = 'WAVE $waveNumber $_waveStartMessage — SURVIVE ${seconds}s';
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

```

- I’ll add clear goal text to the wave start message so players know exactly what to do.

Let me implement it now.

- I updated `WaveAnnouncement.showWaveStart` to include the objective with the actual wave duration.

What I did:
- Wave start now reads like: “WAVE X starts — SURVIVE Ns” using `gameRef.waveDuration.ceil()` so it stays consistent with your config and mode.

Would you like me to also:
- Add a brief tooltip for the first wave only (e.g., “Avoid damage. Defeat enemies to earn coins.”)?
- Show a tiny subtext for Endless mode (e.g., “Waves get harder every 5 waves.”) when `currentGameMode == endless`?

---

**User**

uh it's too long now -- maybe in two lines?

---

**Cursor**

I'll split the wave start message into two lines by setting the title to "WAVE X starts" and using the second line for "SURVIVE Ns". I'll also move the second line slightly below the title so they don't overlap. I'll make the edits in `lib/components/wave_announcement.dart` and then check for linter issues.

```dart
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
      position: Vector2(screenSize.x / 2, screenSize.y * 0.58), // Just below the title
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
    waveTitle.text = 'WAVE $waveNumber $_waveStartMessage';
    countdownText.text = 'SURVIVE ${seconds}s';
    
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

```

- I split the message across two lines and nudged the second line down so it doesn’t overlap.

Changes:
- Title: “WAVE X starts”
- Subline: “SURVIVE Ns”, positioned at 58% screen height.

Want the subline smaller or lighter to reduce visual weight, or is the current size good?

