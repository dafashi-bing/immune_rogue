import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/circle_rouge_game.dart';
import 'config/display_config.dart';
import 'overlays/start_menu_overlay.dart';
import 'overlays/game_mode_selection_overlay.dart';
import 'overlays/hero_selection_overlay.dart';
import 'overlays/pause_menu_overlay.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/ultimate_video_overlay.dart';

void main() {
  runApp(const CircleRougeApp());
}

class CircleRougeApp extends StatelessWidget {
  const CircleRougeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Circle Rouge',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'monospace', // Use monospace as fallback to avoid Noto font warnings
      ),
      home: FutureBuilder(
        future: DisplayConfig.instance.loadConfig(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.black,
            body: LayoutBuilder(
              builder: (context, constraints) {
                // Get the available screen space
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;
                
                // Get the configured dimensions
                final configWidth = DisplayConfig.instance.windowWidth;
                final configHeight = DisplayConfig.instance.windowHeight;
                final configAspectRatio = configWidth / configHeight;
                
                double gameWidth, gameHeight;
                
                // Calculate game size to maintain aspect ratio and fit screen
                if (screenWidth / screenHeight > configAspectRatio) {
                  // Screen is wider - constrain by height
                  gameHeight = screenHeight;
                  gameWidth = gameHeight * configAspectRatio;
                } else {
                  // Screen is taller - constrain by width  
                  gameWidth = screenWidth;
                  gameHeight = gameWidth / configAspectRatio;
                }
                
                // Update display config with actual rendered size
                DisplayConfig.instance.updateArenaDimensions(gameWidth, gameHeight);
                
                return Container(
                  width: screenWidth,
                  height: screenHeight,
                  color: Colors.black,
                  child: Center(
                    child: SizedBox(
                      width: gameWidth,
                      height: gameHeight,
                      child: GameWidget<CircleRougeGame>.controlled(
                        gameFactory: () {
                          final game = CircleRougeGame();
                          game.updateScreenDimensions(gameWidth, gameHeight);
                          return game;
                        },
                        overlayBuilderMap: {
                          'StartMenu': (context, game) => StartMenuOverlay(game: game),
                          'GameModeSelection': (context, game) => GameModeSelectionOverlay(game: game),
                          'HeroSelection': (context, game) => HeroSelectionOverlay(game: game),
                          'PauseMenu': (context, game) => PauseMenuOverlay(game: game),
                          'GameOver': (context, game) => GameOverOverlay(game: game, isVictory: false),
                          'Victory': (context, game) => GameOverOverlay(game: game, isVictory: true),
                          'UltimateVideo': (context, game) => UltimateVideoOverlay(
                            game: game,
                            videoPath: game.ultimateVideoPath ?? '',
                            onComplete: game.onUltimateVideoComplete,
                          ),
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
