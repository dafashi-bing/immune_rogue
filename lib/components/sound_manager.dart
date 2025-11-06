import 'package:flame_audio/flame_audio.dart';
import 'dart:math';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  // Sound effect mappings for hero abilities
  static const Map<String, String> heroAbilitySounds = {
    'circle': 'dash_trim.mp3',
    'triangle': 'spike_shot_trim.mp3', 
    'square': 'shield_bash_trim.mp3',
    'pentagon': 'star_flare_trim.mp3',
    'hexagon': 'hex_field.mp3',
    'heptagon': 'heptagon_resonance.mp3', // Updated to use new audio file
  };

  // BGM tracks for random selection
  static const List<String> bgmTracks = [
    'bgm/geometric_pulse.mp3',
    'bgm/digital_clash.mp3',
    'bgm/digital_clash_2.mp3',
  ];

  // Additional game sound effects
  static const String clearSound = 'clear.mp3';
  static const String failSound = 'fail.mp3';
  static const String victorySound = 'victory.mp3';
  static const String purchaseSound = 'purchase.mp3';
  static const String shieldBreakSound = 'chaser_shield_break.mp3'; // New audio file
  static const String retryTokenCollectSound = 'retry_token_collect.mp3'; // New audio file
  
  // Wave transition sounds
  static const String waveStartSound = 'sfx_wave_start_chime.mp3'; // New dedicated wave start chime
  static const String waveCompleteSound = 'clear.mp3'; // Reuse clear sound for wave complete
  static const String gameStartSound = 'clear.mp3'; // Reuse clear sound for game start
  static const String waveTransitionSound = 'clear.mp3'; // Reuse clear sound for transitions
  static const String shopTransitionSound = 'purchase.mp3'; // Reuse purchase sound for shop transitions
  
  // Enemy ability sounds
  static const String droneDeploySound = 'sfx_drone_deploy.mp3';
  static const String bomberExplodeSound = 'sfx_bomber_explode.mp3';
  static const String sniperSnipeSound = 'sfx_sniper_snipe.mp3';
  static const String splitterSplitSound = 'sfx_splitter_split.mp3';
  static const String mineDeploySound = 'sfx_mine_deploy.mp3';
  static const String mineExplodeSound = 'sfx_mine_explode.mp3';

  // Volume control
  double _volume = 0.7;
  double _musicVolume = 0.5; // Separate volume for background music
  
  double get volume => _volume;
  set volume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  double get musicVolume => _musicVolume;
  set musicVolume(double value) {
    _musicVolume = value.clamp(0.0, 1.0);
  }

  // Preload all sound effects
  Future<void> preloadSounds() async {
    try {
      // Preload hero ability sounds
      for (final soundFile in heroAbilitySounds.values) {
        await FlameAudio.audioCache.load(soundFile);
      }
      
      // Preload all BGM tracks
      for (final bgmFile in bgmTracks) {
        await FlameAudio.audioCache.load(bgmFile);
      }
      
      // Preload game sound effects
      await FlameAudio.audioCache.load(clearSound);
      await FlameAudio.audioCache.load(failSound);
      await FlameAudio.audioCache.load(victorySound);
      await FlameAudio.audioCache.load(purchaseSound);
      await FlameAudio.audioCache.load(shieldBreakSound);
      await FlameAudio.audioCache.load(retryTokenCollectSound);
      
      // Preload enemy ability sounds
      await FlameAudio.audioCache.load(droneDeploySound);
      await FlameAudio.audioCache.load(bomberExplodeSound);
      await FlameAudio.audioCache.load(sniperSnipeSound);
      await FlameAudio.audioCache.load(splitterSplitSound);
      await FlameAudio.audioCache.load(mineDeploySound);
      await FlameAudio.audioCache.load(mineExplodeSound);
    } catch (e) {
      print('Error preloading sounds: $e');
    }
  }

  // Play hero ability sound
  Future<void> playHeroAbilitySound(String heroShape) async {
    try {
      final soundFile = heroAbilitySounds[heroShape];
      if (soundFile != null) {
        await FlameAudio.play(soundFile, volume: _volume);
      }
    } catch (e) {
      print('Error playing hero ability sound for $heroShape: $e');
    }
  }

  // Play random battle background music (looping)
  Future<void> playBattleBGM() async {
    try {
      final random = Random();
      final selectedTrack = bgmTracks[random.nextInt(bgmTracks.length)];
      print('Playing BGM: $selectedTrack');
      await FlameAudio.bgm.play(selectedTrack, volume: _musicVolume);
    } catch (e) {
      print('Error playing battle BGM: $e');
    }
  }

  // Stop background music
  Future<void> stopBGM() async {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      print('Error stopping BGM: $e');
    }
  }

  // Play wave clear sound
  Future<void> playClearSound() async {
    try {
      // Use timeout to prevent hanging
      await FlameAudio.play(clearSound, volume: _volume).timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      print('Error playing clear sound: $e');
    }
  }

  // Play game over/fail sound
  Future<void> playFailSound() async {
    try {
      await FlameAudio.play(failSound, volume: _volume);
    } catch (e) {
      print('Error playing fail sound: $e');
    }
  }

  // Play victory sound (all waves completed)
  Future<void> playVictorySound() async {
    try {
      await FlameAudio.play(victorySound, volume: _volume);
    } catch (e) {
      print('Error playing victory sound: $e');
    }
  }

  // Play purchase sound (shop interaction)
  Future<void> playPurchaseSound() async {
    try {
      await FlameAudio.play(purchaseSound, volume: _volume);
    } catch (e) {
      print('Error playing purchase sound: $e');
    }
  }

  // Play shield break sound
  Future<void> playShieldBreakSound() async {
    try {
      await FlameAudio.play(shieldBreakSound, volume: _volume);
    } catch (e) {
      print('Error playing shield break sound: $e');
    }
  }

  // Play retry token collect sound
  Future<void> playRetryTokenCollectSound() async {
    try {
      await FlameAudio.play(retryTokenCollectSound, volume: _volume);
    } catch (e) {
      print('Error playing retry token collect sound: $e');
    }
  }

  // Play wave start sound
  Future<void> playWaveStartSound() async {
    try {
      // Use timeout to prevent hanging
      await FlameAudio.play(waveStartSound, volume: _volume).timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      print('Error playing wave start sound: $e');
    }
  }

  // Play drone deployment sound
  Future<void> playDroneDeploySound() async {
    try {
      await FlameAudio.play(droneDeploySound, volume: _volume);
    } catch (e) {
      print('Error playing drone deploy sound: $e');
    }
  }

  // Play bomber explosion sound
  Future<void> playBomberExplodeSound() async {
    try {
      await FlameAudio.play(bomberExplodeSound, volume: _volume);
    } catch (e) {
      print('Error playing bomber explode sound: $e');
    }
  }

  // Play sniper snipe sound
  Future<void> playSniperSnipeSound() async {
    try {
      await FlameAudio.play(sniperSnipeSound, volume: _volume);
    } catch (e) {
      print('Error playing sniper snipe sound: $e');
    }
  }

  // Play splitter split sound
  Future<void> playSplitterSplitSound() async {
    try {
      await FlameAudio.play(splitterSplitSound, volume: _volume);
    } catch (e) {
      print('Error playing splitter split sound: $e');
    }
  }

  // Play mine deployment sound
  Future<void> playMineDeploySound() async {
    try {
      await FlameAudio.play(mineDeploySound, volume: _volume);
    } catch (e) {
      print('Error playing mine deploy sound: $e');
    }
  }

  // Play mine explosion sound
  Future<void> playMineExplodeSound() async {
    try {
      await FlameAudio.play(mineExplodeSound, volume: _volume);
    } catch (e) {
      print('Error playing mine explode sound: $e');
    }
  }

  // Play wave complete sound
  Future<void> playWaveCompleteSound() async {
    try {
      // Use timeout to prevent hanging
      await FlameAudio.play(waveCompleteSound, volume: _volume).timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      print('Error playing wave complete sound: $e');
    }
  }

  // Play game start sound
  Future<void> playGameStartSound() async {
    try {
      await FlameAudio.play(gameStartSound, volume: _volume);
    } catch (e) {
      print('Error playing game start sound: $e');
    }
  }

  // Play wave transition sound
  Future<void> playWaveTransitionSound() async {
    try {
      await FlameAudio.play(waveTransitionSound, volume: _volume);
    } catch (e) {
      print('Error playing wave transition sound: $e');
    }
  }

  // Play shop transition sound
  Future<void> playShopTransitionSound() async {
    try {
      await FlameAudio.play(shopTransitionSound, volume: _volume);
    } catch (e) {
      print('Error playing shop transition sound: $e');
    }
  }

  // Helper method to stop all sounds (if needed)
  Future<void> stopAllSounds() async {
    try {
      FlameAudio.audioCache.clearAll();
      FlameAudio.bgm.stop();
    } catch (e) {
      print('Error stopping sounds: $e');
    }
  }
} 