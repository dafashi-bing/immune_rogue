import 'package:flutter/material.dart';
import '../game/circle_rouge_game.dart';
import '../config/game_mode_config.dart';

class GameModeSelectionOverlay extends StatefulWidget {
  final CircleRougeGame game;

  const GameModeSelectionOverlay({super.key, required this.game});

  @override
  State<GameModeSelectionOverlay> createState() => _GameModeSelectionOverlayState();
}

class _GameModeSelectionOverlayState extends State<GameModeSelectionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String? selectedGameMode;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _selectGameMode(String modeId) {
    setState(() {
      selectedGameMode = modeId;
    });
    
    // Set the game mode and proceed to hero selection
    widget.game.setGameMode(modeId);
    widget.game.proceedToHeroSelection();
  }

  void _goBack() {
    widget.game.showStartMenu();
  }

  @override
  Widget build(BuildContext context) {
    final gameModes = GameModeConfig.instance.getAllGameModes();
    
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F1F),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(30.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2D2D4A),
                    Color(0xFF1E1E3A),
                    Color(0xFF151528),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFF4A9EFF).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A9EFF).withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4A9EFF).withOpacity(0.1),
                          const Color(0xFF9C27B0).withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: const Text(
                      'SELECT GAME MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Game Mode Cards
                  ...gameModes.map((gameMode) => _buildGameModeCard(gameMode)).toList(),
                  
                  const SizedBox(height: 30),
                  
                  // Back Button
                  Container(
                    width: 200,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF424242),
                          Color(0xFF303030),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextButton(
                      onPressed: _goBack,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        '← Back to Menu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameModeCard(GameModeData gameMode) {
    final isSelected = selectedGameMode == gameMode.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectGameMode(gameMode.id),
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gameMode.primaryColor.withOpacity(isSelected ? 0.3 : 0.1),
                  gameMode.secondaryColor.withOpacity(isSelected ? 0.2 : 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected 
                    ? gameMode.primaryColor.withOpacity(0.6)
                    : gameMode.primaryColor.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: gameMode.primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: Row(
              children: [
                // Mode Icon/Indicator
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gameMode.primaryColor, gameMode.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: gameMode.primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getGameModeIcon(gameMode.id),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Mode Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gameMode.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: gameMode.primaryColor.withOpacity(0.5),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        gameMode.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildGameModeStats(gameMode),
                    ],
                  ),
                ),
                
                // Selection indicator
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: gameMode.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameModeStats(GameModeData gameMode) {
    List<Widget> stats = [];
    
    if (gameMode.maxWaves == -1) {
      stats.add(_buildStatChip('∞ Waves', Colors.purple));
    } else {
      stats.add(_buildStatChip('${gameMode.maxWaves} Waves', Colors.blue));
    }
    
    if (gameMode.scaling > 1.0) {
      stats.add(_buildStatChip('${(gameMode.scaling * 100).toInt()}% Scaling', Colors.orange));
    }
    
    if (gameMode.retryTokens) {
      stats.add(_buildStatChip('Retry Tokens', Colors.green));
    }
    
    if (gameMode.playerHealth == 1) {
      stats.add(_buildStatChip('1 HP', Colors.red));
    }
    
    return Wrap(
      spacing: 8,
      children: stats,
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getGameModeIcon(String modeId) {
    switch (modeId) {
      case 'normal':
        return Icons.play_arrow_rounded;
      case 'endless':
        return Icons.all_inclusive;
      case 'oneHpChallenge':
        return Icons.favorite;
      default:
        return Icons.games;
    }
  }
} 