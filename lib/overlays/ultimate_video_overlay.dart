import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../game/circle_rouge_game.dart';

/// Overlay widget that plays an ultimate video with fade transitions
class UltimateVideoOverlay extends StatefulWidget {
  final CircleRougeGame game;
  final String videoPath;
  final VoidCallback? onComplete;

  const UltimateVideoOverlay({
    super.key,
    required this.game,
    required this.videoPath,
    this.onComplete,
  });

  @override
  State<UltimateVideoOverlay> createState() => _UltimateVideoOverlayState();
}

class _UltimateVideoOverlayState extends State<UltimateVideoOverlay>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  double _fadeInDuration = 0.5; // 0.5 seconds to fade in
  double _videoDuration = 3.0; // Video plays for 3 seconds
  Timer? _fadeOutTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: (_fadeInDuration * 1000).toInt()),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    print('[ULTIMATE_VIDEO] Step 1: Initializing video player...');
    print('[ULTIMATE_VIDEO] Video path: ${widget.videoPath}');
    
    try {
      // video_player_win is installed as a dependency and will be used automatically on Windows
      // The standard VideoPlayerController will use the Windows implementation if available
      print('[ULTIMATE_VIDEO] Step 2: Creating VideoPlayerController for asset');
      _controller = VideoPlayerController.asset(widget.videoPath);
      
      print('[ULTIMATE_VIDEO] Step 3: Calling initialize()...');
      await _controller!.initialize();
      print('[ULTIMATE_VIDEO] Step 4: Video initialized successfully');
      
      _controller!.setLooping(false);
      _controller!.setVolume(1.0);
      print('[ULTIMATE_VIDEO] Step 5: Video configured (no loop, volume 1.0)');
      
      // Start fade in
      print('[ULTIMATE_VIDEO] Step 6: Starting fade-in animation');
      _fadeController.forward();
      
      // Start playing
      print('[ULTIMATE_VIDEO] Step 7: Starting video playback');
      await _controller!.play();
      print('[ULTIMATE_VIDEO] Step 8: Video playback started');
      
      setState(() {
        _isInitialized = true;
      });
      print('[ULTIMATE_VIDEO] Step 9: UI updated, video is visible');
      
      // Schedule fade out after video duration
      _fadeOutTimer = Timer(Duration(milliseconds: (_videoDuration * 1000).toInt()), () {
        print('[ULTIMATE_VIDEO] Step 10: Video duration elapsed, starting fade-out');
        _fadeOut();
      });
      
      print('[ULTIMATE_VIDEO] ✅ Video setup complete! Playing for ${_videoDuration}s');
    } catch (e, stackTrace) {
      print('[ULTIMATE_VIDEO] ❌ Error loading ultimate video: $e');
      print('[ULTIMATE_VIDEO] Error type: ${e.runtimeType}');
      print('[ULTIMATE_VIDEO] Stack trace: $stackTrace');
      
      // Check if it's a MissingPluginException (plugin not registered)
      if (e.toString().contains('MissingPluginException') || 
          e.toString().contains('No implementation found')) {
        print('[ULTIMATE_VIDEO] ⚠️ Video player plugin not available. This may require:');
        print('[ULTIMATE_VIDEO]   1. Running "flutter clean" and "flutter pub get"');
        print('[ULTIMATE_VIDEO]   2. Full rebuild (not hot reload): "flutter run"');
        print('[ULTIMATE_VIDEO]   3. Or video playback may not be supported on this platform');
        print('[ULTIMATE_VIDEO] Continuing without video - ultimate will still execute');
      }
      
      // If video fails, show a brief black screen then complete
      // This maintains the timing of the ultimate flow
      print('[ULTIMATE_VIDEO] Showing brief transition (${_videoDuration}s) without video');
      _fadeController.forward();
      
      // Schedule completion after the same duration as video would play
      _fadeOutTimer = Timer(Duration(milliseconds: (_videoDuration * 1000).toInt()), () {
        print('[ULTIMATE_VIDEO] Transition duration elapsed, completing');
        _fadeOut();
      });
    }
  }

  void _fadeOut() {
    print('[ULTIMATE_VIDEO] Step 11: Fade-out animation started');
    // Call onComplete immediately when fade-out starts, not when it finishes
    // This removes the gap between video and ultimate
    print('[ULTIMATE_VIDEO] Step 12: Calling onComplete callback immediately (before fade completes)');
    widget.onComplete?.call();
    
    _fadeController.reverse().then((_) {
      print('[ULTIMATE_VIDEO] Step 13: Fade-out animation complete');
      _complete();
    });
  }

  void _complete() {
    print('[ULTIMATE_VIDEO] Step 14: Completing video overlay');
    _fadeOutTimer?.cancel();
    _controller?.pause();
    _controller?.dispose();
    print('[ULTIMATE_VIDEO] Step 15: Video controller disposed');
    
    print('[ULTIMATE_VIDEO] Step 16: Removing overlay');
    widget.game.overlays.remove('UltimateVideo');
    print('[ULTIMATE_VIDEO] ✅ Video overlay complete and removed');
  }

  @override
  void dispose() {
    _fadeOutTimer?.cancel();
    _fadeController.dispose();
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black,
            child: _isInitialized && _controller != null && _controller!.value.isInitialized
                ? Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                : const Center(
                    // Show a simple indicator or just black screen if video fails
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

