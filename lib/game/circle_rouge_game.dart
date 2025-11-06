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