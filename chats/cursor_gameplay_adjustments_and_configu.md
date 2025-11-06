# Gameplay adjustments and configuration requests
_Exported on 9/26/2025 at 22:11:53 PDT from Cursor (1.6.45)_

---

**User**

restart still doesn't clears the arena
Auto Injector's MAX HP effect is not working. And I think the original description is a bit ambiguous. Probably the reason causing this weird implementation: Let's make it every 10 kill +2 max hp (caps at 50 per stack). So if user has 2, they could potentially get +100 max HP with 500 kills
Let's have Enlarged Caliber also enlarge character, and slows down character by 25% each time the item is purchased. And caps at 5 purchases
Let's remove drone limit, player can purchase infinite drones
Let's increase sniper bullet dmg. Now it takes away player 50% of HP if hit
I want all number configs for enemies to be configurable in a json file under /assets/config/, just like other config files.
Let's spawn 6 swarm at each spawn
Let's split 6 replicas for splitter after being killed
Let's just have miner's mine deal dmg directly on player, instead of spreading bullets.

---

**Cursor**

I'll help you implement these changes to your Shape Rogue game. Let me first explore the codebase to understand the current structure and then create a plan for all the requested modifications.

Now I have a good understanding of the codebase. Let me start implementing the requested changes. First, let me fix the restart arena issue and then work through the other changes.

I can see the issue with the restart not clearing arena. The `_clearLingeringComponents()` method clears some components like mines, drones, and hex fields, but it might be missing other arena components. Let me fix this and then work on the other changes.

```dart
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
import '../components/abilities/hex_field.dart';
import '../components/companions/drone_wingman.dart';
import '../components/companions/hero_clone.dart';
import '../config/item_config.dart';
import '../config/wave_config.dart';
import '../config/hero_config.dart';
import '../config/game_mode_config.dart';
import '../config/display_config.dart';

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
  double get waveDuration => WaveConfig.instance.settings?.waveDuration ?? 30.0;
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
        position: Vector2.zero(),
        anchor: Anchor.topLeft,
      );
      add(backgroundArena);
    } catch (e) {
      print('Could not load background image: $e');
      // Create a simple colored background as fallback
      final rect = RectangleComponent(
        size: Vector2(arenaWidth, arenaHeight),
        position: Vector2.zero(),
        paint: Paint()..color = const Color(0xFF1A1A1A),
        anchor: Anchor.topLeft,
      );
      add(rect);
    }
    
    // Load other configurations
    await ItemConfig.instance.loadConfig();
    await WaveConfig.instance.loadConfig();
    await HeroConfig.instance.loadConfig();
    await GameModeConfig.instance.loadConfig();
    
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
    
    // Remove all overlays
    overlays.remove('HeroSelection');
    overlays.remove('GameOver');
    overlays.remove('Victory');
    overlays.remove('PauseMenu');
    
    clearAllItems();
    _clearLingeringComponents();

    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.resetPassiveEffects();
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
    
    // Start first wave
    startWave(currentWave);
  }
  
  void restartGame() {
    // Reset game over sound flag
    gameOverSoundPlayed = false;
    
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
    _clearLingeringComponents();
    
    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.resetPassiveEffects();
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
    
    // Add stats overlay for coin and stats display during gameplay
    if (!statsOverlay.isMounted) {
      add(statsOverlay);
    }
    statsOverlay.show();
    
    // Start first wave (which will start BGM)
    startWave(currentWave);
  }
  
  void showStartMenu() {
    gameState = GameState.startMenu;
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
    
    // Try to drop item (unified system)
    if (enemy is PositionComponent) {
      consumableDropManager.tryDropItem(enemy.position);
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
      _clearLingeringComponents();
      
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
          shopPanel.show();
          
          // Ensure stats overlay is on top by adding it after the shop panel
          if (statsOverlay.isMounted) {
            statsOverlay.removeFromParent();
          }
          add(statsOverlay);
          statsOverlay.show();
          
          // Auto refresh shop items
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
  
  void onHeroDeath() {
    if (gameOverSoundPlayed) return; // Prevent multiple fail sounds
    
    // Handle 1HP Challenge mode retry tokens
    if (currentGameMode == GameMode.oneHpChallenge && retryTokens > 0) {
      consumeRetryToken();
      revivePlayer();
      return;
    }
    
    gameState = GameState.gameOver;
    gameOverSoundPlayed = true;
    
    // Clear all item drops when game ends
    clearAllItems();
    _clearLingeringComponents();
    
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
      hud.updateArmor(hero.shield, hero.totalShieldHP);
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
      hud.updateWaveTimer(remainingTime);
      
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
      
      // Update background size if it exists
      if (backgroundArena.isMounted) {
        backgroundArena.size = Vector2(arenaWidth, arenaHeight);
      }
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
  
  void _clearLingeringComponents() {
    final componentsToRemove = <Component>[];

    for (final component in children) {
      if (component is DroneWingman ||
          component is HeroClone ||
          component is HexField ||
          component is AbilityVisualEffect ||
          component is Mine ||
          component.runtimeType.toString().contains('Projectile') ||
          component.runtimeType.toString().contains('Effect') ||
          component.runtimeType.toString().contains('Explosion')) {
        componentsToRemove.add(component);
      }
    }

    for (final component in componentsToRemove) {
      component.removeFromParent();
    }
  }

  void showEffectNotification(String effectType, double value, double duration) {
    // Simple console output for now - could be enhanced with UI notifications
    print('Effect applied: $effectType (${value.toStringAsFixed(1)}) for ${duration.toStringAsFixed(1)}s');
  }
} 

```

Now let me fix the Auto Injector item. I need to update the items.json config and the hero implementation to make it work with kills instead of just healing per kill.

```json
{
  "items": [
    {
      "id": "health_potion",
      "name": "Health Potion",
      "cost": 30,
      "description": "Restore 50 HP",
      "type": "consumable",
      "icon": "health_potion_transparent.png",
      "effect": {
        "type": "heal",
        "value": 50
      }
    },
    {
      "id": "dash_mastery",
      "name": "Dash Mastery",
      "cost": 60,
      "description": "-20% Dash Cooldown",
      "type": "upgrade",
      "icon": "ability_mastery_transparent.png",
      "effect": {
        "type": "dash_cooldown_multiplier",
        "value": 0.8
      }
    },
    {
      "id": "max_health_up",
      "name": "Max Health Up",
      "cost": 50,
      "description": "+25 Max Health",
      "type": "upgrade",
      "icon": "max_health_up_transparent.png",
      "effect": {
        "type": "max_health_increase",
        "value": 25
      }
    },
    {
      "id": "attack_speed_up",
      "name": "Attack Speed Up",
      "cost": 60,
      "description": "+25% Attack Speed",
      "type": "upgrade",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "attack_speed_multiplier",
        "value": 0.25
      }
    },
    {
      "id": "speed_boost",
      "name": "Speed Boost",
      "cost": 40,
      "description": "+25% Movement Speed",
      "type": "upgrade",
      "icon": "speed_boost_transparent.png",
      "effect": {
        "type": "speed_multiplier",
        "value": 0.25
      }
    },
    {
      "id": "extended_reach",
      "name": "Extended Reach",
      "cost": 150,
      "description": "+50% Range for all attacks and abilities",
      "type": "upgrade",
      "icon": "extended_reach_transparent.png",
      "effect": {
        "type": "range_multiplier",
        "value": 0.5
      }
    },
    {
      "id": "spread_master",
      "name": "Spread Master",
      "cost": 70,
      "description": "+1 projectile per shot, stack up to +9 (max 10 shots)",
      "type": "passive",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "projectile_count",
        "value": 1,
        "max_stacks": 9
      }
    },
    {
      "id": "bouncing_bullets",
      "name": "Bouncing Bullets",
      "cost": 80,
      "description": "+1 projectile bounce per shot, stackable to +3",
      "type": "passive",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "projectile_bounces",
        "value": 1,
        "max_stacks": 3
      }
    },
    {
      "id": "drone_wingman",
      "name": "Drone Wingman",
      "cost": 90,
      "description": "Summons one auto-firing drone (0.8 shots/sec), stackable to 3 drones",
      "type": "passive",
      "icon": "ability_mastery_transparent.png",
      "effect": {
        "type": "drone_count",
        "value": 1,
        "max_stacks": 3
      }
    },
    {
      "id": "enlarged_caliber",
      "name": "Enlarged Caliber",
      "cost": 60,
      "description": "+10% projectile diameter per stack, stackable to +100%",
      "type": "passive",
      "icon": "extended_reach_transparent.png",
      "effect": {
        "type": "projectile_size",
        "value": 0.1,
        "max_stacks": 10
      }
    },
    {
      "id": "clone_projection",
      "name": "Clone Projection",
      "cost": 120,
      "description": "Spend 50% current HP to spawn a clone that mimics player",
      "type": "active_passive",
      "icon": "ability_mastery_transparent.png",
      "effect": {
        "type": "clone_spawn",
        "value": 0.5,
        "max_stacks": 1
      }
    },
    {
      "id": "vampiric_coating",
      "name": "Vampiric Coating",
      "cost": 80,
      "description": "+5% life steal per stack, max +20%",
      "type": "passive",
      "icon": "health_potion_transparent.png",
      "effect": {
        "type": "life_steal",
        "value": 0.05,
        "max_stacks": 4
      }
    },
    {
      "id": "armor_plating",
      "name": "Armor Plating",
      "cost": 70,
      "description": "+5 shield HP per stack, max +100; shields fully regens between waves",
      "type": "passive",
      "icon": "max_health_up_transparent.png",
      "effect": {
        "type": "shield_hp",
        "value": 5,
        "max_stacks": 20
      }
    },
    {
      "id": "coin_magnet",
      "name": "Coin Magnet",
      "cost": 50,
      "description": "+20% coin earn, max +100%",
      "type": "passive",
      "icon": "speed_boost_transparent.png",
      "effect": {
        "type": "coin_multiplier",
        "value": 0.2,
        "max_stacks": 5
      }
    },
    {
      "id": "auto_injector",
      "name": "Auto-Injector",
      "cost": 100,
      "description": "Every 10 kills grants +2 Max HP (caps at +50 per stack)",
      "type": "passive",
      "icon": "health_potion_transparent.png",
      "effect": {
        "type": "kill_based_max_health",
        "value": 2,
        "max_stacks": 5
      }
    },
    {
      "id": "critical_striker",
      "name": "Critical Striker",
      "cost": 75,
      "description": "+2% crit chance per stack, max +10%",
      "type": "passive",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "crit_chance",
        "value": 0.02,
        "max_stacks": 5
      }
    }
  ]
}

```

Now I need to update the shop panel to handle the new effect type and add kill tracking to the hero:

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game/circle_rouge_game.dart';
import '../config/item_config.dart';
import '../config/wave_config.dart';
import 'sound_manager.dart';
import '../config/display_config.dart';
import '../config/game_mode_config.dart';
import 'ui/item_detail_card.dart';

class ShopItem {
  final String id;
  final String name;
  final int cost;
  final String description;
  final String icon;
  final void Function() onPurchase;
  
  ShopItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
    required this.icon,
    required this.onPurchase,
  });
  
  factory ShopItem.fromItemData(ItemData itemData, void Function() onPurchase, int scaledCost) {
    return ShopItem(
      id: itemData.id,
      name: itemData.name,
      cost: scaledCost,
      description: itemData.description,
      icon: itemData.icon,
      onPurchase: onPurchase,
    );
  }
}

class ShopPanel extends RectangleComponent with HasGameRef<CircleRougeGame>, TapCallbacks {
  late List<ShopSlot> itemSlots;
  late RectangleComponent rollButton;
  late TextComponent rollButtonText;
  late TextComponent titleText;
  late TextComponent instructionText;
  late RectangleComponent backgroundGradient;
  late RectangleComponent headerPanel;
  late RectangleComponent footerPanel;
  
  bool isVisible = false;
  
  static const double panelWidth = 715.0;
  static const double panelHeight = 550.0;
  static const double slotWidth = 176.0;
  static const double slotHeight = 275.0;
  static const double slotSpacing = 49.5;
  
  ShopPanel() : super(
    size: Vector2(panelWidth, panelHeight),
    paint: Paint()..color = Colors.transparent,
    position: Vector2(
      (DisplayConfig.instance.arenaWidth - panelWidth) / 2,
      (DisplayConfig.instance.arenaHeight - panelHeight) / 2,
    ),
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Background with enhanced gradient effect
    backgroundGradient = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      paint: Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D2D4A),
            Color(0xFF1E1E3A),
            Color(0xFF151528),
          ],
        ).createShader(Rect.fromLTWH(0, 0, panelWidth, panelHeight)),
      position: Vector2.zero(),
    );
    add(backgroundGradient);
    
    // Main border with enhanced glow effect
    final border = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF4A9EFF).withOpacity(0.6),
      position: Vector2.zero(),
    );
    add(border);
    
    // Outer glow effect
    final outerGlow = RectangleComponent(
      size: Vector2(panelWidth + 10, panelHeight + 10),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = const Color(0xFF4A9EFF).withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      position: Vector2(-5, -5),
    );
    add(outerGlow);
    
    // Header panel with gradient
    headerPanel = RectangleComponent(
      size: Vector2(panelWidth - 20, 99),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF4A9EFF),
            Color(0xFF9C27B0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, panelWidth - 20, 99))
        ..color = const Color(0xFF4A9EFF).withOpacity(0.15),
      position: Vector2(10, 10),
    );
    add(headerPanel);
    
    // Header border with glow
    final headerBorder = RectangleComponent(
      size: Vector2(panelWidth - 20, 99),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4A9EFF).withOpacity(0.6),
      position: Vector2(10, 10),
    );
    add(headerBorder);
    
    // Title with enhanced styling and shader mask effect
    titleText = TextComponent(
      text: 'MYSTICAL SHOP',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white, // This will be overridden by the gradient
          fontSize: 35.2, // Increased from 32 (10% bigger)
          fontWeight: FontWeight.w900,
          letterSpacing: 3.0,
          shadows: [
            Shadow(
              color: Color(0xFF4A9EFF),
              blurRadius: 15,
            ),
            Shadow(
              color: Color(0xFF9C27B0),
              blurRadius: 10,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 5,
            ),
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(panelWidth / 2, 33), // Adjusted from 30 (10% bigger)
    );
    add(titleText);
    
    // Instructions with enhanced styling
    instructionText = TextComponent(
      text: 'Enhance your hero with powerful upgrades',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 17.6, // Increased from 16 (10% bigger)
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 6,
            ),
            Shadow(
              color: Color(0xFF4A9EFF),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(panelWidth / 2, 77), // Adjusted from 70 (10% bigger)
    );
    add(instructionText);
    
    // Create item slots with better positioning
    itemSlots = [];
    final slotsStartX = (panelWidth - (3 * slotWidth + 2 * slotSpacing)) / 2;
    for (int i = 0; i < 3; i++) {
      final slot = ShopSlot(
        position: Vector2(
          slotsStartX + i * (slotWidth + slotSpacing),
          121,
        ),
      );
      itemSlots.add(slot);
      add(slot);
    }
    
    // Footer panel with gradient background
    footerPanel = RectangleComponent(
      size: Vector2(panelWidth - 20, 70),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF2D2D4A),
            Color(0xFF1E1E3A),
          ],
        ).createShader(Rect.fromLTWH(0, 0, panelWidth - 20, 70))
        ..color = const Color(0xFF2D2D4A).withOpacity(0.6),
      position: Vector2(10, panelHeight - 80),
    );
    add(footerPanel);
    
    // Footer border
    final footerBorder = RectangleComponent(
      size: Vector2(panelWidth - 20, 70),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4A9EFF).withOpacity(0.3),
      position: Vector2(10, panelHeight - 80),
    );
    add(footerBorder);
    
    // Roll button with enhanced gradient styling
    rollButton = RectangleComponent(
      size: Vector2(140, 45),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF2196F3),
            Color(0xFF1976D2),
          ],
        ).createShader(Rect.fromLTWH(0, 0, 140, 45)),
      position: Vector2((panelWidth - 140) / 2 - 90, panelHeight - 65),
    );
    add(rollButton);
    
    // Roll button glow effect
    final rollButtonGlow = RectangleComponent(
      size: Vector2(140, 45),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF2196F3).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      position: Vector2((panelWidth - 140) / 2 - 90, panelHeight - 65),
    );
    add(rollButtonGlow);
    
    rollButtonText = TextComponent(
      text: 'REROLL (10)',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(70, 22.5),
    );
    rollButton.add(rollButtonText);
    
    // Continue button with enhanced gradient styling
    final continueButton = RectangleComponent(
      size: Vector2(140, 45),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF388E3C),
          ],
        ).createShader(Rect.fromLTWH(0, 0, 140, 45)),
      position: Vector2((panelWidth - 140) / 2 + 90, panelHeight - 65),
    );
    add(continueButton);
    
    // Continue button glow effect
    final continueButtonGlow = RectangleComponent(
      size: Vector2(140, 45),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF4CAF50).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      position: Vector2((panelWidth - 140) / 2 + 90, panelHeight - 65),
    );
    add(continueButtonGlow);
    
    final continueButtonText = TextComponent(
      text: 'CONTINUE',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(70, 22.5),
    );
    continueButton.add(continueButtonText);
    
    // Store continue button reference for tap detection
    continueButton.add(Component());
    continueButton.children.register<Component>();
    
    // Initially hidden
    hide();
    
    // Populate with initial items
    rollShopItems();
  }
  
  void show() {
    isVisible = true;
    opacity = 1.0;
  }
  
  void hide() {
    isVisible = false;
    opacity = 0.0;
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    if (!isVisible) return false;
    
    final localPoint = event.localPosition;
    
    // Check if roll button was tapped - updated for 10% bigger dimensions
    final rollButtonRect = Rect.fromLTWH(
      rollButton.position.x,
      rollButton.position.y,
      154, // Updated from 140
      49.5, // Updated from 45
    );
    
    if (rollButtonRect.contains(Offset(localPoint.x, localPoint.y))) {
      rollShopItems();
      return true;
    }
    
    // Check if continue button was tapped - updated for 10% bigger dimensions
    final continueButtonPosition = Vector2((panelWidth - 154) / 2 + 99, panelHeight - 71.5); // Updated from 140/90/65
    final continueButtonRect = Rect.fromLTWH(
      continueButtonPosition.x,
      continueButtonPosition.y,
      154, // Updated from 140
      49.5, // Updated from 45
    );
    
    if (continueButtonRect.contains(Offset(localPoint.x, localPoint.y))) {
      closeShop();
      return true;
    }
    
    return false;
  }
  
  void rollShopItems() {
    // Check if all items are sold (free roll)
    final allItemsSold = itemSlots.every((slot) => slot.currentItem == null);
    
    // Get roll cost from configuration
    final rollCost = allItemsSold ? 0 : (WaveConfig.instance.shopConfig?.rollCost ?? 10);
    
    // Check if player has enough coins to roll
    if (gameRef.hero.coins < rollCost) {
      return; // Not enough coins to roll
    }
    
    // Spend coins for rolling (if not free)
    if (rollCost > 0) {
      gameRef.hero.spendCoins(rollCost);
    }
    
    final availableItems = _getAvailableItems();
    final random = Random();
    
    for (int i = 0; i < 3; i++) {
      if (availableItems.isNotEmpty) {
        final randomItem = availableItems[random.nextInt(availableItems.length)];
        itemSlots[i].setItem(randomItem);
      }
    }
    
    // Update roll button text after rolling
    final newRollCost = WaveConfig.instance.shopConfig?.rollCost ?? 10;
    rollButtonText.text = 'REROLL ($newRollCost)';
  }
  
  List<ShopItem> _getAvailableItems() {
    final itemConfig = ItemConfig.instance;
    final shopConfig = WaveConfig.instance.shopConfig;
    List<ShopItem> availableItems = [];
    final random = Random();
    
    for (final itemData in itemConfig.items) {
      // Skip health-related items in 1HP Challenge mode
      if (gameRef.currentGameMode == GameMode.oneHpChallenge) {
        if (itemData.effect.type == 'heal' || 
            itemData.effect.type == 'max_health_increase') {
          continue; // Skip health items in 1HP mode
        }
      }
      
      // Calculate scaled price based on current wave using configuration
      double waveMultiplier = 1.0;
      double randomMultiplier = 1.0;
      
      if (shopConfig != null) {
        waveMultiplier = 1.0 + (shopConfig.waveMultiplier * (gameRef.currentWave - 1));
        randomMultiplier = (1.0 - shopConfig.randomVariance) + (random.nextDouble() * shopConfig.randomVariance * 2);
      } else {
        // Fallback to old hardcoded values
        waveMultiplier = 1.0 + (0.2 * (gameRef.currentWave - 1));
        randomMultiplier = 0.95 + (random.nextDouble() * 0.1);
      }
      
      final scaledCost = (itemData.cost * waveMultiplier * randomMultiplier).round();
      
      // Create dynamic name for ability cooldown reduction based on hero's ability
      if (itemData.id == 'dash_mastery') {
        final heroAbilityName = gameRef.hero.heroData.ability.name;
        availableItems.add(ShopItem(
          id: itemData.id,
          name: '$heroAbilityName Mastery',
          cost: scaledCost,
          description: '-25% ${heroAbilityName} Cooldown',
          icon: itemData.icon,
          onPurchase: () => _applyItemEffect(itemData),
        ));
      } else {
        availableItems.add(ShopItem.fromItemData(itemData, () => _applyItemEffect(itemData), scaledCost));
      }
    }
    
    return availableItems;
  }
  
  void _applyItemEffect(ItemData itemData) {
    switch (itemData.effect.type) {
      case 'heal':
        final healAmount = (gameRef.hero.maxHealth - gameRef.hero.health).clamp(0.0, itemData.effect.value);
        gameRef.hero.heal(healAmount);
        break;
      case 'dash_cooldown_multiplier':
        // Apply ability cooldown reduction
        gameRef.hero.abilityCooldownMultiplier *= itemData.effect.value;
        break;
      case 'max_health_increase':
        gameRef.hero.maxHealth += itemData.effect.value;
        gameRef.hero.health += itemData.effect.value;
        break;
      case 'attack_speed_multiplier':
        gameRef.hero.attackSpeedMultiplier += itemData.effect.value;
        break;
      case 'speed_multiplier':
        gameRef.hero.speedMultiplier += itemData.effect.value;
        break;
      case 'range_multiplier':
        gameRef.hero.rangeMultiplier += itemData.effect.value;
        break;
      // New stackable passive effects
      case 'projectile_count':
      case 'projectile_bounces':
      case 'projectile_size':
      case 'life_steal':
      case 'shield_hp':
      case 'coin_multiplier':
      case 'heal_per_kill':
      case 'crit_chance':
      case 'clone_spawn':
      case 'max_health_boost':
      case 'kill_based_max_health':
        final maxStacks = itemData.effect.maxStacks ?? 1;
        gameRef.hero.addPassiveEffect(itemData.effect.type, maxStacks);
        // Max health boost only affects max HP, not current HP
        break;
      case 'drone_count':
        final maxStacks = itemData.effect.maxStacks ?? 1;
        gameRef.hero.addPassiveEffect(itemData.effect.type, maxStacks);
        // Update drone count immediately
        gameRef.hero.updateDroneCount();
        break;
      default:
        print('Unknown item effect type: ${itemData.effect.type}');
    }
  }
  
  void onItemPurchased() {
    // Update roll button text based on remaining items
    final allItemsSold = itemSlots.every((slot) => slot.currentItem == null);
    final rollCost = allItemsSold ? 0 : (WaveConfig.instance.shopConfig?.rollCost ?? 10);
    rollButtonText.text = rollCost == 0 ? 'REROLL (FREE)' : 'REROLL ($rollCost)';
  }
  
  void closeShop() {
    hide();
    gameRef.onShopClosed();
  }
}

class ShopSlot extends RectangleComponent with TapCallbacks, HasGameRef<CircleRougeGame> {
  late TextBoxComponent nameText;
  late TextComponent costText;
  late TextComponent descriptionText;
  late RectangleComponent buyButton;
  late TextComponent buyButtonText;
  late Component itemIcon;
  late RectangleComponent border;
  late RectangleComponent outerGlow;
  late RectangleComponent buyButtonGlow;
  
  ShopItem? currentItem;
  
  ShopSlot({required Vector2 position}) : super(
    size: Vector2(ShopPanel.slotWidth, ShopPanel.slotHeight),
    paint: Paint()..color = Colors.transparent,
    position: position,
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Background with enhanced gradient
    final background = RectangleComponent(
      size: Vector2(size.x, size.y),
      paint: Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A3A3A),
            Color(0xFF2A2A2A),
            Color(0xFF1A1A1A),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
      position: Vector2.zero(),
    );
    add(background);
    
    // Border with enhanced glow
    border = RectangleComponent(
      size: Vector2(size.x, size.y),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4A9EFF).withOpacity(0.5),
      position: Vector2.zero(),
    );
    add(border);
    
    // Outer glow effect for slots
    outerGlow = RectangleComponent(
      size: Vector2(size.x + 4, size.y + 4),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xFF4A9EFF).withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      position: Vector2(-2, -2),
    );
    add(outerGlow);
    
    // Initialize item icon as empty placeholder - will be replaced when item is set
    itemIcon = RectangleComponent(
      size: Vector2(44, 44),
      position: Vector2((size.x - 44) / 2, 22),
      paint: Paint()..color = Colors.transparent,
    );
    add(itemIcon);
    
    // Item name with enhanced styling and line wrapping
    nameText = TextBoxComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF4A9EFF),
          fontSize: 17.6,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: [
            Shadow(
              color: Color(0xFF4A9EFF),
              blurRadius: 6,
            ),
          ],
        ),
      ),
      align: Anchor.center,
      boxConfig: TextBoxConfig(
        maxWidth: size.x - 10,
        timePerChar: 0.0,
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 82.5),
    );
    add(nameText);
    
    // Item description with better styling
    descriptionText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 13.2,
          fontWeight: FontWeight.w500,
          height: 1.4,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 132),
    );
    add(descriptionText);
    
    // Cost with enhanced styling
    costText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFEB3B),
          fontSize: 19.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: [
            Shadow(
              color: Color(0xFFFFEB3B),
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
      position: Vector2(size.x / 2, 170.5),
    );
    add(costText);
    
    // Buy button with enhanced gradient styling
    buyButton = RectangleComponent(
      size: Vector2(143, 44),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF388E3C),
          ],
        ).createShader(Rect.fromLTWH(0, 0, 143, 44)),
      position: Vector2((size.x - 143) / 2, size.y - 60.5),
    );
    add(buyButton);
    
    // Buy button glow effect
    buyButtonGlow = RectangleComponent(
      size: Vector2(143, 44),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF4CAF50).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      position: Vector2((size.x - 143) / 2, size.y - 60.5),
    );
    add(buyButtonGlow);
    
    buyButtonText = TextComponent(
      text: 'PURCHASE',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15.4,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(71.5, 22),
    );
    buyButton.add(buyButtonText);
  }
  
  // Get category colors based on item type
  Map<String, Color> _getCategoryColors(String itemId) {
    switch (itemId) {
      case 'health_potion':
      case 'max_health_up':
        // Green for health items
        return {
          'primary': const Color(0xFF4CAF50),
          'secondary': const Color(0xFF66BB6A),
          'glow': const Color(0xFF4CAF50),
        };
      case 'attack_speed_up':
        // Red for attack items
        return {
          'primary': const Color(0xFFF44336),
          'secondary': const Color(0xFFE57373),
          'glow': const Color(0xFFF44336),
        };
      case 'speed_boost':
        // Blue for speed items
        return {
          'primary': const Color(0xFF2196F3),
          'secondary': const Color(0xFF64B5F6),
          'glow': const Color(0xFF2196F3),
        };
      case 'dash_mastery':
        // Hero color for ability items
        final heroColor = gameRef.hero.heroData.color;
        return {
          'primary': heroColor,
          'secondary': heroColor.withOpacity(0.8),
          'glow': heroColor,
        };
      default:
        // Default blue theme
        return {
          'primary': const Color(0xFF4A9EFF),
          'secondary': const Color(0xFF64B5F6),
          'glow': const Color(0xFF4A9EFF),
        };
    }
  }

  void setItem(ShopItem item) async {
    currentItem = item;
    final colors = _getCategoryColors(item.id);
    
    nameText.text = item.name.toUpperCase();
    descriptionText.text = item.description;
    costText.text = '${item.cost} COINS';
    
    // Replace the current icon with a sprite-based icon
    if (itemIcon.isMounted) {
      itemIcon.removeFromParent();
    }
    
    try {
      // Try to load the actual item icon sprite
      final sprite = await Sprite.load(item.icon);
      itemIcon = SpriteComponent(
        sprite: sprite,
        size: Vector2(44, 44),
        position: Vector2((size.x - 44) / 2, 22),
        anchor: Anchor.topLeft,
      );
    } catch (e) {
      print('Could not load item icon: ${item.icon}, using colored rectangle fallback');
      // Fallback to colored rectangle with category color
      itemIcon = RectangleComponent(
        size: Vector2(44, 44),
        position: Vector2((size.x - 44) / 2, 22),
        paint: Paint()..color = colors['primary']!,
      );
    }
    
    add(itemIcon);
    
    // Update name text color to match category
    nameText.textRenderer = TextPaint(
      style: TextStyle(
        color: colors['primary']!,
        fontSize: 17.6,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        shadows: [
          Shadow(
            color: colors['glow']!,
            blurRadius: 6,
          ),
        ],
      ),
    );
    
    // Update border and glow colors to match category
    border.paint.color = colors['primary']!.withOpacity(0.6);
    outerGlow.paint.color = colors['glow']!.withOpacity(0.15);
    
    // Update buy button styling based on affordability and category
    if (gameRef.hero.coins >= item.cost) {
      // Update buy button gradient with category colors
      buyButton.paint.shader = LinearGradient(
        colors: [
          colors['primary']!,
          colors['secondary']!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, 143, 44));
      
      buyButtonGlow.paint.color = colors['glow']!.withOpacity(0.5);
      buyButtonText.text = 'PURCHASE';
    } else {
      // Grey for unaffordable items
      buyButton.paint.shader = const LinearGradient(
        colors: [
          Color(0xFF757575),
          Color(0xFF616161),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 143, 44));
      
      buyButtonGlow.paint.color = const Color(0xFF757575).withOpacity(0.3);
      buyButtonText.text = 'TOO EXPENSIVE';
      border.paint.color = const Color(0xFFF44336).withOpacity(0.4);
    }
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    if (currentItem == null) return false;
    
    final localPoint = event.localPosition;
    
    // Check if buy button was tapped
    if (buyButton.containsLocalPoint(localPoint - buyButton.position)) {
      attemptPurchase();
      return true;
    }
    
    // Check if item info area was tapped (anywhere except buy button)
    if (localPoint.y < buyButton.position.y) {
      showItemDetails();
      return true;
    }
    
    return false;
  }
  
  void showItemDetails() {
    if (currentItem == null) return;
    
    final detailCard = ItemDetailCard(
      item: currentItem!,
      onClose: () {
        // Detail card handles its own removal
      },
    );
    
    // Add to the game at a high priority to appear on top
    gameRef.add(detailCard);
    
    // Play UI sound effect
    // SoundManager().playUICardOpenSound();
  }
  
  void attemptPurchase() {
    if (currentItem == null) return;
    
    if (gameRef.hero.coins >= currentItem!.cost) {
      gameRef.hero.spendCoins(currentItem!.cost);
      currentItem!.onPurchase();
      
      // Play purchase sound effect
      SoundManager().playPurchaseSound();
      
      // Clear this slot with enhanced sold styling
      currentItem = null;
      nameText.text = 'SOLD';
      nameText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Color(0xFF4CAF50),
          fontSize: 17.6,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Color(0xFF4CAF50),
              blurRadius: 8,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 3,
            ),
          ],
        ),
      );
      descriptionText.text = 'Item purchased successfully!';
      descriptionText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Color(0xFF4CAF50),
          fontSize: 13.2,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      );
      costText.text = '';
      
      // Update buy button to sold out styling
      buyButton.paint.shader = const LinearGradient(
        colors: [
          Color(0xFF757575),
          Color(0xFF616161),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 143, 44));
      
      buyButtonGlow.paint.color = const Color(0xFF757575).withOpacity(0.3);
      buyButtonText.text = 'SOLD OUT';
      
      // Update border and glow to success green
      border.paint.color = const Color(0xFF4CAF50).withOpacity(0.8);
      outerGlow.paint.color = const Color(0xFF4CAF50).withOpacity(0.2);
      
      // Clear the item icon - handle both SpriteComponent and RectangleComponent types
      if (itemIcon.isMounted) {
        itemIcon.removeFromParent();
      }
      
      // Add transparent placeholder
      itemIcon = RectangleComponent(
        size: Vector2(44, 44),
        position: Vector2((size.x - 44) / 2, 22),
        paint: Paint()..color = Colors.transparent,
      );
      add(itemIcon);
      
      // Update parent shop immediately
      if (parent is ShopPanel) {
        (parent as ShopPanel).onItemPurchased();
      }
    }
  }
} 
```

Now I need to update the hero to track kills and implement the kill-based max health system:

I need to find where the kill tracking and enemy destroyed logic is handled:

Let me check how the enemy destroyed system works and add kill tracking:

I need to add kill tracking to the hero and implement the Auto Injector logic. Let me first add a kill counter to the Hero class:

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/circle_rouge_game.dart';
import '../config/hero_config.dart';
import '../config/display_config.dart';
import 'abilities/hex_field.dart';
import 'enemies/enemy_chaser.dart';
import 'enemies/enemy_shooter.dart';
import 'enemies/shielded_chaser.dart';
import 'enemies/projectile.dart';
import 'enemies/shape_projectile.dart';
import 'enemies/triangle_projectile.dart';
import 'sound_manager.dart';
import 'companions/drone_wingman.dart';
import 'companions/hero_clone.dart';

class TemporaryEffect {
  final String type;
  final double value;
  final double duration;
  double remainingTime;
  
  TemporaryEffect({
    required this.type,
    required this.value,
    required this.duration,
  }) : remainingTime = duration;
  
  void update(double dt) {
    remainingTime -= dt;
  }
  
  bool get isExpired => remainingTime <= 0;
}

class Hero extends PositionComponent with HasGameRef<CircleRougeGame>, KeyboardHandler {
  // Hero configuration
  late HeroData heroData;
  final String heroId;
  
  // Hero visual properties
  late double heroRadius;
  late Paint heroPaint;
  
  // Base movement properties - will be scaled based on arena size
  static const double baseMoveSpeed = 200.0;
  
  // Base dash properties (for heroes that don't have special abilities)
  static const double baseDashDistance = 120.0;
  static const double baseDashSpeed = 500.0;
  
  // Base shooting properties
  static const double baseShootRange = 250.0;
  static const double fireRate = 2.0; // Shots per second
  double lastShotTime = 0.0;
  
  // Get scaled values based on arena size
  double get moveSpeed => (heroData.moveSpeed / 320.0 * baseMoveSpeed) * DisplayConfig.instance.scaleFactor;
  double get dashDistance => baseDashDistance * DisplayConfig.instance.scaleFactor;
  double get dashSpeed => baseDashSpeed * DisplayConfig.instance.scaleFactor;
  double get shootRange => baseShootRange * DisplayConfig.instance.scaleFactor * rangeMultiplier;
  
  // Attack speed modifier (can be upgraded)
  double attackSpeedMultiplier = 1.0;
  
  // Movement speed modifier (can be upgraded)
  double speedMultiplier = 1.0;
  
  // Ability cooldown modifier (can be upgraded)
  double abilityCooldownMultiplier = 1.0;
  
  // Range modifier (can be upgraded)
  double rangeMultiplier = 1.0;
  
  // Weapon overclock visual effect
  // Weapon overclock now handled by temporary effect system
  
  // Ability system
  double lastAbilityTime = -double.infinity;
  bool isUsingAbility = false;
  Vector2? abilityTarget;
  
  // Hero stats
  double health = 100.0;
  double maxHealth = 100.0;
  double energy = 100.0;
  double maxEnergy = 100.0;
  int coins = 0;
  int killCount = 0;
  
  // Invincibility after wave completion
  bool isInvincible = false;
  double invincibilityTimer = 0.0;
  static const double invincibilityDuration = 3.0; // 3 seconds of invincibility
  
  // Damage invincibility (separate from wave completion invincibility)
  bool isDamageInvincible = false;
  double damageInvincibilityTimer = 0.0;
  static const double damageInvincibilityDuration = 0.5; // 0.5 seconds after taking damage
  
  // Temporary effects system
  final Map<String, TemporaryEffect> _temporaryEffects = {};
  
  // Stackable passive effects system
  final Map<String, int> _passiveEffectStacks = {};
  
  // Drone companion system
  final List<DroneWingman> _activeDrones = [];
  
  // Clone system
  HeroClone? _activeClone;
  
  // Shield system
  double shield = 0.0;
  double maxShield = 0.0;
  
  // Input tracking
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  
  Hero({required Vector2 position, required this.heroId}) : super(
    position: position,
    size: Vector2.all(30.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    heroRadius = 15.0 * DisplayConfig.instance.scaleFactor;
    heroPaint = Paint()..color = const Color(0xFF4CAF50);
    _initializeHero(heroId);
  }
  
  void _initializeHero(String heroId) {
    final heroConfig = HeroConfig.instance.getHeroById(heroId);
    if (heroConfig != null) {
      heroData = heroConfig;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    } else {
      // Fallback to default circle hero
      heroData = HeroConfig.instance.defaultHero;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    }
  }
  
  double get effectiveMaxHealth {
    return maxHealth + totalMaxHealthBoost;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Blinking effect during damage invincibility
    if (isDamageInvincible) {
      final blinkTime = (damageInvincibilityTimer * 8) % 1.0; // 8 blinks per second
      if (blinkTime > 0.5) {
        return; // Don't render during blink "off" phase
      }
    }
    
    final center = Offset(size.x / 2, size.y / 2);
    final shapeSize = size.x;
    
    // Old weapon overclock glow removed - now handled by active effect glow
    
    // Active effect glow
    final activeEffect = currentActiveEffect;
    if (activeEffect != null) {
      final effectTime = (DateTime.now().millisecondsSinceEpoch / 1000.0) % 1.5; // 1.5-second cycle
      final glowIntensity = (sin(effectTime * pi * 2) * 0.3 + 0.7); // 0.4 to 1.0
      final glowRadius = 15.0 * glowIntensity;
      
      // Get effect color
      Color effectColor;
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
        default:
          effectColor = const Color(0xFFFFFFFF); // White fallback
      }
      
      final effectGlowPaint = Paint()
        ..color = effectColor.withOpacity(0.8 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      // Draw effect glow based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + glowRadius, effectGlowPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'square':
          _drawSquare(canvas, center, effectGlowPaint, glowRadius);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
      }
    }
    
    // Draw main hero shape
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(center, heroRadius, heroPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, shapeSize, heroPaint, 0);
        break;
      case 'square':
        _drawSquare(canvas, center, heroPaint, 0);
        break;
      case 'pentagon':
        _drawPentagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'hexagon':
        _drawHexagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, shapeSize, heroPaint, 0);
        break;
    }
    
    // Draw shield outline if shield effect is active
    if (hasTemporaryEffect('shield') && shield > 0) {
      final shieldOpacity = (shield / maxShield).clamp(0.3, 1.0); // Fade as shield depletes
      final shieldPaint = Paint()
        ..color = const Color(0xFFFF9800).withOpacity(0.6 * shieldOpacity) // Orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Draw shield outline based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + 4, shieldPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'square':
          _drawSquare(canvas, center, shieldPaint, 4);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, shieldPaint, 4);
          break;
      }
    }
    
  }
  
  void _drawTriangle(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius / 2);
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius / 2);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSquare(Canvas canvas, Offset center, Paint paint, double glowRadius) {
    final size = (this.size.x * 0.8) + (glowRadius * 2);
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      ),
      paint,
    );
  }
  
  void _drawPentagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 5; i++) {
      final angle = -90 + (i * 72); // Pentagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHexagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 6; i++) {
      final angle = -90 + (i * 60); // Hexagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHeptagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  // Collision detection method for other components to use
  @override
  bool containsPoint(Vector2 point) {
    final distance = position.distanceTo(point);
    return distance <= heroRadius;
  }
  
  // Get collision radius for enemy collision detection
  double get collisionRadius => heroRadius;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Weapon overclock now handled by temporary effect system
    
    // Update invincibility timer
    if (isInvincible) {
      invincibilityTimer += dt;
      if (invincibilityTimer >= invincibilityDuration) {
        isInvincible = false;
        invincibilityTimer = 0.0;
      }
    }
    
    // Update damage invincibility timer
    if (isDamageInvincible) {
      damageInvincibilityTimer += dt;
      if (damageInvincibilityTimer >= damageInvincibilityDuration) {
        isDamageInvincible = false;
        damageInvincibilityTimer = 0.0;
      }
    }
    
    // Update temporary effects
    _updateTemporaryEffects(dt);
    
    if (isUsingAbility) {
      _updateAbility(dt);
    } else {
      _updateMovement(dt);
    }
    
    // Auto-shoot at enemies
    _tryAutoShoot();
    
    // Regenerate energy
    if (energy < maxEnergy) {
      energy = (energy + 50 * dt).clamp(0, maxEnergy);
    }
    
    // Keep hero within arena bounds
    _constrainToArena();
    
    // Update ability cooldown in HUD
    _updateAbilityCooldownDisplay();
  }
  
  void _tryAutoShoot() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    if (currentTime - lastShotTime < (1.0 / (fireRate * attackSpeedMultiplier))) {
      return; // Still on cooldown
    }
    
    // Find nearest enemy
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance && distance <= shootRange) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    // Shoot at nearest enemy if found
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      final direction = (nearestEnemy.position - position).normalized();
      _fireProjectile(direction);
      lastShotTime = currentTime;
    }
  }
  
  void _fireProjectile(Vector2 direction) {
    final projectileCount = totalProjectileCount;
    final projectileBounces = totalProjectileBounces;
    final projectileScale = totalProjectileSize;
    final critChance = totalCritChance;
    
    // Calculate spread angle if multiple projectiles
    final spreadAngle = projectileCount > 1 ? pi / 6 : 0.0; // 30 degrees total spread
    final angleStep = projectileCount > 1 ? spreadAngle / (projectileCount - 1) : 0.0;
    final startAngle = projectileCount > 1 ? -spreadAngle / 2 : 0.0;
    
    for (int i = 0; i < projectileCount; i++) {
      // Calculate direction for each projectile
      Vector2 projectileDirection;
      if (projectileCount == 1) {
        projectileDirection = direction;
      } else {
        final angle = startAngle + (i * angleStep);
        final baseAngle = atan2(direction.y, direction.x);
        final newAngle = baseAngle + angle;
        projectileDirection = Vector2(cos(newAngle), sin(newAngle));
      }
      
      // Check for critical hit (now instant kill, so damage doesn't matter)
      final isCritical = Random().nextDouble() < critChance;
      final finalDamage = 25.0; // Base damage (critical = instant kill)
      
      final projectile = ShapeProjectile(
        startPosition: position.clone(),
        direction: projectileDirection,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: finalDamage,
        isEnemyProjectile: false,
        shapeType: heroData.shape,
        heroColor: heroData.color,
        bounces: projectileBounces,
        sizeScale: projectileScale,
        isCritical: isCritical,
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _updateMovement(double dt) {
    Vector2 inputDirection = Vector2.zero();
    
    // Handle WASD movement
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      inputDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      inputDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      inputDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      inputDirection.x += 1;
    }
    
    // Normalize and apply movement
    if (inputDirection.length > 0) {
      inputDirection.normalize();
      position += inputDirection * moveSpeed * effectiveSpeedMultiplier * dt;
    }
  }
  
  void _updateAbility(double dt) {
    // Handle different ability types based on hero configuration
    switch (heroData.ability.type) {
      case 'dash_damage':
        _updateDashDamage(dt);
        break;
      case 'piercing_shot':
        // Piercing shot is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_stun':
        // Area stun is instant, no update needed
        isUsingAbility = false;
        break;
      case 'radial_burst':
        // Radial burst is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_field':
        // Area field is instant placement, no update needed
        isUsingAbility = false;
        break;
      default:
        isUsingAbility = false;
    }
  }
  
  void _updateDashDamage(double dt) {
    if (abilityTarget == null) {
      isUsingAbility = false;
      return;
    }
    
    final direction = (abilityTarget! - position).normalized();
    final movement = direction * dashSpeed * dt;
    
    // Check for enemy collisions during dash
    // Create a copy to avoid ConcurrentModificationError
    final enemiesCopy = List<Component>.from(gameRef.currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy is PositionComponent) {
        final distanceToEnemy = position.distanceTo(enemy.position);
        // Use different radius checks for different enemy types
        double enemyRadius = 15.0 * DisplayConfig.instance.scaleFactor; // Default radius
        
        if (enemy is EnemyChaser) {
          enemyRadius = enemy.radius;
        } else if (enemy is EnemyShooter) {
          enemyRadius = enemy.radius;
        } else if (enemy is ShieldedChaser) {
          enemyRadius = enemy.radius;
        }
        
        if (distanceToEnemy < heroRadius + enemyRadius) {
          // Damage enemy during rolling surge
          if (enemy is EnemyChaser) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is EnemyShooter) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is ShieldedChaser) {
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          } else {
            // Fallback for other enemy types - remove them directly
            if (enemy.parent != null) {
              gameRef.onEnemyDestroyed(enemy);
            }
          }
        }
      }
    }
    
    if (position.distanceTo(abilityTarget!) <= movement.length) {
      position = abilityTarget!;
      isUsingAbility = false;
      abilityTarget = null;
    } else {
      position += movement;
    }
  }
  
  void _tryAbility() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    
    if (currentTime - lastAbilityTime < effectiveCooldown || energy < 25) {
      return; // Ability on cooldown or not enough energy
    }
    
    switch (heroData.ability.type) {
      case 'dash_damage':
        _executeDashDamage();
        break;
      case 'piercing_shot':
        _executePiercingShot();
        break;
      case 'area_stun':
        _executeAreaStun();
        break;
      case 'radial_burst':
        _executeRadialBurst();
        break;
      case 'area_field':
        _executeAreaField();
        break;
      case 'resonance_knockback':
        _executeResonanceKnockback();
        break;
    }
    
    lastAbilityTime = currentTime;
    energy -= 25; // Ability costs energy
  }
  
  void _executeDashDamage() {
    // Play sound effect for circle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Get current input direction for rolling surge
    Vector2 dashDirection = Vector2.zero();
    
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dashDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dashDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dashDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dashDirection.x += 1;
    }
    
    // If no input, dash forward (up)
    if (dashDirection.length == 0) {
      dashDirection = Vector2(0, -1);
    }
    
    dashDirection.normalize();
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    abilityTarget = position + dashDirection * scaledRange;
    
    // Constrain ability target to arena
    abilityTarget!.x = abilityTarget!.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    abilityTarget!.y = abilityTarget!.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
    
    isUsingAbility = true;
  }
  
  void _executePiercingShot() {
    // Play sound effect for triangle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Find direction to nearest enemy or shoot forward
    Vector2 direction = Vector2(0, -1); // Default forward
    
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      direction = (nearestEnemy.position - position).normalized();
    }
    
    // Create massive triangle projectile with hero color and range scaling
    final projectile = TriangleProjectile(
      startPosition: position.clone(),
      direction: direction,
      speed: 500.0 * DisplayConfig.instance.scaleFactor,
      damage: heroData.ability.damage,
      isEnemyProjectile: false,
      heroColor: heroData.color, // Pass hero color
      rangeMultiplier: rangeMultiplier, // Scale with range upgrades
    );
    
    gameRef.add(projectile);
  }
  
  void _executeAreaStun() {
    // Play sound effect for square hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Calculate effective range (now has range limitation)
    final effectiveRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final stunDuration = heroData.ability.stunDuration ?? 3.0;
    
    // Create visual effect for the ability
    _createSquareAbilityEffect(effectiveRange);
    
    // Stun enemies within range
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= effectiveRange) {
          // Apply stun effect to different enemy types
          if (enemy is EnemyChaser) {
            enemy.stun(stunDuration);
          } else if (enemy is EnemyShooter) {
            enemy.stun(stunDuration);
          } else if (enemy is ShieldedChaser) {
            enemy.stun(stunDuration);
            // Also instantly break shield with ability damage
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          }
        }
      }
    }
    
    // Stun enemy projectiles within range
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= effectiveRange) {
          // Check if it's an enemy projectile and apply slow effect (stun)
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectile.applySlowEffect(0.0); // 0 speed = stunned
          }
        }
      }
    }
    
    print('Shield Bash! Stunned enemies within ${effectiveRange.toInt()} range for ${stunDuration}s');
  }
  
  void _executeRadialBurst() {
    // Play sound effect for pentagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Fire projectiles in all directions
    final projectileCount = heroData.ability.projectileCount ?? 5;
    final angleStep = (2 * pi) / projectileCount;
    
    for (int i = 0; i < projectileCount; i++) {
      final angle = i * angleStep;
      final direction = Vector2(cos(angle), sin(angle));
      
      // Create scaled projectile based on range multiplier
      final scaledRadius = 6.0 * DisplayConfig.instance.scaleFactor * rangeMultiplier;
      
      final projectile = Projectile(
        startPosition: position.clone(),
        direction: direction,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: heroData.ability.damage,
        isEnemyProjectile: false,
        heroColor: heroData.color,
        scaledRadius: scaledRadius, // Pass scaled radius for bullet size
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _executeAreaField() {
    // Play sound effect for hexagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Create visual hex field effect
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final duration = heroData.ability.duration ?? 4.0;
    
    final hexField = HexField(
      position: position.clone(),
      radius: scaledRange,
      duration: duration,
      damage: heroData.ability.damage,
      slowPercent: heroData.ability.slowPercent ?? 0.3,
    );
    
    gameRef.add(hexField);
  }
  
  void _executeResonanceKnockback() {
    // Play sound effect for heptagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final knockbackDistance = (heroData.ability.knockbackDistance ?? 30.0) * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    
    // Create visual effect for the ability
    _createHeptagonAbilityEffect(scaledRange);
    
    // Find enemies within range and apply damage + knockback
    final enemiesToKnockback = <Component>[];
    final projectilesToPush = <Component>[];
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= scaledRange) {
          enemiesToKnockback.add(enemy);
        }
      }
    }
    
    // Find enemy projectiles within range to push away and stun them
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= scaledRange) {
          // Check if it's an enemy projectile
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectilesToPush.add(projectile);
          }
        }
      }
    }
    
    // Apply damage and knockback to all enemies in range
    for (final enemy in enemiesToKnockback) {
      if (enemy is PositionComponent) {
        // Apply damage
        if (enemy is EnemyChaser) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is EnemyShooter) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is ShieldedChaser) {
          enemy.takeDamage(heroData.ability.damage, isAbility: true);
        }
        
        // Apply knockback
        final directionToEnemy = (enemy.position - position).normalized();
        final knockbackTarget = enemy.position + directionToEnemy * knockbackDistance;
        
        // Constrain knockback target to arena bounds
        final constrainedTarget = Vector2(
          knockbackTarget.x.clamp(50.0, DisplayConfig.instance.arenaWidth - 50.0),
          knockbackTarget.y.clamp(50.0, DisplayConfig.instance.arenaHeight - 50.0),
        );
        
        enemy.position = constrainedTarget;
      }
    }
    
    // Push away enemy projectiles
    for (final projectile in projectilesToPush) {
      if (projectile is PositionComponent) {
        final directionToProjectile = (projectile.position - position).normalized();
        final pushTarget = projectile.position + directionToProjectile * knockbackDistance;
        
        // Constrain push target to arena bounds
        final constrainedTarget = Vector2(
          pushTarget.x.clamp(0.0, DisplayConfig.instance.arenaWidth),
          pushTarget.y.clamp(0.0, DisplayConfig.instance.arenaHeight),
        );
        
        projectile.position = constrainedTarget;
      }
    }
    
    // Visual feedback
    print('Resonance Knockback! Hit ${enemiesToKnockback.length} enemies and pushed ${projectilesToPush.length} projectiles');
  }
  
  void _updateAbilityCooldownDisplay() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final timeSinceLastAbility = currentTime - lastAbilityTime;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    final cooldownPercent = (timeSinceLastAbility / effectiveCooldown).clamp(0.0, 1.0);
    final remainingSeconds = (effectiveCooldown - timeSinceLastAbility).clamp(0.0, effectiveCooldown);
    
    if (gameRef.hud.isMounted) {
      gameRef.hud.updateAbilityCooldown(cooldownPercent, remainingSeconds);
    }
  }
  
  void _constrainToArena() {
    position.x = position.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    position.y = position.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    
    // Handle universal escape key navigation
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      // Check if stats overlay is visible and hide it first
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
        return true;
      }
      
      // Check if shop is open and close it
      if (gameRef.gameState == GameState.shopping) {
        gameRef.onShopClosed();
        return true;
      }
      
      // Handle pause/resume for playing state
      if (gameRef.gameState == GameState.playing) {
        gameRef.pauseGame();
        return true;
      } else if (gameRef.gameState == GameState.paused) {
        gameRef.resumeGame();
        return true;
      }
    }
    
    // Handle ability (K key only)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyK) {
      _tryAbility();
      return true;
    }
    
    // Handle clone activation with 'C' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (canActivateClone()) {
        activateClone();
      }
      return true;
    }
    
    // Handle stats overlay toggle with 'I' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyI) {
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
      } else {
        gameRef.statsOverlay.show();
      }
      return true;
    }
    
    return false;
  }
  
  void takeDamage(double damage) {
    if (isInvincible || isDamageInvincible || isUsingAbility) {
      return; // No damage while invincible, damage invincible, or using ability
    }
    
    double remainingDamage = damage;
    
    // Shield absorbs damage first
    if (shield > 0) {
      if (shield >= remainingDamage) {
        // Shield absorbs all damage
        shield -= remainingDamage;
        remainingDamage = 0;
      } else {
        // Shield absorbs partial damage and breaks
        remainingDamage -= shield;
        shield = 0;
        
        // Remove shield effect when shield is broken
        if (hasTemporaryEffect('shield')) {
          print('Shield broken! Removing shield effect.');
          _removeEffectImmediate('shield');
          _temporaryEffects.remove('shield');
        }
      }
    }
    
    // Apply remaining damage to health
    if (remainingDamage > 0) {
      health = (health - remainingDamage).clamp(0, maxHealth);
    }
    
    // Activate damage invincibility
    isDamageInvincible = true;
    damageInvincibilityTimer = 0.0;
    
    if (health <= 0) {
      gameRef.onHeroDeath();
    }
  }
  
  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
  
  void addCoins(int amount) {
    final multiplier = totalCoinMultiplier;
    final finalAmount = (amount * multiplier).round();
    coins += finalAmount;
    if (multiplier > 1.0) {
      print('Coin Magnet: ${amount} -> ${finalAmount} coins (${multiplier}x)');
    }
  }
  
  void spendCoins(int amount) {
    coins = max(0, coins - amount);
  }
  
  void activateInvincibility() {
    isInvincible = true;
    invincibilityTimer = invincibilityDuration;
  }
  
  void _createSquareAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'square',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  void _createHeptagonAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'heptagon',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  // Temporary effects system - only one effect at a time
  void applyTemporaryEffect(String effectType, double value, double duration) {
    // Remove any existing effect first (only one at a time)
    if (_temporaryEffects.isNotEmpty) {
      final oldEffect = _temporaryEffects.entries.first;
      _removeEffectImmediate(oldEffect.key);
      _temporaryEffects.clear();
      print('Replaced effect: ${oldEffect.key} -> $effectType');
    }
    
    // Apply new effect
    _temporaryEffects[effectType] = TemporaryEffect(
      type: effectType,
      value: value,
      duration: duration,
    );
    
    // Apply immediate effects
    _applyEffectImmediate(effectType, value);
    
    print('Applied temporary effect: $effectType (${value}, ${duration}s)');
  }
  
  void _updateTemporaryEffects(double dt) {
    final expiredEffects = <String>[];
    
    for (final entry in _temporaryEffects.entries) {
      final effect = entry.value;
      effect.update(dt);
      
      if (effect.isExpired) {
        expiredEffects.add(entry.key);
        _removeEffectImmediate(entry.key);
      } else {
        // Apply ongoing effects
        _applyEffectOngoing(effect.type, effect.value, dt);
      }
    }
    
    // Remove expired effects
    for (final effectType in expiredEffects) {
      _temporaryEffects.remove(effectType);
    }
  }
  
  void _applyEffectImmediate(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
        speedMultiplier *= (1.0 + value);
        break;
      case 'damage_boost':
        // This will be applied in damage calculations
        break;
      case 'shield':
        shield += value;
        maxShield = maxShield > shield ? maxShield : shield;
        break;
      case 'invincibility':
        isInvincible = true;
        invincibilityTimer = 0.0;
        break;
      case 'weapon_overclock':
        attackSpeedMultiplier *= (1.0 + value);
        break;
    }
  }
  
  void _applyEffectOngoing(String effectType, double value, double dt) {
    switch (effectType) {
      case 'health_regen':
        heal(value * dt);
        break;
    }
  }
  
  void _removeEffectImmediate(String effectType) {
    switch (effectType) {
      case 'speed_boost':
        // Note: This is a simplified approach. In a full implementation,
        // you'd want to track the original multiplier and restore it
        speedMultiplier = 1.0; // Reset to base
        break;
      case 'damage_boost':
        // Reset damage multiplier
        break;
      case 'shield':
        // Shield naturally decays over time
        break;
      case 'invincibility':
        // Invincibility expires naturally
        break;
      case 'weapon_overclock':
        // Reset attack speed multiplier
        attackSpeedMultiplier = 1.0; // Reset to base
        break;
    }
  }
  
  // Get effective damage multiplier including temporary effects
  double get effectiveDamageMultiplier {
    double multiplier = 1.0;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'damage_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Get effective speed multiplier including temporary effects
  double get effectiveSpeedMultiplier {
    double multiplier = speedMultiplier;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'speed_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Check if hero has a specific temporary effect
  bool hasTemporaryEffect(String effectType) {
    return _temporaryEffects.containsKey(effectType);
  }
  
  // Get remaining time for a temporary effect
  double getTemporaryEffectTime(String effectType) {
    final effect = _temporaryEffects[effectType];
    return effect?.remainingTime ?? 0.0;
  }
  
  // Get current active effect for UI display
  TemporaryEffect? get currentActiveEffect {
    return _temporaryEffects.isNotEmpty ? _temporaryEffects.values.first : null;
  }
  
  // Get current active effect info as a formatted string
  String get activeEffectDisplay {
    final effect = currentActiveEffect;
    if (effect == null) return 'None';
    
    final effectName = _getEffectDisplayName(effect.type);
    final effectValue = _getEffectDisplayValue(effect.type, effect.value);
    
    // Handle infinite duration effects (like persistent shields)
    if (effect.remainingTime.isInfinite || effect.remainingTime.isNaN) {
      return '$effectName $effectValue (∞)';
    }
    
    final timeLeft = effect.remainingTime.ceil();
    return '$effectName $effectValue (${timeLeft}s)';
  }
  
  String _getEffectDisplayName(String effectType) {
    switch (effectType) {
      case 'speed_boost': return 'Speed';
      case 'damage_boost': return 'Damage';
      case 'health_regen': return 'Regen';
      case 'shield': return 'Shield';
      case 'invincibility': return 'Invul';
      case 'weapon_overclock': return 'Overclock';
      default: return effectType;
    }
  }
  
  String _getEffectDisplayValue(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
      case 'damage_boost':
      case 'weapon_overclock':
        return '+${(value * 100).round()}%';
      case 'health_regen':
        return '+${value.round()}/s';
      case 'shield':
        return '+${value.round()}';
      case 'invincibility':
        return 'ON';
      default:
        return value.toString();
    }
  }

  // Stackable passive effects system
  void addPassiveEffect(String effectType, int maxStacks) {
    final currentStacks = _passiveEffectStacks[effectType] ?? 0;
    if (currentStacks < maxStacks) {
      _passiveEffectStacks[effectType] = currentStacks + 1;
      print('Added passive effect: $effectType (${currentStacks + 1}/$maxStacks stacks)');
    } else {
      print('Cannot add $effectType: already at max stacks ($maxStacks)');
    }
  }
  
  int getPassiveEffectStacks(String effectType) {
    return _passiveEffectStacks[effectType] ?? 0;
  }
  
  bool hasPassiveEffect(String effectType) {
    return _passiveEffectStacks.containsKey(effectType) && _passiveEffectStacks[effectType]! > 0;
  }
  
  // Get calculated values based on passive effects
  int get totalProjectileCount {
    return 1 + getPassiveEffectStacks('projectile_count');
  }
  
  int get totalProjectileBounces {
    return getPassiveEffectStacks('projectile_bounces');
  }
  
  double get totalProjectileSize {
    return 1.0 + (getPassiveEffectStacks('projectile_size') * 0.5); // 50% increase per stack
  }
  
  int get totalDroneCount {
    return getPassiveEffectStacks('drone_count');
  }
  
  double get totalLifeSteal {
    return getPassiveEffectStacks('life_steal') * 0.05;
  }
  
  double get totalShieldHP {
    return getPassiveEffectStacks('shield_hp') * 5.0;
  }
  
  double get totalCoinMultiplier {
    return 1.0 + (getPassiveEffectStacks('coin_multiplier') * 0.2);
  }
  
  double get totalHealPerKill {
    return getPassiveEffectStacks('heal_per_kill') * 2.0;
  }
  
  double get totalCritChance {
    return getPassiveEffectStacks('crit_chance') * 0.02;
  }
  
  double get totalMaxHealthBoost {
    return getPassiveEffectStacks('max_health_boost') * 10.0;
  }
  
  bool get hasCloneProjection {
    return hasPassiveEffect('clone_spawn');
  }
  
  void resetPassiveEffects() {
    _passiveEffectStacks.clear();
    destroyAllDrones();
    destroyClone();
  }
  
  // Apply heal per kill effect when an enemy is defeated
  void onEnemyKilled() {
    final healAmount = totalHealPerKill;
    if (healAmount > 0) {
      heal(healAmount);
      print('Healed ${healAmount} HP from kill');
    }
  }
  
  // Regenerate shields between waves (Armor Plating effect)
  void regenerateShields() {
    final armorShields = totalShieldHP;
    if (armorShields > 0) {
      // Apply armor plating as a persistent shield effect
      applyTemporaryEffect('shield', armorShields, double.infinity);
      print('Armor plating shields regenerated to ${armorShields.toStringAsFixed(1)} HP');
    }
  }
  
  // Drone management system
  void updateDroneCount() {
    final targetDroneCount = totalDroneCount;
    final currentDroneCount = _activeDrones.length;
    
    if (targetDroneCount > currentDroneCount) {
      // Spawn new drones
      for (int i = currentDroneCount; i < targetDroneCount; i++) {
        final drone = DroneWingman(owner: this, droneIndex: i);
        _activeDrones.add(drone);
        gameRef.add(drone);
        print('Spawned drone ${i + 1}/${targetDroneCount}');
      }
    } else if (targetDroneCount < currentDroneCount) {
      // Remove excess drones
      while (_activeDrones.length > targetDroneCount) {
        final drone = _activeDrones.removeLast();
        drone.destroy();
        print('Removed drone. Remaining: ${_activeDrones.length}');
      }
    }
  }
  
  void destroyAllDrones() {
    for (final drone in _activeDrones) {
      drone.destroy();
    }
    _activeDrones.clear();
    print('All drones destroyed');
  }
  
  // Clone management system
  bool canActivateClone() {
    return hasCloneProjection && _activeClone == null && health > maxHealth * 0.5;
  }
  
  void activateClone() {
    print('🤖 Attempting to activate clone...');
    print('   - Has clone projection: ${hasCloneProjection}');
    print('   - No active clone: ${_activeClone == null}');
    print('   - Current health: ${health.toStringAsFixed(1)}/${maxHealth.toStringAsFixed(1)}');
    print('   - Required health: ${(maxHealth * 0.5).toStringAsFixed(1)}');
    
    if (!canActivateClone()) {
      print('❌ Cannot activate clone: requirements not met');
      return;
    }
    
    // Pay health cost (50% of current health)
    final healthCost = health * 0.5;
    health -= healthCost;
    
    // Spawn clone directly to the right with clear gap
    final cloneOffset = Vector2(80, 0); // Simple fixed offset to the right
    final clonePosition = position + cloneOffset;
    
    print('🤖 Creating HeroClone at position: (${clonePosition.x}, ${clonePosition.y})');
    _activeClone = HeroClone(owner: this, spawnPosition: clonePosition);
    
    print('🤖 Adding clone to game...');
    gameRef.add(_activeClone!);
    
    print('✅ CLONE ACTIVATED! Health cost: ${healthCost.toStringAsFixed(1)}, Clone mounted: ${_activeClone!.isMounted}');
  }
  
  void destroyClone() {
    if (_activeClone != null) {
      _activeClone!.destroy();
      _activeClone = null;
      print('Clone destroyed');
    }
  }
  
  bool get hasActiveClone => _activeClone != null;
  
  // Getter for passive effect stacks (for stats display)
  Map<String, int> get passiveEffectStacks => Map.from(_passiveEffectStacks);
  
  void onCloneDestroyed(HeroClone clone) {
    if (_activeClone == clone) {
      _activeClone = null;
      print('Active clone reference cleared');
    }
  }
}

// Visual effect component for abilities
class AbilityVisualEffect extends PositionComponent with HasGameRef<CircleRougeGame> {
  final double effectRange;
  final String shape;
  final Color color;
  
  double lifetime = 0.0;
  static const double totalLifetime = 0.5; // Blink once and disappear
  static const double blinkDuration = 0.25; // Half the lifetime for one blink
  
  AbilityVisualEffect({
    required Vector2 position,
    required this.effectRange,
    required this.shape,
    required this.color,
  }) : super(
    position: position,
    size: Vector2.all(effectRange * 2),
    anchor: Anchor.center,
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    lifetime += dt;
    
    // Remove after total lifetime
    if (lifetime >= totalLifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Calculate opacity with blinking effect
    final blinkProgress = (lifetime / blinkDuration) % 1.0;
    final opacity = (sin(blinkProgress * pi * 2) * 0.15 + 0.1).clamp(0.0, 0.25); // 25% max opacity
    
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = color.withOpacity(opacity * 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Draw the shape based on type
    switch (shape) {
      case 'square':
        final rect = Rect.fromCenter(
          center: center,
          width: effectRange * 2,
          height: effectRange * 2,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;
      case 'heptagon':
        final path = _createHeptagonPath(center, effectRange);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }
  
  Path _createHeptagonPath(Offset center, double radius) {
    final path = Path();
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * pi / 180);
      final y = center.dy + radius * sin(angle * pi / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    return path;
  }
} 
```

Now I need to update the onEnemyKilled method to handle the kill-based max health system:

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/circle_rouge_game.dart';
import '../config/hero_config.dart';
import '../config/display_config.dart';
import 'abilities/hex_field.dart';
import 'enemies/enemy_chaser.dart';
import 'enemies/enemy_shooter.dart';
import 'enemies/shielded_chaser.dart';
import 'enemies/projectile.dart';
import 'enemies/shape_projectile.dart';
import 'enemies/triangle_projectile.dart';
import 'sound_manager.dart';
import 'companions/drone_wingman.dart';
import 'companions/hero_clone.dart';

class TemporaryEffect {
  final String type;
  final double value;
  final double duration;
  double remainingTime;
  
  TemporaryEffect({
    required this.type,
    required this.value,
    required this.duration,
  }) : remainingTime = duration;
  
  void update(double dt) {
    remainingTime -= dt;
  }
  
  bool get isExpired => remainingTime <= 0;
}

class Hero extends PositionComponent with HasGameRef<CircleRougeGame>, KeyboardHandler {
  // Hero configuration
  late HeroData heroData;
  final String heroId;
  
  // Hero visual properties
  late double heroRadius;
  late Paint heroPaint;
  
  // Base movement properties - will be scaled based on arena size
  static const double baseMoveSpeed = 200.0;
  
  // Base dash properties (for heroes that don't have special abilities)
  static const double baseDashDistance = 120.0;
  static const double baseDashSpeed = 500.0;
  
  // Base shooting properties
  static const double baseShootRange = 250.0;
  static const double fireRate = 2.0; // Shots per second
  double lastShotTime = 0.0;
  
  // Get scaled values based on arena size
  double get moveSpeed => (heroData.moveSpeed / 320.0 * baseMoveSpeed) * DisplayConfig.instance.scaleFactor;
  double get dashDistance => baseDashDistance * DisplayConfig.instance.scaleFactor;
  double get dashSpeed => baseDashSpeed * DisplayConfig.instance.scaleFactor;
  double get shootRange => baseShootRange * DisplayConfig.instance.scaleFactor * rangeMultiplier;
  
  // Attack speed modifier (can be upgraded)
  double attackSpeedMultiplier = 1.0;
  
  // Movement speed modifier (can be upgraded)
  double speedMultiplier = 1.0;
  
  // Ability cooldown modifier (can be upgraded)
  double abilityCooldownMultiplier = 1.0;
  
  // Range modifier (can be upgraded)
  double rangeMultiplier = 1.0;
  
  // Weapon overclock visual effect
  // Weapon overclock now handled by temporary effect system
  
  // Ability system
  double lastAbilityTime = -double.infinity;
  bool isUsingAbility = false;
  Vector2? abilityTarget;
  
  // Hero stats
  double health = 100.0;
  double maxHealth = 100.0;
  double energy = 100.0;
  double maxEnergy = 100.0;
  int coins = 0;
  int killCount = 0;
  
  // Invincibility after wave completion
  bool isInvincible = false;
  double invincibilityTimer = 0.0;
  static const double invincibilityDuration = 3.0; // 3 seconds of invincibility
  
  // Damage invincibility (separate from wave completion invincibility)
  bool isDamageInvincible = false;
  double damageInvincibilityTimer = 0.0;
  static const double damageInvincibilityDuration = 0.5; // 0.5 seconds after taking damage
  
  // Temporary effects system
  final Map<String, TemporaryEffect> _temporaryEffects = {};
  
  // Stackable passive effects system
  final Map<String, int> _passiveEffectStacks = {};
  
  // Drone companion system
  final List<DroneWingman> _activeDrones = [];
  
  // Clone system
  HeroClone? _activeClone;
  
  // Shield system
  double shield = 0.0;
  double maxShield = 0.0;
  
  // Input tracking
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  
  Hero({required Vector2 position, required this.heroId}) : super(
    position: position,
    size: Vector2.all(30.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    heroRadius = 15.0 * DisplayConfig.instance.scaleFactor;
    heroPaint = Paint()..color = const Color(0xFF4CAF50);
    _initializeHero(heroId);
  }
  
  void _initializeHero(String heroId) {
    final heroConfig = HeroConfig.instance.getHeroById(heroId);
    if (heroConfig != null) {
      heroData = heroConfig;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    } else {
      // Fallback to default circle hero
      heroData = HeroConfig.instance.defaultHero;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    }
  }
  
  double get effectiveMaxHealth {
    return maxHealth + totalMaxHealthBoost;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Blinking effect during damage invincibility
    if (isDamageInvincible) {
      final blinkTime = (damageInvincibilityTimer * 8) % 1.0; // 8 blinks per second
      if (blinkTime > 0.5) {
        return; // Don't render during blink "off" phase
      }
    }
    
    final center = Offset(size.x / 2, size.y / 2);
    final shapeSize = size.x;
    
    // Old weapon overclock glow removed - now handled by active effect glow
    
    // Active effect glow
    final activeEffect = currentActiveEffect;
    if (activeEffect != null) {
      final effectTime = (DateTime.now().millisecondsSinceEpoch / 1000.0) % 1.5; // 1.5-second cycle
      final glowIntensity = (sin(effectTime * pi * 2) * 0.3 + 0.7); // 0.4 to 1.0
      final glowRadius = 15.0 * glowIntensity;
      
      // Get effect color
      Color effectColor;
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
        default:
          effectColor = const Color(0xFFFFFFFF); // White fallback
      }
      
      final effectGlowPaint = Paint()
        ..color = effectColor.withOpacity(0.8 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      // Draw effect glow based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + glowRadius, effectGlowPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'square':
          _drawSquare(canvas, center, effectGlowPaint, glowRadius);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
      }
    }
    
    // Draw main hero shape
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(center, heroRadius, heroPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, shapeSize, heroPaint, 0);
        break;
      case 'square':
        _drawSquare(canvas, center, heroPaint, 0);
        break;
      case 'pentagon':
        _drawPentagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'hexagon':
        _drawHexagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, shapeSize, heroPaint, 0);
        break;
    }
    
    // Draw shield outline if shield effect is active
    if (hasTemporaryEffect('shield') && shield > 0) {
      final shieldOpacity = (shield / maxShield).clamp(0.3, 1.0); // Fade as shield depletes
      final shieldPaint = Paint()
        ..color = const Color(0xFFFF9800).withOpacity(0.6 * shieldOpacity) // Orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Draw shield outline based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + 4, shieldPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'square':
          _drawSquare(canvas, center, shieldPaint, 4);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, shieldPaint, 4);
          break;
      }
    }
    
  }
  
  void _drawTriangle(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius / 2);
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius / 2);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSquare(Canvas canvas, Offset center, Paint paint, double glowRadius) {
    final size = (this.size.x * 0.8) + (glowRadius * 2);
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      ),
      paint,
    );
  }
  
  void _drawPentagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 5; i++) {
      final angle = -90 + (i * 72); // Pentagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHexagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 6; i++) {
      final angle = -90 + (i * 60); // Hexagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHeptagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  // Collision detection method for other components to use
  @override
  bool containsPoint(Vector2 point) {
    final distance = position.distanceTo(point);
    return distance <= heroRadius;
  }
  
  // Get collision radius for enemy collision detection
  double get collisionRadius => heroRadius;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Weapon overclock now handled by temporary effect system
    
    // Update invincibility timer
    if (isInvincible) {
      invincibilityTimer += dt;
      if (invincibilityTimer >= invincibilityDuration) {
        isInvincible = false;
        invincibilityTimer = 0.0;
      }
    }
    
    // Update damage invincibility timer
    if (isDamageInvincible) {
      damageInvincibilityTimer += dt;
      if (damageInvincibilityTimer >= damageInvincibilityDuration) {
        isDamageInvincible = false;
        damageInvincibilityTimer = 0.0;
      }
    }
    
    // Update temporary effects
    _updateTemporaryEffects(dt);
    
    if (isUsingAbility) {
      _updateAbility(dt);
    } else {
      _updateMovement(dt);
    }
    
    // Auto-shoot at enemies
    _tryAutoShoot();
    
    // Regenerate energy
    if (energy < maxEnergy) {
      energy = (energy + 50 * dt).clamp(0, maxEnergy);
    }
    
    // Keep hero within arena bounds
    _constrainToArena();
    
    // Update ability cooldown in HUD
    _updateAbilityCooldownDisplay();
  }
  
  void _tryAutoShoot() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    if (currentTime - lastShotTime < (1.0 / (fireRate * attackSpeedMultiplier))) {
      return; // Still on cooldown
    }
    
    // Find nearest enemy
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance && distance <= shootRange) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    // Shoot at nearest enemy if found
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      final direction = (nearestEnemy.position - position).normalized();
      _fireProjectile(direction);
      lastShotTime = currentTime;
    }
  }
  
  void _fireProjectile(Vector2 direction) {
    final projectileCount = totalProjectileCount;
    final projectileBounces = totalProjectileBounces;
    final projectileScale = totalProjectileSize;
    final critChance = totalCritChance;
    
    // Calculate spread angle if multiple projectiles
    final spreadAngle = projectileCount > 1 ? pi / 6 : 0.0; // 30 degrees total spread
    final angleStep = projectileCount > 1 ? spreadAngle / (projectileCount - 1) : 0.0;
    final startAngle = projectileCount > 1 ? -spreadAngle / 2 : 0.0;
    
    for (int i = 0; i < projectileCount; i++) {
      // Calculate direction for each projectile
      Vector2 projectileDirection;
      if (projectileCount == 1) {
        projectileDirection = direction;
      } else {
        final angle = startAngle + (i * angleStep);
        final baseAngle = atan2(direction.y, direction.x);
        final newAngle = baseAngle + angle;
        projectileDirection = Vector2(cos(newAngle), sin(newAngle));
      }
      
      // Check for critical hit (now instant kill, so damage doesn't matter)
      final isCritical = Random().nextDouble() < critChance;
      final finalDamage = 25.0; // Base damage (critical = instant kill)
      
      final projectile = ShapeProjectile(
        startPosition: position.clone(),
        direction: projectileDirection,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: finalDamage,
        isEnemyProjectile: false,
        shapeType: heroData.shape,
        heroColor: heroData.color,
        bounces: projectileBounces,
        sizeScale: projectileScale,
        isCritical: isCritical,
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _updateMovement(double dt) {
    Vector2 inputDirection = Vector2.zero();
    
    // Handle WASD movement
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      inputDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      inputDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      inputDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      inputDirection.x += 1;
    }
    
    // Normalize and apply movement
    if (inputDirection.length > 0) {
      inputDirection.normalize();
      position += inputDirection * moveSpeed * effectiveSpeedMultiplier * dt;
    }
  }
  
  void _updateAbility(double dt) {
    // Handle different ability types based on hero configuration
    switch (heroData.ability.type) {
      case 'dash_damage':
        _updateDashDamage(dt);
        break;
      case 'piercing_shot':
        // Piercing shot is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_stun':
        // Area stun is instant, no update needed
        isUsingAbility = false;
        break;
      case 'radial_burst':
        // Radial burst is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_field':
        // Area field is instant placement, no update needed
        isUsingAbility = false;
        break;
      default:
        isUsingAbility = false;
    }
  }
  
  void _updateDashDamage(double dt) {
    if (abilityTarget == null) {
      isUsingAbility = false;
      return;
    }
    
    final direction = (abilityTarget! - position).normalized();
    final movement = direction * dashSpeed * dt;
    
    // Check for enemy collisions during dash
    // Create a copy to avoid ConcurrentModificationError
    final enemiesCopy = List<Component>.from(gameRef.currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy is PositionComponent) {
        final distanceToEnemy = position.distanceTo(enemy.position);
        // Use different radius checks for different enemy types
        double enemyRadius = 15.0 * DisplayConfig.instance.scaleFactor; // Default radius
        
        if (enemy is EnemyChaser) {
          enemyRadius = enemy.radius;
        } else if (enemy is EnemyShooter) {
          enemyRadius = enemy.radius;
        } else if (enemy is ShieldedChaser) {
          enemyRadius = enemy.radius;
        }
        
        if (distanceToEnemy < heroRadius + enemyRadius) {
          // Damage enemy during rolling surge
          if (enemy is EnemyChaser) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is EnemyShooter) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is ShieldedChaser) {
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          } else {
            // Fallback for other enemy types - remove them directly
            if (enemy.parent != null) {
              gameRef.onEnemyDestroyed(enemy);
            }
          }
        }
      }
    }
    
    if (position.distanceTo(abilityTarget!) <= movement.length) {
      position = abilityTarget!;
      isUsingAbility = false;
      abilityTarget = null;
    } else {
      position += movement;
    }
  }
  
  void _tryAbility() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    
    if (currentTime - lastAbilityTime < effectiveCooldown || energy < 25) {
      return; // Ability on cooldown or not enough energy
    }
    
    switch (heroData.ability.type) {
      case 'dash_damage':
        _executeDashDamage();
        break;
      case 'piercing_shot':
        _executePiercingShot();
        break;
      case 'area_stun':
        _executeAreaStun();
        break;
      case 'radial_burst':
        _executeRadialBurst();
        break;
      case 'area_field':
        _executeAreaField();
        break;
      case 'resonance_knockback':
        _executeResonanceKnockback();
        break;
    }
    
    lastAbilityTime = currentTime;
    energy -= 25; // Ability costs energy
  }
  
  void _executeDashDamage() {
    // Play sound effect for circle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Get current input direction for rolling surge
    Vector2 dashDirection = Vector2.zero();
    
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dashDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dashDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dashDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dashDirection.x += 1;
    }
    
    // If no input, dash forward (up)
    if (dashDirection.length == 0) {
      dashDirection = Vector2(0, -1);
    }
    
    dashDirection.normalize();
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    abilityTarget = position + dashDirection * scaledRange;
    
    // Constrain ability target to arena
    abilityTarget!.x = abilityTarget!.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    abilityTarget!.y = abilityTarget!.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
    
    isUsingAbility = true;
  }
  
  void _executePiercingShot() {
    // Play sound effect for triangle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Find direction to nearest enemy or shoot forward
    Vector2 direction = Vector2(0, -1); // Default forward
    
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      direction = (nearestEnemy.position - position).normalized();
    }
    
    // Create massive triangle projectile with hero color and range scaling
    final projectile = TriangleProjectile(
      startPosition: position.clone(),
      direction: direction,
      speed: 500.0 * DisplayConfig.instance.scaleFactor,
      damage: heroData.ability.damage,
      isEnemyProjectile: false,
      heroColor: heroData.color, // Pass hero color
      rangeMultiplier: rangeMultiplier, // Scale with range upgrades
    );
    
    gameRef.add(projectile);
  }
  
  void _executeAreaStun() {
    // Play sound effect for square hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Calculate effective range (now has range limitation)
    final effectiveRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final stunDuration = heroData.ability.stunDuration ?? 3.0;
    
    // Create visual effect for the ability
    _createSquareAbilityEffect(effectiveRange);
    
    // Stun enemies within range
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= effectiveRange) {
          // Apply stun effect to different enemy types
          if (enemy is EnemyChaser) {
            enemy.stun(stunDuration);
          } else if (enemy is EnemyShooter) {
            enemy.stun(stunDuration);
          } else if (enemy is ShieldedChaser) {
            enemy.stun(stunDuration);
            // Also instantly break shield with ability damage
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          }
        }
      }
    }
    
    // Stun enemy projectiles within range
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= effectiveRange) {
          // Check if it's an enemy projectile and apply slow effect (stun)
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectile.applySlowEffect(0.0); // 0 speed = stunned
          }
        }
      }
    }
    
    print('Shield Bash! Stunned enemies within ${effectiveRange.toInt()} range for ${stunDuration}s');
  }
  
  void _executeRadialBurst() {
    // Play sound effect for pentagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Fire projectiles in all directions
    final projectileCount = heroData.ability.projectileCount ?? 5;
    final angleStep = (2 * pi) / projectileCount;
    
    for (int i = 0; i < projectileCount; i++) {
      final angle = i * angleStep;
      final direction = Vector2(cos(angle), sin(angle));
      
      // Create scaled projectile based on range multiplier
      final scaledRadius = 6.0 * DisplayConfig.instance.scaleFactor * rangeMultiplier;
      
      final projectile = Projectile(
        startPosition: position.clone(),
        direction: direction,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: heroData.ability.damage,
        isEnemyProjectile: false,
        heroColor: heroData.color,
        scaledRadius: scaledRadius, // Pass scaled radius for bullet size
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _executeAreaField() {
    // Play sound effect for hexagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Create visual hex field effect
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final duration = heroData.ability.duration ?? 4.0;
    
    final hexField = HexField(
      position: position.clone(),
      radius: scaledRange,
      duration: duration,
      damage: heroData.ability.damage,
      slowPercent: heroData.ability.slowPercent ?? 0.3,
    );
    
    gameRef.add(hexField);
  }
  
  void _executeResonanceKnockback() {
    // Play sound effect for heptagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final knockbackDistance = (heroData.ability.knockbackDistance ?? 30.0) * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    
    // Create visual effect for the ability
    _createHeptagonAbilityEffect(scaledRange);
    
    // Find enemies within range and apply damage + knockback
    final enemiesToKnockback = <Component>[];
    final projectilesToPush = <Component>[];
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= scaledRange) {
          enemiesToKnockback.add(enemy);
        }
      }
    }
    
    // Find enemy projectiles within range to push away and stun them
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= scaledRange) {
          // Check if it's an enemy projectile
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectilesToPush.add(projectile);
          }
        }
      }
    }
    
    // Apply damage and knockback to all enemies in range
    for (final enemy in enemiesToKnockback) {
      if (enemy is PositionComponent) {
        // Apply damage
        if (enemy is EnemyChaser) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is EnemyShooter) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is ShieldedChaser) {
          enemy.takeDamage(heroData.ability.damage, isAbility: true);
        }
        
        // Apply knockback
        final directionToEnemy = (enemy.position - position).normalized();
        final knockbackTarget = enemy.position + directionToEnemy * knockbackDistance;
        
        // Constrain knockback target to arena bounds
        final constrainedTarget = Vector2(
          knockbackTarget.x.clamp(50.0, DisplayConfig.instance.arenaWidth - 50.0),
          knockbackTarget.y.clamp(50.0, DisplayConfig.instance.arenaHeight - 50.0),
        );
        
        enemy.position = constrainedTarget;
      }
    }
    
    // Push away enemy projectiles
    for (final projectile in projectilesToPush) {
      if (projectile is PositionComponent) {
        final directionToProjectile = (projectile.position - position).normalized();
        final pushTarget = projectile.position + directionToProjectile * knockbackDistance;
        
        // Constrain push target to arena bounds
        final constrainedTarget = Vector2(
          pushTarget.x.clamp(0.0, DisplayConfig.instance.arenaWidth),
          pushTarget.y.clamp(0.0, DisplayConfig.instance.arenaHeight),
        );
        
        projectile.position = constrainedTarget;
      }
    }
    
    // Visual feedback
    print('Resonance Knockback! Hit ${enemiesToKnockback.length} enemies and pushed ${projectilesToPush.length} projectiles');
  }
  
  void _updateAbilityCooldownDisplay() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final timeSinceLastAbility = currentTime - lastAbilityTime;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    final cooldownPercent = (timeSinceLastAbility / effectiveCooldown).clamp(0.0, 1.0);
    final remainingSeconds = (effectiveCooldown - timeSinceLastAbility).clamp(0.0, effectiveCooldown);
    
    if (gameRef.hud.isMounted) {
      gameRef.hud.updateAbilityCooldown(cooldownPercent, remainingSeconds);
    }
  }
  
  void _constrainToArena() {
    position.x = position.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    position.y = position.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    
    // Handle universal escape key navigation
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      // Check if stats overlay is visible and hide it first
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
        return true;
      }
      
      // Check if shop is open and close it
      if (gameRef.gameState == GameState.shopping) {
        gameRef.onShopClosed();
        return true;
      }
      
      // Handle pause/resume for playing state
      if (gameRef.gameState == GameState.playing) {
        gameRef.pauseGame();
        return true;
      } else if (gameRef.gameState == GameState.paused) {
        gameRef.resumeGame();
        return true;
      }
    }
    
    // Handle ability (K key only)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyK) {
      _tryAbility();
      return true;
    }
    
    // Handle clone activation with 'C' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (canActivateClone()) {
        activateClone();
      }
      return true;
    }
    
    // Handle stats overlay toggle with 'I' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyI) {
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
      } else {
        gameRef.statsOverlay.show();
      }
      return true;
    }
    
    return false;
  }
  
  void takeDamage(double damage) {
    if (isInvincible || isDamageInvincible || isUsingAbility) {
      return; // No damage while invincible, damage invincible, or using ability
    }
    
    double remainingDamage = damage;
    
    // Shield absorbs damage first
    if (shield > 0) {
      if (shield >= remainingDamage) {
        // Shield absorbs all damage
        shield -= remainingDamage;
        remainingDamage = 0;
      } else {
        // Shield absorbs partial damage and breaks
        remainingDamage -= shield;
        shield = 0;
        
        // Remove shield effect when shield is broken
        if (hasTemporaryEffect('shield')) {
          print('Shield broken! Removing shield effect.');
          _removeEffectImmediate('shield');
          _temporaryEffects.remove('shield');
        }
      }
    }
    
    // Apply remaining damage to health
    if (remainingDamage > 0) {
      health = (health - remainingDamage).clamp(0, maxHealth);
    }
    
    // Activate damage invincibility
    isDamageInvincible = true;
    damageInvincibilityTimer = 0.0;
    
    if (health <= 0) {
      gameRef.onHeroDeath();
    }
  }
  
  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
  
  void addCoins(int amount) {
    final multiplier = totalCoinMultiplier;
    final finalAmount = (amount * multiplier).round();
    coins += finalAmount;
    if (multiplier > 1.0) {
      print('Coin Magnet: ${amount} -> ${finalAmount} coins (${multiplier}x)');
    }
  }
  
  void spendCoins(int amount) {
    coins = max(0, coins - amount);
  }
  
  void activateInvincibility() {
    isInvincible = true;
    invincibilityTimer = invincibilityDuration;
  }
  
  void _createSquareAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'square',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  void _createHeptagonAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'heptagon',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  // Temporary effects system - only one effect at a time
  void applyTemporaryEffect(String effectType, double value, double duration) {
    // Remove any existing effect first (only one at a time)
    if (_temporaryEffects.isNotEmpty) {
      final oldEffect = _temporaryEffects.entries.first;
      _removeEffectImmediate(oldEffect.key);
      _temporaryEffects.clear();
      print('Replaced effect: ${oldEffect.key} -> $effectType');
    }
    
    // Apply new effect
    _temporaryEffects[effectType] = TemporaryEffect(
      type: effectType,
      value: value,
      duration: duration,
    );
    
    // Apply immediate effects
    _applyEffectImmediate(effectType, value);
    
    print('Applied temporary effect: $effectType (${value}, ${duration}s)');
  }
  
  void _updateTemporaryEffects(double dt) {
    final expiredEffects = <String>[];
    
    for (final entry in _temporaryEffects.entries) {
      final effect = entry.value;
      effect.update(dt);
      
      if (effect.isExpired) {
        expiredEffects.add(entry.key);
        _removeEffectImmediate(entry.key);
      } else {
        // Apply ongoing effects
        _applyEffectOngoing(effect.type, effect.value, dt);
      }
    }
    
    // Remove expired effects
    for (final effectType in expiredEffects) {
      _temporaryEffects.remove(effectType);
    }
  }
  
  void _applyEffectImmediate(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
        speedMultiplier *= (1.0 + value);
        break;
      case 'damage_boost':
        // This will be applied in damage calculations
        break;
      case 'shield':
        shield += value;
        maxShield = maxShield > shield ? maxShield : shield;
        break;
      case 'invincibility':
        isInvincible = true;
        invincibilityTimer = 0.0;
        break;
      case 'weapon_overclock':
        attackSpeedMultiplier *= (1.0 + value);
        break;
    }
  }
  
  void _applyEffectOngoing(String effectType, double value, double dt) {
    switch (effectType) {
      case 'health_regen':
        heal(value * dt);
        break;
    }
  }
  
  void _removeEffectImmediate(String effectType) {
    switch (effectType) {
      case 'speed_boost':
        // Note: This is a simplified approach. In a full implementation,
        // you'd want to track the original multiplier and restore it
        speedMultiplier = 1.0; // Reset to base
        break;
      case 'damage_boost':
        // Reset damage multiplier
        break;
      case 'shield':
        // Shield naturally decays over time
        break;
      case 'invincibility':
        // Invincibility expires naturally
        break;
      case 'weapon_overclock':
        // Reset attack speed multiplier
        attackSpeedMultiplier = 1.0; // Reset to base
        break;
    }
  }
  
  // Get effective damage multiplier including temporary effects
  double get effectiveDamageMultiplier {
    double multiplier = 1.0;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'damage_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Get effective speed multiplier including temporary effects
  double get effectiveSpeedMultiplier {
    double multiplier = speedMultiplier;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'speed_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Check if hero has a specific temporary effect
  bool hasTemporaryEffect(String effectType) {
    return _temporaryEffects.containsKey(effectType);
  }
  
  // Get remaining time for a temporary effect
  double getTemporaryEffectTime(String effectType) {
    final effect = _temporaryEffects[effectType];
    return effect?.remainingTime ?? 0.0;
  }
  
  // Get current active effect for UI display
  TemporaryEffect? get currentActiveEffect {
    return _temporaryEffects.isNotEmpty ? _temporaryEffects.values.first : null;
  }
  
  // Get current active effect info as a formatted string
  String get activeEffectDisplay {
    final effect = currentActiveEffect;
    if (effect == null) return 'None';
    
    final effectName = _getEffectDisplayName(effect.type);
    final effectValue = _getEffectDisplayValue(effect.type, effect.value);
    
    // Handle infinite duration effects (like persistent shields)
    if (effect.remainingTime.isInfinite || effect.remainingTime.isNaN) {
      return '$effectName $effectValue (∞)';
    }
    
    final timeLeft = effect.remainingTime.ceil();
    return '$effectName $effectValue (${timeLeft}s)';
  }
  
  String _getEffectDisplayName(String effectType) {
    switch (effectType) {
      case 'speed_boost': return 'Speed';
      case 'damage_boost': return 'Damage';
      case 'health_regen': return 'Regen';
      case 'shield': return 'Shield';
      case 'invincibility': return 'Invul';
      case 'weapon_overclock': return 'Overclock';
      default: return effectType;
    }
  }
  
  String _getEffectDisplayValue(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
      case 'damage_boost':
      case 'weapon_overclock':
        return '+${(value * 100).round()}%';
      case 'health_regen':
        return '+${value.round()}/s';
      case 'shield':
        return '+${value.round()}';
      case 'invincibility':
        return 'ON';
      default:
        return value.toString();
    }
  }

  // Stackable passive effects system
  void addPassiveEffect(String effectType, int maxStacks) {
    final currentStacks = _passiveEffectStacks[effectType] ?? 0;
    if (currentStacks < maxStacks) {
      _passiveEffectStacks[effectType] = currentStacks + 1;
      print('Added passive effect: $effectType (${currentStacks + 1}/$maxStacks stacks)');
    } else {
      print('Cannot add $effectType: already at max stacks ($maxStacks)');
    }
  }
  
  int getPassiveEffectStacks(String effectType) {
    return _passiveEffectStacks[effectType] ?? 0;
  }
  
  bool hasPassiveEffect(String effectType) {
    return _passiveEffectStacks.containsKey(effectType) && _passiveEffectStacks[effectType]! > 0;
  }
  
  // Get calculated values based on passive effects
  int get totalProjectileCount {
    return 1 + getPassiveEffectStacks('projectile_count');
  }
  
  int get totalProjectileBounces {
    return getPassiveEffectStacks('projectile_bounces');
  }
  
  double get totalProjectileSize {
    return 1.0 + (getPassiveEffectStacks('projectile_size') * 0.5); // 50% increase per stack
  }
  
  int get totalDroneCount {
    return getPassiveEffectStacks('drone_count');
  }
  
  double get totalLifeSteal {
    return getPassiveEffectStacks('life_steal') * 0.05;
  }
  
  double get totalShieldHP {
    return getPassiveEffectStacks('shield_hp') * 5.0;
  }
  
  double get totalCoinMultiplier {
    return 1.0 + (getPassiveEffectStacks('coin_multiplier') * 0.2);
  }
  
  double get totalHealPerKill {
    return getPassiveEffectStacks('heal_per_kill') * 2.0;
  }
  
  double get totalCritChance {
    return getPassiveEffectStacks('crit_chance') * 0.02;
  }
  
  double get totalMaxHealthBoost {
    return getPassiveEffectStacks('max_health_boost') * 10.0;
  }
  
  bool get hasCloneProjection {
    return hasPassiveEffect('clone_spawn');
  }
  
  void resetPassiveEffects() {
    _passiveEffectStacks.clear();
    destroyAllDrones();
    destroyClone();
  }
  
  // Apply heal per kill effect when an enemy is defeated
  void onEnemyKilled() {
    killCount++;
    
    final healAmount = totalHealPerKill;
    if (healAmount > 0) {
      heal(healAmount);
      print('Healed ${healAmount} HP from kill');
    }
    
    // Handle kill-based max health boost (Auto Injector)
    final autoInjectorStacks = getPassiveEffectStacks('kill_based_max_health');
    if (autoInjectorStacks > 0 && killCount % 10 == 0) {
      final maxHealthIncrease = autoInjectorStacks * 2.0; // 2 HP per stack
      final currentBonus = (killCount ~/ 10) * maxHealthIncrease;
      final maxBonus = autoInjectorStacks * 50.0; // 50 HP max per stack
      
      if (currentBonus <= maxBonus) {
        maxHealth += maxHealthIncrease;
        health += maxHealthIncrease; // Also heal current HP
        print('Auto Injector: +${maxHealthIncrease} max HP from ${killCount} kills');
      }
    }
  }
  
  // Regenerate shields between waves (Armor Plating effect)
  void regenerateShields() {
    final armorShields = totalShieldHP;
    if (armorShields > 0) {
      // Apply armor plating as a persistent shield effect
      applyTemporaryEffect('shield', armorShields, double.infinity);
      print('Armor plating shields regenerated to ${armorShields.toStringAsFixed(1)} HP');
    }
  }
  
  // Drone management system
  void updateDroneCount() {
    final targetDroneCount = totalDroneCount;
    final currentDroneCount = _activeDrones.length;
    
    if (targetDroneCount > currentDroneCount) {
      // Spawn new drones
      for (int i = currentDroneCount; i < targetDroneCount; i++) {
        final drone = DroneWingman(owner: this, droneIndex: i);
        _activeDrones.add(drone);
        gameRef.add(drone);
        print('Spawned drone ${i + 1}/${targetDroneCount}');
      }
    } else if (targetDroneCount < currentDroneCount) {
      // Remove excess drones
      while (_activeDrones.length > targetDroneCount) {
        final drone = _activeDrones.removeLast();
        drone.destroy();
        print('Removed drone. Remaining: ${_activeDrones.length}');
      }
    }
  }
  
  void destroyAllDrones() {
    for (final drone in _activeDrones) {
      drone.destroy();
    }
    _activeDrones.clear();
    print('All drones destroyed');
  }
  
  // Clone management system
  bool canActivateClone() {
    return hasCloneProjection && _activeClone == null && health > maxHealth * 0.5;
  }
  
  void activateClone() {
    print('🤖 Attempting to activate clone...');
    print('   - Has clone projection: ${hasCloneProjection}');
    print('   - No active clone: ${_activeClone == null}');
    print('   - Current health: ${health.toStringAsFixed(1)}/${maxHealth.toStringAsFixed(1)}');
    print('   - Required health: ${(maxHealth * 0.5).toStringAsFixed(1)}');
    
    if (!canActivateClone()) {
      print('❌ Cannot activate clone: requirements not met');
      return;
    }
    
    // Pay health cost (50% of current health)
    final healthCost = health * 0.5;
    health -= healthCost;
    
    // Spawn clone directly to the right with clear gap
    final cloneOffset = Vector2(80, 0); // Simple fixed offset to the right
    final clonePosition = position + cloneOffset;
    
    print('🤖 Creating HeroClone at position: (${clonePosition.x}, ${clonePosition.y})');
    _activeClone = HeroClone(owner: this, spawnPosition: clonePosition);
    
    print('🤖 Adding clone to game...');
    gameRef.add(_activeClone!);
    
    print('✅ CLONE ACTIVATED! Health cost: ${healthCost.toStringAsFixed(1)}, Clone mounted: ${_activeClone!.isMounted}');
  }
  
  void destroyClone() {
    if (_activeClone != null) {
      _activeClone!.destroy();
      _activeClone = null;
      print('Clone destroyed');
    }
  }
  
  bool get hasActiveClone => _activeClone != null;
  
  // Getter for passive effect stacks (for stats display)
  Map<String, int> get passiveEffectStacks => Map.from(_passiveEffectStacks);
  
  void onCloneDestroyed(HeroClone clone) {
    if (_activeClone == clone) {
      _activeClone = null;
      print('Active clone reference cleared');
    }
  }
}

// Visual effect component for abilities
class AbilityVisualEffect extends PositionComponent with HasGameRef<CircleRougeGame> {
  final double effectRange;
  final String shape;
  final Color color;
  
  double lifetime = 0.0;
  static const double totalLifetime = 0.5; // Blink once and disappear
  static const double blinkDuration = 0.25; // Half the lifetime for one blink
  
  AbilityVisualEffect({
    required Vector2 position,
    required this.effectRange,
    required this.shape,
    required this.color,
  }) : super(
    position: position,
    size: Vector2.all(effectRange * 2),
    anchor: Anchor.center,
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    lifetime += dt;
    
    // Remove after total lifetime
    if (lifetime >= totalLifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Calculate opacity with blinking effect
    final blinkProgress = (lifetime / blinkDuration) % 1.0;
    final opacity = (sin(blinkProgress * pi * 2) * 0.15 + 0.1).clamp(0.0, 0.25); // 25% max opacity
    
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = color.withOpacity(opacity * 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Draw the shape based on type
    switch (shape) {
      case 'square':
        final rect = Rect.fromCenter(
          center: center,
          width: effectRange * 2,
          height: effectRange * 2,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;
      case 'heptagon':
        final path = _createHeptagonPath(center, effectRange);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }
  
  Path _createHeptagonPath(Offset center, double radius) {
    final path = Path();
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * pi / 180);
      final y = center.dy + radius * sin(angle * pi / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    return path;
  }
} 
```

Now I need to update the resetPassiveEffects method to also reset kill count:

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/circle_rouge_game.dart';
import '../config/hero_config.dart';
import '../config/display_config.dart';
import 'abilities/hex_field.dart';
import 'enemies/enemy_chaser.dart';
import 'enemies/enemy_shooter.dart';
import 'enemies/shielded_chaser.dart';
import 'enemies/projectile.dart';
import 'enemies/shape_projectile.dart';
import 'enemies/triangle_projectile.dart';
import 'sound_manager.dart';
import 'companions/drone_wingman.dart';
import 'companions/hero_clone.dart';

class TemporaryEffect {
  final String type;
  final double value;
  final double duration;
  double remainingTime;
  
  TemporaryEffect({
    required this.type,
    required this.value,
    required this.duration,
  }) : remainingTime = duration;
  
  void update(double dt) {
    remainingTime -= dt;
  }
  
  bool get isExpired => remainingTime <= 0;
}

class Hero extends PositionComponent with HasGameRef<CircleRougeGame>, KeyboardHandler {
  // Hero configuration
  late HeroData heroData;
  final String heroId;
  
  // Hero visual properties
  late double heroRadius;
  late Paint heroPaint;
  
  // Base movement properties - will be scaled based on arena size
  static const double baseMoveSpeed = 200.0;
  
  // Base dash properties (for heroes that don't have special abilities)
  static const double baseDashDistance = 120.0;
  static const double baseDashSpeed = 500.0;
  
  // Base shooting properties
  static const double baseShootRange = 250.0;
  static const double fireRate = 2.0; // Shots per second
  double lastShotTime = 0.0;
  
  // Get scaled values based on arena size
  double get moveSpeed => (heroData.moveSpeed / 320.0 * baseMoveSpeed) * DisplayConfig.instance.scaleFactor;
  double get dashDistance => baseDashDistance * DisplayConfig.instance.scaleFactor;
  double get dashSpeed => baseDashSpeed * DisplayConfig.instance.scaleFactor;
  double get shootRange => baseShootRange * DisplayConfig.instance.scaleFactor * rangeMultiplier;
  
  // Attack speed modifier (can be upgraded)
  double attackSpeedMultiplier = 1.0;
  
  // Movement speed modifier (can be upgraded)
  double speedMultiplier = 1.0;
  
  // Ability cooldown modifier (can be upgraded)
  double abilityCooldownMultiplier = 1.0;
  
  // Range modifier (can be upgraded)
  double rangeMultiplier = 1.0;
  
  // Weapon overclock visual effect
  // Weapon overclock now handled by temporary effect system
  
  // Ability system
  double lastAbilityTime = -double.infinity;
  bool isUsingAbility = false;
  Vector2? abilityTarget;
  
  // Hero stats
  double health = 100.0;
  double maxHealth = 100.0;
  double energy = 100.0;
  double maxEnergy = 100.0;
  int coins = 0;
  int killCount = 0;
  
  // Invincibility after wave completion
  bool isInvincible = false;
  double invincibilityTimer = 0.0;
  static const double invincibilityDuration = 3.0; // 3 seconds of invincibility
  
  // Damage invincibility (separate from wave completion invincibility)
  bool isDamageInvincible = false;
  double damageInvincibilityTimer = 0.0;
  static const double damageInvincibilityDuration = 0.5; // 0.5 seconds after taking damage
  
  // Temporary effects system
  final Map<String, TemporaryEffect> _temporaryEffects = {};
  
  // Stackable passive effects system
  final Map<String, int> _passiveEffectStacks = {};
  
  // Drone companion system
  final List<DroneWingman> _activeDrones = [];
  
  // Clone system
  HeroClone? _activeClone;
  
  // Shield system
  double shield = 0.0;
  double maxShield = 0.0;
  
  // Input tracking
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  
  Hero({required Vector2 position, required this.heroId}) : super(
    position: position,
    size: Vector2.all(30.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    heroRadius = 15.0 * DisplayConfig.instance.scaleFactor;
    heroPaint = Paint()..color = const Color(0xFF4CAF50);
    _initializeHero(heroId);
  }
  
  void _initializeHero(String heroId) {
    final heroConfig = HeroConfig.instance.getHeroById(heroId);
    if (heroConfig != null) {
      heroData = heroConfig;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    } else {
      // Fallback to default circle hero
      heroData = HeroConfig.instance.defaultHero;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    }
  }
  
  double get effectiveMaxHealth {
    return maxHealth + totalMaxHealthBoost;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Blinking effect during damage invincibility
    if (isDamageInvincible) {
      final blinkTime = (damageInvincibilityTimer * 8) % 1.0; // 8 blinks per second
      if (blinkTime > 0.5) {
        return; // Don't render during blink "off" phase
      }
    }
    
    final center = Offset(size.x / 2, size.y / 2);
    final shapeSize = size.x;
    
    // Old weapon overclock glow removed - now handled by active effect glow
    
    // Active effect glow
    final activeEffect = currentActiveEffect;
    if (activeEffect != null) {
      final effectTime = (DateTime.now().millisecondsSinceEpoch / 1000.0) % 1.5; // 1.5-second cycle
      final glowIntensity = (sin(effectTime * pi * 2) * 0.3 + 0.7); // 0.4 to 1.0
      final glowRadius = 15.0 * glowIntensity;
      
      // Get effect color
      Color effectColor;
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
        default:
          effectColor = const Color(0xFFFFFFFF); // White fallback
      }
      
      final effectGlowPaint = Paint()
        ..color = effectColor.withOpacity(0.8 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      // Draw effect glow based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + glowRadius, effectGlowPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'square':
          _drawSquare(canvas, center, effectGlowPaint, glowRadius);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
      }
    }
    
    // Draw main hero shape
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(center, heroRadius, heroPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, shapeSize, heroPaint, 0);
        break;
      case 'square':
        _drawSquare(canvas, center, heroPaint, 0);
        break;
      case 'pentagon':
        _drawPentagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'hexagon':
        _drawHexagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, shapeSize, heroPaint, 0);
        break;
    }
    
    // Draw shield outline if shield effect is active
    if (hasTemporaryEffect('shield') && shield > 0) {
      final shieldOpacity = (shield / maxShield).clamp(0.3, 1.0); // Fade as shield depletes
      final shieldPaint = Paint()
        ..color = const Color(0xFFFF9800).withOpacity(0.6 * shieldOpacity) // Orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Draw shield outline based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + 4, shieldPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'square':
          _drawSquare(canvas, center, shieldPaint, 4);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, shieldPaint, 4);
          break;
      }
    }
    
  }
  
  void _drawTriangle(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius / 2);
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius / 2);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSquare(Canvas canvas, Offset center, Paint paint, double glowRadius) {
    final size = (this.size.x * 0.8) + (glowRadius * 2);
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      ),
      paint,
    );
  }
  
  void _drawPentagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 5; i++) {
      final angle = -90 + (i * 72); // Pentagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHexagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 6; i++) {
      final angle = -90 + (i * 60); // Hexagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHeptagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  // Collision detection method for other components to use
  @override
  bool containsPoint(Vector2 point) {
    final distance = position.distanceTo(point);
    return distance <= heroRadius;
  }
  
  // Get collision radius for enemy collision detection
  double get collisionRadius => heroRadius;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Weapon overclock now handled by temporary effect system
    
    // Update invincibility timer
    if (isInvincible) {
      invincibilityTimer += dt;
      if (invincibilityTimer >= invincibilityDuration) {
        isInvincible = false;
        invincibilityTimer = 0.0;
      }
    }
    
    // Update damage invincibility timer
    if (isDamageInvincible) {
      damageInvincibilityTimer += dt;
      if (damageInvincibilityTimer >= damageInvincibilityDuration) {
        isDamageInvincible = false;
        damageInvincibilityTimer = 0.0;
      }
    }
    
    // Update temporary effects
    _updateTemporaryEffects(dt);
    
    if (isUsingAbility) {
      _updateAbility(dt);
    } else {
      _updateMovement(dt);
    }
    
    // Auto-shoot at enemies
    _tryAutoShoot();
    
    // Regenerate energy
    if (energy < maxEnergy) {
      energy = (energy + 50 * dt).clamp(0, maxEnergy);
    }
    
    // Keep hero within arena bounds
    _constrainToArena();
    
    // Update ability cooldown in HUD
    _updateAbilityCooldownDisplay();
  }
  
  void _tryAutoShoot() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    if (currentTime - lastShotTime < (1.0 / (fireRate * attackSpeedMultiplier))) {
      return; // Still on cooldown
    }
    
    // Find nearest enemy
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance && distance <= shootRange) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    // Shoot at nearest enemy if found
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      final direction = (nearestEnemy.position - position).normalized();
      _fireProjectile(direction);
      lastShotTime = currentTime;
    }
  }
  
  void _fireProjectile(Vector2 direction) {
    final projectileCount = totalProjectileCount;
    final projectileBounces = totalProjectileBounces;
    final projectileScale = totalProjectileSize;
    final critChance = totalCritChance;
    
    // Calculate spread angle if multiple projectiles
    final spreadAngle = projectileCount > 1 ? pi / 6 : 0.0; // 30 degrees total spread
    final angleStep = projectileCount > 1 ? spreadAngle / (projectileCount - 1) : 0.0;
    final startAngle = projectileCount > 1 ? -spreadAngle / 2 : 0.0;
    
    for (int i = 0; i < projectileCount; i++) {
      // Calculate direction for each projectile
      Vector2 projectileDirection;
      if (projectileCount == 1) {
        projectileDirection = direction;
      } else {
        final angle = startAngle + (i * angleStep);
        final baseAngle = atan2(direction.y, direction.x);
        final newAngle = baseAngle + angle;
        projectileDirection = Vector2(cos(newAngle), sin(newAngle));
      }
      
      // Check for critical hit (now instant kill, so damage doesn't matter)
      final isCritical = Random().nextDouble() < critChance;
      final finalDamage = 25.0; // Base damage (critical = instant kill)
      
      final projectile = ShapeProjectile(
        startPosition: position.clone(),
        direction: projectileDirection,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: finalDamage,
        isEnemyProjectile: false,
        shapeType: heroData.shape,
        heroColor: heroData.color,
        bounces: projectileBounces,
        sizeScale: projectileScale,
        isCritical: isCritical,
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _updateMovement(double dt) {
    Vector2 inputDirection = Vector2.zero();
    
    // Handle WASD movement
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      inputDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      inputDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      inputDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      inputDirection.x += 1;
    }
    
    // Normalize and apply movement
    if (inputDirection.length > 0) {
      inputDirection.normalize();
      position += inputDirection * moveSpeed * effectiveSpeedMultiplier * dt;
    }
  }
  
  void _updateAbility(double dt) {
    // Handle different ability types based on hero configuration
    switch (heroData.ability.type) {
      case 'dash_damage':
        _updateDashDamage(dt);
        break;
      case 'piercing_shot':
        // Piercing shot is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_stun':
        // Area stun is instant, no update needed
        isUsingAbility = false;
        break;
      case 'radial_burst':
        // Radial burst is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_field':
        // Area field is instant placement, no update needed
        isUsingAbility = false;
        break;
      default:
        isUsingAbility = false;
    }
  }
  
  void _updateDashDamage(double dt) {
    if (abilityTarget == null) {
      isUsingAbility = false;
      return;
    }
    
    final direction = (abilityTarget! - position).normalized();
    final movement = direction * dashSpeed * dt;
    
    // Check for enemy collisions during dash
    // Create a copy to avoid ConcurrentModificationError
    final enemiesCopy = List<Component>.from(gameRef.currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy is PositionComponent) {
        final distanceToEnemy = position.distanceTo(enemy.position);
        // Use different radius checks for different enemy types
        double enemyRadius = 15.0 * DisplayConfig.instance.scaleFactor; // Default radius
        
        if (enemy is EnemyChaser) {
          enemyRadius = enemy.radius;
        } else if (enemy is EnemyShooter) {
          enemyRadius = enemy.radius;
        } else if (enemy is ShieldedChaser) {
          enemyRadius = enemy.radius;
        }
        
        if (distanceToEnemy < heroRadius + enemyRadius) {
          // Damage enemy during rolling surge
          if (enemy is EnemyChaser) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is EnemyShooter) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is ShieldedChaser) {
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          } else {
            // Fallback for other enemy types - remove them directly
            if (enemy.parent != null) {
              gameRef.onEnemyDestroyed(enemy);
            }
          }
        }
      }
    }
    
    if (position.distanceTo(abilityTarget!) <= movement.length) {
      position = abilityTarget!;
      isUsingAbility = false;
      abilityTarget = null;
    } else {
      position += movement;
    }
  }
  
  void _tryAbility() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    
    if (currentTime - lastAbilityTime < effectiveCooldown || energy < 25) {
      return; // Ability on cooldown or not enough energy
    }
    
    switch (heroData.ability.type) {
      case 'dash_damage':
        _executeDashDamage();
        break;
      case 'piercing_shot':
        _executePiercingShot();
        break;
      case 'area_stun':
        _executeAreaStun();
        break;
      case 'radial_burst':
        _executeRadialBurst();
        break;
      case 'area_field':
        _executeAreaField();
        break;
      case 'resonance_knockback':
        _executeResonanceKnockback();
        break;
    }
    
    lastAbilityTime = currentTime;
    energy -= 25; // Ability costs energy
  }
  
  void _executeDashDamage() {
    // Play sound effect for circle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Get current input direction for rolling surge
    Vector2 dashDirection = Vector2.zero();
    
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dashDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dashDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dashDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dashDirection.x += 1;
    }
    
    // If no input, dash forward (up)
    if (dashDirection.length == 0) {
      dashDirection = Vector2(0, -1);
    }
    
    dashDirection.normalize();
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    abilityTarget = position + dashDirection * scaledRange;
    
    // Constrain ability target to arena
    abilityTarget!.x = abilityTarget!.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    abilityTarget!.y = abilityTarget!.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
    
    isUsingAbility = true;
  }
  
  void _executePiercingShot() {
    // Play sound effect for triangle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Find direction to nearest enemy or shoot forward
    Vector2 direction = Vector2(0, -1); // Default forward
    
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      direction = (nearestEnemy.position - position).normalized();
    }
    
    // Create massive triangle projectile with hero color and range scaling
    final projectile = TriangleProjectile(
      startPosition: position.clone(),
      direction: direction,
      speed: 500.0 * DisplayConfig.instance.scaleFactor,
      damage: heroData.ability.damage,
      isEnemyProjectile: false,
      heroColor: heroData.color, // Pass hero color
      rangeMultiplier: rangeMultiplier, // Scale with range upgrades
    );
    
    gameRef.add(projectile);
  }
  
  void _executeAreaStun() {
    // Play sound effect for square hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Calculate effective range (now has range limitation)
    final effectiveRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final stunDuration = heroData.ability.stunDuration ?? 3.0;
    
    // Create visual effect for the ability
    _createSquareAbilityEffect(effectiveRange);
    
    // Stun enemies within range
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= effectiveRange) {
          // Apply stun effect to different enemy types
          if (enemy is EnemyChaser) {
            enemy.stun(stunDuration);
          } else if (enemy is EnemyShooter) {
            enemy.stun(stunDuration);
          } else if (enemy is ShieldedChaser) {
            enemy.stun(stunDuration);
            // Also instantly break shield with ability damage
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          }
        }
      }
    }
    
    // Stun enemy projectiles within range
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= effectiveRange) {
          // Check if it's an enemy projectile and apply slow effect (stun)
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectile.applySlowEffect(0.0); // 0 speed = stunned
          }
        }
      }
    }
    
    print('Shield Bash! Stunned enemies within ${effectiveRange.toInt()} range for ${stunDuration}s');
  }
  
  void _executeRadialBurst() {
    // Play sound effect for pentagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Fire projectiles in all directions
    final projectileCount = heroData.ability.projectileCount ?? 5;
    final angleStep = (2 * pi) / projectileCount;
    
    for (int i = 0; i < projectileCount; i++) {
      final angle = i * angleStep;
      final direction = Vector2(cos(angle), sin(angle));
      
      // Create scaled projectile based on range multiplier
      final scaledRadius = 6.0 * DisplayConfig.instance.scaleFactor * rangeMultiplier;
      
      final projectile = Projectile(
        startPosition: position.clone(),
        direction: direction,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: heroData.ability.damage,
        isEnemyProjectile: false,
        heroColor: heroData.color,
        scaledRadius: scaledRadius, // Pass scaled radius for bullet size
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _executeAreaField() {
    // Play sound effect for hexagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Create visual hex field effect
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final duration = heroData.ability.duration ?? 4.0;
    
    final hexField = HexField(
      position: position.clone(),
      radius: scaledRange,
      duration: duration,
      damage: heroData.ability.damage,
      slowPercent: heroData.ability.slowPercent ?? 0.3,
    );
    
    gameRef.add(hexField);
  }
  
  void _executeResonanceKnockback() {
    // Play sound effect for heptagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final knockbackDistance = (heroData.ability.knockbackDistance ?? 30.0) * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    
    // Create visual effect for the ability
    _createHeptagonAbilityEffect(scaledRange);
    
    // Find enemies within range and apply damage + knockback
    final enemiesToKnockback = <Component>[];
    final projectilesToPush = <Component>[];
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= scaledRange) {
          enemiesToKnockback.add(enemy);
        }
      }
    }
    
    // Find enemy projectiles within range to push away and stun them
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= scaledRange) {
          // Check if it's an enemy projectile
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectilesToPush.add(projectile);
          }
        }
      }
    }
    
    // Apply damage and knockback to all enemies in range
    for (final enemy in enemiesToKnockback) {
      if (enemy is PositionComponent) {
        // Apply damage
        if (enemy is EnemyChaser) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is EnemyShooter) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is ShieldedChaser) {
          enemy.takeDamage(heroData.ability.damage, isAbility: true);
        }
        
        // Apply knockback
        final directionToEnemy = (enemy.position - position).normalized();
        final knockbackTarget = enemy.position + directionToEnemy * knockbackDistance;
        
        // Constrain knockback target to arena bounds
        final constrainedTarget = Vector2(
          knockbackTarget.x.clamp(50.0, DisplayConfig.instance.arenaWidth - 50.0),
          knockbackTarget.y.clamp(50.0, DisplayConfig.instance.arenaHeight - 50.0),
        );
        
        enemy.position = constrainedTarget;
      }
    }
    
    // Push away enemy projectiles
    for (final projectile in projectilesToPush) {
      if (projectile is PositionComponent) {
        final directionToProjectile = (projectile.position - position).normalized();
        final pushTarget = projectile.position + directionToProjectile * knockbackDistance;
        
        // Constrain push target to arena bounds
        final constrainedTarget = Vector2(
          pushTarget.x.clamp(0.0, DisplayConfig.instance.arenaWidth),
          pushTarget.y.clamp(0.0, DisplayConfig.instance.arenaHeight),
        );
        
        projectile.position = constrainedTarget;
      }
    }
    
    // Visual feedback
    print('Resonance Knockback! Hit ${enemiesToKnockback.length} enemies and pushed ${projectilesToPush.length} projectiles');
  }
  
  void _updateAbilityCooldownDisplay() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final timeSinceLastAbility = currentTime - lastAbilityTime;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    final cooldownPercent = (timeSinceLastAbility / effectiveCooldown).clamp(0.0, 1.0);
    final remainingSeconds = (effectiveCooldown - timeSinceLastAbility).clamp(0.0, effectiveCooldown);
    
    if (gameRef.hud.isMounted) {
      gameRef.hud.updateAbilityCooldown(cooldownPercent, remainingSeconds);
    }
  }
  
  void _constrainToArena() {
    position.x = position.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    position.y = position.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    
    // Handle universal escape key navigation
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      // Check if stats overlay is visible and hide it first
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
        return true;
      }
      
      // Check if shop is open and close it
      if (gameRef.gameState == GameState.shopping) {
        gameRef.onShopClosed();
        return true;
      }
      
      // Handle pause/resume for playing state
      if (gameRef.gameState == GameState.playing) {
        gameRef.pauseGame();
        return true;
      } else if (gameRef.gameState == GameState.paused) {
        gameRef.resumeGame();
        return true;
      }
    }
    
    // Handle ability (K key only)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyK) {
      _tryAbility();
      return true;
    }
    
    // Handle clone activation with 'C' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (canActivateClone()) {
        activateClone();
      }
      return true;
    }
    
    // Handle stats overlay toggle with 'I' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyI) {
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
      } else {
        gameRef.statsOverlay.show();
      }
      return true;
    }
    
    return false;
  }
  
  void takeDamage(double damage) {
    if (isInvincible || isDamageInvincible || isUsingAbility) {
      return; // No damage while invincible, damage invincible, or using ability
    }
    
    double remainingDamage = damage;
    
    // Shield absorbs damage first
    if (shield > 0) {
      if (shield >= remainingDamage) {
        // Shield absorbs all damage
        shield -= remainingDamage;
        remainingDamage = 0;
      } else {
        // Shield absorbs partial damage and breaks
        remainingDamage -= shield;
        shield = 0;
        
        // Remove shield effect when shield is broken
        if (hasTemporaryEffect('shield')) {
          print('Shield broken! Removing shield effect.');
          _removeEffectImmediate('shield');
          _temporaryEffects.remove('shield');
        }
      }
    }
    
    // Apply remaining damage to health
    if (remainingDamage > 0) {
      health = (health - remainingDamage).clamp(0, maxHealth);
    }
    
    // Activate damage invincibility
    isDamageInvincible = true;
    damageInvincibilityTimer = 0.0;
    
    if (health <= 0) {
      gameRef.onHeroDeath();
    }
  }
  
  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
  
  void addCoins(int amount) {
    final multiplier = totalCoinMultiplier;
    final finalAmount = (amount * multiplier).round();
    coins += finalAmount;
    if (multiplier > 1.0) {
      print('Coin Magnet: ${amount} -> ${finalAmount} coins (${multiplier}x)');
    }
  }
  
  void spendCoins(int amount) {
    coins = max(0, coins - amount);
  }
  
  void activateInvincibility() {
    isInvincible = true;
    invincibilityTimer = invincibilityDuration;
  }
  
  void _createSquareAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'square',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  void _createHeptagonAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'heptagon',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  // Temporary effects system - only one effect at a time
  void applyTemporaryEffect(String effectType, double value, double duration) {
    // Remove any existing effect first (only one at a time)
    if (_temporaryEffects.isNotEmpty) {
      final oldEffect = _temporaryEffects.entries.first;
      _removeEffectImmediate(oldEffect.key);
      _temporaryEffects.clear();
      print('Replaced effect: ${oldEffect.key} -> $effectType');
    }
    
    // Apply new effect
    _temporaryEffects[effectType] = TemporaryEffect(
      type: effectType,
      value: value,
      duration: duration,
    );
    
    // Apply immediate effects
    _applyEffectImmediate(effectType, value);
    
    print('Applied temporary effect: $effectType (${value}, ${duration}s)');
  }
  
  void _updateTemporaryEffects(double dt) {
    final expiredEffects = <String>[];
    
    for (final entry in _temporaryEffects.entries) {
      final effect = entry.value;
      effect.update(dt);
      
      if (effect.isExpired) {
        expiredEffects.add(entry.key);
        _removeEffectImmediate(entry.key);
      } else {
        // Apply ongoing effects
        _applyEffectOngoing(effect.type, effect.value, dt);
      }
    }
    
    // Remove expired effects
    for (final effectType in expiredEffects) {
      _temporaryEffects.remove(effectType);
    }
  }
  
  void _applyEffectImmediate(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
        speedMultiplier *= (1.0 + value);
        break;
      case 'damage_boost':
        // This will be applied in damage calculations
        break;
      case 'shield':
        shield += value;
        maxShield = maxShield > shield ? maxShield : shield;
        break;
      case 'invincibility':
        isInvincible = true;
        invincibilityTimer = 0.0;
        break;
      case 'weapon_overclock':
        attackSpeedMultiplier *= (1.0 + value);
        break;
    }
  }
  
  void _applyEffectOngoing(String effectType, double value, double dt) {
    switch (effectType) {
      case 'health_regen':
        heal(value * dt);
        break;
    }
  }
  
  void _removeEffectImmediate(String effectType) {
    switch (effectType) {
      case 'speed_boost':
        // Note: This is a simplified approach. In a full implementation,
        // you'd want to track the original multiplier and restore it
        speedMultiplier = 1.0; // Reset to base
        break;
      case 'damage_boost':
        // Reset damage multiplier
        break;
      case 'shield':
        // Shield naturally decays over time
        break;
      case 'invincibility':
        // Invincibility expires naturally
        break;
      case 'weapon_overclock':
        // Reset attack speed multiplier
        attackSpeedMultiplier = 1.0; // Reset to base
        break;
    }
  }
  
  // Get effective damage multiplier including temporary effects
  double get effectiveDamageMultiplier {
    double multiplier = 1.0;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'damage_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Get effective speed multiplier including temporary effects
  double get effectiveSpeedMultiplier {
    double multiplier = speedMultiplier;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'speed_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Check if hero has a specific temporary effect
  bool hasTemporaryEffect(String effectType) {
    return _temporaryEffects.containsKey(effectType);
  }
  
  // Get remaining time for a temporary effect
  double getTemporaryEffectTime(String effectType) {
    final effect = _temporaryEffects[effectType];
    return effect?.remainingTime ?? 0.0;
  }
  
  // Get current active effect for UI display
  TemporaryEffect? get currentActiveEffect {
    return _temporaryEffects.isNotEmpty ? _temporaryEffects.values.first : null;
  }
  
  // Get current active effect info as a formatted string
  String get activeEffectDisplay {
    final effect = currentActiveEffect;
    if (effect == null) return 'None';
    
    final effectName = _getEffectDisplayName(effect.type);
    final effectValue = _getEffectDisplayValue(effect.type, effect.value);
    
    // Handle infinite duration effects (like persistent shields)
    if (effect.remainingTime.isInfinite || effect.remainingTime.isNaN) {
      return '$effectName $effectValue (∞)';
    }
    
    final timeLeft = effect.remainingTime.ceil();
    return '$effectName $effectValue (${timeLeft}s)';
  }
  
  String _getEffectDisplayName(String effectType) {
    switch (effectType) {
      case 'speed_boost': return 'Speed';
      case 'damage_boost': return 'Damage';
      case 'health_regen': return 'Regen';
      case 'shield': return 'Shield';
      case 'invincibility': return 'Invul';
      case 'weapon_overclock': return 'Overclock';
      default: return effectType;
    }
  }
  
  String _getEffectDisplayValue(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
      case 'damage_boost':
      case 'weapon_overclock':
        return '+${(value * 100).round()}%';
      case 'health_regen':
        return '+${value.round()}/s';
      case 'shield':
        return '+${value.round()}';
      case 'invincibility':
        return 'ON';
      default:
        return value.toString();
    }
  }

  // Stackable passive effects system
  void addPassiveEffect(String effectType, int maxStacks) {
    final currentStacks = _passiveEffectStacks[effectType] ?? 0;
    if (currentStacks < maxStacks) {
      _passiveEffectStacks[effectType] = currentStacks + 1;
      print('Added passive effect: $effectType (${currentStacks + 1}/$maxStacks stacks)');
    } else {
      print('Cannot add $effectType: already at max stacks ($maxStacks)');
    }
  }
  
  int getPassiveEffectStacks(String effectType) {
    return _passiveEffectStacks[effectType] ?? 0;
  }
  
  bool hasPassiveEffect(String effectType) {
    return _passiveEffectStacks.containsKey(effectType) && _passiveEffectStacks[effectType]! > 0;
  }
  
  // Get calculated values based on passive effects
  int get totalProjectileCount {
    return 1 + getPassiveEffectStacks('projectile_count');
  }
  
  int get totalProjectileBounces {
    return getPassiveEffectStacks('projectile_bounces');
  }
  
  double get totalProjectileSize {
    return 1.0 + (getPassiveEffectStacks('projectile_size') * 0.5); // 50% increase per stack
  }
  
  int get totalDroneCount {
    return getPassiveEffectStacks('drone_count');
  }
  
  double get totalLifeSteal {
    return getPassiveEffectStacks('life_steal') * 0.05;
  }
  
  double get totalShieldHP {
    return getPassiveEffectStacks('shield_hp') * 5.0;
  }
  
  double get totalCoinMultiplier {
    return 1.0 + (getPassiveEffectStacks('coin_multiplier') * 0.2);
  }
  
  double get totalHealPerKill {
    return getPassiveEffectStacks('heal_per_kill') * 2.0;
  }
  
  double get totalCritChance {
    return getPassiveEffectStacks('crit_chance') * 0.02;
  }
  
  double get totalMaxHealthBoost {
    return getPassiveEffectStacks('max_health_boost') * 10.0;
  }
  
  bool get hasCloneProjection {
    return hasPassiveEffect('clone_spawn');
  }
  
  void resetPassiveEffects() {
    _passiveEffectStacks.clear();
    killCount = 0;
    destroyAllDrones();
    destroyClone();
  }
  
  // Apply heal per kill effect when an enemy is defeated
  void onEnemyKilled() {
    killCount++;
    
    final healAmount = totalHealPerKill;
    if (healAmount > 0) {
      heal(healAmount);
      print('Healed ${healAmount} HP from kill');
    }
    
    // Handle kill-based max health boost (Auto Injector)
    final autoInjectorStacks = getPassiveEffectStacks('kill_based_max_health');
    if (autoInjectorStacks > 0 && killCount % 10 == 0) {
      final maxHealthIncrease = autoInjectorStacks * 2.0; // 2 HP per stack
      final currentBonus = (killCount ~/ 10) * maxHealthIncrease;
      final maxBonus = autoInjectorStacks * 50.0; // 50 HP max per stack
      
      if (currentBonus <= maxBonus) {
        maxHealth += maxHealthIncrease;
        health += maxHealthIncrease; // Also heal current HP
        print('Auto Injector: +${maxHealthIncrease} max HP from ${killCount} kills');
      }
    }
  }
  
  // Regenerate shields between waves (Armor Plating effect)
  void regenerateShields() {
    final armorShields = totalShieldHP;
    if (armorShields > 0) {
      // Apply armor plating as a persistent shield effect
      applyTemporaryEffect('shield', armorShields, double.infinity);
      print('Armor plating shields regenerated to ${armorShields.toStringAsFixed(1)} HP');
    }
  }
  
  // Drone management system
  void updateDroneCount() {
    final targetDroneCount = totalDroneCount;
    final currentDroneCount = _activeDrones.length;
    
    if (targetDroneCount > currentDroneCount) {
      // Spawn new drones
      for (int i = currentDroneCount; i < targetDroneCount; i++) {
        final drone = DroneWingman(owner: this, droneIndex: i);
        _activeDrones.add(drone);
        gameRef.add(drone);
        print('Spawned drone ${i + 1}/${targetDroneCount}');
      }
    } else if (targetDroneCount < currentDroneCount) {
      // Remove excess drones
      while (_activeDrones.length > targetDroneCount) {
        final drone = _activeDrones.removeLast();
        drone.destroy();
        print('Removed drone. Remaining: ${_activeDrones.length}');
      }
    }
  }
  
  void destroyAllDrones() {
    for (final drone in _activeDrones) {
      drone.destroy();
    }
    _activeDrones.clear();
    print('All drones destroyed');
  }
  
  // Clone management system
  bool canActivateClone() {
    return hasCloneProjection && _activeClone == null && health > maxHealth * 0.5;
  }
  
  void activateClone() {
    print('🤖 Attempting to activate clone...');
    print('   - Has clone projection: ${hasCloneProjection}');
    print('   - No active clone: ${_activeClone == null}');
    print('   - Current health: ${health.toStringAsFixed(1)}/${maxHealth.toStringAsFixed(1)}');
    print('   - Required health: ${(maxHealth * 0.5).toStringAsFixed(1)}');
    
    if (!canActivateClone()) {
      print('❌ Cannot activate clone: requirements not met');
      return;
    }
    
    // Pay health cost (50% of current health)
    final healthCost = health * 0.5;
    health -= healthCost;
    
    // Spawn clone directly to the right with clear gap
    final cloneOffset = Vector2(80, 0); // Simple fixed offset to the right
    final clonePosition = position + cloneOffset;
    
    print('🤖 Creating HeroClone at position: (${clonePosition.x}, ${clonePosition.y})');
    _activeClone = HeroClone(owner: this, spawnPosition: clonePosition);
    
    print('🤖 Adding clone to game...');
    gameRef.add(_activeClone!);
    
    print('✅ CLONE ACTIVATED! Health cost: ${healthCost.toStringAsFixed(1)}, Clone mounted: ${_activeClone!.isMounted}');
  }
  
  void destroyClone() {
    if (_activeClone != null) {
      _activeClone!.destroy();
      _activeClone = null;
      print('Clone destroyed');
    }
  }
  
  bool get hasActiveClone => _activeClone != null;
  
  // Getter for passive effect stacks (for stats display)
  Map<String, int> get passiveEffectStacks => Map.from(_passiveEffectStacks);
  
  void onCloneDestroyed(HeroClone clone) {
    if (_activeClone == clone) {
      _activeClone = null;
      print('Active clone reference cleared');
    }
  }
}

// Visual effect component for abilities
class AbilityVisualEffect extends PositionComponent with HasGameRef<CircleRougeGame> {
  final double effectRange;
  final String shape;
  final Color color;
  
  double lifetime = 0.0;
  static const double totalLifetime = 0.5; // Blink once and disappear
  static const double blinkDuration = 0.25; // Half the lifetime for one blink
  
  AbilityVisualEffect({
    required Vector2 position,
    required this.effectRange,
    required this.shape,
    required this.color,
  }) : super(
    position: position,
    size: Vector2.all(effectRange * 2),
    anchor: Anchor.center,
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    lifetime += dt;
    
    // Remove after total lifetime
    if (lifetime >= totalLifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Calculate opacity with blinking effect
    final blinkProgress = (lifetime / blinkDuration) % 1.0;
    final opacity = (sin(blinkProgress * pi * 2) * 0.15 + 0.1).clamp(0.0, 0.25); // 25% max opacity
    
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = color.withOpacity(opacity * 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Draw the shape based on type
    switch (shape) {
      case 'square':
        final rect = Rect.fromCenter(
          center: center,
          width: effectRange * 2,
          height: effectRange * 2,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;
      case 'heptagon':
        final path = _createHeptagonPath(center, effectRange);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }
  
  Path _createHeptagonPath(Offset center, double radius) {
    final path = Path();
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * pi / 180);
      final y = center.dy + radius * sin(angle * pi / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    return path;
  }
} 
```

I also need to update the item detail card to show the correct information for the Auto Injector:

```dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../shop_panel.dart';

class ItemDetailCard extends RectangleComponent with HasGameRef<CircleRougeGame>, TapCallbacks {
  final ShopItem item;
  final VoidCallback onClose;
  
  // Visual components
  late RectangleComponent background;
  late RectangleComponent border;
  late TextComponent titleText;
  late TextComponent descriptionText;
  late TextComponent costText;
  late TextComponent stackInfoText;
  late TextComponent instructionText;
  
  // Animation properties
  double animationTime = 0.0;
  static const double animationDuration = 0.3;
  bool isClosing = false;
  
  ItemDetailCard({
    required this.item,
    required this.onClose,
  }) : super(
    anchor: Anchor.center,
  ) {
    final screenWidth = DisplayConfig.instance.settings?.windowWidth ?? 800.0;
    final screenHeight = DisplayConfig.instance.settings?.windowHeight ?? 600.0;
    
    // Card dimensions
    final cardWidth = (screenWidth * 0.6).clamp(300.0, 500.0);
    final cardHeight = (screenHeight * 0.4).clamp(200.0, 300.0);
    
    size = Vector2(cardWidth, cardHeight);
    position = Vector2(screenWidth / 2, screenHeight / 2);
    
    _setupVisualComponents();
  }
  
  void _setupVisualComponents() {
    // Background with semi-transparent overlay
    background = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFF1A1A1A).withOpacity(0.95)
        ..style = PaintingStyle.fill,
    );
    add(background);
    
    // Border with item category color
    final borderColor = _getItemCategoryColor();
    border = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    add(border);
    
    // Title text
    titleText = TextComponent(
      text: item.name.toUpperCase(),
      textRenderer: TextPaint(
        style: TextStyle(
          color: borderColor,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      position: Vector2(size.x / 2, 40),
      anchor: Anchor.center,
    );
    add(titleText);
    
    // Cost text
    costText = TextComponent(
      text: '${item.cost} COINS',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD700), // Gold color
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(size.x / 2, 70),
      anchor: Anchor.center,
    );
    add(costText);
    
    // Description text (word-wrapped)
    final wrappedDescription = _wrapText(item.description, 45);
    descriptionText = TextComponent(
      text: wrappedDescription,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.4,
        ),
      ),
      position: Vector2(size.x / 2, 110),
      anchor: Anchor.center,
    );
    add(descriptionText);
    
    // Stack information (if applicable)
    final stackInfo = _getStackInfo();
    if (stackInfo.isNotEmpty) {
      stackInfoText = TextComponent(
        text: stackInfo,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFF88FF88), // Light green
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        position: Vector2(size.x / 2, size.y - 70),
        anchor: Anchor.center,
      );
      add(stackInfoText);
    }
    
    // Instruction text
    instructionText = TextComponent(
      text: 'TAP ANYWHERE TO CLOSE',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
      position: Vector2(size.x / 2, size.y - 30),
      anchor: Anchor.center,
    );
    add(instructionText);
  }
  
  Color _getItemCategoryColor() {
    // Determine color based on item type/category
    switch (item.id) {
      // Combat Enhancement items
      case 'spread_master':
      case 'bouncing_bullets':
      case 'enlarged_caliber':
        return const Color(0xFFFF6B6B); // Red
      
      // Support Systems
      case 'drone_wingman':
      case 'clone_projection':
        return const Color(0xFF4ECDC4); // Teal
      
      // Survivability
      case 'vampiric_coating':
      case 'armor_plating':
      case 'auto_injector':
        return const Color(0xFF45B7D1); // Blue
      
      // Utility
      case 'coin_magnet':
      case 'critical_striker':
        return const Color(0xFFFFD93D); // Yellow
      
      // Traditional upgrades
      case 'health_potion':
      case 'max_health_up':
        return const Color(0xFF6BCF7F); // Green
      
      case 'attack_speed_up':
      case 'speed_boost':
      case 'extended_reach':
      case 'dash_mastery':
        return const Color(0xFFB19CD9); // Purple
      
      default:
        return const Color(0xFF888888); // Gray fallback
    }
  }
  
  String _getStackInfo() {
    final hero = gameRef.hero;
    
    switch (item.id) {
      case 'spread_master':
        final current = hero.getPassiveEffectStacks('projectile_count');
        return 'Current: +$current projectiles (Max: +9)';
      
      case 'bouncing_bullets':
        final current = hero.getPassiveEffectStacks('projectile_bounces');
        return 'Current: +$current bounces (Max: +3)';
      
      case 'drone_wingman':
        final current = hero.getPassiveEffectStacks('drone_count');
        return 'Current: $current drones (Max: 3)';
      
      case 'enlarged_caliber':
        final current = hero.getPassiveEffectStacks('projectile_size');
        final percentage = (current * 10);
        return 'Current: +$percentage% size (Max: +100%)';
      
      case 'vampiric_coating':
        final current = hero.getPassiveEffectStacks('life_steal');
        final percentage = (current * 5);
        return 'Current: +$percentage% life steal (Max: +20%)';
      
      case 'armor_plating':
        final current = hero.getPassiveEffectStacks('shield_hp');
        final shieldHP = current * 5;
        return 'Current: +$shieldHP shield HP (Max: +100)';
      
      case 'coin_magnet':
        final current = hero.getPassiveEffectStacks('coin_multiplier');
        final percentage = (current * 20);
        return 'Current: +$percentage% coin earn (Max: +100%)';
      
      case 'auto_injector':
        final current = hero.getPassiveEffectStacks('kill_based_max_health');
        final maxHealthPer10Kills = current * 2;
        final maxPossible = current * 50;
        return 'Current: +$maxHealthPer10Kills max HP per 10 kills (Max: +$maxPossible total)';
      
      case 'critical_striker':
        final current = hero.getPassiveEffectStacks('crit_chance');
        final percentage = (current * 2);
        return 'Current: +$percentage% crit chance (Max: +10%)';
      
      case 'clone_projection':
        final hasClone = hero.hasCloneProjection;
        return hasClone ? 'Clone Projection: Available (Press C)' : 'Not owned';
      
      default:
        return '';
    }
  }
  
  String _wrapText(String text, int maxLineLength) {
    final words = text.split(' ');
    final lines = <String>[];
    String currentLine = '';
    
    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine + ' ' + word).length <= maxLineLength) {
        currentLine += ' ' + word;
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    
    return lines.join('\n');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Handle animation
    if (!isClosing) {
      animationTime += dt;
      if (animationTime < animationDuration) {
        final progress = animationTime / animationDuration;
        final easeProgress = _easeOutCubic(progress);
        
        // Scale animation
        scale = Vector2.all(easeProgress);
        
        // Fade in
        final opacity = easeProgress;
        background.paint.color = const Color(0xFF1A1A1A).withOpacity(0.95 * opacity);
        border.paint.color = _getItemCategoryColor().withOpacity(opacity);
      } else {
        scale = Vector2.all(1.0);
      }
    } else {
      animationTime -= dt * 3; // Faster closing animation
      if (animationTime <= 0) {
        removeFromParent();
        return;
      }
      
      final progress = animationTime / animationDuration;
      scale = Vector2.all(progress);
      
      // Fade out
      final opacity = progress;
      background.paint.color = const Color(0xFF1A1A1A).withOpacity(0.95 * opacity);
      border.paint.color = _getItemCategoryColor().withOpacity(opacity);
    }
  }
  
  double _easeOutCubic(double t) {
    return 1 - pow(1 - t, 3);
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    close();
    return true;
  }
  
  void close() {
    if (!isClosing) {
      isClosing = true;
      onClose();
    }
  }
  
  double pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

```

Now let me work on the Enlarged Caliber item to make it enlarge the character and slow them down. First, I need to update the item configuration:

```json
{
  "items": [
    {
      "id": "health_potion",
      "name": "Health Potion",
      "cost": 30,
      "description": "Restore 50 HP",
      "type": "consumable",
      "icon": "health_potion_transparent.png",
      "effect": {
        "type": "heal",
        "value": 50
      }
    },
    {
      "id": "dash_mastery",
      "name": "Dash Mastery",
      "cost": 60,
      "description": "-20% Dash Cooldown",
      "type": "upgrade",
      "icon": "ability_mastery_transparent.png",
      "effect": {
        "type": "dash_cooldown_multiplier",
        "value": 0.8
      }
    },
    {
      "id": "max_health_up",
      "name": "Max Health Up",
      "cost": 50,
      "description": "+25 Max Health",
      "type": "upgrade",
      "icon": "max_health_up_transparent.png",
      "effect": {
        "type": "max_health_increase",
        "value": 25
      }
    },
    {
      "id": "attack_speed_up",
      "name": "Attack Speed Up",
      "cost": 60,
      "description": "+25% Attack Speed",
      "type": "upgrade",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "attack_speed_multiplier",
        "value": 0.25
      }
    },
    {
      "id": "speed_boost",
      "name": "Speed Boost",
      "cost": 40,
      "description": "+25% Movement Speed",
      "type": "upgrade",
      "icon": "speed_boost_transparent.png",
      "effect": {
        "type": "speed_multiplier",
        "value": 0.25
      }
    },
    {
      "id": "extended_reach",
      "name": "Extended Reach",
      "cost": 150,
      "description": "+50% Range for all attacks and abilities",
      "type": "upgrade",
      "icon": "extended_reach_transparent.png",
      "effect": {
        "type": "range_multiplier",
        "value": 0.5
      }
    },
    {
      "id": "spread_master",
      "name": "Spread Master",
      "cost": 70,
      "description": "+1 projectile per shot, stack up to +9 (max 10 shots)",
      "type": "passive",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "projectile_count",
        "value": 1,
        "max_stacks": 9
      }
    },
    {
      "id": "bouncing_bullets",
      "name": "Bouncing Bullets",
      "cost": 80,
      "description": "+1 projectile bounce per shot, stackable to +3",
      "type": "passive",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "projectile_bounces",
        "value": 1,
        "max_stacks": 3
      }
    },
    {
      "id": "drone_wingman",
      "name": "Drone Wingman",
      "cost": 90,
      "description": "Summons one auto-firing drone (0.8 shots/sec), stackable to 3 drones",
      "type": "passive",
      "icon": "ability_mastery_transparent.png",
      "effect": {
        "type": "drone_count",
        "value": 1,
        "max_stacks": 3
      }
    },
    {
      "id": "enlarged_caliber",
      "name": "Enlarged Caliber",
      "cost": 60,
      "description": "+10% projectile diameter and character size, -25% speed per stack (max 5 stacks)",
      "type": "passive",
      "icon": "extended_reach_transparent.png",
      "effect": {
        "type": "enlarged_caliber",
        "value": 0.1,
        "max_stacks": 5
      }
    },
    {
      "id": "clone_projection",
      "name": "Clone Projection",
      "cost": 120,
      "description": "Spend 50% current HP to spawn a clone that mimics player",
      "type": "active_passive",
      "icon": "ability_mastery_transparent.png",
      "effect": {
        "type": "clone_spawn",
        "value": 0.5,
        "max_stacks": 1
      }
    },
    {
      "id": "vampiric_coating",
      "name": "Vampiric Coating",
      "cost": 80,
      "description": "+5% life steal per stack, max +20%",
      "type": "passive",
      "icon": "health_potion_transparent.png",
      "effect": {
        "type": "life_steal",
        "value": 0.05,
        "max_stacks": 4
      }
    },
    {
      "id": "armor_plating",
      "name": "Armor Plating",
      "cost": 70,
      "description": "+5 shield HP per stack, max +100; shields fully regens between waves",
      "type": "passive",
      "icon": "max_health_up_transparent.png",
      "effect": {
        "type": "shield_hp",
        "value": 5,
        "max_stacks": 20
      }
    },
    {
      "id": "coin_magnet",
      "name": "Coin Magnet",
      "cost": 50,
      "description": "+20% coin earn, max +100%",
      "type": "passive",
      "icon": "speed_boost_transparent.png",
      "effect": {
        "type": "coin_multiplier",
        "value": 0.2,
        "max_stacks": 5
      }
    },
    {
      "id": "auto_injector",
      "name": "Auto-Injector",
      "cost": 100,
      "description": "Every 10 kills grants +2 Max HP (caps at +50 per stack)",
      "type": "passive",
      "icon": "health_potion_transparent.png",
      "effect": {
        "type": "kill_based_max_health",
        "value": 2,
        "max_stacks": 5
      }
    },
    {
      "id": "critical_striker",
      "name": "Critical Striker",
      "cost": 75,
      "description": "+2% crit chance per stack, max +10%",
      "type": "passive",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "crit_chance",
        "value": 0.02,
        "max_stacks": 5
      }
    }
  ]
}

```

Now I need to update the shop panel to handle the new enlarged_caliber effect:

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game/circle_rouge_game.dart';
import '../config/item_config.dart';
import '../config/wave_config.dart';
import 'sound_manager.dart';
import '../config/display_config.dart';
import '../config/game_mode_config.dart';
import 'ui/item_detail_card.dart';

class ShopItem {
  final String id;
  final String name;
  final int cost;
  final String description;
  final String icon;
  final void Function() onPurchase;
  
  ShopItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
    required this.icon,
    required this.onPurchase,
  });
  
  factory ShopItem.fromItemData(ItemData itemData, void Function() onPurchase, int scaledCost) {
    return ShopItem(
      id: itemData.id,
      name: itemData.name,
      cost: scaledCost,
      description: itemData.description,
      icon: itemData.icon,
      onPurchase: onPurchase,
    );
  }
}

class ShopPanel extends RectangleComponent with HasGameRef<CircleRougeGame>, TapCallbacks {
  late List<ShopSlot> itemSlots;
  late RectangleComponent rollButton;
  late TextComponent rollButtonText;
  late TextComponent titleText;
  late TextComponent instructionText;
  late RectangleComponent backgroundGradient;
  late RectangleComponent headerPanel;
  late RectangleComponent footerPanel;
  
  bool isVisible = false;
  
  static const double panelWidth = 715.0;
  static const double panelHeight = 550.0;
  static const double slotWidth = 176.0;
  static const double slotHeight = 275.0;
  static const double slotSpacing = 49.5;
  
  ShopPanel() : super(
    size: Vector2(panelWidth, panelHeight),
    paint: Paint()..color = Colors.transparent,
    position: Vector2(
      (DisplayConfig.instance.arenaWidth - panelWidth) / 2,
      (DisplayConfig.instance.arenaHeight - panelHeight) / 2,
    ),
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Background with enhanced gradient effect
    backgroundGradient = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      paint: Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D2D4A),
            Color(0xFF1E1E3A),
            Color(0xFF151528),
          ],
        ).createShader(Rect.fromLTWH(0, 0, panelWidth, panelHeight)),
      position: Vector2.zero(),
    );
    add(backgroundGradient);
    
    // Main border with enhanced glow effect
    final border = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF4A9EFF).withOpacity(0.6),
      position: Vector2.zero(),
    );
    add(border);
    
    // Outer glow effect
    final outerGlow = RectangleComponent(
      size: Vector2(panelWidth + 10, panelHeight + 10),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = const Color(0xFF4A9EFF).withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      position: Vector2(-5, -5),
    );
    add(outerGlow);
    
    // Header panel with gradient
    headerPanel = RectangleComponent(
      size: Vector2(panelWidth - 20, 99),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF4A9EFF),
            Color(0xFF9C27B0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, panelWidth - 20, 99))
        ..color = const Color(0xFF4A9EFF).withOpacity(0.15),
      position: Vector2(10, 10),
    );
    add(headerPanel);
    
    // Header border with glow
    final headerBorder = RectangleComponent(
      size: Vector2(panelWidth - 20, 99),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4A9EFF).withOpacity(0.6),
      position: Vector2(10, 10),
    );
    add(headerBorder);
    
    // Title with enhanced styling and shader mask effect
    titleText = TextComponent(
      text: 'MYSTICAL SHOP',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white, // This will be overridden by the gradient
          fontSize: 35.2, // Increased from 32 (10% bigger)
          fontWeight: FontWeight.w900,
          letterSpacing: 3.0,
          shadows: [
            Shadow(
              color: Color(0xFF4A9EFF),
              blurRadius: 15,
            ),
            Shadow(
              color: Color(0xFF9C27B0),
              blurRadius: 10,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 5,
            ),
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(panelWidth / 2, 33), // Adjusted from 30 (10% bigger)
    );
    add(titleText);
    
    // Instructions with enhanced styling
    instructionText = TextComponent(
      text: 'Enhance your hero with powerful upgrades',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 17.6, // Increased from 16 (10% bigger)
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 6,
            ),
            Shadow(
              color: Color(0xFF4A9EFF),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(panelWidth / 2, 77), // Adjusted from 70 (10% bigger)
    );
    add(instructionText);
    
    // Create item slots with better positioning
    itemSlots = [];
    final slotsStartX = (panelWidth - (3 * slotWidth + 2 * slotSpacing)) / 2;
    for (int i = 0; i < 3; i++) {
      final slot = ShopSlot(
        position: Vector2(
          slotsStartX + i * (slotWidth + slotSpacing),
          121,
        ),
      );
      itemSlots.add(slot);
      add(slot);
    }
    
    // Footer panel with gradient background
    footerPanel = RectangleComponent(
      size: Vector2(panelWidth - 20, 70),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF2D2D4A),
            Color(0xFF1E1E3A),
          ],
        ).createShader(Rect.fromLTWH(0, 0, panelWidth - 20, 70))
        ..color = const Color(0xFF2D2D4A).withOpacity(0.6),
      position: Vector2(10, panelHeight - 80),
    );
    add(footerPanel);
    
    // Footer border
    final footerBorder = RectangleComponent(
      size: Vector2(panelWidth - 20, 70),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4A9EFF).withOpacity(0.3),
      position: Vector2(10, panelHeight - 80),
    );
    add(footerBorder);
    
    // Roll button with enhanced gradient styling
    rollButton = RectangleComponent(
      size: Vector2(140, 45),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF2196F3),
            Color(0xFF1976D2),
          ],
        ).createShader(Rect.fromLTWH(0, 0, 140, 45)),
      position: Vector2((panelWidth - 140) / 2 - 90, panelHeight - 65),
    );
    add(rollButton);
    
    // Roll button glow effect
    final rollButtonGlow = RectangleComponent(
      size: Vector2(140, 45),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF2196F3).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      position: Vector2((panelWidth - 140) / 2 - 90, panelHeight - 65),
    );
    add(rollButtonGlow);
    
    rollButtonText = TextComponent(
      text: 'REROLL (10)',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(70, 22.5),
    );
    rollButton.add(rollButtonText);
    
    // Continue button with enhanced gradient styling
    final continueButton = RectangleComponent(
      size: Vector2(140, 45),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF388E3C),
          ],
        ).createShader(Rect.fromLTWH(0, 0, 140, 45)),
      position: Vector2((panelWidth - 140) / 2 + 90, panelHeight - 65),
    );
    add(continueButton);
    
    // Continue button glow effect
    final continueButtonGlow = RectangleComponent(
      size: Vector2(140, 45),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF4CAF50).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      position: Vector2((panelWidth - 140) / 2 + 90, panelHeight - 65),
    );
    add(continueButtonGlow);
    
    final continueButtonText = TextComponent(
      text: 'CONTINUE',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(70, 22.5),
    );
    continueButton.add(continueButtonText);
    
    // Store continue button reference for tap detection
    continueButton.add(Component());
    continueButton.children.register<Component>();
    
    // Initially hidden
    hide();
    
    // Populate with initial items
    rollShopItems();
  }
  
  void show() {
    isVisible = true;
    opacity = 1.0;
  }
  
  void hide() {
    isVisible = false;
    opacity = 0.0;
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    if (!isVisible) return false;
    
    final localPoint = event.localPosition;
    
    // Check if roll button was tapped - updated for 10% bigger dimensions
    final rollButtonRect = Rect.fromLTWH(
      rollButton.position.x,
      rollButton.position.y,
      154, // Updated from 140
      49.5, // Updated from 45
    );
    
    if (rollButtonRect.contains(Offset(localPoint.x, localPoint.y))) {
      rollShopItems();
      return true;
    }
    
    // Check if continue button was tapped - updated for 10% bigger dimensions
    final continueButtonPosition = Vector2((panelWidth - 154) / 2 + 99, panelHeight - 71.5); // Updated from 140/90/65
    final continueButtonRect = Rect.fromLTWH(
      continueButtonPosition.x,
      continueButtonPosition.y,
      154, // Updated from 140
      49.5, // Updated from 45
    );
    
    if (continueButtonRect.contains(Offset(localPoint.x, localPoint.y))) {
      closeShop();
      return true;
    }
    
    return false;
  }
  
  void rollShopItems() {
    // Check if all items are sold (free roll)
    final allItemsSold = itemSlots.every((slot) => slot.currentItem == null);
    
    // Get roll cost from configuration
    final rollCost = allItemsSold ? 0 : (WaveConfig.instance.shopConfig?.rollCost ?? 10);
    
    // Check if player has enough coins to roll
    if (gameRef.hero.coins < rollCost) {
      return; // Not enough coins to roll
    }
    
    // Spend coins for rolling (if not free)
    if (rollCost > 0) {
      gameRef.hero.spendCoins(rollCost);
    }
    
    final availableItems = _getAvailableItems();
    final random = Random();
    
    for (int i = 0; i < 3; i++) {
      if (availableItems.isNotEmpty) {
        final randomItem = availableItems[random.nextInt(availableItems.length)];
        itemSlots[i].setItem(randomItem);
      }
    }
    
    // Update roll button text after rolling
    final newRollCost = WaveConfig.instance.shopConfig?.rollCost ?? 10;
    rollButtonText.text = 'REROLL ($newRollCost)';
  }
  
  List<ShopItem> _getAvailableItems() {
    final itemConfig = ItemConfig.instance;
    final shopConfig = WaveConfig.instance.shopConfig;
    List<ShopItem> availableItems = [];
    final random = Random();
    
    for (final itemData in itemConfig.items) {
      // Skip health-related items in 1HP Challenge mode
      if (gameRef.currentGameMode == GameMode.oneHpChallenge) {
        if (itemData.effect.type == 'heal' || 
            itemData.effect.type == 'max_health_increase') {
          continue; // Skip health items in 1HP mode
        }
      }
      
      // Calculate scaled price based on current wave using configuration
      double waveMultiplier = 1.0;
      double randomMultiplier = 1.0;
      
      if (shopConfig != null) {
        waveMultiplier = 1.0 + (shopConfig.waveMultiplier * (gameRef.currentWave - 1));
        randomMultiplier = (1.0 - shopConfig.randomVariance) + (random.nextDouble() * shopConfig.randomVariance * 2);
      } else {
        // Fallback to old hardcoded values
        waveMultiplier = 1.0 + (0.2 * (gameRef.currentWave - 1));
        randomMultiplier = 0.95 + (random.nextDouble() * 0.1);
      }
      
      final scaledCost = (itemData.cost * waveMultiplier * randomMultiplier).round();
      
      // Create dynamic name for ability cooldown reduction based on hero's ability
      if (itemData.id == 'dash_mastery') {
        final heroAbilityName = gameRef.hero.heroData.ability.name;
        availableItems.add(ShopItem(
          id: itemData.id,
          name: '$heroAbilityName Mastery',
          cost: scaledCost,
          description: '-25% ${heroAbilityName} Cooldown',
          icon: itemData.icon,
          onPurchase: () => _applyItemEffect(itemData),
        ));
      } else {
        availableItems.add(ShopItem.fromItemData(itemData, () => _applyItemEffect(itemData), scaledCost));
      }
    }
    
    return availableItems;
  }
  
  void _applyItemEffect(ItemData itemData) {
    switch (itemData.effect.type) {
      case 'heal':
        final healAmount = (gameRef.hero.maxHealth - gameRef.hero.health).clamp(0.0, itemData.effect.value);
        gameRef.hero.heal(healAmount);
        break;
      case 'dash_cooldown_multiplier':
        // Apply ability cooldown reduction
        gameRef.hero.abilityCooldownMultiplier *= itemData.effect.value;
        break;
      case 'max_health_increase':
        gameRef.hero.maxHealth += itemData.effect.value;
        gameRef.hero.health += itemData.effect.value;
        break;
      case 'attack_speed_multiplier':
        gameRef.hero.attackSpeedMultiplier += itemData.effect.value;
        break;
      case 'speed_multiplier':
        gameRef.hero.speedMultiplier += itemData.effect.value;
        break;
      case 'range_multiplier':
        gameRef.hero.rangeMultiplier += itemData.effect.value;
        break;
      // New stackable passive effects
      case 'projectile_count':
      case 'projectile_bounces':
      case 'projectile_size':
      case 'life_steal':
      case 'shield_hp':
      case 'coin_multiplier':
      case 'heal_per_kill':
      case 'crit_chance':
      case 'clone_spawn':
      case 'max_health_boost':
      case 'kill_based_max_health':
      case 'enlarged_caliber':
        final maxStacks = itemData.effect.maxStacks ?? 1;
        gameRef.hero.addPassiveEffect(itemData.effect.type, maxStacks);
        // Max health boost only affects max HP, not current HP
        break;
      case 'drone_count':
        final maxStacks = itemData.effect.maxStacks ?? 1;
        gameRef.hero.addPassiveEffect(itemData.effect.type, maxStacks);
        // Update drone count immediately
        gameRef.hero.updateDroneCount();
        break;
      default:
        print('Unknown item effect type: ${itemData.effect.type}');
    }
  }
  
  void onItemPurchased() {
    // Update roll button text based on remaining items
    final allItemsSold = itemSlots.every((slot) => slot.currentItem == null);
    final rollCost = allItemsSold ? 0 : (WaveConfig.instance.shopConfig?.rollCost ?? 10);
    rollButtonText.text = rollCost == 0 ? 'REROLL (FREE)' : 'REROLL ($rollCost)';
  }
  
  void closeShop() {
    hide();
    gameRef.onShopClosed();
  }
}

class ShopSlot extends RectangleComponent with TapCallbacks, HasGameRef<CircleRougeGame> {
  late TextBoxComponent nameText;
  late TextComponent costText;
  late TextComponent descriptionText;
  late RectangleComponent buyButton;
  late TextComponent buyButtonText;
  late Component itemIcon;
  late RectangleComponent border;
  late RectangleComponent outerGlow;
  late RectangleComponent buyButtonGlow;
  
  ShopItem? currentItem;
  
  ShopSlot({required Vector2 position}) : super(
    size: Vector2(ShopPanel.slotWidth, ShopPanel.slotHeight),
    paint: Paint()..color = Colors.transparent,
    position: position,
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Background with enhanced gradient
    final background = RectangleComponent(
      size: Vector2(size.x, size.y),
      paint: Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A3A3A),
            Color(0xFF2A2A2A),
            Color(0xFF1A1A1A),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
      position: Vector2.zero(),
    );
    add(background);
    
    // Border with enhanced glow
    border = RectangleComponent(
      size: Vector2(size.x, size.y),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4A9EFF).withOpacity(0.5),
      position: Vector2.zero(),
    );
    add(border);
    
    // Outer glow effect for slots
    outerGlow = RectangleComponent(
      size: Vector2(size.x + 4, size.y + 4),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xFF4A9EFF).withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      position: Vector2(-2, -2),
    );
    add(outerGlow);
    
    // Initialize item icon as empty placeholder - will be replaced when item is set
    itemIcon = RectangleComponent(
      size: Vector2(44, 44),
      position: Vector2((size.x - 44) / 2, 22),
      paint: Paint()..color = Colors.transparent,
    );
    add(itemIcon);
    
    // Item name with enhanced styling and line wrapping
    nameText = TextBoxComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF4A9EFF),
          fontSize: 17.6,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: [
            Shadow(
              color: Color(0xFF4A9EFF),
              blurRadius: 6,
            ),
          ],
        ),
      ),
      align: Anchor.center,
      boxConfig: TextBoxConfig(
        maxWidth: size.x - 10,
        timePerChar: 0.0,
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 82.5),
    );
    add(nameText);
    
    // Item description with better styling
    descriptionText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 13.2,
          fontWeight: FontWeight.w500,
          height: 1.4,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 132),
    );
    add(descriptionText);
    
    // Cost with enhanced styling
    costText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFEB3B),
          fontSize: 19.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: [
            Shadow(
              color: Color(0xFFFFEB3B),
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
      position: Vector2(size.x / 2, 170.5),
    );
    add(costText);
    
    // Buy button with enhanced gradient styling
    buyButton = RectangleComponent(
      size: Vector2(143, 44),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF388E3C),
          ],
        ).createShader(Rect.fromLTWH(0, 0, 143, 44)),
      position: Vector2((size.x - 143) / 2, size.y - 60.5),
    );
    add(buyButton);
    
    // Buy button glow effect
    buyButtonGlow = RectangleComponent(
      size: Vector2(143, 44),
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF4CAF50).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      position: Vector2((size.x - 143) / 2, size.y - 60.5),
    );
    add(buyButtonGlow);
    
    buyButtonText = TextComponent(
      text: 'PURCHASE',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15.4,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(71.5, 22),
    );
    buyButton.add(buyButtonText);
  }
  
  // Get category colors based on item type
  Map<String, Color> _getCategoryColors(String itemId) {
    switch (itemId) {
      case 'health_potion':
      case 'max_health_up':
        // Green for health items
        return {
          'primary': const Color(0xFF4CAF50),
          'secondary': const Color(0xFF66BB6A),
          'glow': const Color(0xFF4CAF50),
        };
      case 'attack_speed_up':
        // Red for attack items
        return {
          'primary': const Color(0xFFF44336),
          'secondary': const Color(0xFFE57373),
          'glow': const Color(0xFFF44336),
        };
      case 'speed_boost':
        // Blue for speed items
        return {
          'primary': const Color(0xFF2196F3),
          'secondary': const Color(0xFF64B5F6),
          'glow': const Color(0xFF2196F3),
        };
      case 'dash_mastery':
        // Hero color for ability items
        final heroColor = gameRef.hero.heroData.color;
        return {
          'primary': heroColor,
          'secondary': heroColor.withOpacity(0.8),
          'glow': heroColor,
        };
      default:
        // Default blue theme
        return {
          'primary': const Color(0xFF4A9EFF),
          'secondary': const Color(0xFF64B5F6),
          'glow': const Color(0xFF4A9EFF),
        };
    }
  }

  void setItem(ShopItem item) async {
    currentItem = item;
    final colors = _getCategoryColors(item.id);
    
    nameText.text = item.name.toUpperCase();
    descriptionText.text = item.description;
    costText.text = '${item.cost} COINS';
    
    // Replace the current icon with a sprite-based icon
    if (itemIcon.isMounted) {
      itemIcon.removeFromParent();
    }
    
    try {
      // Try to load the actual item icon sprite
      final sprite = await Sprite.load(item.icon);
      itemIcon = SpriteComponent(
        sprite: sprite,
        size: Vector2(44, 44),
        position: Vector2((size.x - 44) / 2, 22),
        anchor: Anchor.topLeft,
      );
    } catch (e) {
      print('Could not load item icon: ${item.icon}, using colored rectangle fallback');
      // Fallback to colored rectangle with category color
      itemIcon = RectangleComponent(
        size: Vector2(44, 44),
        position: Vector2((size.x - 44) / 2, 22),
        paint: Paint()..color = colors['primary']!,
      );
    }
    
    add(itemIcon);
    
    // Update name text color to match category
    nameText.textRenderer = TextPaint(
      style: TextStyle(
        color: colors['primary']!,
        fontSize: 17.6,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        shadows: [
          Shadow(
            color: colors['glow']!,
            blurRadius: 6,
          ),
        ],
      ),
    );
    
    // Update border and glow colors to match category
    border.paint.color = colors['primary']!.withOpacity(0.6);
    outerGlow.paint.color = colors['glow']!.withOpacity(0.15);
    
    // Update buy button styling based on affordability and category
    if (gameRef.hero.coins >= item.cost) {
      // Update buy button gradient with category colors
      buyButton.paint.shader = LinearGradient(
        colors: [
          colors['primary']!,
          colors['secondary']!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, 143, 44));
      
      buyButtonGlow.paint.color = colors['glow']!.withOpacity(0.5);
      buyButtonText.text = 'PURCHASE';
    } else {
      // Grey for unaffordable items
      buyButton.paint.shader = const LinearGradient(
        colors: [
          Color(0xFF757575),
          Color(0xFF616161),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 143, 44));
      
      buyButtonGlow.paint.color = const Color(0xFF757575).withOpacity(0.3);
      buyButtonText.text = 'TOO EXPENSIVE';
      border.paint.color = const Color(0xFFF44336).withOpacity(0.4);
    }
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    if (currentItem == null) return false;
    
    final localPoint = event.localPosition;
    
    // Check if buy button was tapped
    if (buyButton.containsLocalPoint(localPoint - buyButton.position)) {
      attemptPurchase();
      return true;
    }
    
    // Check if item info area was tapped (anywhere except buy button)
    if (localPoint.y < buyButton.position.y) {
      showItemDetails();
      return true;
    }
    
    return false;
  }
  
  void showItemDetails() {
    if (currentItem == null) return;
    
    final detailCard = ItemDetailCard(
      item: currentItem!,
      onClose: () {
        // Detail card handles its own removal
      },
    );
    
    // Add to the game at a high priority to appear on top
    gameRef.add(detailCard);
    
    // Play UI sound effect
    // SoundManager().playUICardOpenSound();
  }
  
  void attemptPurchase() {
    if (currentItem == null) return;
    
    if (gameRef.hero.coins >= currentItem!.cost) {
      gameRef.hero.spendCoins(currentItem!.cost);
      currentItem!.onPurchase();
      
      // Play purchase sound effect
      SoundManager().playPurchaseSound();
      
      // Clear this slot with enhanced sold styling
      currentItem = null;
      nameText.text = 'SOLD';
      nameText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Color(0xFF4CAF50),
          fontSize: 17.6,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Color(0xFF4CAF50),
              blurRadius: 8,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 3,
            ),
          ],
        ),
      );
      descriptionText.text = 'Item purchased successfully!';
      descriptionText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Color(0xFF4CAF50),
          fontSize: 13.2,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      );
      costText.text = '';
      
      // Update buy button to sold out styling
      buyButton.paint.shader = const LinearGradient(
        colors: [
          Color(0xFF757575),
          Color(0xFF616161),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 143, 44));
      
      buyButtonGlow.paint.color = const Color(0xFF757575).withOpacity(0.3);
      buyButtonText.text = 'SOLD OUT';
      
      // Update border and glow to success green
      border.paint.color = const Color(0xFF4CAF50).withOpacity(0.8);
      outerGlow.paint.color = const Color(0xFF4CAF50).withOpacity(0.2);
      
      // Clear the item icon - handle both SpriteComponent and RectangleComponent types
      if (itemIcon.isMounted) {
        itemIcon.removeFromParent();
      }
      
      // Add transparent placeholder
      itemIcon = RectangleComponent(
        size: Vector2(44, 44),
        position: Vector2((size.x - 44) / 2, 22),
        paint: Paint()..color = Colors.transparent,
      );
      add(itemIcon);
      
      // Update parent shop immediately
      if (parent is ShopPanel) {
        (parent as ShopPanel).onItemPurchased();
      }
    }
  }
} 
```

Now I need to update the Hero class to handle enlarged caliber effects. I need to add getters for both projectile size and character size, and modify the speed calculation:

```dart
  double get totalProjectileSize {
    final regularSize = 1.0 + (getPassiveEffectStacks('projectile_size') * 0.1);
    final enlargedSize = 1.0 + (getPassiveEffectStacks('enlarged_caliber') * 0.1);
    return regularSize * enlargedSize;
  }
  
  double get characterSizeMultiplier {
    return 1.0 + (getPassiveEffectStacks('enlarged_caliber') * 0.1);
  }
  
  double get enlargedCaliberSpeedPenalty {
    return getPassiveEffectStacks('enlarged_caliber') * 0.25;
  }
```

Let me find the location of the totalProjectileSize getter:

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/circle_rouge_game.dart';
import '../config/hero_config.dart';
import '../config/display_config.dart';
import 'abilities/hex_field.dart';
import 'enemies/enemy_chaser.dart';
import 'enemies/enemy_shooter.dart';
import 'enemies/shielded_chaser.dart';
import 'enemies/projectile.dart';
import 'enemies/shape_projectile.dart';
import 'enemies/triangle_projectile.dart';
import 'sound_manager.dart';
import 'companions/drone_wingman.dart';
import 'companions/hero_clone.dart';

class TemporaryEffect {
  final String type;
  final double value;
  final double duration;
  double remainingTime;
  
  TemporaryEffect({
    required this.type,
    required this.value,
    required this.duration,
  }) : remainingTime = duration;
  
  void update(double dt) {
    remainingTime -= dt;
  }
  
  bool get isExpired => remainingTime <= 0;
}

class Hero extends PositionComponent with HasGameRef<CircleRougeGame>, KeyboardHandler {
  // Hero configuration
  late HeroData heroData;
  final String heroId;
  
  // Hero visual properties
  late double heroRadius;
  late Paint heroPaint;
  
  // Base movement properties - will be scaled based on arena size
  static const double baseMoveSpeed = 200.0;
  
  // Base dash properties (for heroes that don't have special abilities)
  static const double baseDashDistance = 120.0;
  static const double baseDashSpeed = 500.0;
  
  // Base shooting properties
  static const double baseShootRange = 250.0;
  static const double fireRate = 2.0; // Shots per second
  double lastShotTime = 0.0;
  
  // Get scaled values based on arena size
  double get moveSpeed => (heroData.moveSpeed / 320.0 * baseMoveSpeed) * DisplayConfig.instance.scaleFactor;
  double get dashDistance => baseDashDistance * DisplayConfig.instance.scaleFactor;
  double get dashSpeed => baseDashSpeed * DisplayConfig.instance.scaleFactor;
  double get shootRange => baseShootRange * DisplayConfig.instance.scaleFactor * rangeMultiplier;
  
  // Attack speed modifier (can be upgraded)
  double attackSpeedMultiplier = 1.0;
  
  // Movement speed modifier (can be upgraded)
  double speedMultiplier = 1.0;
  
  // Ability cooldown modifier (can be upgraded)
  double abilityCooldownMultiplier = 1.0;
  
  // Range modifier (can be upgraded)
  double rangeMultiplier = 1.0;
  
  // Weapon overclock visual effect
  // Weapon overclock now handled by temporary effect system
  
  // Ability system
  double lastAbilityTime = -double.infinity;
  bool isUsingAbility = false;
  Vector2? abilityTarget;
  
  // Hero stats
  double health = 100.0;
  double maxHealth = 100.0;
  double energy = 100.0;
  double maxEnergy = 100.0;
  int coins = 0;
  int killCount = 0;
  
  // Invincibility after wave completion
  bool isInvincible = false;
  double invincibilityTimer = 0.0;
  static const double invincibilityDuration = 3.0; // 3 seconds of invincibility
  
  // Damage invincibility (separate from wave completion invincibility)
  bool isDamageInvincible = false;
  double damageInvincibilityTimer = 0.0;
  static const double damageInvincibilityDuration = 0.5; // 0.5 seconds after taking damage
  
  // Temporary effects system
  final Map<String, TemporaryEffect> _temporaryEffects = {};
  
  // Stackable passive effects system
  final Map<String, int> _passiveEffectStacks = {};
  
  // Drone companion system
  final List<DroneWingman> _activeDrones = [];
  
  // Clone system
  HeroClone? _activeClone;
  
  // Shield system
  double shield = 0.0;
  double maxShield = 0.0;
  
  // Input tracking
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  
  Hero({required Vector2 position, required this.heroId}) : super(
    position: position,
    size: Vector2.all(30.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    heroRadius = 15.0 * DisplayConfig.instance.scaleFactor;
    heroPaint = Paint()..color = const Color(0xFF4CAF50);
    _initializeHero(heroId);
  }
  
  void _initializeHero(String heroId) {
    final heroConfig = HeroConfig.instance.getHeroById(heroId);
    if (heroConfig != null) {
      heroData = heroConfig;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    } else {
      // Fallback to default circle hero
      heroData = HeroConfig.instance.defaultHero;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    }
  }
  
  double get effectiveMaxHealth {
    return maxHealth + totalMaxHealthBoost;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Blinking effect during damage invincibility
    if (isDamageInvincible) {
      final blinkTime = (damageInvincibilityTimer * 8) % 1.0; // 8 blinks per second
      if (blinkTime > 0.5) {
        return; // Don't render during blink "off" phase
      }
    }
    
    final center = Offset(size.x / 2, size.y / 2);
    final shapeSize = size.x;
    
    // Old weapon overclock glow removed - now handled by active effect glow
    
    // Active effect glow
    final activeEffect = currentActiveEffect;
    if (activeEffect != null) {
      final effectTime = (DateTime.now().millisecondsSinceEpoch / 1000.0) % 1.5; // 1.5-second cycle
      final glowIntensity = (sin(effectTime * pi * 2) * 0.3 + 0.7); // 0.4 to 1.0
      final glowRadius = 15.0 * glowIntensity;
      
      // Get effect color
      Color effectColor;
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
        default:
          effectColor = const Color(0xFFFFFFFF); // White fallback
      }
      
      final effectGlowPaint = Paint()
        ..color = effectColor.withOpacity(0.8 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      // Draw effect glow based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + glowRadius, effectGlowPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'square':
          _drawSquare(canvas, center, effectGlowPaint, glowRadius);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
      }
    }
    
    // Draw main hero shape
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(center, heroRadius, heroPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, shapeSize, heroPaint, 0);
        break;
      case 'square':
        _drawSquare(canvas, center, heroPaint, 0);
        break;
      case 'pentagon':
        _drawPentagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'hexagon':
        _drawHexagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, shapeSize, heroPaint, 0);
        break;
    }
    
    // Draw shield outline if shield effect is active
    if (hasTemporaryEffect('shield') && shield > 0) {
      final shieldOpacity = (shield / maxShield).clamp(0.3, 1.0); // Fade as shield depletes
      final shieldPaint = Paint()
        ..color = const Color(0xFFFF9800).withOpacity(0.6 * shieldOpacity) // Orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Draw shield outline based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + 4, shieldPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'square':
          _drawSquare(canvas, center, shieldPaint, 4);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, shieldPaint, 4);
          break;
      }
    }
    
  }
  
  void _drawTriangle(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius / 2);
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius / 2);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSquare(Canvas canvas, Offset center, Paint paint, double glowRadius) {
    final size = (this.size.x * 0.8) + (glowRadius * 2);
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      ),
      paint,
    );
  }
  
  void _drawPentagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 5; i++) {
      final angle = -90 + (i * 72); // Pentagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHexagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 6; i++) {
      final angle = -90 + (i * 60); // Hexagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHeptagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  // Collision detection method for other components to use
  @override
  bool containsPoint(Vector2 point) {
    final distance = position.distanceTo(point);
    return distance <= heroRadius;
  }
  
  // Get collision radius for enemy collision detection
  double get collisionRadius => heroRadius;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Weapon overclock now handled by temporary effect system
    
    // Update invincibility timer
    if (isInvincible) {
      invincibilityTimer += dt;
      if (invincibilityTimer >= invincibilityDuration) {
        isInvincible = false;
        invincibilityTimer = 0.0;
      }
    }
    
    // Update damage invincibility timer
    if (isDamageInvincible) {
      damageInvincibilityTimer += dt;
      if (damageInvincibilityTimer >= damageInvincibilityDuration) {
        isDamageInvincible = false;
        damageInvincibilityTimer = 0.0;
      }
    }
    
    // Update temporary effects
    _updateTemporaryEffects(dt);
    
    if (isUsingAbility) {
      _updateAbility(dt);
    } else {
      _updateMovement(dt);
    }
    
    // Auto-shoot at enemies
    _tryAutoShoot();
    
    // Regenerate energy
    if (energy < maxEnergy) {
      energy = (energy + 50 * dt).clamp(0, maxEnergy);
    }
    
    // Keep hero within arena bounds
    _constrainToArena();
    
    // Update ability cooldown in HUD
    _updateAbilityCooldownDisplay();
  }
  
  void _tryAutoShoot() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    if (currentTime - lastShotTime < (1.0 / (fireRate * attackSpeedMultiplier))) {
      return; // Still on cooldown
    }
    
    // Find nearest enemy
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance && distance <= shootRange) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    // Shoot at nearest enemy if found
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      final direction = (nearestEnemy.position - position).normalized();
      _fireProjectile(direction);
      lastShotTime = currentTime;
    }
  }
  
  void _fireProjectile(Vector2 direction) {
    final projectileCount = totalProjectileCount;
    final projectileBounces = totalProjectileBounces;
    final projectileScale = totalProjectileSize;
    final critChance = totalCritChance;
    
    // Calculate spread angle if multiple projectiles
    final spreadAngle = projectileCount > 1 ? pi / 6 : 0.0; // 30 degrees total spread
    final angleStep = projectileCount > 1 ? spreadAngle / (projectileCount - 1) : 0.0;
    final startAngle = projectileCount > 1 ? -spreadAngle / 2 : 0.0;
    
    for (int i = 0; i < projectileCount; i++) {
      // Calculate direction for each projectile
      Vector2 projectileDirection;
      if (projectileCount == 1) {
        projectileDirection = direction;
      } else {
        final angle = startAngle + (i * angleStep);
        final baseAngle = atan2(direction.y, direction.x);
        final newAngle = baseAngle + angle;
        projectileDirection = Vector2(cos(newAngle), sin(newAngle));
      }
      
      // Check for critical hit (now instant kill, so damage doesn't matter)
      final isCritical = Random().nextDouble() < critChance;
      final finalDamage = 25.0; // Base damage (critical = instant kill)
      
      final projectile = ShapeProjectile(
        startPosition: position.clone(),
        direction: projectileDirection,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: finalDamage,
        isEnemyProjectile: false,
        shapeType: heroData.shape,
        heroColor: heroData.color,
        bounces: projectileBounces,
        sizeScale: projectileScale,
        isCritical: isCritical,
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _updateMovement(double dt) {
    Vector2 inputDirection = Vector2.zero();
    
    // Handle WASD movement
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      inputDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      inputDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      inputDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      inputDirection.x += 1;
    }
    
    // Normalize and apply movement
    if (inputDirection.length > 0) {
      inputDirection.normalize();
      position += inputDirection * moveSpeed * effectiveSpeedMultiplier * dt;
    }
  }
  
  void _updateAbility(double dt) {
    // Handle different ability types based on hero configuration
    switch (heroData.ability.type) {
      case 'dash_damage':
        _updateDashDamage(dt);
        break;
      case 'piercing_shot':
        // Piercing shot is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_stun':
        // Area stun is instant, no update needed
        isUsingAbility = false;
        break;
      case 'radial_burst':
        // Radial burst is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_field':
        // Area field is instant placement, no update needed
        isUsingAbility = false;
        break;
      default:
        isUsingAbility = false;
    }
  }
  
  void _updateDashDamage(double dt) {
    if (abilityTarget == null) {
      isUsingAbility = false;
      return;
    }
    
    final direction = (abilityTarget! - position).normalized();
    final movement = direction * dashSpeed * dt;
    
    // Check for enemy collisions during dash
    // Create a copy to avoid ConcurrentModificationError
    final enemiesCopy = List<Component>.from(gameRef.currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy is PositionComponent) {
        final distanceToEnemy = position.distanceTo(enemy.position);
        // Use different radius checks for different enemy types
        double enemyRadius = 15.0 * DisplayConfig.instance.scaleFactor; // Default radius
        
        if (enemy is EnemyChaser) {
          enemyRadius = enemy.radius;
        } else if (enemy is EnemyShooter) {
          enemyRadius = enemy.radius;
        } else if (enemy is ShieldedChaser) {
          enemyRadius = enemy.radius;
        }
        
        if (distanceToEnemy < heroRadius + enemyRadius) {
          // Damage enemy during rolling surge
          if (enemy is EnemyChaser) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is EnemyShooter) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is ShieldedChaser) {
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          } else {
            // Fallback for other enemy types - remove them directly
            if (enemy.parent != null) {
              gameRef.onEnemyDestroyed(enemy);
            }
          }
        }
      }
    }
    
    if (position.distanceTo(abilityTarget!) <= movement.length) {
      position = abilityTarget!;
      isUsingAbility = false;
      abilityTarget = null;
    } else {
      position += movement;
    }
  }
  
  void _tryAbility() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    
    if (currentTime - lastAbilityTime < effectiveCooldown || energy < 25) {
      return; // Ability on cooldown or not enough energy
    }
    
    switch (heroData.ability.type) {
      case 'dash_damage':
        _executeDashDamage();
        break;
      case 'piercing_shot':
        _executePiercingShot();
        break;
      case 'area_stun':
        _executeAreaStun();
        break;
      case 'radial_burst':
        _executeRadialBurst();
        break;
      case 'area_field':
        _executeAreaField();
        break;
      case 'resonance_knockback':
        _executeResonanceKnockback();
        break;
    }
    
    lastAbilityTime = currentTime;
    energy -= 25; // Ability costs energy
  }
  
  void _executeDashDamage() {
    // Play sound effect for circle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Get current input direction for rolling surge
    Vector2 dashDirection = Vector2.zero();
    
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dashDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dashDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dashDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dashDirection.x += 1;
    }
    
    // If no input, dash forward (up)
    if (dashDirection.length == 0) {
      dashDirection = Vector2(0, -1);
    }
    
    dashDirection.normalize();
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    abilityTarget = position + dashDirection * scaledRange;
    
    // Constrain ability target to arena
    abilityTarget!.x = abilityTarget!.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    abilityTarget!.y = abilityTarget!.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
    
    isUsingAbility = true;
  }
  
  void _executePiercingShot() {
    // Play sound effect for triangle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Find direction to nearest enemy or shoot forward
    Vector2 direction = Vector2(0, -1); // Default forward
    
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      direction = (nearestEnemy.position - position).normalized();
    }
    
    // Create massive triangle projectile with hero color and range scaling
    final projectile = TriangleProjectile(
      startPosition: position.clone(),
      direction: direction,
      speed: 500.0 * DisplayConfig.instance.scaleFactor,
      damage: heroData.ability.damage,
      isEnemyProjectile: false,
      heroColor: heroData.color, // Pass hero color
      rangeMultiplier: rangeMultiplier, // Scale with range upgrades
    );
    
    gameRef.add(projectile);
  }
  
  void _executeAreaStun() {
    // Play sound effect for square hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Calculate effective range (now has range limitation)
    final effectiveRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final stunDuration = heroData.ability.stunDuration ?? 3.0;
    
    // Create visual effect for the ability
    _createSquareAbilityEffect(effectiveRange);
    
    // Stun enemies within range
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= effectiveRange) {
          // Apply stun effect to different enemy types
          if (enemy is EnemyChaser) {
            enemy.stun(stunDuration);
          } else if (enemy is EnemyShooter) {
            enemy.stun(stunDuration);
          } else if (enemy is ShieldedChaser) {
            enemy.stun(stunDuration);
            // Also instantly break shield with ability damage
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          }
        }
      }
    }
    
    // Stun enemy projectiles within range
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= effectiveRange) {
          // Check if it's an enemy projectile and apply slow effect (stun)
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectile.applySlowEffect(0.0); // 0 speed = stunned
          }
        }
      }
    }
    
    print('Shield Bash! Stunned enemies within ${effectiveRange.toInt()} range for ${stunDuration}s');
  }
  
  void _executeRadialBurst() {
    // Play sound effect for pentagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Fire projectiles in all directions
    final projectileCount = heroData.ability.projectileCount ?? 5;
    final angleStep = (2 * pi) / projectileCount;
    
    for (int i = 0; i < projectileCount; i++) {
      final angle = i * angleStep;
      final direction = Vector2(cos(angle), sin(angle));
      
      // Create scaled projectile based on range multiplier
      final scaledRadius = 6.0 * DisplayConfig.instance.scaleFactor * rangeMultiplier;
      
      final projectile = Projectile(
        startPosition: position.clone(),
        direction: direction,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: heroData.ability.damage,
        isEnemyProjectile: false,
        heroColor: heroData.color,
        scaledRadius: scaledRadius, // Pass scaled radius for bullet size
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _executeAreaField() {
    // Play sound effect for hexagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Create visual hex field effect
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final duration = heroData.ability.duration ?? 4.0;
    
    final hexField = HexField(
      position: position.clone(),
      radius: scaledRange,
      duration: duration,
      damage: heroData.ability.damage,
      slowPercent: heroData.ability.slowPercent ?? 0.3,
    );
    
    gameRef.add(hexField);
  }
  
  void _executeResonanceKnockback() {
    // Play sound effect for heptagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final knockbackDistance = (heroData.ability.knockbackDistance ?? 30.0) * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    
    // Create visual effect for the ability
    _createHeptagonAbilityEffect(scaledRange);
    
    // Find enemies within range and apply damage + knockback
    final enemiesToKnockback = <Component>[];
    final projectilesToPush = <Component>[];
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= scaledRange) {
          enemiesToKnockback.add(enemy);
        }
      }
    }
    
    // Find enemy projectiles within range to push away and stun them
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= scaledRange) {
          // Check if it's an enemy projectile
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectilesToPush.add(projectile);
          }
        }
      }
    }
    
    // Apply damage and knockback to all enemies in range
    for (final enemy in enemiesToKnockback) {
      if (enemy is PositionComponent) {
        // Apply damage
        if (enemy is EnemyChaser) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is EnemyShooter) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is ShieldedChaser) {
          enemy.takeDamage(heroData.ability.damage, isAbility: true);
        }
        
        // Apply knockback
        final directionToEnemy = (enemy.position - position).normalized();
        final knockbackTarget = enemy.position + directionToEnemy * knockbackDistance;
        
        // Constrain knockback target to arena bounds
        final constrainedTarget = Vector2(
          knockbackTarget.x.clamp(50.0, DisplayConfig.instance.arenaWidth - 50.0),
          knockbackTarget.y.clamp(50.0, DisplayConfig.instance.arenaHeight - 50.0),
        );
        
        enemy.position = constrainedTarget;
      }
    }
    
    // Push away enemy projectiles
    for (final projectile in projectilesToPush) {
      if (projectile is PositionComponent) {
        final directionToProjectile = (projectile.position - position).normalized();
        final pushTarget = projectile.position + directionToProjectile * knockbackDistance;
        
        // Constrain push target to arena bounds
        final constrainedTarget = Vector2(
          pushTarget.x.clamp(0.0, DisplayConfig.instance.arenaWidth),
          pushTarget.y.clamp(0.0, DisplayConfig.instance.arenaHeight),
        );
        
        projectile.position = constrainedTarget;
      }
    }
    
    // Visual feedback
    print('Resonance Knockback! Hit ${enemiesToKnockback.length} enemies and pushed ${projectilesToPush.length} projectiles');
  }
  
  void _updateAbilityCooldownDisplay() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final timeSinceLastAbility = currentTime - lastAbilityTime;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    final cooldownPercent = (timeSinceLastAbility / effectiveCooldown).clamp(0.0, 1.0);
    final remainingSeconds = (effectiveCooldown - timeSinceLastAbility).clamp(0.0, effectiveCooldown);
    
    if (gameRef.hud.isMounted) {
      gameRef.hud.updateAbilityCooldown(cooldownPercent, remainingSeconds);
    }
  }
  
  void _constrainToArena() {
    position.x = position.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    position.y = position.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    
    // Handle universal escape key navigation
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      // Check if stats overlay is visible and hide it first
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
        return true;
      }
      
      // Check if shop is open and close it
      if (gameRef.gameState == GameState.shopping) {
        gameRef.onShopClosed();
        return true;
      }
      
      // Handle pause/resume for playing state
      if (gameRef.gameState == GameState.playing) {
        gameRef.pauseGame();
        return true;
      } else if (gameRef.gameState == GameState.paused) {
        gameRef.resumeGame();
        return true;
      }
    }
    
    // Handle ability (K key only)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyK) {
      _tryAbility();
      return true;
    }
    
    // Handle clone activation with 'C' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (canActivateClone()) {
        activateClone();
      }
      return true;
    }
    
    // Handle stats overlay toggle with 'I' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyI) {
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
      } else {
        gameRef.statsOverlay.show();
      }
      return true;
    }
    
    return false;
  }
  
  void takeDamage(double damage) {
    if (isInvincible || isDamageInvincible || isUsingAbility) {
      return; // No damage while invincible, damage invincible, or using ability
    }
    
    double remainingDamage = damage;
    
    // Shield absorbs damage first
    if (shield > 0) {
      if (shield >= remainingDamage) {
        // Shield absorbs all damage
        shield -= remainingDamage;
        remainingDamage = 0;
      } else {
        // Shield absorbs partial damage and breaks
        remainingDamage -= shield;
        shield = 0;
        
        // Remove shield effect when shield is broken
        if (hasTemporaryEffect('shield')) {
          print('Shield broken! Removing shield effect.');
          _removeEffectImmediate('shield');
          _temporaryEffects.remove('shield');
        }
      }
    }
    
    // Apply remaining damage to health
    if (remainingDamage > 0) {
      health = (health - remainingDamage).clamp(0, maxHealth);
    }
    
    // Activate damage invincibility
    isDamageInvincible = true;
    damageInvincibilityTimer = 0.0;
    
    if (health <= 0) {
      gameRef.onHeroDeath();
    }
  }
  
  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
  
  void addCoins(int amount) {
    final multiplier = totalCoinMultiplier;
    final finalAmount = (amount * multiplier).round();
    coins += finalAmount;
    if (multiplier > 1.0) {
      print('Coin Magnet: ${amount} -> ${finalAmount} coins (${multiplier}x)');
    }
  }
  
  void spendCoins(int amount) {
    coins = max(0, coins - amount);
  }
  
  void activateInvincibility() {
    isInvincible = true;
    invincibilityTimer = invincibilityDuration;
  }
  
  void _createSquareAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'square',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  void _createHeptagonAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'heptagon',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  // Temporary effects system - only one effect at a time
  void applyTemporaryEffect(String effectType, double value, double duration) {
    // Remove any existing effect first (only one at a time)
    if (_temporaryEffects.isNotEmpty) {
      final oldEffect = _temporaryEffects.entries.first;
      _removeEffectImmediate(oldEffect.key);
      _temporaryEffects.clear();
      print('Replaced effect: ${oldEffect.key} -> $effectType');
    }
    
    // Apply new effect
    _temporaryEffects[effectType] = TemporaryEffect(
      type: effectType,
      value: value,
      duration: duration,
    );
    
    // Apply immediate effects
    _applyEffectImmediate(effectType, value);
    
    print('Applied temporary effect: $effectType (${value}, ${duration}s)');
  }
  
  void _updateTemporaryEffects(double dt) {
    final expiredEffects = <String>[];
    
    for (final entry in _temporaryEffects.entries) {
      final effect = entry.value;
      effect.update(dt);
      
      if (effect.isExpired) {
        expiredEffects.add(entry.key);
        _removeEffectImmediate(entry.key);
      } else {
        // Apply ongoing effects
        _applyEffectOngoing(effect.type, effect.value, dt);
      }
    }
    
    // Remove expired effects
    for (final effectType in expiredEffects) {
      _temporaryEffects.remove(effectType);
    }
  }
  
  void _applyEffectImmediate(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
        speedMultiplier *= (1.0 + value);
        break;
      case 'damage_boost':
        // This will be applied in damage calculations
        break;
      case 'shield':
        shield += value;
        maxShield = maxShield > shield ? maxShield : shield;
        break;
      case 'invincibility':
        isInvincible = true;
        invincibilityTimer = 0.0;
        break;
      case 'weapon_overclock':
        attackSpeedMultiplier *= (1.0 + value);
        break;
    }
  }
  
  void _applyEffectOngoing(String effectType, double value, double dt) {
    switch (effectType) {
      case 'health_regen':
        heal(value * dt);
        break;
    }
  }
  
  void _removeEffectImmediate(String effectType) {
    switch (effectType) {
      case 'speed_boost':
        // Note: This is a simplified approach. In a full implementation,
        // you'd want to track the original multiplier and restore it
        speedMultiplier = 1.0; // Reset to base
        break;
      case 'damage_boost':
        // Reset damage multiplier
        break;
      case 'shield':
        // Shield naturally decays over time
        break;
      case 'invincibility':
        // Invincibility expires naturally
        break;
      case 'weapon_overclock':
        // Reset attack speed multiplier
        attackSpeedMultiplier = 1.0; // Reset to base
        break;
    }
  }
  
  // Get effective damage multiplier including temporary effects
  double get effectiveDamageMultiplier {
    double multiplier = 1.0;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'damage_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Get effective speed multiplier including temporary effects
  double get effectiveSpeedMultiplier {
    double multiplier = speedMultiplier;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'speed_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Check if hero has a specific temporary effect
  bool hasTemporaryEffect(String effectType) {
    return _temporaryEffects.containsKey(effectType);
  }
  
  // Get remaining time for a temporary effect
  double getTemporaryEffectTime(String effectType) {
    final effect = _temporaryEffects[effectType];
    return effect?.remainingTime ?? 0.0;
  }
  
  // Get current active effect for UI display
  TemporaryEffect? get currentActiveEffect {
    return _temporaryEffects.isNotEmpty ? _temporaryEffects.values.first : null;
  }
  
  // Get current active effect info as a formatted string
  String get activeEffectDisplay {
    final effect = currentActiveEffect;
    if (effect == null) return 'None';
    
    final effectName = _getEffectDisplayName(effect.type);
    final effectValue = _getEffectDisplayValue(effect.type, effect.value);
    
    // Handle infinite duration effects (like persistent shields)
    if (effect.remainingTime.isInfinite || effect.remainingTime.isNaN) {
      return '$effectName $effectValue (∞)';
    }
    
    final timeLeft = effect.remainingTime.ceil();
    return '$effectName $effectValue (${timeLeft}s)';
  }
  
  String _getEffectDisplayName(String effectType) {
    switch (effectType) {
      case 'speed_boost': return 'Speed';
      case 'damage_boost': return 'Damage';
      case 'health_regen': return 'Regen';
      case 'shield': return 'Shield';
      case 'invincibility': return 'Invul';
      case 'weapon_overclock': return 'Overclock';
      default: return effectType;
    }
  }
  
  String _getEffectDisplayValue(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
      case 'damage_boost':
      case 'weapon_overclock':
        return '+${(value * 100).round()}%';
      case 'health_regen':
        return '+${value.round()}/s';
      case 'shield':
        return '+${value.round()}';
      case 'invincibility':
        return 'ON';
      default:
        return value.toString();
    }
  }

  // Stackable passive effects system
  void addPassiveEffect(String effectType, int maxStacks) {
    final currentStacks = _passiveEffectStacks[effectType] ?? 0;
    if (currentStacks < maxStacks) {
      _passiveEffectStacks[effectType] = currentStacks + 1;
      print('Added passive effect: $effectType (${currentStacks + 1}/$maxStacks stacks)');
    } else {
      print('Cannot add $effectType: already at max stacks ($maxStacks)');
    }
  }
  
  int getPassiveEffectStacks(String effectType) {
    return _passiveEffectStacks[effectType] ?? 0;
  }
  
  bool hasPassiveEffect(String effectType) {
    return _passiveEffectStacks.containsKey(effectType) && _passiveEffectStacks[effectType]! > 0;
  }
  
  // Get calculated values based on passive effects
  int get totalProjectileCount {
    return 1 + getPassiveEffectStacks('projectile_count');
  }
  
  int get totalProjectileBounces {
    return getPassiveEffectStacks('projectile_bounces');
  }
  
  double get totalProjectileSize {
    final regularSize = 1.0 + (getPassiveEffectStacks('projectile_size') * 0.5); // 50% increase per stack
    final enlargedSize = 1.0 + (getPassiveEffectStacks('enlarged_caliber') * 0.1); // 10% increase per stack
    return regularSize * enlargedSize;
  }
  
  double get characterSizeMultiplier {
    return 1.0 + (getPassiveEffectStacks('enlarged_caliber') * 0.1);
  }
  
  double get enlargedCaliberSpeedPenalty {
    return getPassiveEffectStacks('enlarged_caliber') * 0.25;
  }
  
  int get totalDroneCount {
    return getPassiveEffectStacks('drone_count');
  }
  
  double get totalLifeSteal {
    return getPassiveEffectStacks('life_steal') * 0.05;
  }
  
  double get totalShieldHP {
    return getPassiveEffectStacks('shield_hp') * 5.0;
  }
  
  double get totalCoinMultiplier {
    return 1.0 + (getPassiveEffectStacks('coin_multiplier') * 0.2);
  }
  
  double get totalHealPerKill {
    return getPassiveEffectStacks('heal_per_kill') * 2.0;
  }
  
  double get totalCritChance {
    return getPassiveEffectStacks('crit_chance') * 0.02;
  }
  
  double get totalMaxHealthBoost {
    return getPassiveEffectStacks('max_health_boost') * 10.0;
  }
  
  bool get hasCloneProjection {
    return hasPassiveEffect('clone_spawn');
  }
  
  void resetPassiveEffects() {
    _passiveEffectStacks.clear();
    killCount = 0;
    destroyAllDrones();
    destroyClone();
  }
  
  // Apply heal per kill effect when an enemy is defeated
  void onEnemyKilled() {
    killCount++;
    
    final healAmount = totalHealPerKill;
    if (healAmount > 0) {
      heal(healAmount);
      print('Healed ${healAmount} HP from kill');
    }
    
    // Handle kill-based max health boost (Auto Injector)
    final autoInjectorStacks = getPassiveEffectStacks('kill_based_max_health');
    if (autoInjectorStacks > 0 && killCount % 10 == 0) {
      final maxHealthIncrease = autoInjectorStacks * 2.0; // 2 HP per stack
      final currentBonus = (killCount ~/ 10) * maxHealthIncrease;
      final maxBonus = autoInjectorStacks * 50.0; // 50 HP max per stack
      
      if (currentBonus <= maxBonus) {
        maxHealth += maxHealthIncrease;
        health += maxHealthIncrease; // Also heal current HP
        print('Auto Injector: +${maxHealthIncrease} max HP from ${killCount} kills');
      }
    }
  }
  
  // Regenerate shields between waves (Armor Plating effect)
  void regenerateShields() {
    final armorShields = totalShieldHP;
    if (armorShields > 0) {
      // Apply armor plating as a persistent shield effect
      applyTemporaryEffect('shield', armorShields, double.infinity);
      print('Armor plating shields regenerated to ${armorShields.toStringAsFixed(1)} HP');
    }
  }
  
  // Drone management system
  void updateDroneCount() {
    final targetDroneCount = totalDroneCount;
    final currentDroneCount = _activeDrones.length;
    
    if (targetDroneCount > currentDroneCount) {
      // Spawn new drones
      for (int i = currentDroneCount; i < targetDroneCount; i++) {
        final drone = DroneWingman(owner: this, droneIndex: i);
        _activeDrones.add(drone);
        gameRef.add(drone);
        print('Spawned drone ${i + 1}/${targetDroneCount}');
      }
    } else if (targetDroneCount < currentDroneCount) {
      // Remove excess drones
      while (_activeDrones.length > targetDroneCount) {
        final drone = _activeDrones.removeLast();
        drone.destroy();
        print('Removed drone. Remaining: ${_activeDrones.length}');
      }
    }
  }
  
  void destroyAllDrones() {
    for (final drone in _activeDrones) {
      drone.destroy();
    }
    _activeDrones.clear();
    print('All drones destroyed');
  }
  
  // Clone management system
  bool canActivateClone() {
    return hasCloneProjection && _activeClone == null && health > maxHealth * 0.5;
  }
  
  void activateClone() {
    print('🤖 Attempting to activate clone...');
    print('   - Has clone projection: ${hasCloneProjection}');
    print('   - No active clone: ${_activeClone == null}');
    print('   - Current health: ${health.toStringAsFixed(1)}/${maxHealth.toStringAsFixed(1)}');
    print('   - Required health: ${(maxHealth * 0.5).toStringAsFixed(1)}');
    
    if (!canActivateClone()) {
      print('❌ Cannot activate clone: requirements not met');
      return;
    }
    
    // Pay health cost (50% of current health)
    final healthCost = health * 0.5;
    health -= healthCost;
    
    // Spawn clone directly to the right with clear gap
    final cloneOffset = Vector2(80, 0); // Simple fixed offset to the right
    final clonePosition = position + cloneOffset;
    
    print('🤖 Creating HeroClone at position: (${clonePosition.x}, ${clonePosition.y})');
    _activeClone = HeroClone(owner: this, spawnPosition: clonePosition);
    
    print('🤖 Adding clone to game...');
    gameRef.add(_activeClone!);
    
    print('✅ CLONE ACTIVATED! Health cost: ${healthCost.toStringAsFixed(1)}, Clone mounted: ${_activeClone!.isMounted}');
  }
  
  void destroyClone() {
    if (_activeClone != null) {
      _activeClone!.destroy();
      _activeClone = null;
      print('Clone destroyed');
    }
  }
  
  bool get hasActiveClone => _activeClone != null;
  
  // Getter for passive effect stacks (for stats display)
  Map<String, int> get passiveEffectStacks => Map.from(_passiveEffectStacks);
  
  void onCloneDestroyed(HeroClone clone) {
    if (_activeClone == clone) {
      _activeClone = null;
      print('Active clone reference cleared');
    }
  }
}

// Visual effect component for abilities
class AbilityVisualEffect extends PositionComponent with HasGameRef<CircleRougeGame> {
  final double effectRange;
  final String shape;
  final Color color;
  
  double lifetime = 0.0;
  static const double totalLifetime = 0.5; // Blink once and disappear
  static const double blinkDuration = 0.25; // Half the lifetime for one blink
  
  AbilityVisualEffect({
    required Vector2 position,
    required this.effectRange,
    required this.shape,
    required this.color,
  }) : super(
    position: position,
    size: Vector2.all(effectRange * 2),
    anchor: Anchor.center,
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    lifetime += dt;
    
    // Remove after total lifetime
    if (lifetime >= totalLifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Calculate opacity with blinking effect
    final blinkProgress = (lifetime / blinkDuration) % 1.0;
    final opacity = (sin(blinkProgress * pi * 2) * 0.15 + 0.1).clamp(0.0, 0.25); // 25% max opacity
    
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = color.withOpacity(opacity * 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Draw the shape based on type
    switch (shape) {
      case 'square':
        final rect = Rect.fromCenter(
          center: center,
          width: effectRange * 2,
          height: effectRange * 2,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;
      case 'heptagon':
        final path = _createHeptagonPath(center, effectRange);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }
  
  Path _createHeptagonPath(Offset center, double radius) {
    final path = Path();
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * pi / 180);
      final y = center.dy + radius * sin(angle * pi / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    return path;
  }
} 
```

Now I need to update the moveSpeed getter to apply the speed penalty:

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/circle_rouge_game.dart';
import '../config/hero_config.dart';
import '../config/display_config.dart';
import 'abilities/hex_field.dart';
import 'enemies/enemy_chaser.dart';
import 'enemies/enemy_shooter.dart';
import 'enemies/shielded_chaser.dart';
import 'enemies/projectile.dart';
import 'enemies/shape_projectile.dart';
import 'enemies/triangle_projectile.dart';
import 'sound_manager.dart';
import 'companions/drone_wingman.dart';
import 'companions/hero_clone.dart';

class TemporaryEffect {
  final String type;
  final double value;
  final double duration;
  double remainingTime;
  
  TemporaryEffect({
    required this.type,
    required this.value,
    required this.duration,
  }) : remainingTime = duration;
  
  void update(double dt) {
    remainingTime -= dt;
  }
  
  bool get isExpired => remainingTime <= 0;
}

class Hero extends PositionComponent with HasGameRef<CircleRougeGame>, KeyboardHandler {
  // Hero configuration
  late HeroData heroData;
  final String heroId;
  
  // Hero visual properties
  late double heroRadius;
  late Paint heroPaint;
  
  // Base movement properties - will be scaled based on arena size
  static const double baseMoveSpeed = 200.0;
  
  // Base dash properties (for heroes that don't have special abilities)
  static const double baseDashDistance = 120.0;
  static const double baseDashSpeed = 500.0;
  
  // Base shooting properties
  static const double baseShootRange = 250.0;
  static const double fireRate = 2.0; // Shots per second
  double lastShotTime = 0.0;
  
  // Get scaled values based on arena size
  double get moveSpeed {
    final baseSpeed = (heroData.moveSpeed / 320.0 * baseMoveSpeed) * DisplayConfig.instance.scaleFactor;
    final speedPenalty = enlargedCaliberSpeedPenalty;
    return baseSpeed * (1.0 - speedPenalty);
  }
  double get dashDistance => baseDashDistance * DisplayConfig.instance.scaleFactor;
  double get dashSpeed => baseDashSpeed * DisplayConfig.instance.scaleFactor;
  double get shootRange => baseShootRange * DisplayConfig.instance.scaleFactor * rangeMultiplier;
  
  // Attack speed modifier (can be upgraded)
  double attackSpeedMultiplier = 1.0;
  
  // Movement speed modifier (can be upgraded)
  double speedMultiplier = 1.0;
  
  // Ability cooldown modifier (can be upgraded)
  double abilityCooldownMultiplier = 1.0;
  
  // Range modifier (can be upgraded)
  double rangeMultiplier = 1.0;
  
  // Weapon overclock visual effect
  // Weapon overclock now handled by temporary effect system
  
  // Ability system
  double lastAbilityTime = -double.infinity;
  bool isUsingAbility = false;
  Vector2? abilityTarget;
  
  // Hero stats
  double health = 100.0;
  double maxHealth = 100.0;
  double energy = 100.0;
  double maxEnergy = 100.0;
  int coins = 0;
  int killCount = 0;
  
  // Invincibility after wave completion
  bool isInvincible = false;
  double invincibilityTimer = 0.0;
  static const double invincibilityDuration = 3.0; // 3 seconds of invincibility
  
  // Damage invincibility (separate from wave completion invincibility)
  bool isDamageInvincible = false;
  double damageInvincibilityTimer = 0.0;
  static const double damageInvincibilityDuration = 0.5; // 0.5 seconds after taking damage
  
  // Temporary effects system
  final Map<String, TemporaryEffect> _temporaryEffects = {};
  
  // Stackable passive effects system
  final Map<String, int> _passiveEffectStacks = {};
  
  // Drone companion system
  final List<DroneWingman> _activeDrones = [];
  
  // Clone system
  HeroClone? _activeClone;
  
  // Shield system
  double shield = 0.0;
  double maxShield = 0.0;
  
  // Input tracking
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  
  Hero({required Vector2 position, required this.heroId}) : super(
    position: position,
    size: Vector2.all(30.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    heroRadius = 15.0 * DisplayConfig.instance.scaleFactor;
    heroPaint = Paint()..color = const Color(0xFF4CAF50);
    _initializeHero(heroId);
  }
  
  void _initializeHero(String heroId) {
    final heroConfig = HeroConfig.instance.getHeroById(heroId);
    if (heroConfig != null) {
      heroData = heroConfig;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    } else {
      // Fallback to default circle hero
      heroData = HeroConfig.instance.defaultHero;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    }
  }
  
  double get effectiveMaxHealth {
    return maxHealth + totalMaxHealthBoost;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Blinking effect during damage invincibility
    if (isDamageInvincible) {
      final blinkTime = (damageInvincibilityTimer * 8) % 1.0; // 8 blinks per second
      if (blinkTime > 0.5) {
        return; // Don't render during blink "off" phase
      }
    }
    
    final center = Offset(size.x / 2, size.y / 2);
    final shapeSize = size.x;
    
    // Old weapon overclock glow removed - now handled by active effect glow
    
    // Active effect glow
    final activeEffect = currentActiveEffect;
    if (activeEffect != null) {
      final effectTime = (DateTime.now().millisecondsSinceEpoch / 1000.0) % 1.5; // 1.5-second cycle
      final glowIntensity = (sin(effectTime * pi * 2) * 0.3 + 0.7); // 0.4 to 1.0
      final glowRadius = 15.0 * glowIntensity;
      
      // Get effect color
      Color effectColor;
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
        default:
          effectColor = const Color(0xFFFFFFFF); // White fallback
      }
      
      final effectGlowPaint = Paint()
        ..color = effectColor.withOpacity(0.8 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      // Draw effect glow based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + glowRadius, effectGlowPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'square':
          _drawSquare(canvas, center, effectGlowPaint, glowRadius);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
      }
    }
    
    // Draw main hero shape
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(center, heroRadius, heroPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, shapeSize, heroPaint, 0);
        break;
      case 'square':
        _drawSquare(canvas, center, heroPaint, 0);
        break;
      case 'pentagon':
        _drawPentagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'hexagon':
        _drawHexagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, shapeSize, heroPaint, 0);
        break;
    }
    
    // Draw shield outline if shield effect is active
    if (hasTemporaryEffect('shield') && shield > 0) {
      final shieldOpacity = (shield / maxShield).clamp(0.3, 1.0); // Fade as shield depletes
      final shieldPaint = Paint()
        ..color = const Color(0xFFFF9800).withOpacity(0.6 * shieldOpacity) // Orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Draw shield outline based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + 4, shieldPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'square':
          _drawSquare(canvas, center, shieldPaint, 4);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, shieldPaint, 4);
          break;
      }
    }
    
  }
  
  void _drawTriangle(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius / 2);
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius / 2);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSquare(Canvas canvas, Offset center, Paint paint, double glowRadius) {
    final size = (this.size.x * 0.8) + (glowRadius * 2);
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      ),
      paint,
    );
  }
  
  void _drawPentagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 5; i++) {
      final angle = -90 + (i * 72); // Pentagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHexagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 6; i++) {
      final angle = -90 + (i * 60); // Hexagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHeptagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  // Collision detection method for other components to use
  @override
  bool containsPoint(Vector2 point) {
    final distance = position.distanceTo(point);
    return distance <= heroRadius;
  }
  
  // Get collision radius for enemy collision detection
  double get collisionRadius => heroRadius;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Weapon overclock now handled by temporary effect system
    
    // Update invincibility timer
    if (isInvincible) {
      invincibilityTimer += dt;
      if (invincibilityTimer >= invincibilityDuration) {
        isInvincible = false;
        invincibilityTimer = 0.0;
      }
    }
    
    // Update damage invincibility timer
    if (isDamageInvincible) {
      damageInvincibilityTimer += dt;
      if (damageInvincibilityTimer >= damageInvincibilityDuration) {
        isDamageInvincible = false;
        damageInvincibilityTimer = 0.0;
      }
    }
    
    // Update temporary effects
    _updateTemporaryEffects(dt);
    
    if (isUsingAbility) {
      _updateAbility(dt);
    } else {
      _updateMovement(dt);
    }
    
    // Auto-shoot at enemies
    _tryAutoShoot();
    
    // Regenerate energy
    if (energy < maxEnergy) {
      energy = (energy + 50 * dt).clamp(0, maxEnergy);
    }
    
    // Keep hero within arena bounds
    _constrainToArena();
    
    // Update ability cooldown in HUD
    _updateAbilityCooldownDisplay();
  }
  
  void _tryAutoShoot() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    if (currentTime - lastShotTime < (1.0 / (fireRate * attackSpeedMultiplier))) {
      return; // Still on cooldown
    }
    
    // Find nearest enemy
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance && distance <= shootRange) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    // Shoot at nearest enemy if found
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      final direction = (nearestEnemy.position - position).normalized();
      _fireProjectile(direction);
      lastShotTime = currentTime;
    }
  }
  
  void _fireProjectile(Vector2 direction) {
    final projectileCount = totalProjectileCount;
    final projectileBounces = totalProjectileBounces;
    final projectileScale = totalProjectileSize;
    final critChance = totalCritChance;
    
    // Calculate spread angle if multiple projectiles
    final spreadAngle = projectileCount > 1 ? pi / 6 : 0.0; // 30 degrees total spread
    final angleStep = projectileCount > 1 ? spreadAngle / (projectileCount - 1) : 0.0;
    final startAngle = projectileCount > 1 ? -spreadAngle / 2 : 0.0;
    
    for (int i = 0; i < projectileCount; i++) {
      // Calculate direction for each projectile
      Vector2 projectileDirection;
      if (projectileCount == 1) {
        projectileDirection = direction;
      } else {
        final angle = startAngle + (i * angleStep);
        final baseAngle = atan2(direction.y, direction.x);
        final newAngle = baseAngle + angle;
        projectileDirection = Vector2(cos(newAngle), sin(newAngle));
      }
      
      // Check for critical hit (now instant kill, so damage doesn't matter)
      final isCritical = Random().nextDouble() < critChance;
      final finalDamage = 25.0; // Base damage (critical = instant kill)
      
      final projectile = ShapeProjectile(
        startPosition: position.clone(),
        direction: projectileDirection,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: finalDamage,
        isEnemyProjectile: false,
        shapeType: heroData.shape,
        heroColor: heroData.color,
        bounces: projectileBounces,
        sizeScale: projectileScale,
        isCritical: isCritical,
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _updateMovement(double dt) {
    Vector2 inputDirection = Vector2.zero();
    
    // Handle WASD movement
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      inputDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      inputDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      inputDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      inputDirection.x += 1;
    }
    
    // Normalize and apply movement
    if (inputDirection.length > 0) {
      inputDirection.normalize();
      position += inputDirection * moveSpeed * effectiveSpeedMultiplier * dt;
    }
  }
  
  void _updateAbility(double dt) {
    // Handle different ability types based on hero configuration
    switch (heroData.ability.type) {
      case 'dash_damage':
        _updateDashDamage(dt);
        break;
      case 'piercing_shot':
        // Piercing shot is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_stun':
        // Area stun is instant, no update needed
        isUsingAbility = false;
        break;
      case 'radial_burst':
        // Radial burst is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_field':
        // Area field is instant placement, no update needed
        isUsingAbility = false;
        break;
      default:
        isUsingAbility = false;
    }
  }
  
  void _updateDashDamage(double dt) {
    if (abilityTarget == null) {
      isUsingAbility = false;
      return;
    }
    
    final direction = (abilityTarget! - position).normalized();
    final movement = direction * dashSpeed * dt;
    
    // Check for enemy collisions during dash
    // Create a copy to avoid ConcurrentModificationError
    final enemiesCopy = List<Component>.from(gameRef.currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy is PositionComponent) {
        final distanceToEnemy = position.distanceTo(enemy.position);
        // Use different radius checks for different enemy types
        double enemyRadius = 15.0 * DisplayConfig.instance.scaleFactor; // Default radius
        
        if (enemy is EnemyChaser) {
          enemyRadius = enemy.radius;
        } else if (enemy is EnemyShooter) {
          enemyRadius = enemy.radius;
        } else if (enemy is ShieldedChaser) {
          enemyRadius = enemy.radius;
        }
        
        if (distanceToEnemy < heroRadius + enemyRadius) {
          // Damage enemy during rolling surge
          if (enemy is EnemyChaser) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is EnemyShooter) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is ShieldedChaser) {
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          } else {
            // Fallback for other enemy types - remove them directly
            if (enemy.parent != null) {
              gameRef.onEnemyDestroyed(enemy);
            }
          }
        }
      }
    }
    
    if (position.distanceTo(abilityTarget!) <= movement.length) {
      position = abilityTarget!;
      isUsingAbility = false;
      abilityTarget = null;
    } else {
      position += movement;
    }
  }
  
  void _tryAbility() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    
    if (currentTime - lastAbilityTime < effectiveCooldown || energy < 25) {
      return; // Ability on cooldown or not enough energy
    }
    
    switch (heroData.ability.type) {
      case 'dash_damage':
        _executeDashDamage();
        break;
      case 'piercing_shot':
        _executePiercingShot();
        break;
      case 'area_stun':
        _executeAreaStun();
        break;
      case 'radial_burst':
        _executeRadialBurst();
        break;
      case 'area_field':
        _executeAreaField();
        break;
      case 'resonance_knockback':
        _executeResonanceKnockback();
        break;
    }
    
    lastAbilityTime = currentTime;
    energy -= 25; // Ability costs energy
  }
  
  void _executeDashDamage() {
    // Play sound effect for circle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Get current input direction for rolling surge
    Vector2 dashDirection = Vector2.zero();
    
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dashDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dashDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dashDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dashDirection.x += 1;
    }
    
    // If no input, dash forward (up)
    if (dashDirection.length == 0) {
      dashDirection = Vector2(0, -1);
    }
    
    dashDirection.normalize();
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    abilityTarget = position + dashDirection * scaledRange;
    
    // Constrain ability target to arena
    abilityTarget!.x = abilityTarget!.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    abilityTarget!.y = abilityTarget!.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
    
    isUsingAbility = true;
  }
  
  void _executePiercingShot() {
    // Play sound effect for triangle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Find direction to nearest enemy or shoot forward
    Vector2 direction = Vector2(0, -1); // Default forward
    
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      direction = (nearestEnemy.position - position).normalized();
    }
    
    // Create massive triangle projectile with hero color and range scaling
    final projectile = TriangleProjectile(
      startPosition: position.clone(),
      direction: direction,
      speed: 500.0 * DisplayConfig.instance.scaleFactor,
      damage: heroData.ability.damage,
      isEnemyProjectile: false,
      heroColor: heroData.color, // Pass hero color
      rangeMultiplier: rangeMultiplier, // Scale with range upgrades
    );
    
    gameRef.add(projectile);
  }
  
  void _executeAreaStun() {
    // Play sound effect for square hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Calculate effective range (now has range limitation)
    final effectiveRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final stunDuration = heroData.ability.stunDuration ?? 3.0;
    
    // Create visual effect for the ability
    _createSquareAbilityEffect(effectiveRange);
    
    // Stun enemies within range
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= effectiveRange) {
          // Apply stun effect to different enemy types
          if (enemy is EnemyChaser) {
            enemy.stun(stunDuration);
          } else if (enemy is EnemyShooter) {
            enemy.stun(stunDuration);
          } else if (enemy is ShieldedChaser) {
            enemy.stun(stunDuration);
            // Also instantly break shield with ability damage
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          }
        }
      }
    }
    
    // Stun enemy projectiles within range
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= effectiveRange) {
          // Check if it's an enemy projectile and apply slow effect (stun)
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectile.applySlowEffect(0.0); // 0 speed = stunned
          }
        }
      }
    }
    
    print('Shield Bash! Stunned enemies within ${effectiveRange.toInt()} range for ${stunDuration}s');
  }
  
  void _executeRadialBurst() {
    // Play sound effect for pentagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Fire projectiles in all directions
    final projectileCount = heroData.ability.projectileCount ?? 5;
    final angleStep = (2 * pi) / projectileCount;
    
    for (int i = 0; i < projectileCount; i++) {
      final angle = i * angleStep;
      final direction = Vector2(cos(angle), sin(angle));
      
      // Create scaled projectile based on range multiplier
      final scaledRadius = 6.0 * DisplayConfig.instance.scaleFactor * rangeMultiplier;
      
      final projectile = Projectile(
        startPosition: position.clone(),
        direction: direction,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: heroData.ability.damage,
        isEnemyProjectile: false,
        heroColor: heroData.color,
        scaledRadius: scaledRadius, // Pass scaled radius for bullet size
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _executeAreaField() {
    // Play sound effect for hexagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Create visual hex field effect
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final duration = heroData.ability.duration ?? 4.0;
    
    final hexField = HexField(
      position: position.clone(),
      radius: scaledRange,
      duration: duration,
      damage: heroData.ability.damage,
      slowPercent: heroData.ability.slowPercent ?? 0.3,
    );
    
    gameRef.add(hexField);
  }
  
  void _executeResonanceKnockback() {
    // Play sound effect for heptagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final knockbackDistance = (heroData.ability.knockbackDistance ?? 30.0) * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    
    // Create visual effect for the ability
    _createHeptagonAbilityEffect(scaledRange);
    
    // Find enemies within range and apply damage + knockback
    final enemiesToKnockback = <Component>[];
    final projectilesToPush = <Component>[];
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= scaledRange) {
          enemiesToKnockback.add(enemy);
        }
      }
    }
    
    // Find enemy projectiles within range to push away and stun them
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= scaledRange) {
          // Check if it's an enemy projectile
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectilesToPush.add(projectile);
          }
        }
      }
    }
    
    // Apply damage and knockback to all enemies in range
    for (final enemy in enemiesToKnockback) {
      if (enemy is PositionComponent) {
        // Apply damage
        if (enemy is EnemyChaser) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is EnemyShooter) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is ShieldedChaser) {
          enemy.takeDamage(heroData.ability.damage, isAbility: true);
        }
        
        // Apply knockback
        final directionToEnemy = (enemy.position - position).normalized();
        final knockbackTarget = enemy.position + directionToEnemy * knockbackDistance;
        
        // Constrain knockback target to arena bounds
        final constrainedTarget = Vector2(
          knockbackTarget.x.clamp(50.0, DisplayConfig.instance.arenaWidth - 50.0),
          knockbackTarget.y.clamp(50.0, DisplayConfig.instance.arenaHeight - 50.0),
        );
        
        enemy.position = constrainedTarget;
      }
    }
    
    // Push away enemy projectiles
    for (final projectile in projectilesToPush) {
      if (projectile is PositionComponent) {
        final directionToProjectile = (projectile.position - position).normalized();
        final pushTarget = projectile.position + directionToProjectile * knockbackDistance;
        
        // Constrain push target to arena bounds
        final constrainedTarget = Vector2(
          pushTarget.x.clamp(0.0, DisplayConfig.instance.arenaWidth),
          pushTarget.y.clamp(0.0, DisplayConfig.instance.arenaHeight),
        );
        
        projectile.position = constrainedTarget;
      }
    }
    
    // Visual feedback
    print('Resonance Knockback! Hit ${enemiesToKnockback.length} enemies and pushed ${projectilesToPush.length} projectiles');
  }
  
  void _updateAbilityCooldownDisplay() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final timeSinceLastAbility = currentTime - lastAbilityTime;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    final cooldownPercent = (timeSinceLastAbility / effectiveCooldown).clamp(0.0, 1.0);
    final remainingSeconds = (effectiveCooldown - timeSinceLastAbility).clamp(0.0, effectiveCooldown);
    
    if (gameRef.hud.isMounted) {
      gameRef.hud.updateAbilityCooldown(cooldownPercent, remainingSeconds);
    }
  }
  
  void _constrainToArena() {
    position.x = position.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    position.y = position.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    
    // Handle universal escape key navigation
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      // Check if stats overlay is visible and hide it first
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
        return true;
      }
      
      // Check if shop is open and close it
      if (gameRef.gameState == GameState.shopping) {
        gameRef.onShopClosed();
        return true;
      }
      
      // Handle pause/resume for playing state
      if (gameRef.gameState == GameState.playing) {
        gameRef.pauseGame();
        return true;
      } else if (gameRef.gameState == GameState.paused) {
        gameRef.resumeGame();
        return true;
      }
    }
    
    // Handle ability (K key only)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyK) {
      _tryAbility();
      return true;
    }
    
    // Handle clone activation with 'C' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (canActivateClone()) {
        activateClone();
      }
      return true;
    }
    
    // Handle stats overlay toggle with 'I' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyI) {
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
      } else {
        gameRef.statsOverlay.show();
      }
      return true;
    }
    
    return false;
  }
  
  void takeDamage(double damage) {
    if (isInvincible || isDamageInvincible || isUsingAbility) {
      return; // No damage while invincible, damage invincible, or using ability
    }
    
    double remainingDamage = damage;
    
    // Shield absorbs damage first
    if (shield > 0) {
      if (shield >= remainingDamage) {
        // Shield absorbs all damage
        shield -= remainingDamage;
        remainingDamage = 0;
      } else {
        // Shield absorbs partial damage and breaks
        remainingDamage -= shield;
        shield = 0;
        
        // Remove shield effect when shield is broken
        if (hasTemporaryEffect('shield')) {
          print('Shield broken! Removing shield effect.');
          _removeEffectImmediate('shield');
          _temporaryEffects.remove('shield');
        }
      }
    }
    
    // Apply remaining damage to health
    if (remainingDamage > 0) {
      health = (health - remainingDamage).clamp(0, maxHealth);
    }
    
    // Activate damage invincibility
    isDamageInvincible = true;
    damageInvincibilityTimer = 0.0;
    
    if (health <= 0) {
      gameRef.onHeroDeath();
    }
  }
  
  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
  
  void addCoins(int amount) {
    final multiplier = totalCoinMultiplier;
    final finalAmount = (amount * multiplier).round();
    coins += finalAmount;
    if (multiplier > 1.0) {
      print('Coin Magnet: ${amount} -> ${finalAmount} coins (${multiplier}x)');
    }
  }
  
  void spendCoins(int amount) {
    coins = max(0, coins - amount);
  }
  
  void activateInvincibility() {
    isInvincible = true;
    invincibilityTimer = invincibilityDuration;
  }
  
  void _createSquareAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'square',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  void _createHeptagonAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'heptagon',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  // Temporary effects system - only one effect at a time
  void applyTemporaryEffect(String effectType, double value, double duration) {
    // Remove any existing effect first (only one at a time)
    if (_temporaryEffects.isNotEmpty) {
      final oldEffect = _temporaryEffects.entries.first;
      _removeEffectImmediate(oldEffect.key);
      _temporaryEffects.clear();
      print('Replaced effect: ${oldEffect.key} -> $effectType');
    }
    
    // Apply new effect
    _temporaryEffects[effectType] = TemporaryEffect(
      type: effectType,
      value: value,
      duration: duration,
    );
    
    // Apply immediate effects
    _applyEffectImmediate(effectType, value);
    
    print('Applied temporary effect: $effectType (${value}, ${duration}s)');
  }
  
  void _updateTemporaryEffects(double dt) {
    final expiredEffects = <String>[];
    
    for (final entry in _temporaryEffects.entries) {
      final effect = entry.value;
      effect.update(dt);
      
      if (effect.isExpired) {
        expiredEffects.add(entry.key);
        _removeEffectImmediate(entry.key);
      } else {
        // Apply ongoing effects
        _applyEffectOngoing(effect.type, effect.value, dt);
      }
    }
    
    // Remove expired effects
    for (final effectType in expiredEffects) {
      _temporaryEffects.remove(effectType);
    }
  }
  
  void _applyEffectImmediate(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
        speedMultiplier *= (1.0 + value);
        break;
      case 'damage_boost':
        // This will be applied in damage calculations
        break;
      case 'shield':
        shield += value;
        maxShield = maxShield > shield ? maxShield : shield;
        break;
      case 'invincibility':
        isInvincible = true;
        invincibilityTimer = 0.0;
        break;
      case 'weapon_overclock':
        attackSpeedMultiplier *= (1.0 + value);
        break;
    }
  }
  
  void _applyEffectOngoing(String effectType, double value, double dt) {
    switch (effectType) {
      case 'health_regen':
        heal(value * dt);
        break;
    }
  }
  
  void _removeEffectImmediate(String effectType) {
    switch (effectType) {
      case 'speed_boost':
        // Note: This is a simplified approach. In a full implementation,
        // you'd want to track the original multiplier and restore it
        speedMultiplier = 1.0; // Reset to base
        break;
      case 'damage_boost':
        // Reset damage multiplier
        break;
      case 'shield':
        // Shield naturally decays over time
        break;
      case 'invincibility':
        // Invincibility expires naturally
        break;
      case 'weapon_overclock':
        // Reset attack speed multiplier
        attackSpeedMultiplier = 1.0; // Reset to base
        break;
    }
  }
  
  // Get effective damage multiplier including temporary effects
  double get effectiveDamageMultiplier {
    double multiplier = 1.0;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'damage_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Get effective speed multiplier including temporary effects
  double get effectiveSpeedMultiplier {
    double multiplier = speedMultiplier;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'speed_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Check if hero has a specific temporary effect
  bool hasTemporaryEffect(String effectType) {
    return _temporaryEffects.containsKey(effectType);
  }
  
  // Get remaining time for a temporary effect
  double getTemporaryEffectTime(String effectType) {
    final effect = _temporaryEffects[effectType];
    return effect?.remainingTime ?? 0.0;
  }
  
  // Get current active effect for UI display
  TemporaryEffect? get currentActiveEffect {
    return _temporaryEffects.isNotEmpty ? _temporaryEffects.values.first : null;
  }
  
  // Get current active effect info as a formatted string
  String get activeEffectDisplay {
    final effect = currentActiveEffect;
    if (effect == null) return 'None';
    
    final effectName = _getEffectDisplayName(effect.type);
    final effectValue = _getEffectDisplayValue(effect.type, effect.value);
    
    // Handle infinite duration effects (like persistent shields)
    if (effect.remainingTime.isInfinite || effect.remainingTime.isNaN) {
      return '$effectName $effectValue (∞)';
    }
    
    final timeLeft = effect.remainingTime.ceil();
    return '$effectName $effectValue (${timeLeft}s)';
  }
  
  String _getEffectDisplayName(String effectType) {
    switch (effectType) {
      case 'speed_boost': return 'Speed';
      case 'damage_boost': return 'Damage';
      case 'health_regen': return 'Regen';
      case 'shield': return 'Shield';
      case 'invincibility': return 'Invul';
      case 'weapon_overclock': return 'Overclock';
      default: return effectType;
    }
  }
  
  String _getEffectDisplayValue(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
      case 'damage_boost':
      case 'weapon_overclock':
        return '+${(value * 100).round()}%';
      case 'health_regen':
        return '+${value.round()}/s';
      case 'shield':
        return '+${value.round()}';
      case 'invincibility':
        return 'ON';
      default:
        return value.toString();
    }
  }

  // Stackable passive effects system
  void addPassiveEffect(String effectType, int maxStacks) {
    final currentStacks = _passiveEffectStacks[effectType] ?? 0;
    if (currentStacks < maxStacks) {
      _passiveEffectStacks[effectType] = currentStacks + 1;
      print('Added passive effect: $effectType (${currentStacks + 1}/$maxStacks stacks)');
    } else {
      print('Cannot add $effectType: already at max stacks ($maxStacks)');
    }
  }
  
  int getPassiveEffectStacks(String effectType) {
    return _passiveEffectStacks[effectType] ?? 0;
  }
  
  bool hasPassiveEffect(String effectType) {
    return _passiveEffectStacks.containsKey(effectType) && _passiveEffectStacks[effectType]! > 0;
  }
  
  // Get calculated values based on passive effects
  int get totalProjectileCount {
    return 1 + getPassiveEffectStacks('projectile_count');
  }
  
  int get totalProjectileBounces {
    return getPassiveEffectStacks('projectile_bounces');
  }
  
  double get totalProjectileSize {
    final regularSize = 1.0 + (getPassiveEffectStacks('projectile_size') * 0.5); // 50% increase per stack
    final enlargedSize = 1.0 + (getPassiveEffectStacks('enlarged_caliber') * 0.1); // 10% increase per stack
    return regularSize * enlargedSize;
  }
  
  double get characterSizeMultiplier {
    return 1.0 + (getPassiveEffectStacks('enlarged_caliber') * 0.1);
  }
  
  double get enlargedCaliberSpeedPenalty {
    return getPassiveEffectStacks('enlarged_caliber') * 0.25;
  }
  
  int get totalDroneCount {
    return getPassiveEffectStacks('drone_count');
  }
  
  double get totalLifeSteal {
    return getPassiveEffectStacks('life_steal') * 0.05;
  }
  
  double get totalShieldHP {
    return getPassiveEffectStacks('shield_hp') * 5.0;
  }
  
  double get totalCoinMultiplier {
    return 1.0 + (getPassiveEffectStacks('coin_multiplier') * 0.2);
  }
  
  double get totalHealPerKill {
    return getPassiveEffectStacks('heal_per_kill') * 2.0;
  }
  
  double get totalCritChance {
    return getPassiveEffectStacks('crit_chance') * 0.02;
  }
  
  double get totalMaxHealthBoost {
    return getPassiveEffectStacks('max_health_boost') * 10.0;
  }
  
  bool get hasCloneProjection {
    return hasPassiveEffect('clone_spawn');
  }
  
  void resetPassiveEffects() {
    _passiveEffectStacks.clear();
    killCount = 0;
    destroyAllDrones();
    destroyClone();
  }
  
  // Apply heal per kill effect when an enemy is defeated
  void onEnemyKilled() {
    killCount++;
    
    final healAmount = totalHealPerKill;
    if (healAmount > 0) {
      heal(healAmount);
      print('Healed ${healAmount} HP from kill');
    }
    
    // Handle kill-based max health boost (Auto Injector)
    final autoInjectorStacks = getPassiveEffectStacks('kill_based_max_health');
    if (autoInjectorStacks > 0 && killCount % 10 == 0) {
      final maxHealthIncrease = autoInjectorStacks * 2.0; // 2 HP per stack
      final currentBonus = (killCount ~/ 10) * maxHealthIncrease;
      final maxBonus = autoInjectorStacks * 50.0; // 50 HP max per stack
      
      if (currentBonus <= maxBonus) {
        maxHealth += maxHealthIncrease;
        health += maxHealthIncrease; // Also heal current HP
        print('Auto Injector: +${maxHealthIncrease} max HP from ${killCount} kills');
      }
    }
  }
  
  // Regenerate shields between waves (Armor Plating effect)
  void regenerateShields() {
    final armorShields = totalShieldHP;
    if (armorShields > 0) {
      // Apply armor plating as a persistent shield effect
      applyTemporaryEffect('shield', armorShields, double.infinity);
      print('Armor plating shields regenerated to ${armorShields.toStringAsFixed(1)} HP');
    }
  }
  
  // Drone management system
  void updateDroneCount() {
    final targetDroneCount = totalDroneCount;
    final currentDroneCount = _activeDrones.length;
    
    if (targetDroneCount > currentDroneCount) {
      // Spawn new drones
      for (int i = currentDroneCount; i < targetDroneCount; i++) {
        final drone = DroneWingman(owner: this, droneIndex: i);
        _activeDrones.add(drone);
        gameRef.add(drone);
        print('Spawned drone ${i + 1}/${targetDroneCount}');
      }
    } else if (targetDroneCount < currentDroneCount) {
      // Remove excess drones
      while (_activeDrones.length > targetDroneCount) {
        final drone = _activeDrones.removeLast();
        drone.destroy();
        print('Removed drone. Remaining: ${_activeDrones.length}');
      }
    }
  }
  
  void destroyAllDrones() {
    for (final drone in _activeDrones) {
      drone.destroy();
    }
    _activeDrones.clear();
    print('All drones destroyed');
  }
  
  // Clone management system
  bool canActivateClone() {
    return hasCloneProjection && _activeClone == null && health > maxHealth * 0.5;
  }
  
  void activateClone() {
    print('🤖 Attempting to activate clone...');
    print('   - Has clone projection: ${hasCloneProjection}');
    print('   - No active clone: ${_activeClone == null}');
    print('   - Current health: ${health.toStringAsFixed(1)}/${maxHealth.toStringAsFixed(1)}');
    print('   - Required health: ${(maxHealth * 0.5).toStringAsFixed(1)}');
    
    if (!canActivateClone()) {
      print('❌ Cannot activate clone: requirements not met');
      return;
    }
    
    // Pay health cost (50% of current health)
    final healthCost = health * 0.5;
    health -= healthCost;
    
    // Spawn clone directly to the right with clear gap
    final cloneOffset = Vector2(80, 0); // Simple fixed offset to the right
    final clonePosition = position + cloneOffset;
    
    print('🤖 Creating HeroClone at position: (${clonePosition.x}, ${clonePosition.y})');
    _activeClone = HeroClone(owner: this, spawnPosition: clonePosition);
    
    print('🤖 Adding clone to game...');
    gameRef.add(_activeClone!);
    
    print('✅ CLONE ACTIVATED! Health cost: ${healthCost.toStringAsFixed(1)}, Clone mounted: ${_activeClone!.isMounted}');
  }
  
  void destroyClone() {
    if (_activeClone != null) {
      _activeClone!.destroy();
      _activeClone = null;
      print('Clone destroyed');
    }
  }
  
  bool get hasActiveClone => _activeClone != null;
  
  // Getter for passive effect stacks (for stats display)
  Map<String, int> get passiveEffectStacks => Map.from(_passiveEffectStacks);
  
  void onCloneDestroyed(HeroClone clone) {
    if (_activeClone == clone) {
      _activeClone = null;
      print('Active clone reference cleared');
    }
  }
}

// Visual effect component for abilities
class AbilityVisualEffect extends PositionComponent with HasGameRef<CircleRougeGame> {
  final double effectRange;
  final String shape;
  final Color color;
  
  double lifetime = 0.0;
  static const double totalLifetime = 0.5; // Blink once and disappear
  static const double blinkDuration = 0.25; // Half the lifetime for one blink
  
  AbilityVisualEffect({
    required Vector2 position,
    required this.effectRange,
    required this.shape,
    required this.color,
  }) : super(
    position: position,
    size: Vector2.all(effectRange * 2),
    anchor: Anchor.center,
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    lifetime += dt;
    
    // Remove after total lifetime
    if (lifetime >= totalLifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Calculate opacity with blinking effect
    final blinkProgress = (lifetime / blinkDuration) % 1.0;
    final opacity = (sin(blinkProgress * pi * 2) * 0.15 + 0.1).clamp(0.0, 0.25); // 25% max opacity
    
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = color.withOpacity(opacity * 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Draw the shape based on type
    switch (shape) {
      case 'square':
        final rect = Rect.fromCenter(
          center: center,
          width: effectRange * 2,
          height: effectRange * 2,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;
      case 'heptagon':
        final path = _createHeptagonPath(center, effectRange);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }
  
  Path _createHeptagonPath(Offset center, double radius) {
    final path = Path();
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * pi / 180);
      final y = center.dy + radius * sin(angle * pi / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    return path;
  }
} 
```

Now I need to update the Hero's render method to apply the character size multiplier. Let me find the render method:

I can see the render method, but I need to find where the hero shape is actually drawn. Let me search for the drawing logic:

I can see the hero shape drawing logic. I need to modify the heroRadius and shapeSize to apply the character size multiplier. Let me find where heroRadius is defined:

I can see that heroRadius is defined as a late double. I need to modify how it's calculated to include the character size multiplier. Let me find where it's initialized:

I need to change heroRadius from a late double to a getter that includes the character size multiplier:

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/circle_rouge_game.dart';
import '../config/hero_config.dart';
import '../config/display_config.dart';
import 'abilities/hex_field.dart';
import 'enemies/enemy_chaser.dart';
import 'enemies/enemy_shooter.dart';
import 'enemies/shielded_chaser.dart';
import 'enemies/projectile.dart';
import 'enemies/shape_projectile.dart';
import 'enemies/triangle_projectile.dart';
import 'sound_manager.dart';
import 'companions/drone_wingman.dart';
import 'companions/hero_clone.dart';

class TemporaryEffect {
  final String type;
  final double value;
  final double duration;
  double remainingTime;
  
  TemporaryEffect({
    required this.type,
    required this.value,
    required this.duration,
  }) : remainingTime = duration;
  
  void update(double dt) {
    remainingTime -= dt;
  }
  
  bool get isExpired => remainingTime <= 0;
}

class Hero extends PositionComponent with HasGameRef<CircleRougeGame>, KeyboardHandler {
  // Hero configuration
  late HeroData heroData;
  final String heroId;
  
  // Hero visual properties
  double get heroRadius => 15.0 * DisplayConfig.instance.scaleFactor * characterSizeMultiplier;
  late Paint heroPaint;
  
  // Base movement properties - will be scaled based on arena size
  static const double baseMoveSpeed = 200.0;
  
  // Base dash properties (for heroes that don't have special abilities)
  static const double baseDashDistance = 120.0;
  static const double baseDashSpeed = 500.0;
  
  // Base shooting properties
  static const double baseShootRange = 250.0;
  static const double fireRate = 2.0; // Shots per second
  double lastShotTime = 0.0;
  
  // Get scaled values based on arena size
  double get moveSpeed {
    final baseSpeed = (heroData.moveSpeed / 320.0 * baseMoveSpeed) * DisplayConfig.instance.scaleFactor;
    final speedPenalty = enlargedCaliberSpeedPenalty;
    return baseSpeed * (1.0 - speedPenalty);
  }
  double get dashDistance => baseDashDistance * DisplayConfig.instance.scaleFactor;
  double get dashSpeed => baseDashSpeed * DisplayConfig.instance.scaleFactor;
  double get shootRange => baseShootRange * DisplayConfig.instance.scaleFactor * rangeMultiplier;
  
  // Attack speed modifier (can be upgraded)
  double attackSpeedMultiplier = 1.0;
  
  // Movement speed modifier (can be upgraded)
  double speedMultiplier = 1.0;
  
  // Ability cooldown modifier (can be upgraded)
  double abilityCooldownMultiplier = 1.0;
  
  // Range modifier (can be upgraded)
  double rangeMultiplier = 1.0;
  
  // Weapon overclock visual effect
  // Weapon overclock now handled by temporary effect system
  
  // Ability system
  double lastAbilityTime = -double.infinity;
  bool isUsingAbility = false;
  Vector2? abilityTarget;
  
  // Hero stats
  double health = 100.0;
  double maxHealth = 100.0;
  double energy = 100.0;
  double maxEnergy = 100.0;
  int coins = 0;
  int killCount = 0;
  
  // Invincibility after wave completion
  bool isInvincible = false;
  double invincibilityTimer = 0.0;
  static const double invincibilityDuration = 3.0; // 3 seconds of invincibility
  
  // Damage invincibility (separate from wave completion invincibility)
  bool isDamageInvincible = false;
  double damageInvincibilityTimer = 0.0;
  static const double damageInvincibilityDuration = 0.5; // 0.5 seconds after taking damage
  
  // Temporary effects system
  final Map<String, TemporaryEffect> _temporaryEffects = {};
  
  // Stackable passive effects system
  final Map<String, int> _passiveEffectStacks = {};
  
  // Drone companion system
  final List<DroneWingman> _activeDrones = [];
  
  // Clone system
  HeroClone? _activeClone;
  
  // Shield system
  double shield = 0.0;
  double maxShield = 0.0;
  
  // Input tracking
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  
  Hero({required Vector2 position, required this.heroId}) : super(
    position: position,
    size: Vector2.all(30.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    heroRadius = 15.0 * DisplayConfig.instance.scaleFactor;
    heroPaint = Paint()..color = const Color(0xFF4CAF50);
    _initializeHero(heroId);
  }
  
  void _initializeHero(String heroId) {
    final heroConfig = HeroConfig.instance.getHeroById(heroId);
    if (heroConfig != null) {
      heroData = heroConfig;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    } else {
      // Fallback to default circle hero
      heroData = HeroConfig.instance.defaultHero;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    }
  }
  
  double get effectiveMaxHealth {
    return maxHealth + totalMaxHealthBoost;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Blinking effect during damage invincibility
    if (isDamageInvincible) {
      final blinkTime = (damageInvincibilityTimer * 8) % 1.0; // 8 blinks per second
      if (blinkTime > 0.5) {
        return; // Don't render during blink "off" phase
      }
    }
    
    final center = Offset(size.x / 2, size.y / 2);
    final shapeSize = size.x;
    
    // Old weapon overclock glow removed - now handled by active effect glow
    
    // Active effect glow
    final activeEffect = currentActiveEffect;
    if (activeEffect != null) {
      final effectTime = (DateTime.now().millisecondsSinceEpoch / 1000.0) % 1.5; // 1.5-second cycle
      final glowIntensity = (sin(effectTime * pi * 2) * 0.3 + 0.7); // 0.4 to 1.0
      final glowRadius = 15.0 * glowIntensity;
      
      // Get effect color
      Color effectColor;
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
        default:
          effectColor = const Color(0xFFFFFFFF); // White fallback
      }
      
      final effectGlowPaint = Paint()
        ..color = effectColor.withOpacity(0.8 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      // Draw effect glow based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + glowRadius, effectGlowPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'square':
          _drawSquare(canvas, center, effectGlowPaint, glowRadius);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
      }
    }
    
    // Draw main hero shape
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(center, heroRadius, heroPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, shapeSize, heroPaint, 0);
        break;
      case 'square':
        _drawSquare(canvas, center, heroPaint, 0);
        break;
      case 'pentagon':
        _drawPentagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'hexagon':
        _drawHexagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, shapeSize, heroPaint, 0);
        break;
    }
    
    // Draw shield outline if shield effect is active
    if (hasTemporaryEffect('shield') && shield > 0) {
      final shieldOpacity = (shield / maxShield).clamp(0.3, 1.0); // Fade as shield depletes
      final shieldPaint = Paint()
        ..color = const Color(0xFFFF9800).withOpacity(0.6 * shieldOpacity) // Orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Draw shield outline based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + 4, shieldPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'square':
          _drawSquare(canvas, center, shieldPaint, 4);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, shieldPaint, 4);
          break;
      }
    }
    
  }
  
  void _drawTriangle(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius / 2);
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius / 2);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSquare(Canvas canvas, Offset center, Paint paint, double glowRadius) {
    final size = (this.size.x * 0.8) + (glowRadius * 2);
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      ),
      paint,
    );
  }
  
  void _drawPentagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 5; i++) {
      final angle = -90 + (i * 72); // Pentagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHexagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 6; i++) {
      final angle = -90 + (i * 60); // Hexagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHeptagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  // Collision detection method for other components to use
  @override
  bool containsPoint(Vector2 point) {
    final distance = position.distanceTo(point);
    return distance <= heroRadius;
  }
  
  // Get collision radius for enemy collision detection
  double get collisionRadius => heroRadius;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Weapon overclock now handled by temporary effect system
    
    // Update invincibility timer
    if (isInvincible) {
      invincibilityTimer += dt;
      if (invincibilityTimer >= invincibilityDuration) {
        isInvincible = false;
        invincibilityTimer = 0.0;
      }
    }
    
    // Update damage invincibility timer
    if (isDamageInvincible) {
      damageInvincibilityTimer += dt;
      if (damageInvincibilityTimer >= damageInvincibilityDuration) {
        isDamageInvincible = false;
        damageInvincibilityTimer = 0.0;
      }
    }
    
    // Update temporary effects
    _updateTemporaryEffects(dt);
    
    if (isUsingAbility) {
      _updateAbility(dt);
    } else {
      _updateMovement(dt);
    }
    
    // Auto-shoot at enemies
    _tryAutoShoot();
    
    // Regenerate energy
    if (energy < maxEnergy) {
      energy = (energy + 50 * dt).clamp(0, maxEnergy);
    }
    
    // Keep hero within arena bounds
    _constrainToArena();
    
    // Update ability cooldown in HUD
    _updateAbilityCooldownDisplay();
  }
  
  void _tryAutoShoot() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    if (currentTime - lastShotTime < (1.0 / (fireRate * attackSpeedMultiplier))) {
      return; // Still on cooldown
    }
    
    // Find nearest enemy
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance && distance <= shootRange) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    // Shoot at nearest enemy if found
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      final direction = (nearestEnemy.position - position).normalized();
      _fireProjectile(direction);
      lastShotTime = currentTime;
    }
  }
  
  void _fireProjectile(Vector2 direction) {
    final projectileCount = totalProjectileCount;
    final projectileBounces = totalProjectileBounces;
    final projectileScale = totalProjectileSize;
    final critChance = totalCritChance;
    
    // Calculate spread angle if multiple projectiles
    final spreadAngle = projectileCount > 1 ? pi / 6 : 0.0; // 30 degrees total spread
    final angleStep = projectileCount > 1 ? spreadAngle / (projectileCount - 1) : 0.0;
    final startAngle = projectileCount > 1 ? -spreadAngle / 2 : 0.0;
    
    for (int i = 0; i < projectileCount; i++) {
      // Calculate direction for each projectile
      Vector2 projectileDirection;
      if (projectileCount == 1) {
        projectileDirection = direction;
      } else {
        final angle = startAngle + (i * angleStep);
        final baseAngle = atan2(direction.y, direction.x);
        final newAngle = baseAngle + angle;
        projectileDirection = Vector2(cos(newAngle), sin(newAngle));
      }
      
      // Check for critical hit (now instant kill, so damage doesn't matter)
      final isCritical = Random().nextDouble() < critChance;
      final finalDamage = 25.0; // Base damage (critical = instant kill)
      
      final projectile = ShapeProjectile(
        startPosition: position.clone(),
        direction: projectileDirection,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: finalDamage,
        isEnemyProjectile: false,
        shapeType: heroData.shape,
        heroColor: heroData.color,
        bounces: projectileBounces,
        sizeScale: projectileScale,
        isCritical: isCritical,
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _updateMovement(double dt) {
    Vector2 inputDirection = Vector2.zero();
    
    // Handle WASD movement
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      inputDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      inputDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      inputDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      inputDirection.x += 1;
    }
    
    // Normalize and apply movement
    if (inputDirection.length > 0) {
      inputDirection.normalize();
      position += inputDirection * moveSpeed * effectiveSpeedMultiplier * dt;
    }
  }
  
  void _updateAbility(double dt) {
    // Handle different ability types based on hero configuration
    switch (heroData.ability.type) {
      case 'dash_damage':
        _updateDashDamage(dt);
        break;
      case 'piercing_shot':
        // Piercing shot is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_stun':
        // Area stun is instant, no update needed
        isUsingAbility = false;
        break;
      case 'radial_burst':
        // Radial burst is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_field':
        // Area field is instant placement, no update needed
        isUsingAbility = false;
        break;
      default:
        isUsingAbility = false;
    }
  }
  
  void _updateDashDamage(double dt) {
    if (abilityTarget == null) {
      isUsingAbility = false;
      return;
    }
    
    final direction = (abilityTarget! - position).normalized();
    final movement = direction * dashSpeed * dt;
    
    // Check for enemy collisions during dash
    // Create a copy to avoid ConcurrentModificationError
    final enemiesCopy = List<Component>.from(gameRef.currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy is PositionComponent) {
        final distanceToEnemy = position.distanceTo(enemy.position);
        // Use different radius checks for different enemy types
        double enemyRadius = 15.0 * DisplayConfig.instance.scaleFactor; // Default radius
        
        if (enemy is EnemyChaser) {
          enemyRadius = enemy.radius;
        } else if (enemy is EnemyShooter) {
          enemyRadius = enemy.radius;
        } else if (enemy is ShieldedChaser) {
          enemyRadius = enemy.radius;
        }
        
        if (distanceToEnemy < heroRadius + enemyRadius) {
          // Damage enemy during rolling surge
          if (enemy is EnemyChaser) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is EnemyShooter) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is ShieldedChaser) {
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          } else {
            // Fallback for other enemy types - remove them directly
            if (enemy.parent != null) {
              gameRef.onEnemyDestroyed(enemy);
            }
          }
        }
      }
    }
    
    if (position.distanceTo(abilityTarget!) <= movement.length) {
      position = abilityTarget!;
      isUsingAbility = false;
      abilityTarget = null;
    } else {
      position += movement;
    }
  }
  
  void _tryAbility() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    
    if (currentTime - lastAbilityTime < effectiveCooldown || energy < 25) {
      return; // Ability on cooldown or not enough energy
    }
    
    switch (heroData.ability.type) {
      case 'dash_damage':
        _executeDashDamage();
        break;
      case 'piercing_shot':
        _executePiercingShot();
        break;
      case 'area_stun':
        _executeAreaStun();
        break;
      case 'radial_burst':
        _executeRadialBurst();
        break;
      case 'area_field':
        _executeAreaField();
        break;
      case 'resonance_knockback':
        _executeResonanceKnockback();
        break;
    }
    
    lastAbilityTime = currentTime;
    energy -= 25; // Ability costs energy
  }
  
  void _executeDashDamage() {
    // Play sound effect for circle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Get current input direction for rolling surge
    Vector2 dashDirection = Vector2.zero();
    
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dashDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dashDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dashDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dashDirection.x += 1;
    }
    
    // If no input, dash forward (up)
    if (dashDirection.length == 0) {
      dashDirection = Vector2(0, -1);
    }
    
    dashDirection.normalize();
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    abilityTarget = position + dashDirection * scaledRange;
    
    // Constrain ability target to arena
    abilityTarget!.x = abilityTarget!.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    abilityTarget!.y = abilityTarget!.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
    
    isUsingAbility = true;
  }
  
  void _executePiercingShot() {
    // Play sound effect for triangle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Find direction to nearest enemy or shoot forward
    Vector2 direction = Vector2(0, -1); // Default forward
    
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      direction = (nearestEnemy.position - position).normalized();
    }
    
    // Create massive triangle projectile with hero color and range scaling
    final projectile = TriangleProjectile(
      startPosition: position.clone(),
      direction: direction,
      speed: 500.0 * DisplayConfig.instance.scaleFactor,
      damage: heroData.ability.damage,
      isEnemyProjectile: false,
      heroColor: heroData.color, // Pass hero color
      rangeMultiplier: rangeMultiplier, // Scale with range upgrades
    );
    
    gameRef.add(projectile);
  }
  
  void _executeAreaStun() {
    // Play sound effect for square hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Calculate effective range (now has range limitation)
    final effectiveRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final stunDuration = heroData.ability.stunDuration ?? 3.0;
    
    // Create visual effect for the ability
    _createSquareAbilityEffect(effectiveRange);
    
    // Stun enemies within range
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= effectiveRange) {
          // Apply stun effect to different enemy types
          if (enemy is EnemyChaser) {
            enemy.stun(stunDuration);
          } else if (enemy is EnemyShooter) {
            enemy.stun(stunDuration);
          } else if (enemy is ShieldedChaser) {
            enemy.stun(stunDuration);
            // Also instantly break shield with ability damage
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          }
        }
      }
    }
    
    // Stun enemy projectiles within range
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= effectiveRange) {
          // Check if it's an enemy projectile and apply slow effect (stun)
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectile.applySlowEffect(0.0); // 0 speed = stunned
          }
        }
      }
    }
    
    print('Shield Bash! Stunned enemies within ${effectiveRange.toInt()} range for ${stunDuration}s');
  }
  
  void _executeRadialBurst() {
    // Play sound effect for pentagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Fire projectiles in all directions
    final projectileCount = heroData.ability.projectileCount ?? 5;
    final angleStep = (2 * pi) / projectileCount;
    
    for (int i = 0; i < projectileCount; i++) {
      final angle = i * angleStep;
      final direction = Vector2(cos(angle), sin(angle));
      
      // Create scaled projectile based on range multiplier
      final scaledRadius = 6.0 * DisplayConfig.instance.scaleFactor * rangeMultiplier;
      
      final projectile = Projectile(
        startPosition: position.clone(),
        direction: direction,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: heroData.ability.damage,
        isEnemyProjectile: false,
        heroColor: heroData.color,
        scaledRadius: scaledRadius, // Pass scaled radius for bullet size
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _executeAreaField() {
    // Play sound effect for hexagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Create visual hex field effect
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final duration = heroData.ability.duration ?? 4.0;
    
    final hexField = HexField(
      position: position.clone(),
      radius: scaledRange,
      duration: duration,
      damage: heroData.ability.damage,
      slowPercent: heroData.ability.slowPercent ?? 0.3,
    );
    
    gameRef.add(hexField);
  }
  
  void _executeResonanceKnockback() {
    // Play sound effect for heptagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final knockbackDistance = (heroData.ability.knockbackDistance ?? 30.0) * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    
    // Create visual effect for the ability
    _createHeptagonAbilityEffect(scaledRange);
    
    // Find enemies within range and apply damage + knockback
    final enemiesToKnockback = <Component>[];
    final projectilesToPush = <Component>[];
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= scaledRange) {
          enemiesToKnockback.add(enemy);
        }
      }
    }
    
    // Find enemy projectiles within range to push away and stun them
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= scaledRange) {
          // Check if it's an enemy projectile
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectilesToPush.add(projectile);
          }
        }
      }
    }
    
    // Apply damage and knockback to all enemies in range
    for (final enemy in enemiesToKnockback) {
      if (enemy is PositionComponent) {
        // Apply damage
        if (enemy is EnemyChaser) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is EnemyShooter) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is ShieldedChaser) {
          enemy.takeDamage(heroData.ability.damage, isAbility: true);
        }
        
        // Apply knockback
        final directionToEnemy = (enemy.position - position).normalized();
        final knockbackTarget = enemy.position + directionToEnemy * knockbackDistance;
        
        // Constrain knockback target to arena bounds
        final constrainedTarget = Vector2(
          knockbackTarget.x.clamp(50.0, DisplayConfig.instance.arenaWidth - 50.0),
          knockbackTarget.y.clamp(50.0, DisplayConfig.instance.arenaHeight - 50.0),
        );
        
        enemy.position = constrainedTarget;
      }
    }
    
    // Push away enemy projectiles
    for (final projectile in projectilesToPush) {
      if (projectile is PositionComponent) {
        final directionToProjectile = (projectile.position - position).normalized();
        final pushTarget = projectile.position + directionToProjectile * knockbackDistance;
        
        // Constrain push target to arena bounds
        final constrainedTarget = Vector2(
          pushTarget.x.clamp(0.0, DisplayConfig.instance.arenaWidth),
          pushTarget.y.clamp(0.0, DisplayConfig.instance.arenaHeight),
        );
        
        projectile.position = constrainedTarget;
      }
    }
    
    // Visual feedback
    print('Resonance Knockback! Hit ${enemiesToKnockback.length} enemies and pushed ${projectilesToPush.length} projectiles');
  }
  
  void _updateAbilityCooldownDisplay() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final timeSinceLastAbility = currentTime - lastAbilityTime;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    final cooldownPercent = (timeSinceLastAbility / effectiveCooldown).clamp(0.0, 1.0);
    final remainingSeconds = (effectiveCooldown - timeSinceLastAbility).clamp(0.0, effectiveCooldown);
    
    if (gameRef.hud.isMounted) {
      gameRef.hud.updateAbilityCooldown(cooldownPercent, remainingSeconds);
    }
  }
  
  void _constrainToArena() {
    position.x = position.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    position.y = position.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    
    // Handle universal escape key navigation
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      // Check if stats overlay is visible and hide it first
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
        return true;
      }
      
      // Check if shop is open and close it
      if (gameRef.gameState == GameState.shopping) {
        gameRef.onShopClosed();
        return true;
      }
      
      // Handle pause/resume for playing state
      if (gameRef.gameState == GameState.playing) {
        gameRef.pauseGame();
        return true;
      } else if (gameRef.gameState == GameState.paused) {
        gameRef.resumeGame();
        return true;
      }
    }
    
    // Handle ability (K key only)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyK) {
      _tryAbility();
      return true;
    }
    
    // Handle clone activation with 'C' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (canActivateClone()) {
        activateClone();
      }
      return true;
    }
    
    // Handle stats overlay toggle with 'I' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyI) {
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
      } else {
        gameRef.statsOverlay.show();
      }
      return true;
    }
    
    return false;
  }
  
  void takeDamage(double damage) {
    if (isInvincible || isDamageInvincible || isUsingAbility) {
      return; // No damage while invincible, damage invincible, or using ability
    }
    
    double remainingDamage = damage;
    
    // Shield absorbs damage first
    if (shield > 0) {
      if (shield >= remainingDamage) {
        // Shield absorbs all damage
        shield -= remainingDamage;
        remainingDamage = 0;
      } else {
        // Shield absorbs partial damage and breaks
        remainingDamage -= shield;
        shield = 0;
        
        // Remove shield effect when shield is broken
        if (hasTemporaryEffect('shield')) {
          print('Shield broken! Removing shield effect.');
          _removeEffectImmediate('shield');
          _temporaryEffects.remove('shield');
        }
      }
    }
    
    // Apply remaining damage to health
    if (remainingDamage > 0) {
      health = (health - remainingDamage).clamp(0, maxHealth);
    }
    
    // Activate damage invincibility
    isDamageInvincible = true;
    damageInvincibilityTimer = 0.0;
    
    if (health <= 0) {
      gameRef.onHeroDeath();
    }
  }
  
  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
  
  void addCoins(int amount) {
    final multiplier = totalCoinMultiplier;
    final finalAmount = (amount * multiplier).round();
    coins += finalAmount;
    if (multiplier > 1.0) {
      print('Coin Magnet: ${amount} -> ${finalAmount} coins (${multiplier}x)');
    }
  }
  
  void spendCoins(int amount) {
    coins = max(0, coins - amount);
  }
  
  void activateInvincibility() {
    isInvincible = true;
    invincibilityTimer = invincibilityDuration;
  }
  
  void _createSquareAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'square',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  void _createHeptagonAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'heptagon',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  // Temporary effects system - only one effect at a time
  void applyTemporaryEffect(String effectType, double value, double duration) {
    // Remove any existing effect first (only one at a time)
    if (_temporaryEffects.isNotEmpty) {
      final oldEffect = _temporaryEffects.entries.first;
      _removeEffectImmediate(oldEffect.key);
      _temporaryEffects.clear();
      print('Replaced effect: ${oldEffect.key} -> $effectType');
    }
    
    // Apply new effect
    _temporaryEffects[effectType] = TemporaryEffect(
      type: effectType,
      value: value,
      duration: duration,
    );
    
    // Apply immediate effects
    _applyEffectImmediate(effectType, value);
    
    print('Applied temporary effect: $effectType (${value}, ${duration}s)');
  }
  
  void _updateTemporaryEffects(double dt) {
    final expiredEffects = <String>[];
    
    for (final entry in _temporaryEffects.entries) {
      final effect = entry.value;
      effect.update(dt);
      
      if (effect.isExpired) {
        expiredEffects.add(entry.key);
        _removeEffectImmediate(entry.key);
      } else {
        // Apply ongoing effects
        _applyEffectOngoing(effect.type, effect.value, dt);
      }
    }
    
    // Remove expired effects
    for (final effectType in expiredEffects) {
      _temporaryEffects.remove(effectType);
    }
  }
  
  void _applyEffectImmediate(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
        speedMultiplier *= (1.0 + value);
        break;
      case 'damage_boost':
        // This will be applied in damage calculations
        break;
      case 'shield':
        shield += value;
        maxShield = maxShield > shield ? maxShield : shield;
        break;
      case 'invincibility':
        isInvincible = true;
        invincibilityTimer = 0.0;
        break;
      case 'weapon_overclock':
        attackSpeedMultiplier *= (1.0 + value);
        break;
    }
  }
  
  void _applyEffectOngoing(String effectType, double value, double dt) {
    switch (effectType) {
      case 'health_regen':
        heal(value * dt);
        break;
    }
  }
  
  void _removeEffectImmediate(String effectType) {
    switch (effectType) {
      case 'speed_boost':
        // Note: This is a simplified approach. In a full implementation,
        // you'd want to track the original multiplier and restore it
        speedMultiplier = 1.0; // Reset to base
        break;
      case 'damage_boost':
        // Reset damage multiplier
        break;
      case 'shield':
        // Shield naturally decays over time
        break;
      case 'invincibility':
        // Invincibility expires naturally
        break;
      case 'weapon_overclock':
        // Reset attack speed multiplier
        attackSpeedMultiplier = 1.0; // Reset to base
        break;
    }
  }
  
  // Get effective damage multiplier including temporary effects
  double get effectiveDamageMultiplier {
    double multiplier = 1.0;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'damage_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Get effective speed multiplier including temporary effects
  double get effectiveSpeedMultiplier {
    double multiplier = speedMultiplier;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'speed_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Check if hero has a specific temporary effect
  bool hasTemporaryEffect(String effectType) {
    return _temporaryEffects.containsKey(effectType);
  }
  
  // Get remaining time for a temporary effect
  double getTemporaryEffectTime(String effectType) {
    final effect = _temporaryEffects[effectType];
    return effect?.remainingTime ?? 0.0;
  }
  
  // Get current active effect for UI display
  TemporaryEffect? get currentActiveEffect {
    return _temporaryEffects.isNotEmpty ? _temporaryEffects.values.first : null;
  }
  
  // Get current active effect info as a formatted string
  String get activeEffectDisplay {
    final effect = currentActiveEffect;
    if (effect == null) return 'None';
    
    final effectName = _getEffectDisplayName(effect.type);
    final effectValue = _getEffectDisplayValue(effect.type, effect.value);
    
    // Handle infinite duration effects (like persistent shields)
    if (effect.remainingTime.isInfinite || effect.remainingTime.isNaN) {
      return '$effectName $effectValue (∞)';
    }
    
    final timeLeft = effect.remainingTime.ceil();
    return '$effectName $effectValue (${timeLeft}s)';
  }
  
  String _getEffectDisplayName(String effectType) {
    switch (effectType) {
      case 'speed_boost': return 'Speed';
      case 'damage_boost': return 'Damage';
      case 'health_regen': return 'Regen';
      case 'shield': return 'Shield';
      case 'invincibility': return 'Invul';
      case 'weapon_overclock': return 'Overclock';
      default: return effectType;
    }
  }
  
  String _getEffectDisplayValue(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
      case 'damage_boost':
      case 'weapon_overclock':
        return '+${(value * 100).round()}%';
      case 'health_regen':
        return '+${value.round()}/s';
      case 'shield':
        return '+${value.round()}';
      case 'invincibility':
        return 'ON';
      default:
        return value.toString();
    }
  }

  // Stackable passive effects system
  void addPassiveEffect(String effectType, int maxStacks) {
    final currentStacks = _passiveEffectStacks[effectType] ?? 0;
    if (currentStacks < maxStacks) {
      _passiveEffectStacks[effectType] = currentStacks + 1;
      print('Added passive effect: $effectType (${currentStacks + 1}/$maxStacks stacks)');
    } else {
      print('Cannot add $effectType: already at max stacks ($maxStacks)');
    }
  }
  
  int getPassiveEffectStacks(String effectType) {
    return _passiveEffectStacks[effectType] ?? 0;
  }
  
  bool hasPassiveEffect(String effectType) {
    return _passiveEffectStacks.containsKey(effectType) && _passiveEffectStacks[effectType]! > 0;
  }
  
  // Get calculated values based on passive effects
  int get totalProjectileCount {
    return 1 + getPassiveEffectStacks('projectile_count');
  }
  
  int get totalProjectileBounces {
    return getPassiveEffectStacks('projectile_bounces');
  }
  
  double get totalProjectileSize {
    final regularSize = 1.0 + (getPassiveEffectStacks('projectile_size') * 0.5); // 50% increase per stack
    final enlargedSize = 1.0 + (getPassiveEffectStacks('enlarged_caliber') * 0.1); // 10% increase per stack
    return regularSize * enlargedSize;
  }
  
  double get characterSizeMultiplier {
    return 1.0 + (getPassiveEffectStacks('enlarged_caliber') * 0.1);
  }
  
  double get enlargedCaliberSpeedPenalty {
    return getPassiveEffectStacks('enlarged_caliber') * 0.25;
  }
  
  int get totalDroneCount {
    return getPassiveEffectStacks('drone_count');
  }
  
  double get totalLifeSteal {
    return getPassiveEffectStacks('life_steal') * 0.05;
  }
  
  double get totalShieldHP {
    return getPassiveEffectStacks('shield_hp') * 5.0;
  }
  
  double get totalCoinMultiplier {
    return 1.0 + (getPassiveEffectStacks('coin_multiplier') * 0.2);
  }
  
  double get totalHealPerKill {
    return getPassiveEffectStacks('heal_per_kill') * 2.0;
  }
  
  double get totalCritChance {
    return getPassiveEffectStacks('crit_chance') * 0.02;
  }
  
  double get totalMaxHealthBoost {
    return getPassiveEffectStacks('max_health_boost') * 10.0;
  }
  
  bool get hasCloneProjection {
    return hasPassiveEffect('clone_spawn');
  }
  
  void resetPassiveEffects() {
    _passiveEffectStacks.clear();
    killCount = 0;
    destroyAllDrones();
    destroyClone();
  }
  
  // Apply heal per kill effect when an enemy is defeated
  void onEnemyKilled() {
    killCount++;
    
    final healAmount = totalHealPerKill;
    if (healAmount > 0) {
      heal(healAmount);
      print('Healed ${healAmount} HP from kill');
    }
    
    // Handle kill-based max health boost (Auto Injector)
    final autoInjectorStacks = getPassiveEffectStacks('kill_based_max_health');
    if (autoInjectorStacks > 0 && killCount % 10 == 0) {
      final maxHealthIncrease = autoInjectorStacks * 2.0; // 2 HP per stack
      final currentBonus = (killCount ~/ 10) * maxHealthIncrease;
      final maxBonus = autoInjectorStacks * 50.0; // 50 HP max per stack
      
      if (currentBonus <= maxBonus) {
        maxHealth += maxHealthIncrease;
        health += maxHealthIncrease; // Also heal current HP
        print('Auto Injector: +${maxHealthIncrease} max HP from ${killCount} kills');
      }
    }
  }
  
  // Regenerate shields between waves (Armor Plating effect)
  void regenerateShields() {
    final armorShields = totalShieldHP;
    if (armorShields > 0) {
      // Apply armor plating as a persistent shield effect
      applyTemporaryEffect('shield', armorShields, double.infinity);
      print('Armor plating shields regenerated to ${armorShields.toStringAsFixed(1)} HP');
    }
  }
  
  // Drone management system
  void updateDroneCount() {
    final targetDroneCount = totalDroneCount;
    final currentDroneCount = _activeDrones.length;
    
    if (targetDroneCount > currentDroneCount) {
      // Spawn new drones
      for (int i = currentDroneCount; i < targetDroneCount; i++) {
        final drone = DroneWingman(owner: this, droneIndex: i);
        _activeDrones.add(drone);
        gameRef.add(drone);
        print('Spawned drone ${i + 1}/${targetDroneCount}');
      }
    } else if (targetDroneCount < currentDroneCount) {
      // Remove excess drones
      while (_activeDrones.length > targetDroneCount) {
        final drone = _activeDrones.removeLast();
        drone.destroy();
        print('Removed drone. Remaining: ${_activeDrones.length}');
      }
    }
  }
  
  void destroyAllDrones() {
    for (final drone in _activeDrones) {
      drone.destroy();
    }
    _activeDrones.clear();
    print('All drones destroyed');
  }
  
  // Clone management system
  bool canActivateClone() {
    return hasCloneProjection && _activeClone == null && health > maxHealth * 0.5;
  }
  
  void activateClone() {
    print('🤖 Attempting to activate clone...');
    print('   - Has clone projection: ${hasCloneProjection}');
    print('   - No active clone: ${_activeClone == null}');
    print('   - Current health: ${health.toStringAsFixed(1)}/${maxHealth.toStringAsFixed(1)}');
    print('   - Required health: ${(maxHealth * 0.5).toStringAsFixed(1)}');
    
    if (!canActivateClone()) {
      print('❌ Cannot activate clone: requirements not met');
      return;
    }
    
    // Pay health cost (50% of current health)
    final healthCost = health * 0.5;
    health -= healthCost;
    
    // Spawn clone directly to the right with clear gap
    final cloneOffset = Vector2(80, 0); // Simple fixed offset to the right
    final clonePosition = position + cloneOffset;
    
    print('🤖 Creating HeroClone at position: (${clonePosition.x}, ${clonePosition.y})');
    _activeClone = HeroClone(owner: this, spawnPosition: clonePosition);
    
    print('🤖 Adding clone to game...');
    gameRef.add(_activeClone!);
    
    print('✅ CLONE ACTIVATED! Health cost: ${healthCost.toStringAsFixed(1)}, Clone mounted: ${_activeClone!.isMounted}');
  }
  
  void destroyClone() {
    if (_activeClone != null) {
      _activeClone!.destroy();
      _activeClone = null;
      print('Clone destroyed');
    }
  }
  
  bool get hasActiveClone => _activeClone != null;
  
  // Getter for passive effect stacks (for stats display)
  Map<String, int> get passiveEffectStacks => Map.from(_passiveEffectStacks);
  
  void onCloneDestroyed(HeroClone clone) {
    if (_activeClone == clone) {
      _activeClone = null;
      print('Active clone reference cleared');
    }
  }
}

// Visual effect component for abilities
class AbilityVisualEffect extends PositionComponent with HasGameRef<CircleRougeGame> {
  final double effectRange;
  final String shape;
  final Color color;
  
  double lifetime = 0.0;
  static const double totalLifetime = 0.5; // Blink once and disappear
  static const double blinkDuration = 0.25; // Half the lifetime for one blink
  
  AbilityVisualEffect({
    required Vector2 position,
    required this.effectRange,
    required this.shape,
    required this.color,
  }) : super(
    position: position,
    size: Vector2.all(effectRange * 2),
    anchor: Anchor.center,
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    lifetime += dt;
    
    // Remove after total lifetime
    if (lifetime >= totalLifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Calculate opacity with blinking effect
    final blinkProgress = (lifetime / blinkDuration) % 1.0;
    final opacity = (sin(blinkProgress * pi * 2) * 0.15 + 0.1).clamp(0.0, 0.25); // 25% max opacity
    
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = color.withOpacity(opacity * 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Draw the shape based on type
    switch (shape) {
      case 'square':
        final rect = Rect.fromCenter(
          center: center,
          width: effectRange * 2,
          height: effectRange * 2,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;
      case 'heptagon':
        final path = _createHeptagonPath(center, effectRange);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }
  
  Path _createHeptagonPath(Offset center, double radius) {
    final path = Path();
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * pi / 180);
      final y = center.dy + radius * sin(angle * pi / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    return path;
  }
} 
```

Now I need to remove the heroRadius initialization from the constructor since it's now a getter:

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/circle_rouge_game.dart';
import '../config/hero_config.dart';
import '../config/display_config.dart';
import 'abilities/hex_field.dart';
import 'enemies/enemy_chaser.dart';
import 'enemies/enemy_shooter.dart';
import 'enemies/shielded_chaser.dart';
import 'enemies/projectile.dart';
import 'enemies/shape_projectile.dart';
import 'enemies/triangle_projectile.dart';
import 'sound_manager.dart';
import 'companions/drone_wingman.dart';
import 'companions/hero_clone.dart';

class TemporaryEffect {
  final String type;
  final double value;
  final double duration;
  double remainingTime;
  
  TemporaryEffect({
    required this.type,
    required this.value,
    required this.duration,
  }) : remainingTime = duration;
  
  void update(double dt) {
    remainingTime -= dt;
  }
  
  bool get isExpired => remainingTime <= 0;
}

class Hero extends PositionComponent with HasGameRef<CircleRougeGame>, KeyboardHandler {
  // Hero configuration
  late HeroData heroData;
  final String heroId;
  
  // Hero visual properties
  double get heroRadius => 15.0 * DisplayConfig.instance.scaleFactor * characterSizeMultiplier;
  late Paint heroPaint;
  
  // Base movement properties - will be scaled based on arena size
  static const double baseMoveSpeed = 200.0;
  
  // Base dash properties (for heroes that don't have special abilities)
  static const double baseDashDistance = 120.0;
  static const double baseDashSpeed = 500.0;
  
  // Base shooting properties
  static const double baseShootRange = 250.0;
  static const double fireRate = 2.0; // Shots per second
  double lastShotTime = 0.0;
  
  // Get scaled values based on arena size
  double get moveSpeed {
    final baseSpeed = (heroData.moveSpeed / 320.0 * baseMoveSpeed) * DisplayConfig.instance.scaleFactor;
    final speedPenalty = enlargedCaliberSpeedPenalty;
    return baseSpeed * (1.0 - speedPenalty);
  }
  double get dashDistance => baseDashDistance * DisplayConfig.instance.scaleFactor;
  double get dashSpeed => baseDashSpeed * DisplayConfig.instance.scaleFactor;
  double get shootRange => baseShootRange * DisplayConfig.instance.scaleFactor * rangeMultiplier;
  
  // Attack speed modifier (can be upgraded)
  double attackSpeedMultiplier = 1.0;
  
  // Movement speed modifier (can be upgraded)
  double speedMultiplier = 1.0;
  
  // Ability cooldown modifier (can be upgraded)
  double abilityCooldownMultiplier = 1.0;
  
  // Range modifier (can be upgraded)
  double rangeMultiplier = 1.0;
  
  // Weapon overclock visual effect
  // Weapon overclock now handled by temporary effect system
  
  // Ability system
  double lastAbilityTime = -double.infinity;
  bool isUsingAbility = false;
  Vector2? abilityTarget;
  
  // Hero stats
  double health = 100.0;
  double maxHealth = 100.0;
  double energy = 100.0;
  double maxEnergy = 100.0;
  int coins = 0;
  int killCount = 0;
  
  // Invincibility after wave completion
  bool isInvincible = false;
  double invincibilityTimer = 0.0;
  static const double invincibilityDuration = 3.0; // 3 seconds of invincibility
  
  // Damage invincibility (separate from wave completion invincibility)
  bool isDamageInvincible = false;
  double damageInvincibilityTimer = 0.0;
  static const double damageInvincibilityDuration = 0.5; // 0.5 seconds after taking damage
  
  // Temporary effects system
  final Map<String, TemporaryEffect> _temporaryEffects = {};
  
  // Stackable passive effects system
  final Map<String, int> _passiveEffectStacks = {};
  
  // Drone companion system
  final List<DroneWingman> _activeDrones = [];
  
  // Clone system
  HeroClone? _activeClone;
  
  // Shield system
  double shield = 0.0;
  double maxShield = 0.0;
  
  // Input tracking
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  
  Hero({required Vector2 position, required this.heroId}) : super(
    position: position,
    size: Vector2.all(30.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    heroPaint = Paint()..color = const Color(0xFF4CAF50);
    _initializeHero(heroId);
  }
  
  void _initializeHero(String heroId) {
    final heroConfig = HeroConfig.instance.getHeroById(heroId);
    if (heroConfig != null) {
      heroData = heroConfig;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    } else {
      // Fallback to default circle hero
      heroData = HeroConfig.instance.defaultHero;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    }
  }
  
  double get effectiveMaxHealth {
    return maxHealth + totalMaxHealthBoost;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Blinking effect during damage invincibility
    if (isDamageInvincible) {
      final blinkTime = (damageInvincibilityTimer * 8) % 1.0; // 8 blinks per second
      if (blinkTime > 0.5) {
        return; // Don't render during blink "off" phase
      }
    }
    
    final center = Offset(size.x / 2, size.y / 2);
    final shapeSize = size.x;
    
    // Old weapon overclock glow removed - now handled by active effect glow
    
    // Active effect glow
    final activeEffect = currentActiveEffect;
    if (activeEffect != null) {
      final effectTime = (DateTime.now().millisecondsSinceEpoch / 1000.0) % 1.5; // 1.5-second cycle
      final glowIntensity = (sin(effectTime * pi * 2) * 0.3 + 0.7); // 0.4 to 1.0
      final glowRadius = 15.0 * glowIntensity;
      
      // Get effect color
      Color effectColor;
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
        default:
          effectColor = const Color(0xFFFFFFFF); // White fallback
      }
      
      final effectGlowPaint = Paint()
        ..color = effectColor.withOpacity(0.8 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      // Draw effect glow based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + glowRadius, effectGlowPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'square':
          _drawSquare(canvas, center, effectGlowPaint, glowRadius);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
      }
    }
    
    // Draw main hero shape
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(center, heroRadius, heroPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, shapeSize, heroPaint, 0);
        break;
      case 'square':
        _drawSquare(canvas, center, heroPaint, 0);
        break;
      case 'pentagon':
        _drawPentagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'hexagon':
        _drawHexagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, shapeSize, heroPaint, 0);
        break;
    }
    
    // Draw shield outline if shield effect is active
    if (hasTemporaryEffect('shield') && shield > 0) {
      final shieldOpacity = (shield / maxShield).clamp(0.3, 1.0); // Fade as shield depletes
      final shieldPaint = Paint()
        ..color = const Color(0xFFFF9800).withOpacity(0.6 * shieldOpacity) // Orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Draw shield outline based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + 4, shieldPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'square':
          _drawSquare(canvas, center, shieldPaint, 4);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, shieldPaint, 4);
          break;
      }
    }
    
  }
  
  void _drawTriangle(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius / 2);
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius / 2);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSquare(Canvas canvas, Offset center, Paint paint, double glowRadius) {
    final size = (this.size.x * 0.8) + (glowRadius * 2);
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      ),
      paint,
    );
  }
  
  void _drawPentagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 5; i++) {
      final angle = -90 + (i * 72); // Pentagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHexagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 6; i++) {
      final angle = -90 + (i * 60); // Hexagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHeptagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  // Collision detection method for other components to use
  @override
  bool containsPoint(Vector2 point) {
    final distance = position.distanceTo(point);
    return distance <= heroRadius;
  }
  
  // Get collision radius for enemy collision detection
  double get collisionRadius => heroRadius;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Weapon overclock now handled by temporary effect system
    
    // Update invincibility timer
    if (isInvincible) {
      invincibilityTimer += dt;
      if (invincibilityTimer >= invincibilityDuration) {
        isInvincible = false;
        invincibilityTimer = 0.0;
      }
    }
    
    // Update damage invincibility timer
    if (isDamageInvincible) {
      damageInvincibilityTimer += dt;
      if (damageInvincibilityTimer >= damageInvincibilityDuration) {
        isDamageInvincible = false;
        damageInvincibilityTimer = 0.0;
      }
    }
    
    // Update temporary effects
    _updateTemporaryEffects(dt);
    
    if (isUsingAbility) {
      _updateAbility(dt);
    } else {
      _updateMovement(dt);
    }
    
    // Auto-shoot at enemies
    _tryAutoShoot();
    
    // Regenerate energy
    if (energy < maxEnergy) {
      energy = (energy + 50 * dt).clamp(0, maxEnergy);
    }
    
    // Keep hero within arena bounds
    _constrainToArena();
    
    // Update ability cooldown in HUD
    _updateAbilityCooldownDisplay();
  }
  
  void _tryAutoShoot() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    if (currentTime - lastShotTime < (1.0 / (fireRate * attackSpeedMultiplier))) {
      return; // Still on cooldown
    }
    
    // Find nearest enemy
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance && distance <= shootRange) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    // Shoot at nearest enemy if found
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      final direction = (nearestEnemy.position - position).normalized();
      _fireProjectile(direction);
      lastShotTime = currentTime;
    }
  }
  
  void _fireProjectile(Vector2 direction) {
    final projectileCount = totalProjectileCount;
    final projectileBounces = totalProjectileBounces;
    final projectileScale = totalProjectileSize;
    final critChance = totalCritChance;
    
    // Calculate spread angle if multiple projectiles
    final spreadAngle = projectileCount > 1 ? pi / 6 : 0.0; // 30 degrees total spread
    final angleStep = projectileCount > 1 ? spreadAngle / (projectileCount - 1) : 0.0;
    final startAngle = projectileCount > 1 ? -spreadAngle / 2 : 0.0;
    
    for (int i = 0; i < projectileCount; i++) {
      // Calculate direction for each projectile
      Vector2 projectileDirection;
      if (projectileCount == 1) {
        projectileDirection = direction;
      } else {
        final angle = startAngle + (i * angleStep);
        final baseAngle = atan2(direction.y, direction.x);
        final newAngle = baseAngle + angle;
        projectileDirection = Vector2(cos(newAngle), sin(newAngle));
      }
      
      // Check for critical hit (now instant kill, so damage doesn't matter)
      final isCritical = Random().nextDouble() < critChance;
      final finalDamage = 25.0; // Base damage (critical = instant kill)
      
      final projectile = ShapeProjectile(
        startPosition: position.clone(),
        direction: projectileDirection,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: finalDamage,
        isEnemyProjectile: false,
        shapeType: heroData.shape,
        heroColor: heroData.color,
        bounces: projectileBounces,
        sizeScale: projectileScale,
        isCritical: isCritical,
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _updateMovement(double dt) {
    Vector2 inputDirection = Vector2.zero();
    
    // Handle WASD movement
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      inputDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      inputDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      inputDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      inputDirection.x += 1;
    }
    
    // Normalize and apply movement
    if (inputDirection.length > 0) {
      inputDirection.normalize();
      position += inputDirection * moveSpeed * effectiveSpeedMultiplier * dt;
    }
  }
  
  void _updateAbility(double dt) {
    // Handle different ability types based on hero configuration
    switch (heroData.ability.type) {
      case 'dash_damage':
        _updateDashDamage(dt);
        break;
      case 'piercing_shot':
        // Piercing shot is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_stun':
        // Area stun is instant, no update needed
        isUsingAbility = false;
        break;
      case 'radial_burst':
        // Radial burst is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_field':
        // Area field is instant placement, no update needed
        isUsingAbility = false;
        break;
      default:
        isUsingAbility = false;
    }
  }
  
  void _updateDashDamage(double dt) {
    if (abilityTarget == null) {
      isUsingAbility = false;
      return;
    }
    
    final direction = (abilityTarget! - position).normalized();
    final movement = direction * dashSpeed * dt;
    
    // Check for enemy collisions during dash
    // Create a copy to avoid ConcurrentModificationError
    final enemiesCopy = List<Component>.from(gameRef.currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy is PositionComponent) {
        final distanceToEnemy = position.distanceTo(enemy.position);
        // Use different radius checks for different enemy types
        double enemyRadius = 15.0 * DisplayConfig.instance.scaleFactor; // Default radius
        
        if (enemy is EnemyChaser) {
          enemyRadius = enemy.radius;
        } else if (enemy is EnemyShooter) {
          enemyRadius = enemy.radius;
        } else if (enemy is ShieldedChaser) {
          enemyRadius = enemy.radius;
        }
        
        if (distanceToEnemy < heroRadius + enemyRadius) {
          // Damage enemy during rolling surge
          if (enemy is EnemyChaser) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is EnemyShooter) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is ShieldedChaser) {
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          } else {
            // Fallback for other enemy types - remove them directly
            if (enemy.parent != null) {
              gameRef.onEnemyDestroyed(enemy);
            }
          }
        }
      }
    }
    
    if (position.distanceTo(abilityTarget!) <= movement.length) {
      position = abilityTarget!;
      isUsingAbility = false;
      abilityTarget = null;
    } else {
      position += movement;
    }
  }
  
  void _tryAbility() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    
    if (currentTime - lastAbilityTime < effectiveCooldown || energy < 25) {
      return; // Ability on cooldown or not enough energy
    }
    
    switch (heroData.ability.type) {
      case 'dash_damage':
        _executeDashDamage();
        break;
      case 'piercing_shot':
        _executePiercingShot();
        break;
      case 'area_stun':
        _executeAreaStun();
        break;
      case 'radial_burst':
        _executeRadialBurst();
        break;
      case 'area_field':
        _executeAreaField();
        break;
      case 'resonance_knockback':
        _executeResonanceKnockback();
        break;
    }
    
    lastAbilityTime = currentTime;
    energy -= 25; // Ability costs energy
  }
  
  void _executeDashDamage() {
    // Play sound effect for circle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Get current input direction for rolling surge
    Vector2 dashDirection = Vector2.zero();
    
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dashDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dashDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dashDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dashDirection.x += 1;
    }
    
    // If no input, dash forward (up)
    if (dashDirection.length == 0) {
      dashDirection = Vector2(0, -1);
    }
    
    dashDirection.normalize();
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    abilityTarget = position + dashDirection * scaledRange;
    
    // Constrain ability target to arena
    abilityTarget!.x = abilityTarget!.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    abilityTarget!.y = abilityTarget!.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
    
    isUsingAbility = true;
  }
  
  void _executePiercingShot() {
    // Play sound effect for triangle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Find direction to nearest enemy or shoot forward
    Vector2 direction = Vector2(0, -1); // Default forward
    
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      direction = (nearestEnemy.position - position).normalized();
    }
    
    // Create massive triangle projectile with hero color and range scaling
    final projectile = TriangleProjectile(
      startPosition: position.clone(),
      direction: direction,
      speed: 500.0 * DisplayConfig.instance.scaleFactor,
      damage: heroData.ability.damage,
      isEnemyProjectile: false,
      heroColor: heroData.color, // Pass hero color
      rangeMultiplier: rangeMultiplier, // Scale with range upgrades
    );
    
    gameRef.add(projectile);
  }
  
  void _executeAreaStun() {
    // Play sound effect for square hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Calculate effective range (now has range limitation)
    final effectiveRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final stunDuration = heroData.ability.stunDuration ?? 3.0;
    
    // Create visual effect for the ability
    _createSquareAbilityEffect(effectiveRange);
    
    // Stun enemies within range
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= effectiveRange) {
          // Apply stun effect to different enemy types
          if (enemy is EnemyChaser) {
            enemy.stun(stunDuration);
          } else if (enemy is EnemyShooter) {
            enemy.stun(stunDuration);
          } else if (enemy is ShieldedChaser) {
            enemy.stun(stunDuration);
            // Also instantly break shield with ability damage
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          }
        }
      }
    }
    
    // Stun enemy projectiles within range
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= effectiveRange) {
          // Check if it's an enemy projectile and apply slow effect (stun)
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectile.applySlowEffect(0.0); // 0 speed = stunned
          }
        }
      }
    }
    
    print('Shield Bash! Stunned enemies within ${effectiveRange.toInt()} range for ${stunDuration}s');
  }
  
  void _executeRadialBurst() {
    // Play sound effect for pentagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Fire projectiles in all directions
    final projectileCount = heroData.ability.projectileCount ?? 5;
    final angleStep = (2 * pi) / projectileCount;
    
    for (int i = 0; i < projectileCount; i++) {
      final angle = i * angleStep;
      final direction = Vector2(cos(angle), sin(angle));
      
      // Create scaled projectile based on range multiplier
      final scaledRadius = 6.0 * DisplayConfig.instance.scaleFactor * rangeMultiplier;
      
      final projectile = Projectile(
        startPosition: position.clone(),
        direction: direction,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: heroData.ability.damage,
        isEnemyProjectile: false,
        heroColor: heroData.color,
        scaledRadius: scaledRadius, // Pass scaled radius for bullet size
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _executeAreaField() {
    // Play sound effect for hexagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Create visual hex field effect
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final duration = heroData.ability.duration ?? 4.0;
    
    final hexField = HexField(
      position: position.clone(),
      radius: scaledRange,
      duration: duration,
      damage: heroData.ability.damage,
      slowPercent: heroData.ability.slowPercent ?? 0.3,
    );
    
    gameRef.add(hexField);
  }
  
  void _executeResonanceKnockback() {
    // Play sound effect for heptagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final knockbackDistance = (heroData.ability.knockbackDistance ?? 30.0) * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    
    // Create visual effect for the ability
    _createHeptagonAbilityEffect(scaledRange);
    
    // Find enemies within range and apply damage + knockback
    final enemiesToKnockback = <Component>[];
    final projectilesToPush = <Component>[];
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= scaledRange) {
          enemiesToKnockback.add(enemy);
        }
      }
    }
    
    // Find enemy projectiles within range to push away and stun them
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= scaledRange) {
          // Check if it's an enemy projectile
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectilesToPush.add(projectile);
          }
        }
      }
    }
    
    // Apply damage and knockback to all enemies in range
    for (final enemy in enemiesToKnockback) {
      if (enemy is PositionComponent) {
        // Apply damage
        if (enemy is EnemyChaser) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is EnemyShooter) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is ShieldedChaser) {
          enemy.takeDamage(heroData.ability.damage, isAbility: true);
        }
        
        // Apply knockback
        final directionToEnemy = (enemy.position - position).normalized();
        final knockbackTarget = enemy.position + directionToEnemy * knockbackDistance;
        
        // Constrain knockback target to arena bounds
        final constrainedTarget = Vector2(
          knockbackTarget.x.clamp(50.0, DisplayConfig.instance.arenaWidth - 50.0),
          knockbackTarget.y.clamp(50.0, DisplayConfig.instance.arenaHeight - 50.0),
        );
        
        enemy.position = constrainedTarget;
      }
    }
    
    // Push away enemy projectiles
    for (final projectile in projectilesToPush) {
      if (projectile is PositionComponent) {
        final directionToProjectile = (projectile.position - position).normalized();
        final pushTarget = projectile.position + directionToProjectile * knockbackDistance;
        
        // Constrain push target to arena bounds
        final constrainedTarget = Vector2(
          pushTarget.x.clamp(0.0, DisplayConfig.instance.arenaWidth),
          pushTarget.y.clamp(0.0, DisplayConfig.instance.arenaHeight),
        );
        
        projectile.position = constrainedTarget;
      }
    }
    
    // Visual feedback
    print('Resonance Knockback! Hit ${enemiesToKnockback.length} enemies and pushed ${projectilesToPush.length} projectiles');
  }
  
  void _updateAbilityCooldownDisplay() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final timeSinceLastAbility = currentTime - lastAbilityTime;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    final cooldownPercent = (timeSinceLastAbility / effectiveCooldown).clamp(0.0, 1.0);
    final remainingSeconds = (effectiveCooldown - timeSinceLastAbility).clamp(0.0, effectiveCooldown);
    
    if (gameRef.hud.isMounted) {
      gameRef.hud.updateAbilityCooldown(cooldownPercent, remainingSeconds);
    }
  }
  
  void _constrainToArena() {
    position.x = position.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    position.y = position.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    
    // Handle universal escape key navigation
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      // Check if stats overlay is visible and hide it first
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
        return true;
      }
      
      // Check if shop is open and close it
      if (gameRef.gameState == GameState.shopping) {
        gameRef.onShopClosed();
        return true;
      }
      
      // Handle pause/resume for playing state
      if (gameRef.gameState == GameState.playing) {
        gameRef.pauseGame();
        return true;
      } else if (gameRef.gameState == GameState.paused) {
        gameRef.resumeGame();
        return true;
      }
    }
    
    // Handle ability (K key only)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyK) {
      _tryAbility();
      return true;
    }
    
    // Handle clone activation with 'C' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (canActivateClone()) {
        activateClone();
      }
      return true;
    }
    
    // Handle stats overlay toggle with 'I' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyI) {
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
      } else {
        gameRef.statsOverlay.show();
      }
      return true;
    }
    
    return false;
  }
  
  void takeDamage(double damage) {
    if (isInvincible || isDamageInvincible || isUsingAbility) {
      return; // No damage while invincible, damage invincible, or using ability
    }
    
    double remainingDamage = damage;
    
    // Shield absorbs damage first
    if (shield > 0) {
      if (shield >= remainingDamage) {
        // Shield absorbs all damage
        shield -= remainingDamage;
        remainingDamage = 0;
      } else {
        // Shield absorbs partial damage and breaks
        remainingDamage -= shield;
        shield = 0;
        
        // Remove shield effect when shield is broken
        if (hasTemporaryEffect('shield')) {
          print('Shield broken! Removing shield effect.');
          _removeEffectImmediate('shield');
          _temporaryEffects.remove('shield');
        }
      }
    }
    
    // Apply remaining damage to health
    if (remainingDamage > 0) {
      health = (health - remainingDamage).clamp(0, maxHealth);
    }
    
    // Activate damage invincibility
    isDamageInvincible = true;
    damageInvincibilityTimer = 0.0;
    
    if (health <= 0) {
      gameRef.onHeroDeath();
    }
  }
  
  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
  
  void addCoins(int amount) {
    final multiplier = totalCoinMultiplier;
    final finalAmount = (amount * multiplier).round();
    coins += finalAmount;
    if (multiplier > 1.0) {
      print('Coin Magnet: ${amount} -> ${finalAmount} coins (${multiplier}x)');
    }
  }
  
  void spendCoins(int amount) {
    coins = max(0, coins - amount);
  }
  
  void activateInvincibility() {
    isInvincible = true;
    invincibilityTimer = invincibilityDuration;
  }
  
  void _createSquareAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'square',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  void _createHeptagonAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'heptagon',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  // Temporary effects system - only one effect at a time
  void applyTemporaryEffect(String effectType, double value, double duration) {
    // Remove any existing effect first (only one at a time)
    if (_temporaryEffects.isNotEmpty) {
      final oldEffect = _temporaryEffects.entries.first;
      _removeEffectImmediate(oldEffect.key);
      _temporaryEffects.clear();
      print('Replaced effect: ${oldEffect.key} -> $effectType');
    }
    
    // Apply new effect
    _temporaryEffects[effectType] = TemporaryEffect(
      type: effectType,
      value: value,
      duration: duration,
    );
    
    // Apply immediate effects
    _applyEffectImmediate(effectType, value);
    
    print('Applied temporary effect: $effectType (${value}, ${duration}s)');
  }
  
  void _updateTemporaryEffects(double dt) {
    final expiredEffects = <String>[];
    
    for (final entry in _temporaryEffects.entries) {
      final effect = entry.value;
      effect.update(dt);
      
      if (effect.isExpired) {
        expiredEffects.add(entry.key);
        _removeEffectImmediate(entry.key);
      } else {
        // Apply ongoing effects
        _applyEffectOngoing(effect.type, effect.value, dt);
      }
    }
    
    // Remove expired effects
    for (final effectType in expiredEffects) {
      _temporaryEffects.remove(effectType);
    }
  }
  
  void _applyEffectImmediate(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
        speedMultiplier *= (1.0 + value);
        break;
      case 'damage_boost':
        // This will be applied in damage calculations
        break;
      case 'shield':
        shield += value;
        maxShield = maxShield > shield ? maxShield : shield;
        break;
      case 'invincibility':
        isInvincible = true;
        invincibilityTimer = 0.0;
        break;
      case 'weapon_overclock':
        attackSpeedMultiplier *= (1.0 + value);
        break;
    }
  }
  
  void _applyEffectOngoing(String effectType, double value, double dt) {
    switch (effectType) {
      case 'health_regen':
        heal(value * dt);
        break;
    }
  }
  
  void _removeEffectImmediate(String effectType) {
    switch (effectType) {
      case 'speed_boost':
        // Note: This is a simplified approach. In a full implementation,
        // you'd want to track the original multiplier and restore it
        speedMultiplier = 1.0; // Reset to base
        break;
      case 'damage_boost':
        // Reset damage multiplier
        break;
      case 'shield':
        // Shield naturally decays over time
        break;
      case 'invincibility':
        // Invincibility expires naturally
        break;
      case 'weapon_overclock':
        // Reset attack speed multiplier
        attackSpeedMultiplier = 1.0; // Reset to base
        break;
    }
  }
  
  // Get effective damage multiplier including temporary effects
  double get effectiveDamageMultiplier {
    double multiplier = 1.0;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'damage_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Get effective speed multiplier including temporary effects
  double get effectiveSpeedMultiplier {
    double multiplier = speedMultiplier;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'speed_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Check if hero has a specific temporary effect
  bool hasTemporaryEffect(String effectType) {
    return _temporaryEffects.containsKey(effectType);
  }
  
  // Get remaining time for a temporary effect
  double getTemporaryEffectTime(String effectType) {
    final effect = _temporaryEffects[effectType];
    return effect?.remainingTime ?? 0.0;
  }
  
  // Get current active effect for UI display
  TemporaryEffect? get currentActiveEffect {
    return _temporaryEffects.isNotEmpty ? _temporaryEffects.values.first : null;
  }
  
  // Get current active effect info as a formatted string
  String get activeEffectDisplay {
    final effect = currentActiveEffect;
    if (effect == null) return 'None';
    
    final effectName = _getEffectDisplayName(effect.type);
    final effectValue = _getEffectDisplayValue(effect.type, effect.value);
    
    // Handle infinite duration effects (like persistent shields)
    if (effect.remainingTime.isInfinite || effect.remainingTime.isNaN) {
      return '$effectName $effectValue (∞)';
    }
    
    final timeLeft = effect.remainingTime.ceil();
    return '$effectName $effectValue (${timeLeft}s)';
  }
  
  String _getEffectDisplayName(String effectType) {
    switch (effectType) {
      case 'speed_boost': return 'Speed';
      case 'damage_boost': return 'Damage';
      case 'health_regen': return 'Regen';
      case 'shield': return 'Shield';
      case 'invincibility': return 'Invul';
      case 'weapon_overclock': return 'Overclock';
      default: return effectType;
    }
  }
  
  String _getEffectDisplayValue(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
      case 'damage_boost':
      case 'weapon_overclock':
        return '+${(value * 100).round()}%';
      case 'health_regen':
        return '+${value.round()}/s';
      case 'shield':
        return '+${value.round()}';
      case 'invincibility':
        return 'ON';
      default:
        return value.toString();
    }
  }

  // Stackable passive effects system
  void addPassiveEffect(String effectType, int maxStacks) {
    final currentStacks = _passiveEffectStacks[effectType] ?? 0;
    if (currentStacks < maxStacks) {
      _passiveEffectStacks[effectType] = currentStacks + 1;
      print('Added passive effect: $effectType (${currentStacks + 1}/$maxStacks stacks)');
    } else {
      print('Cannot add $effectType: already at max stacks ($maxStacks)');
    }
  }
  
  int getPassiveEffectStacks(String effectType) {
    return _passiveEffectStacks[effectType] ?? 0;
  }
  
  bool hasPassiveEffect(String effectType) {
    return _passiveEffectStacks.containsKey(effectType) && _passiveEffectStacks[effectType]! > 0;
  }
  
  // Get calculated values based on passive effects
  int get totalProjectileCount {
    return 1 + getPassiveEffectStacks('projectile_count');
  }
  
  int get totalProjectileBounces {
    return getPassiveEffectStacks('projectile_bounces');
  }
  
  double get totalProjectileSize {
    final regularSize = 1.0 + (getPassiveEffectStacks('projectile_size') * 0.5); // 50% increase per stack
    final enlargedSize = 1.0 + (getPassiveEffectStacks('enlarged_caliber') * 0.1); // 10% increase per stack
    return regularSize * enlargedSize;
  }
  
  double get characterSizeMultiplier {
    return 1.0 + (getPassiveEffectStacks('enlarged_caliber') * 0.1);
  }
  
  double get enlargedCaliberSpeedPenalty {
    return getPassiveEffectStacks('enlarged_caliber') * 0.25;
  }
  
  int get totalDroneCount {
    return getPassiveEffectStacks('drone_count');
  }
  
  double get totalLifeSteal {
    return getPassiveEffectStacks('life_steal') * 0.05;
  }
  
  double get totalShieldHP {
    return getPassiveEffectStacks('shield_hp') * 5.0;
  }
  
  double get totalCoinMultiplier {
    return 1.0 + (getPassiveEffectStacks('coin_multiplier') * 0.2);
  }
  
  double get totalHealPerKill {
    return getPassiveEffectStacks('heal_per_kill') * 2.0;
  }
  
  double get totalCritChance {
    return getPassiveEffectStacks('crit_chance') * 0.02;
  }
  
  double get totalMaxHealthBoost {
    return getPassiveEffectStacks('max_health_boost') * 10.0;
  }
  
  bool get hasCloneProjection {
    return hasPassiveEffect('clone_spawn');
  }
  
  void resetPassiveEffects() {
    _passiveEffectStacks.clear();
    killCount = 0;
    destroyAllDrones();
    destroyClone();
  }
  
  // Apply heal per kill effect when an enemy is defeated
  void onEnemyKilled() {
    killCount++;
    
    final healAmount = totalHealPerKill;
    if (healAmount > 0) {
      heal(healAmount);
      print('Healed ${healAmount} HP from kill');
    }
    
    // Handle kill-based max health boost (Auto Injector)
    final autoInjectorStacks = getPassiveEffectStacks('kill_based_max_health');
    if (autoInjectorStacks > 0 && killCount % 10 == 0) {
      final maxHealthIncrease = autoInjectorStacks * 2.0; // 2 HP per stack
      final currentBonus = (killCount ~/ 10) * maxHealthIncrease;
      final maxBonus = autoInjectorStacks * 50.0; // 50 HP max per stack
      
      if (currentBonus <= maxBonus) {
        maxHealth += maxHealthIncrease;
        health += maxHealthIncrease; // Also heal current HP
        print('Auto Injector: +${maxHealthIncrease} max HP from ${killCount} kills');
      }
    }
  }
  
  // Regenerate shields between waves (Armor Plating effect)
  void regenerateShields() {
    final armorShields = totalShieldHP;
    if (armorShields > 0) {
      // Apply armor plating as a persistent shield effect
      applyTemporaryEffect('shield', armorShields, double.infinity);
      print('Armor plating shields regenerated to ${armorShields.toStringAsFixed(1)} HP');
    }
  }
  
  // Drone management system
  void updateDroneCount() {
    final targetDroneCount = totalDroneCount;
    final currentDroneCount = _activeDrones.length;
    
    if (targetDroneCount > currentDroneCount) {
      // Spawn new drones
      for (int i = currentDroneCount; i < targetDroneCount; i++) {
        final drone = DroneWingman(owner: this, droneIndex: i);
        _activeDrones.add(drone);
        gameRef.add(drone);
        print('Spawned drone ${i + 1}/${targetDroneCount}');
      }
    } else if (targetDroneCount < currentDroneCount) {
      // Remove excess drones
      while (_activeDrones.length > targetDroneCount) {
        final drone = _activeDrones.removeLast();
        drone.destroy();
        print('Removed drone. Remaining: ${_activeDrones.length}');
      }
    }
  }
  
  void destroyAllDrones() {
    for (final drone in _activeDrones) {
      drone.destroy();
    }
    _activeDrones.clear();
    print('All drones destroyed');
  }
  
  // Clone management system
  bool canActivateClone() {
    return hasCloneProjection && _activeClone == null && health > maxHealth * 0.5;
  }
  
  void activateClone() {
    print('🤖 Attempting to activate clone...');
    print('   - Has clone projection: ${hasCloneProjection}');
    print('   - No active clone: ${_activeClone == null}');
    print('   - Current health: ${health.toStringAsFixed(1)}/${maxHealth.toStringAsFixed(1)}');
    print('   - Required health: ${(maxHealth * 0.5).toStringAsFixed(1)}');
    
    if (!canActivateClone()) {
      print('❌ Cannot activate clone: requirements not met');
      return;
    }
    
    // Pay health cost (50% of current health)
    final healthCost = health * 0.5;
    health -= healthCost;
    
    // Spawn clone directly to the right with clear gap
    final cloneOffset = Vector2(80, 0); // Simple fixed offset to the right
    final clonePosition = position + cloneOffset;
    
    print('🤖 Creating HeroClone at position: (${clonePosition.x}, ${clonePosition.y})');
    _activeClone = HeroClone(owner: this, spawnPosition: clonePosition);
    
    print('🤖 Adding clone to game...');
    gameRef.add(_activeClone!);
    
    print('✅ CLONE ACTIVATED! Health cost: ${healthCost.toStringAsFixed(1)}, Clone mounted: ${_activeClone!.isMounted}');
  }
  
  void destroyClone() {
    if (_activeClone != null) {
      _activeClone!.destroy();
      _activeClone = null;
      print('Clone destroyed');
    }
  }
  
  bool get hasActiveClone => _activeClone != null;
  
  // Getter for passive effect stacks (for stats display)
  Map<String, int> get passiveEffectStacks => Map.from(_passiveEffectStacks);
  
  void onCloneDestroyed(HeroClone clone) {
    if (_activeClone == clone) {
      _activeClone = null;
      print('Active clone reference cleared');
    }
  }
}

// Visual effect component for abilities
class AbilityVisualEffect extends PositionComponent with HasGameRef<CircleRougeGame> {
  final double effectRange;
  final String shape;
  final Color color;
  
  double lifetime = 0.0;
  static const double totalLifetime = 0.5; // Blink once and disappear
  static const double blinkDuration = 0.25; // Half the lifetime for one blink
  
  AbilityVisualEffect({
    required Vector2 position,
    required this.effectRange,
    required this.shape,
    required this.color,
  }) : super(
    position: position,
    size: Vector2.all(effectRange * 2),
    anchor: Anchor.center,
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    lifetime += dt;
    
    // Remove after total lifetime
    if (lifetime >= totalLifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Calculate opacity with blinking effect
    final blinkProgress = (lifetime / blinkDuration) % 1.0;
    final opacity = (sin(blinkProgress * pi * 2) * 0.15 + 0.1).clamp(0.0, 0.25); // 25% max opacity
    
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = color.withOpacity(opacity * 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Draw the shape based on type
    switch (shape) {
      case 'square':
        final rect = Rect.fromCenter(
          center: center,
          width: effectRange * 2,
          height: effectRange * 2,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;
      case 'heptagon':
        final path = _createHeptagonPath(center, effectRange);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }
  
  Path _createHeptagonPath(Offset center, double radius) {
    final path = Path();
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * pi / 180);
      final y = center.dy + radius * sin(angle * pi / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    return path;
  }
} 
```

I also need to update the shapeSize in the render method to use the character size multiplier:

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/circle_rouge_game.dart';
import '../config/hero_config.dart';
import '../config/display_config.dart';
import 'abilities/hex_field.dart';
import 'enemies/enemy_chaser.dart';
import 'enemies/enemy_shooter.dart';
import 'enemies/shielded_chaser.dart';
import 'enemies/projectile.dart';
import 'enemies/shape_projectile.dart';
import 'enemies/triangle_projectile.dart';
import 'sound_manager.dart';
import 'companions/drone_wingman.dart';
import 'companions/hero_clone.dart';

class TemporaryEffect {
  final String type;
  final double value;
  final double duration;
  double remainingTime;
  
  TemporaryEffect({
    required this.type,
    required this.value,
    required this.duration,
  }) : remainingTime = duration;
  
  void update(double dt) {
    remainingTime -= dt;
  }
  
  bool get isExpired => remainingTime <= 0;
}

class Hero extends PositionComponent with HasGameRef<CircleRougeGame>, KeyboardHandler {
  // Hero configuration
  late HeroData heroData;
  final String heroId;
  
  // Hero visual properties
  double get heroRadius => 15.0 * DisplayConfig.instance.scaleFactor * characterSizeMultiplier;
  late Paint heroPaint;
  
  // Base movement properties - will be scaled based on arena size
  static const double baseMoveSpeed = 200.0;
  
  // Base dash properties (for heroes that don't have special abilities)
  static const double baseDashDistance = 120.0;
  static const double baseDashSpeed = 500.0;
  
  // Base shooting properties
  static const double baseShootRange = 250.0;
  static const double fireRate = 2.0; // Shots per second
  double lastShotTime = 0.0;
  
  // Get scaled values based on arena size
  double get moveSpeed {
    final baseSpeed = (heroData.moveSpeed / 320.0 * baseMoveSpeed) * DisplayConfig.instance.scaleFactor;
    final speedPenalty = enlargedCaliberSpeedPenalty;
    return baseSpeed * (1.0 - speedPenalty);
  }
  double get dashDistance => baseDashDistance * DisplayConfig.instance.scaleFactor;
  double get dashSpeed => baseDashSpeed * DisplayConfig.instance.scaleFactor;
  double get shootRange => baseShootRange * DisplayConfig.instance.scaleFactor * rangeMultiplier;
  
  // Attack speed modifier (can be upgraded)
  double attackSpeedMultiplier = 1.0;
  
  // Movement speed modifier (can be upgraded)
  double speedMultiplier = 1.0;
  
  // Ability cooldown modifier (can be upgraded)
  double abilityCooldownMultiplier = 1.0;
  
  // Range modifier (can be upgraded)
  double rangeMultiplier = 1.0;
  
  // Weapon overclock visual effect
  // Weapon overclock now handled by temporary effect system
  
  // Ability system
  double lastAbilityTime = -double.infinity;
  bool isUsingAbility = false;
  Vector2? abilityTarget;
  
  // Hero stats
  double health = 100.0;
  double maxHealth = 100.0;
  double energy = 100.0;
  double maxEnergy = 100.0;
  int coins = 0;
  int killCount = 0;
  
  // Invincibility after wave completion
  bool isInvincible = false;
  double invincibilityTimer = 0.0;
  static const double invincibilityDuration = 3.0; // 3 seconds of invincibility
  
  // Damage invincibility (separate from wave completion invincibility)
  bool isDamageInvincible = false;
  double damageInvincibilityTimer = 0.0;
  static const double damageInvincibilityDuration = 0.5; // 0.5 seconds after taking damage
  
  // Temporary effects system
  final Map<String, TemporaryEffect> _temporaryEffects = {};
  
  // Stackable passive effects system
  final Map<String, int> _passiveEffectStacks = {};
  
  // Drone companion system
  final List<DroneWingman> _activeDrones = [];
  
  // Clone system
  HeroClone? _activeClone;
  
  // Shield system
  double shield = 0.0;
  double maxShield = 0.0;
  
  // Input tracking
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  
  Hero({required Vector2 position, required this.heroId}) : super(
    position: position,
    size: Vector2.all(30.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    heroPaint = Paint()..color = const Color(0xFF4CAF50);
    _initializeHero(heroId);
  }
  
  void _initializeHero(String heroId) {
    final heroConfig = HeroConfig.instance.getHeroById(heroId);
    if (heroConfig != null) {
      heroData = heroConfig;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    } else {
      // Fallback to default circle hero
      heroData = HeroConfig.instance.defaultHero;
      health = heroData.health;
      maxHealth = heroData.health;
      heroPaint.color = heroData.color;
    }
  }
  
  double get effectiveMaxHealth {
    return maxHealth + totalMaxHealthBoost;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Blinking effect during damage invincibility
    if (isDamageInvincible) {
      final blinkTime = (damageInvincibilityTimer * 8) % 1.0; // 8 blinks per second
      if (blinkTime > 0.5) {
        return; // Don't render during blink "off" phase
      }
    }
    
    final center = Offset(size.x / 2, size.y / 2);
    final shapeSize = size.x * characterSizeMultiplier;
    
    // Old weapon overclock glow removed - now handled by active effect glow
    
    // Active effect glow
    final activeEffect = currentActiveEffect;
    if (activeEffect != null) {
      final effectTime = (DateTime.now().millisecondsSinceEpoch / 1000.0) % 1.5; // 1.5-second cycle
      final glowIntensity = (sin(effectTime * pi * 2) * 0.3 + 0.7); // 0.4 to 1.0
      final glowRadius = 15.0 * glowIntensity;
      
      // Get effect color
      Color effectColor;
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
        default:
          effectColor = const Color(0xFFFFFFFF); // White fallback
      }
      
      final effectGlowPaint = Paint()
        ..color = effectColor.withOpacity(0.8 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      // Draw effect glow based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + glowRadius, effectGlowPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'square':
          _drawSquare(canvas, center, effectGlowPaint, glowRadius);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, effectGlowPaint, glowRadius);
          break;
      }
    }
    
    // Draw main hero shape
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(center, heroRadius, heroPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, shapeSize, heroPaint, 0);
        break;
      case 'square':
        _drawSquare(canvas, center, heroPaint, 0);
        break;
      case 'pentagon':
        _drawPentagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'hexagon':
        _drawHexagon(canvas, shapeSize, heroPaint, 0);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, shapeSize, heroPaint, 0);
        break;
    }
    
    // Draw shield outline if shield effect is active
    if (hasTemporaryEffect('shield') && shield > 0) {
      final shieldOpacity = (shield / maxShield).clamp(0.3, 1.0); // Fade as shield depletes
      final shieldPaint = Paint()
        ..color = const Color(0xFFFF9800).withOpacity(0.6 * shieldOpacity) // Orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Draw shield outline based on hero shape
      switch (heroData.shape) {
        case 'circle':
          canvas.drawCircle(center, heroRadius + 4, shieldPaint);
          break;
        case 'triangle':
          _drawTriangle(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'square':
          _drawSquare(canvas, center, shieldPaint, 4);
          break;
        case 'pentagon':
          _drawPentagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'hexagon':
          _drawHexagon(canvas, shapeSize, shieldPaint, 4);
          break;
        case 'heptagon':
          _drawHeptagon(canvas, shapeSize, shieldPaint, 4);
          break;
      }
    }
    
  }
  
  void _drawTriangle(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius / 2);
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius / 2);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSquare(Canvas canvas, Offset center, Paint paint, double glowRadius) {
    final size = (this.size.x * 0.8) + (glowRadius * 2);
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      ),
      paint,
    );
  }
  
  void _drawPentagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 5; i++) {
      final angle = -90 + (i * 72); // Pentagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHexagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 6; i++) {
      final angle = -90 + (i * 60); // Hexagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHeptagon(Canvas canvas, double shapeSize, Paint paint, double glowRadius) {
    final path = Path();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (shapeSize * 0.4) + glowRadius;
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * 3.14159 / 180);
      final y = center.dy + radius * sin(angle * 3.14159 / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  // Collision detection method for other components to use
  @override
  bool containsPoint(Vector2 point) {
    final distance = position.distanceTo(point);
    return distance <= heroRadius;
  }
  
  // Get collision radius for enemy collision detection
  double get collisionRadius => heroRadius;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Weapon overclock now handled by temporary effect system
    
    // Update invincibility timer
    if (isInvincible) {
      invincibilityTimer += dt;
      if (invincibilityTimer >= invincibilityDuration) {
        isInvincible = false;
        invincibilityTimer = 0.0;
      }
    }
    
    // Update damage invincibility timer
    if (isDamageInvincible) {
      damageInvincibilityTimer += dt;
      if (damageInvincibilityTimer >= damageInvincibilityDuration) {
        isDamageInvincible = false;
        damageInvincibilityTimer = 0.0;
      }
    }
    
    // Update temporary effects
    _updateTemporaryEffects(dt);
    
    if (isUsingAbility) {
      _updateAbility(dt);
    } else {
      _updateMovement(dt);
    }
    
    // Auto-shoot at enemies
    _tryAutoShoot();
    
    // Regenerate energy
    if (energy < maxEnergy) {
      energy = (energy + 50 * dt).clamp(0, maxEnergy);
    }
    
    // Keep hero within arena bounds
    _constrainToArena();
    
    // Update ability cooldown in HUD
    _updateAbilityCooldownDisplay();
  }
  
  void _tryAutoShoot() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    if (currentTime - lastShotTime < (1.0 / (fireRate * attackSpeedMultiplier))) {
      return; // Still on cooldown
    }
    
    // Find nearest enemy
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance && distance <= shootRange) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    // Shoot at nearest enemy if found
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      final direction = (nearestEnemy.position - position).normalized();
      _fireProjectile(direction);
      lastShotTime = currentTime;
    }
  }
  
  void _fireProjectile(Vector2 direction) {
    final projectileCount = totalProjectileCount;
    final projectileBounces = totalProjectileBounces;
    final projectileScale = totalProjectileSize;
    final critChance = totalCritChance;
    
    // Calculate spread angle if multiple projectiles
    final spreadAngle = projectileCount > 1 ? pi / 6 : 0.0; // 30 degrees total spread
    final angleStep = projectileCount > 1 ? spreadAngle / (projectileCount - 1) : 0.0;
    final startAngle = projectileCount > 1 ? -spreadAngle / 2 : 0.0;
    
    for (int i = 0; i < projectileCount; i++) {
      // Calculate direction for each projectile
      Vector2 projectileDirection;
      if (projectileCount == 1) {
        projectileDirection = direction;
      } else {
        final angle = startAngle + (i * angleStep);
        final baseAngle = atan2(direction.y, direction.x);
        final newAngle = baseAngle + angle;
        projectileDirection = Vector2(cos(newAngle), sin(newAngle));
      }
      
      // Check for critical hit (now instant kill, so damage doesn't matter)
      final isCritical = Random().nextDouble() < critChance;
      final finalDamage = 25.0; // Base damage (critical = instant kill)
      
      final projectile = ShapeProjectile(
        startPosition: position.clone(),
        direction: projectileDirection,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: finalDamage,
        isEnemyProjectile: false,
        shapeType: heroData.shape,
        heroColor: heroData.color,
        bounces: projectileBounces,
        sizeScale: projectileScale,
        isCritical: isCritical,
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _updateMovement(double dt) {
    Vector2 inputDirection = Vector2.zero();
    
    // Handle WASD movement
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      inputDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      inputDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      inputDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      inputDirection.x += 1;
    }
    
    // Normalize and apply movement
    if (inputDirection.length > 0) {
      inputDirection.normalize();
      position += inputDirection * moveSpeed * effectiveSpeedMultiplier * dt;
    }
  }
  
  void _updateAbility(double dt) {
    // Handle different ability types based on hero configuration
    switch (heroData.ability.type) {
      case 'dash_damage':
        _updateDashDamage(dt);
        break;
      case 'piercing_shot':
        // Piercing shot is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_stun':
        // Area stun is instant, no update needed
        isUsingAbility = false;
        break;
      case 'radial_burst':
        // Radial burst is instant, no update needed
        isUsingAbility = false;
        break;
      case 'area_field':
        // Area field is instant placement, no update needed
        isUsingAbility = false;
        break;
      default:
        isUsingAbility = false;
    }
  }
  
  void _updateDashDamage(double dt) {
    if (abilityTarget == null) {
      isUsingAbility = false;
      return;
    }
    
    final direction = (abilityTarget! - position).normalized();
    final movement = direction * dashSpeed * dt;
    
    // Check for enemy collisions during dash
    // Create a copy to avoid ConcurrentModificationError
    final enemiesCopy = List<Component>.from(gameRef.currentEnemies);
    for (final enemy in enemiesCopy) {
      if (enemy is PositionComponent) {
        final distanceToEnemy = position.distanceTo(enemy.position);
        // Use different radius checks for different enemy types
        double enemyRadius = 15.0 * DisplayConfig.instance.scaleFactor; // Default radius
        
        if (enemy is EnemyChaser) {
          enemyRadius = enemy.radius;
        } else if (enemy is EnemyShooter) {
          enemyRadius = enemy.radius;
        } else if (enemy is ShieldedChaser) {
          enemyRadius = enemy.radius;
        }
        
        if (distanceToEnemy < heroRadius + enemyRadius) {
          // Damage enemy during rolling surge
          if (enemy is EnemyChaser) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is EnemyShooter) {
            enemy.takeDamage(heroData.ability.damage);
          } else if (enemy is ShieldedChaser) {
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          } else {
            // Fallback for other enemy types - remove them directly
            if (enemy.parent != null) {
              gameRef.onEnemyDestroyed(enemy);
            }
          }
        }
      }
    }
    
    if (position.distanceTo(abilityTarget!) <= movement.length) {
      position = abilityTarget!;
      isUsingAbility = false;
      abilityTarget = null;
    } else {
      position += movement;
    }
  }
  
  void _tryAbility() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    
    if (currentTime - lastAbilityTime < effectiveCooldown || energy < 25) {
      return; // Ability on cooldown or not enough energy
    }
    
    switch (heroData.ability.type) {
      case 'dash_damage':
        _executeDashDamage();
        break;
      case 'piercing_shot':
        _executePiercingShot();
        break;
      case 'area_stun':
        _executeAreaStun();
        break;
      case 'radial_burst':
        _executeRadialBurst();
        break;
      case 'area_field':
        _executeAreaField();
        break;
      case 'resonance_knockback':
        _executeResonanceKnockback();
        break;
    }
    
    lastAbilityTime = currentTime;
    energy -= 25; // Ability costs energy
  }
  
  void _executeDashDamage() {
    // Play sound effect for circle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Get current input direction for rolling surge
    Vector2 dashDirection = Vector2.zero();
    
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dashDirection.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dashDirection.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dashDirection.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dashDirection.x += 1;
    }
    
    // If no input, dash forward (up)
    if (dashDirection.length == 0) {
      dashDirection = Vector2(0, -1);
    }
    
    dashDirection.normalize();
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    abilityTarget = position + dashDirection * scaledRange;
    
    // Constrain ability target to arena
    abilityTarget!.x = abilityTarget!.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    abilityTarget!.y = abilityTarget!.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
    
    isUsingAbility = true;
  }
  
  void _executePiercingShot() {
    // Play sound effect for triangle hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Find direction to nearest enemy or shoot forward
    Vector2 direction = Vector2(0, -1); // Default forward
    
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      direction = (nearestEnemy.position - position).normalized();
    }
    
    // Create massive triangle projectile with hero color and range scaling
    final projectile = TriangleProjectile(
      startPosition: position.clone(),
      direction: direction,
      speed: 500.0 * DisplayConfig.instance.scaleFactor,
      damage: heroData.ability.damage,
      isEnemyProjectile: false,
      heroColor: heroData.color, // Pass hero color
      rangeMultiplier: rangeMultiplier, // Scale with range upgrades
    );
    
    gameRef.add(projectile);
  }
  
  void _executeAreaStun() {
    // Play sound effect for square hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Calculate effective range (now has range limitation)
    final effectiveRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final stunDuration = heroData.ability.stunDuration ?? 3.0;
    
    // Create visual effect for the ability
    _createSquareAbilityEffect(effectiveRange);
    
    // Stun enemies within range
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= effectiveRange) {
          // Apply stun effect to different enemy types
          if (enemy is EnemyChaser) {
            enemy.stun(stunDuration);
          } else if (enemy is EnemyShooter) {
            enemy.stun(stunDuration);
          } else if (enemy is ShieldedChaser) {
            enemy.stun(stunDuration);
            // Also instantly break shield with ability damage
            enemy.takeDamage(heroData.ability.damage, isAbility: true);
          }
        }
      }
    }
    
    // Stun enemy projectiles within range
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= effectiveRange) {
          // Check if it's an enemy projectile and apply slow effect (stun)
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectile.applySlowEffect(0.0); // 0 speed = stunned
          }
        }
      }
    }
    
    print('Shield Bash! Stunned enemies within ${effectiveRange.toInt()} range for ${stunDuration}s');
  }
  
  void _executeRadialBurst() {
    // Play sound effect for pentagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Fire projectiles in all directions
    final projectileCount = heroData.ability.projectileCount ?? 5;
    final angleStep = (2 * pi) / projectileCount;
    
    for (int i = 0; i < projectileCount; i++) {
      final angle = i * angleStep;
      final direction = Vector2(cos(angle), sin(angle));
      
      // Create scaled projectile based on range multiplier
      final scaledRadius = 6.0 * DisplayConfig.instance.scaleFactor * rangeMultiplier;
      
      final projectile = Projectile(
        startPosition: position.clone(),
        direction: direction,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: heroData.ability.damage,
        isEnemyProjectile: false,
        heroColor: heroData.color,
        scaledRadius: scaledRadius, // Pass scaled radius for bullet size
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _executeAreaField() {
    // Play sound effect for hexagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Create visual hex field effect
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final duration = heroData.ability.duration ?? 4.0;
    
    final hexField = HexField(
      position: position.clone(),
      radius: scaledRange,
      duration: duration,
      damage: heroData.ability.damage,
      slowPercent: heroData.ability.slowPercent ?? 0.3,
    );
    
    gameRef.add(hexField);
  }
  
  void _executeResonanceKnockback() {
    // Play sound effect for heptagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    final scaledRange = heroData.ability.range * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    final knockbackDistance = (heroData.ability.knockbackDistance ?? 30.0) * DisplayConfig.instance.scaleFactor * rangeMultiplier;
    
    // Create visual effect for the ability
    _createHeptagonAbilityEffect(scaledRange);
    
    // Find enemies within range and apply damage + knockback
    final enemiesToKnockback = <Component>[];
    final projectilesToPush = <Component>[];
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= scaledRange) {
          enemiesToKnockback.add(enemy);
        }
      }
    }
    
    // Find enemy projectiles within range to push away and stun them
    for (final projectile in gameRef.currentProjectiles) {
      if (projectile is PositionComponent) {
        final distance = position.distanceTo(projectile.position);
        if (distance <= scaledRange) {
          // Check if it's an enemy projectile
          if (projectile is Projectile && projectile.isEnemyProjectile) {
            projectilesToPush.add(projectile);
          }
        }
      }
    }
    
    // Apply damage and knockback to all enemies in range
    for (final enemy in enemiesToKnockback) {
      if (enemy is PositionComponent) {
        // Apply damage
        if (enemy is EnemyChaser) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is EnemyShooter) {
          enemy.takeDamage(heroData.ability.damage);
        } else if (enemy is ShieldedChaser) {
          enemy.takeDamage(heroData.ability.damage, isAbility: true);
        }
        
        // Apply knockback
        final directionToEnemy = (enemy.position - position).normalized();
        final knockbackTarget = enemy.position + directionToEnemy * knockbackDistance;
        
        // Constrain knockback target to arena bounds
        final constrainedTarget = Vector2(
          knockbackTarget.x.clamp(50.0, DisplayConfig.instance.arenaWidth - 50.0),
          knockbackTarget.y.clamp(50.0, DisplayConfig.instance.arenaHeight - 50.0),
        );
        
        enemy.position = constrainedTarget;
      }
    }
    
    // Push away enemy projectiles
    for (final projectile in projectilesToPush) {
      if (projectile is PositionComponent) {
        final directionToProjectile = (projectile.position - position).normalized();
        final pushTarget = projectile.position + directionToProjectile * knockbackDistance;
        
        // Constrain push target to arena bounds
        final constrainedTarget = Vector2(
          pushTarget.x.clamp(0.0, DisplayConfig.instance.arenaWidth),
          pushTarget.y.clamp(0.0, DisplayConfig.instance.arenaHeight),
        );
        
        projectile.position = constrainedTarget;
      }
    }
    
    // Visual feedback
    print('Resonance Knockback! Hit ${enemiesToKnockback.length} enemies and pushed ${projectilesToPush.length} projectiles');
  }
  
  void _updateAbilityCooldownDisplay() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final timeSinceLastAbility = currentTime - lastAbilityTime;
    final effectiveCooldown = heroData.ability.cooldown * abilityCooldownMultiplier;
    final cooldownPercent = (timeSinceLastAbility / effectiveCooldown).clamp(0.0, 1.0);
    final remainingSeconds = (effectiveCooldown - timeSinceLastAbility).clamp(0.0, effectiveCooldown);
    
    if (gameRef.hud.isMounted) {
      gameRef.hud.updateAbilityCooldown(cooldownPercent, remainingSeconds);
    }
  }
  
  void _constrainToArena() {
    position.x = position.x.clamp(heroRadius, DisplayConfig.instance.arenaWidth - heroRadius);
    position.y = position.y.clamp(heroRadius, DisplayConfig.instance.arenaHeight - heroRadius);
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    
    // Handle universal escape key navigation
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      // Check if stats overlay is visible and hide it first
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
        return true;
      }
      
      // Check if shop is open and close it
      if (gameRef.gameState == GameState.shopping) {
        gameRef.onShopClosed();
        return true;
      }
      
      // Handle pause/resume for playing state
      if (gameRef.gameState == GameState.playing) {
        gameRef.pauseGame();
        return true;
      } else if (gameRef.gameState == GameState.paused) {
        gameRef.resumeGame();
        return true;
      }
    }
    
    // Handle ability (K key only)
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyK) {
      _tryAbility();
      return true;
    }
    
    // Handle clone activation with 'C' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (canActivateClone()) {
        activateClone();
      }
      return true;
    }
    
    // Handle stats overlay toggle with 'I' key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyI) {
      if (gameRef.statsOverlay.isVisible) {
        gameRef.statsOverlay.hide();
      } else {
        gameRef.statsOverlay.show();
      }
      return true;
    }
    
    return false;
  }
  
  void takeDamage(double damage) {
    if (isInvincible || isDamageInvincible || isUsingAbility) {
      return; // No damage while invincible, damage invincible, or using ability
    }
    
    double remainingDamage = damage;
    
    // Shield absorbs damage first
    if (shield > 0) {
      if (shield >= remainingDamage) {
        // Shield absorbs all damage
        shield -= remainingDamage;
        remainingDamage = 0;
      } else {
        // Shield absorbs partial damage and breaks
        remainingDamage -= shield;
        shield = 0;
        
        // Remove shield effect when shield is broken
        if (hasTemporaryEffect('shield')) {
          print('Shield broken! Removing shield effect.');
          _removeEffectImmediate('shield');
          _temporaryEffects.remove('shield');
        }
      }
    }
    
    // Apply remaining damage to health
    if (remainingDamage > 0) {
      health = (health - remainingDamage).clamp(0, maxHealth);
    }
    
    // Activate damage invincibility
    isDamageInvincible = true;
    damageInvincibilityTimer = 0.0;
    
    if (health <= 0) {
      gameRef.onHeroDeath();
    }
  }
  
  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
  
  void addCoins(int amount) {
    final multiplier = totalCoinMultiplier;
    final finalAmount = (amount * multiplier).round();
    coins += finalAmount;
    if (multiplier > 1.0) {
      print('Coin Magnet: ${amount} -> ${finalAmount} coins (${multiplier}x)');
    }
  }
  
  void spendCoins(int amount) {
    coins = max(0, coins - amount);
  }
  
  void activateInvincibility() {
    isInvincible = true;
    invincibilityTimer = invincibilityDuration;
  }
  
  void _createSquareAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'square',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  void _createHeptagonAbilityEffect(double effectiveRange) {
    final effect = AbilityVisualEffect(
      position: position.clone(),
      effectRange: effectiveRange,
      shape: 'heptagon',
      color: heroData.color,
    );
    gameRef.add(effect);
  }
  
  // Temporary effects system - only one effect at a time
  void applyTemporaryEffect(String effectType, double value, double duration) {
    // Remove any existing effect first (only one at a time)
    if (_temporaryEffects.isNotEmpty) {
      final oldEffect = _temporaryEffects.entries.first;
      _removeEffectImmediate(oldEffect.key);
      _temporaryEffects.clear();
      print('Replaced effect: ${oldEffect.key} -> $effectType');
    }
    
    // Apply new effect
    _temporaryEffects[effectType] = TemporaryEffect(
      type: effectType,
      value: value,
      duration: duration,
    );
    
    // Apply immediate effects
    _applyEffectImmediate(effectType, value);
    
    print('Applied temporary effect: $effectType (${value}, ${duration}s)');
  }
  
  void _updateTemporaryEffects(double dt) {
    final expiredEffects = <String>[];
    
    for (final entry in _temporaryEffects.entries) {
      final effect = entry.value;
      effect.update(dt);
      
      if (effect.isExpired) {
        expiredEffects.add(entry.key);
        _removeEffectImmediate(entry.key);
      } else {
        // Apply ongoing effects
        _applyEffectOngoing(effect.type, effect.value, dt);
      }
    }
    
    // Remove expired effects
    for (final effectType in expiredEffects) {
      _temporaryEffects.remove(effectType);
    }
  }
  
  void _applyEffectImmediate(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
        speedMultiplier *= (1.0 + value);
        break;
      case 'damage_boost':
        // This will be applied in damage calculations
        break;
      case 'shield':
        shield += value;
        maxShield = maxShield > shield ? maxShield : shield;
        break;
      case 'invincibility':
        isInvincible = true;
        invincibilityTimer = 0.0;
        break;
      case 'weapon_overclock':
        attackSpeedMultiplier *= (1.0 + value);
        break;
    }
  }
  
  void _applyEffectOngoing(String effectType, double value, double dt) {
    switch (effectType) {
      case 'health_regen':
        heal(value * dt);
        break;
    }
  }
  
  void _removeEffectImmediate(String effectType) {
    switch (effectType) {
      case 'speed_boost':
        // Note: This is a simplified approach. In a full implementation,
        // you'd want to track the original multiplier and restore it
        speedMultiplier = 1.0; // Reset to base
        break;
      case 'damage_boost':
        // Reset damage multiplier
        break;
      case 'shield':
        // Shield naturally decays over time
        break;
      case 'invincibility':
        // Invincibility expires naturally
        break;
      case 'weapon_overclock':
        // Reset attack speed multiplier
        attackSpeedMultiplier = 1.0; // Reset to base
        break;
    }
  }
  
  // Get effective damage multiplier including temporary effects
  double get effectiveDamageMultiplier {
    double multiplier = 1.0;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'damage_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Get effective speed multiplier including temporary effects
  double get effectiveSpeedMultiplier {
    double multiplier = speedMultiplier;
    for (final effect in _temporaryEffects.values) {
      if (effect.type == 'speed_boost') {
        multiplier *= (1.0 + effect.value);
      }
    }
    return multiplier;
  }
  
  // Check if hero has a specific temporary effect
  bool hasTemporaryEffect(String effectType) {
    return _temporaryEffects.containsKey(effectType);
  }
  
  // Get remaining time for a temporary effect
  double getTemporaryEffectTime(String effectType) {
    final effect = _temporaryEffects[effectType];
    return effect?.remainingTime ?? 0.0;
  }
  
  // Get current active effect for UI display
  TemporaryEffect? get currentActiveEffect {
    return _temporaryEffects.isNotEmpty ? _temporaryEffects.values.first : null;
  }
  
  // Get current active effect info as a formatted string
  String get activeEffectDisplay {
    final effect = currentActiveEffect;
    if (effect == null) return 'None';
    
    final effectName = _getEffectDisplayName(effect.type);
    final effectValue = _getEffectDisplayValue(effect.type, effect.value);
    
    // Handle infinite duration effects (like persistent shields)
    if (effect.remainingTime.isInfinite || effect.remainingTime.isNaN) {
      return '$effectName $effectValue (∞)';
    }
    
    final timeLeft = effect.remainingTime.ceil();
    return '$effectName $effectValue (${timeLeft}s)';
  }
  
  String _getEffectDisplayName(String effectType) {
    switch (effectType) {
      case 'speed_boost': return 'Speed';
      case 'damage_boost': return 'Damage';
      case 'health_regen': return 'Regen';
      case 'shield': return 'Shield';
      case 'invincibility': return 'Invul';
      case 'weapon_overclock': return 'Overclock';
      default: return effectType;
    }
  }
  
  String _getEffectDisplayValue(String effectType, double value) {
    switch (effectType) {
      case 'speed_boost':
      case 'damage_boost':
      case 'weapon_overclock':
        return '+${(value * 100).round()}%';
      case 'health_regen':
        return '+${value.round()}/s';
      case 'shield':
        return '+${value.round()}';
      case 'invincibility':
        return 'ON';
      default:
        return value.toString();
    }
  }

  // Stackable passive effects system
  void addPassiveEffect(String effectType, int maxStacks) {
    final currentStacks = _passiveEffectStacks[effectType] ?? 0;
    if (currentStacks < maxStacks) {
      _passiveEffectStacks[effectType] = currentStacks + 1;
      print('Added passive effect: $effectType (${currentStacks + 1}/$maxStacks stacks)');
    } else {
      print('Cannot add $effectType: already at max stacks ($maxStacks)');
    }
  }
  
  int getPassiveEffectStacks(String effectType) {
    return _passiveEffectStacks[effectType] ?? 0;
  }
  
  bool hasPassiveEffect(String effectType) {
    return _passiveEffectStacks.containsKey(effectType) && _passiveEffectStacks[effectType]! > 0;
  }
  
  // Get calculated values based on passive effects
  int get totalProjectileCount {
    return 1 + getPassiveEffectStacks('projectile_count');
  }
  
  int get totalProjectileBounces {
    return getPassiveEffectStacks('projectile_bounces');
  }
  
  double get totalProjectileSize {
    final regularSize = 1.0 + (getPassiveEffectStacks('projectile_size') * 0.5); // 50% increase per stack
    final enlargedSize = 1.0 + (getPassiveEffectStacks('enlarged_caliber') * 0.1); // 10% increase per stack
    return regularSize * enlargedSize;
  }
  
  double get characterSizeMultiplier {
    return 1.0 + (getPassiveEffectStacks('enlarged_caliber') * 0.1);
  }
  
  double get enlargedCaliberSpeedPenalty {
    return getPassiveEffectStacks('enlarged_caliber') * 0.25;
  }
  
  int get totalDroneCount {
    return getPassiveEffectStacks('drone_count');
  }
  
  double get totalLifeSteal {
    return getPassiveEffectStacks('life_steal') * 0.05;
  }
  
  double get totalShieldHP {
    return getPassiveEffectStacks('shield_hp') * 5.0;
  }
  
  double get totalCoinMultiplier {
    return 1.0 + (getPassiveEffectStacks('coin_multiplier') * 0.2);
  }
  
  double get totalHealPerKill {
    return getPassiveEffectStacks('heal_per_kill') * 2.0;
  }
  
  double get totalCritChance {
    return getPassiveEffectStacks('crit_chance') * 0.02;
  }
  
  double get totalMaxHealthBoost {
    return getPassiveEffectStacks('max_health_boost') * 10.0;
  }
  
  bool get hasCloneProjection {
    return hasPassiveEffect('clone_spawn');
  }
  
  void resetPassiveEffects() {
    _passiveEffectStacks.clear();
    killCount = 0;
    destroyAllDrones();
    destroyClone();
  }
  
  // Apply heal per kill effect when an enemy is defeated
  void onEnemyKilled() {
    killCount++;
    
    final healAmount = totalHealPerKill;
    if (healAmount > 0) {
      heal(healAmount);
      print('Healed ${healAmount} HP from kill');
    }
    
    // Handle kill-based max health boost (Auto Injector)
    final autoInjectorStacks = getPassiveEffectStacks('kill_based_max_health');
    if (autoInjectorStacks > 0 && killCount % 10 == 0) {
      final maxHealthIncrease = autoInjectorStacks * 2.0; // 2 HP per stack
      final currentBonus = (killCount ~/ 10) * maxHealthIncrease;
      final maxBonus = autoInjectorStacks * 50.0; // 50 HP max per stack
      
      if (currentBonus <= maxBonus) {
        maxHealth += maxHealthIncrease;
        health += maxHealthIncrease; // Also heal current HP
        print('Auto Injector: +${maxHealthIncrease} max HP from ${killCount} kills');
      }
    }
  }
  
  // Regenerate shields between waves (Armor Plating effect)
  void regenerateShields() {
    final armorShields = totalShieldHP;
    if (armorShields > 0) {
      // Apply armor plating as a persistent shield effect
      applyTemporaryEffect('shield', armorShields, double.infinity);
      print('Armor plating shields regenerated to ${armorShields.toStringAsFixed(1)} HP');
    }
  }
  
  // Drone management system
  void updateDroneCount() {
    final targetDroneCount = totalDroneCount;
    final currentDroneCount = _activeDrones.length;
    
    if (targetDroneCount > currentDroneCount) {
      // Spawn new drones
      for (int i = currentDroneCount; i < targetDroneCount; i++) {
        final drone = DroneWingman(owner: this, droneIndex: i);
        _activeDrones.add(drone);
        gameRef.add(drone);
        print('Spawned drone ${i + 1}/${targetDroneCount}');
      }
    } else if (targetDroneCount < currentDroneCount) {
      // Remove excess drones
      while (_activeDrones.length > targetDroneCount) {
        final drone = _activeDrones.removeLast();
        drone.destroy();
        print('Removed drone. Remaining: ${_activeDrones.length}');
      }
    }
  }
  
  void destroyAllDrones() {
    for (final drone in _activeDrones) {
      drone.destroy();
    }
    _activeDrones.clear();
    print('All drones destroyed');
  }
  
  // Clone management system
  bool canActivateClone() {
    return hasCloneProjection && _activeClone == null && health > maxHealth * 0.5;
  }
  
  void activateClone() {
    print('🤖 Attempting to activate clone...');
    print('   - Has clone projection: ${hasCloneProjection}');
    print('   - No active clone: ${_activeClone == null}');
    print('   - Current health: ${health.toStringAsFixed(1)}/${maxHealth.toStringAsFixed(1)}');
    print('   - Required health: ${(maxHealth * 0.5).toStringAsFixed(1)}');
    
    if (!canActivateClone()) {
      print('❌ Cannot activate clone: requirements not met');
      return;
    }
    
    // Pay health cost (50% of current health)
    final healthCost = health * 0.5;
    health -= healthCost;
    
    // Spawn clone directly to the right with clear gap
    final cloneOffset = Vector2(80, 0); // Simple fixed offset to the right
    final clonePosition = position + cloneOffset;
    
    print('🤖 Creating HeroClone at position: (${clonePosition.x}, ${clonePosition.y})');
    _activeClone = HeroClone(owner: this, spawnPosition: clonePosition);
    
    print('🤖 Adding clone to game...');
    gameRef.add(_activeClone!);
    
    print('✅ CLONE ACTIVATED! Health cost: ${healthCost.toStringAsFixed(1)}, Clone mounted: ${_activeClone!.isMounted}');
  }
  
  void destroyClone() {
    if (_activeClone != null) {
      _activeClone!.destroy();
      _activeClone = null;
      print('Clone destroyed');
    }
  }
  
  bool get hasActiveClone => _activeClone != null;
  
  // Getter for passive effect stacks (for stats display)
  Map<String, int> get passiveEffectStacks => Map.from(_passiveEffectStacks);
  
  void onCloneDestroyed(HeroClone clone) {
    if (_activeClone == clone) {
      _activeClone = null;
      print('Active clone reference cleared');
    }
  }
}

// Visual effect component for abilities
class AbilityVisualEffect extends PositionComponent with HasGameRef<CircleRougeGame> {
  final double effectRange;
  final String shape;
  final Color color;
  
  double lifetime = 0.0;
  static const double totalLifetime = 0.5; // Blink once and disappear
  static const double blinkDuration = 0.25; // Half the lifetime for one blink
  
  AbilityVisualEffect({
    required Vector2 position,
    required this.effectRange,
    required this.shape,
    required this.color,
  }) : super(
    position: position,
    size: Vector2.all(effectRange * 2),
    anchor: Anchor.center,
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    lifetime += dt;
    
    // Remove after total lifetime
    if (lifetime >= totalLifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Calculate opacity with blinking effect
    final blinkProgress = (lifetime / blinkDuration) % 1.0;
    final opacity = (sin(blinkProgress * pi * 2) * 0.15 + 0.1).clamp(0.0, 0.25); // 25% max opacity
    
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = color.withOpacity(opacity * 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Draw the shape based on type
    switch (shape) {
      case 'square':
        final rect = Rect.fromCenter(
          center: center,
          width: effectRange * 2,
          height: effectRange * 2,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;
      case 'heptagon':
        final path = _createHeptagonPath(center, effectRange);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }
  
  Path _createHeptagonPath(Offset center, double radius) {
    final path = Path();
    
    for (int i = 0; i < 7; i++) {
      final angle = -90 + (i * 51.42857142857143); // Heptagon angles
      final x = center.dx + radius * cos(angle * pi / 180);
      final y = center.dy + radius * sin(angle * pi / 180);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    return path;
  }
} 
```

Now I need to update the item detail card to show the correct information for the enlarged caliber:

```dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../shop_panel.dart';

class ItemDetailCard extends RectangleComponent with HasGameRef<CircleRougeGame>, TapCallbacks {
  final ShopItem item;
  final VoidCallback onClose;
  
  // Visual components
  late RectangleComponent background;
  late RectangleComponent border;
  late TextComponent titleText;
  late TextComponent descriptionText;
  late TextComponent costText;
  late TextComponent stackInfoText;
  late TextComponent instructionText;
  
  // Animation properties
  double animationTime = 0.0;
  static const double animationDuration = 0.3;
  bool isClosing = false;
  
  ItemDetailCard({
    required this.item,
    required this.onClose,
  }) : super(
    anchor: Anchor.center,
  ) {
    final screenWidth = DisplayConfig.instance.settings?.windowWidth ?? 800.0;
    final screenHeight = DisplayConfig.instance.settings?.windowHeight ?? 600.0;
    
    // Card dimensions
    final cardWidth = (screenWidth * 0.6).clamp(300.0, 500.0);
    final cardHeight = (screenHeight * 0.4).clamp(200.0, 300.0);
    
    size = Vector2(cardWidth, cardHeight);
    position = Vector2(screenWidth / 2, screenHeight / 2);
    
    _setupVisualComponents();
  }
  
  void _setupVisualComponents() {
    // Background with semi-transparent overlay
    background = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFF1A1A1A).withOpacity(0.95)
        ..style = PaintingStyle.fill,
    );
    add(background);
    
    // Border with item category color
    final borderColor = _getItemCategoryColor();
    border = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    add(border);
    
    // Title text
    titleText = TextComponent(
      text: item.name.toUpperCase(),
      textRenderer: TextPaint(
        style: TextStyle(
          color: borderColor,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      position: Vector2(size.x / 2, 40),
      anchor: Anchor.center,
    );
    add(titleText);
    
    // Cost text
    costText = TextComponent(
      text: '${item.cost} COINS',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD700), // Gold color
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(size.x / 2, 70),
      anchor: Anchor.center,
    );
    add(costText);
    
    // Description text (word-wrapped)
    final wrappedDescription = _wrapText(item.description, 45);
    descriptionText = TextComponent(
      text: wrappedDescription,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.4,
        ),
      ),
      position: Vector2(size.x / 2, 110),
      anchor: Anchor.center,
    );
    add(descriptionText);
    
    // Stack information (if applicable)
    final stackInfo = _getStackInfo();
    if (stackInfo.isNotEmpty) {
      stackInfoText = TextComponent(
        text: stackInfo,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFF88FF88), // Light green
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        position: Vector2(size.x / 2, size.y - 70),
        anchor: Anchor.center,
      );
      add(stackInfoText);
    }
    
    // Instruction text
    instructionText = TextComponent(
      text: 'TAP ANYWHERE TO CLOSE',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
      position: Vector2(size.x / 2, size.y - 30),
      anchor: Anchor.center,
    );
    add(instructionText);
  }
  
  Color _getItemCategoryColor() {
    // Determine color based on item type/category
    switch (item.id) {
      // Combat Enhancement items
      case 'spread_master':
      case 'bouncing_bullets':
      case 'enlarged_caliber':
        return const Color(0xFFFF6B6B); // Red
      
      // Support Systems
      case 'drone_wingman':
      case 'clone_projection':
        return const Color(0xFF4ECDC4); // Teal
      
      // Survivability
      case 'vampiric_coating':
      case 'armor_plating':
      case 'auto_injector':
        return const Color(0xFF45B7D1); // Blue
      
      // Utility
      case 'coin_magnet':
      case 'critical_striker':
        return const Color(0xFFFFD93D); // Yellow
      
      // Traditional upgrades
      case 'health_potion':
      case 'max_health_up':
        return const Color(0xFF6BCF7F); // Green
      
      case 'attack_speed_up':
      case 'speed_boost':
      case 'extended_reach':
      case 'dash_mastery':
        return const Color(0xFFB19CD9); // Purple
      
      default:
        return const Color(0xFF888888); // Gray fallback
    }
  }
  
  String _getStackInfo() {
    final hero = gameRef.hero;
    
    switch (item.id) {
      case 'spread_master':
        final current = hero.getPassiveEffectStacks('projectile_count');
        return 'Current: +$current projectiles (Max: +9)';
      
      case 'bouncing_bullets':
        final current = hero.getPassiveEffectStacks('projectile_bounces');
        return 'Current: +$current bounces (Max: +3)';
      
      case 'drone_wingman':
        final current = hero.getPassiveEffectStacks('drone_count');
        return 'Current: $current drones (Max: 3)';
      
      case 'enlarged_caliber':
        final current = hero.getPassiveEffectStacks('enlarged_caliber');
        final sizePercentage = (current * 10);
        final speedPenalty = (current * 25);
        return 'Current: +$sizePercentage% size, -$speedPenalty% speed (Max: 5 stacks)';
      
      case 'vampiric_coating':
        final current = hero.getPassiveEffectStacks('life_steal');
        final percentage = (current * 5);
        return 'Current: +$percentage% life steal (Max: +20%)';
      
      case 'armor_plating':
        final current = hero.getPassiveEffectStacks('shield_hp');
        final shieldHP = current * 5;
        return 'Current: +$shieldHP shield HP (Max: +100)';
      
      case 'coin_magnet':
        final current = hero.getPassiveEffectStacks('coin_multiplier');
        final percentage = (current * 20);
        return 'Current: +$percentage% coin earn (Max: +100%)';
      
      case 'auto_injector':
        final current = hero.getPassiveEffectStacks('kill_based_max_health');
        final maxHealthPer10Kills = current * 2;
        final maxPossible = current * 50;
        return 'Current: +$maxHealthPer10Kills max HP per 10 kills (Max: +$maxPossible total)';
      
      case 'critical_striker':
        final current = hero.getPassiveEffectStacks('crit_chance');
        final percentage = (current * 2);
        return 'Current: +$percentage% crit chance (Max: +10%)';
      
      case 'clone_projection':
        final hasClone = hero.hasCloneProjection;
        return hasClone ? 'Clone Projection: Available (Press C)' : 'Not owned';
      
      default:
        return '';
    }
  }
  
  String _wrapText(String text, int maxLineLength) {
    final words = text.split(' ');
    final lines = <String>[];
    String currentLine = '';
    
    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine + ' ' + word).length <= maxLineLength) {
        currentLine += ' ' + word;
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    
    return lines.join('\n');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Handle animation
    if (!isClosing) {
      animationTime += dt;
      if (animationTime < animationDuration) {
        final progress = animationTime / animationDuration;
        final easeProgress = _easeOutCubic(progress);
        
        // Scale animation
        scale = Vector2.all(easeProgress);
        
        // Fade in
        final opacity = easeProgress;
        background.paint.color = const Color(0xFF1A1A1A).withOpacity(0.95 * opacity);
        border.paint.color = _getItemCategoryColor().withOpacity(opacity);
      } else {
        scale = Vector2.all(1.0);
      }
    } else {
      animationTime -= dt * 3; // Faster closing animation
      if (animationTime <= 0) {
        removeFromParent();
        return;
      }
      
      final progress = animationTime / animationDuration;
      scale = Vector2.all(progress);
      
      // Fade out
      final opacity = progress;
      background.paint.color = const Color(0xFF1A1A1A).withOpacity(0.95 * opacity);
      border.paint.color = _getItemCategoryColor().withOpacity(opacity);
    }
  }
  
  double _easeOutCubic(double t) {
    return 1 - pow(1 - t, 3);
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    close();
    return true;
  }
  
  void close() {
    if (!isClosing) {
      isClosing = true;
      onClose();
    }
  }
  
  double pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

```

Now let me work on removing the drone limit. I need to update the items.json and the drone system:

```json
{
  "items": [
    {
      "id": "health_potion",
      "name": "Health Potion",
      "cost": 30,
      "description": "Restore 50 HP",
      "type": "consumable",
      "icon": "health_potion_transparent.png",
      "effect": {
        "type": "heal",
        "value": 50
      }
    },
    {
      "id": "dash_mastery",
      "name": "Dash Mastery",
      "cost": 60,
      "description": "-20% Dash Cooldown",
      "type": "upgrade",
      "icon": "ability_mastery_transparent.png",
      "effect": {
        "type": "dash_cooldown_multiplier",
        "value": 0.8
      }
    },
    {
      "id": "max_health_up",
      "name": "Max Health Up",
      "cost": 50,
      "description": "+25 Max Health",
      "type": "upgrade",
      "icon": "max_health_up_transparent.png",
      "effect": {
        "type": "max_health_increase",
        "value": 25
      }
    },
    {
      "id": "attack_speed_up",
      "name": "Attack Speed Up",
      "cost": 60,
      "description": "+25% Attack Speed",
      "type": "upgrade",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "attack_speed_multiplier",
        "value": 0.25
      }
    },
    {
      "id": "speed_boost",
      "name": "Speed Boost",
      "cost": 40,
      "description": "+25% Movement Speed",
      "type": "upgrade",
      "icon": "speed_boost_transparent.png",
      "effect": {
        "type": "speed_multiplier",
        "value": 0.25
      }
    },
    {
      "id": "extended_reach",
      "name": "Extended Reach",
      "cost": 150,
      "description": "+50% Range for all attacks and abilities",
      "type": "upgrade",
      "icon": "extended_reach_transparent.png",
      "effect": {
        "type": "range_multiplier",
        "value": 0.5
      }
    },
    {
      "id": "spread_master",
      "name": "Spread Master",
      "cost": 70,
      "description": "+1 projectile per shot, stack up to +9 (max 10 shots)",
      "type": "passive",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "projectile_count",
        "value": 1,
        "max_stacks": 9
      }
    },
    {
      "id": "bouncing_bullets",
      "name": "Bouncing Bullets",
      "cost": 80,
      "description": "+1 projectile bounce per shot, stackable to +3",
      "type": "passive",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "projectile_bounces",
        "value": 1,
        "max_stacks": 3
      }
    },
    {
      "id": "drone_wingman",
      "name": "Drone Wingman",
      "cost": 90,
      "description": "Summons one auto-firing drone (0.8 shots/sec), unlimited stacks",
      "type": "passive",
      "icon": "ability_mastery_transparent.png",
      "effect": {
        "type": "drone_count",
        "value": 1,
        "max_stacks": 999
      }
    },
    {
      "id": "enlarged_caliber",
      "name": "Enlarged Caliber",
      "cost": 60,
      "description": "+10% projectile diameter and character size, -25% speed per stack (max 5 stacks)",
      "type": "passive",
      "icon": "extended_reach_transparent.png",
      "effect": {
        "type": "enlarged_caliber",
        "value": 0.1,
        "max_stacks": 5
      }
    },
    {
      "id": "clone_projection",
      "name": "Clone Projection",
      "cost": 120,
      "description": "Spend 50% current HP to spawn a clone that mimics player",
      "type": "active_passive",
      "icon": "ability_mastery_transparent.png",
      "effect": {
        "type": "clone_spawn",
        "value": 0.5,
        "max_stacks": 1
      }
    },
    {
      "id": "vampiric_coating",
      "name": "Vampiric Coating",
      "cost": 80,
      "description": "+5% life steal per stack, max +20%",
      "type": "passive",
      "icon": "health_potion_transparent.png",
      "effect": {
        "type": "life_steal",
        "value": 0.05,
        "max_stacks": 4
      }
    },
    {
      "id": "armor_plating",
      "name": "Armor Plating",
      "cost": 70,
      "description": "+5 shield HP per stack, max +100; shields fully regens between waves",
      "type": "passive",
      "icon": "max_health_up_transparent.png",
      "effect": {
        "type": "shield_hp",
        "value": 5,
        "max_stacks": 20
      }
    },
    {
      "id": "coin_magnet",
      "name": "Coin Magnet",
      "cost": 50,
      "description": "+20% coin earn, max +100%",
      "type": "passive",
      "icon": "speed_boost_transparent.png",
      "effect": {
        "type": "coin_multiplier",
        "value": 0.2,
        "max_stacks": 5
      }
    },
    {
      "id": "auto_injector",
      "name": "Auto-Injector",
      "cost": 100,
      "description": "Every 10 kills grants +2 Max HP (caps at +50 per stack)",
      "type": "passive",
      "icon": "health_potion_transparent.png",
      "effect": {
        "type": "kill_based_max_health",
        "value": 2,
        "max_stacks": 5
      }
    },
    {
      "id": "critical_striker",
      "name": "Critical Striker",
      "cost": 75,
      "description": "+2% crit chance per stack, max +10%",
      "type": "passive",
      "icon": "attack_speed_transparent.png",
      "effect": {
        "type": "crit_chance",
        "value": 0.02,
        "max_stacks": 5
      }
    }
  ]
}

```

Now I need to update the item detail card to reflect the unlimited drones:

```dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../shop_panel.dart';

class ItemDetailCard extends RectangleComponent with HasGameRef<CircleRougeGame>, TapCallbacks {
  final ShopItem item;
  final VoidCallback onClose;
  
  // Visual components
  late RectangleComponent background;
  late RectangleComponent border;
  late TextComponent titleText;
  late TextComponent descriptionText;
  late TextComponent costText;
  late TextComponent stackInfoText;
  late TextComponent instructionText;
  
  // Animation properties
  double animationTime = 0.0;
  static const double animationDuration = 0.3;
  bool isClosing = false;
  
  ItemDetailCard({
    required this.item,
    required this.onClose,
  }) : super(
    anchor: Anchor.center,
  ) {
    final screenWidth = DisplayConfig.instance.settings?.windowWidth ?? 800.0;
    final screenHeight = DisplayConfig.instance.settings?.windowHeight ?? 600.0;
    
    // Card dimensions
    final cardWidth = (screenWidth * 0.6).clamp(300.0, 500.0);
    final cardHeight = (screenHeight * 0.4).clamp(200.0, 300.0);
    
    size = Vector2(cardWidth, cardHeight);
    position = Vector2(screenWidth / 2, screenHeight / 2);
    
    _setupVisualComponents();
  }
  
  void _setupVisualComponents() {
    // Background with semi-transparent overlay
    background = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFF1A1A1A).withOpacity(0.95)
        ..style = PaintingStyle.fill,
    );
    add(background);
    
    // Border with item category color
    final borderColor = _getItemCategoryColor();
    border = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    add(border);
    
    // Title text
    titleText = TextComponent(
      text: item.name.toUpperCase(),
      textRenderer: TextPaint(
        style: TextStyle(
          color: borderColor,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      position: Vector2(size.x / 2, 40),
      anchor: Anchor.center,
    );
    add(titleText);
    
    // Cost text
    costText = TextComponent(
      text: '${item.cost} COINS',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD700), // Gold color
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(size.x / 2, 70),
      anchor: Anchor.center,
    );
    add(costText);
    
    // Description text (word-wrapped)
    final wrappedDescription = _wrapText(item.description, 45);
    descriptionText = TextComponent(
      text: wrappedDescription,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.4,
        ),
      ),
      position: Vector2(size.x / 2, 110),
      anchor: Anchor.center,
    );
    add(descriptionText);
    
    // Stack information (if applicable)
    final stackInfo = _getStackInfo();
    if (stackInfo.isNotEmpty) {
      stackInfoText = TextComponent(
        text: stackInfo,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFF88FF88), // Light green
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        position: Vector2(size.x / 2, size.y - 70),
        anchor: Anchor.center,
      );
      add(stackInfoText);
    }
    
    // Instruction text
    instructionText = TextComponent(
      text: 'TAP ANYWHERE TO CLOSE',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
      position: Vector2(size.x / 2, size.y - 30),
      anchor: Anchor.center,
    );
    add(instructionText);
  }
  
  Color _getItemCategoryColor() {
    // Determine color based on item type/category
    switch (item.id) {
      // Combat Enhancement items
      case 'spread_master':
      case 'bouncing_bullets':
      case 'enlarged_caliber':
        return const Color(0xFFFF6B6B); // Red
      
      // Support Systems
      case 'drone_wingman':
      case 'clone_projection':
        return const Color(0xFF4ECDC4); // Teal
      
      // Survivability
      case 'vampiric_coating':
      case 'armor_plating':
      case 'auto_injector':
        return const Color(0xFF45B7D1); // Blue
      
      // Utility
      case 'coin_magnet':
      case 'critical_striker':
        return const Color(0xFFFFD93D); // Yellow
      
      // Traditional upgrades
      case 'health_potion':
      case 'max_health_up':
        return const Color(0xFF6BCF7F); // Green
      
      case 'attack_speed_up':
      case 'speed_boost':
      case 'extended_reach':
      case 'dash_mastery':
        return const Color(0xFFB19CD9); // Purple
      
      default:
        return const Color(0xFF888888); // Gray fallback
    }
  }
  
  String _getStackInfo() {
    final hero = gameRef.hero;
    
    switch (item.id) {
      case 'spread_master':
        final current = hero.getPassiveEffectStacks('projectile_count');
        return 'Current: +$current projectiles (Max: +9)';
      
      case 'bouncing_bullets':
        final current = hero.getPassiveEffectStacks('projectile_bounces');
        return 'Current: +$current bounces (Max: +3)';
      
      case 'drone_wingman':
        final current = hero.getPassiveEffectStacks('drone_count');
        return 'Current: $current drones (Unlimited)';
      
      case 'enlarged_caliber':
        final current = hero.getPassiveEffectStacks('enlarged_caliber');
        final sizePercentage = (current * 10);
        final speedPenalty = (current * 25);
        return 'Current: +$sizePercentage% size, -$speedPenalty% speed (Max: 5 stacks)';
      
      case 'vampiric_coating':
        final current = hero.getPassiveEffectStacks('life_steal');
        final percentage = (current * 5);
        return 'Current: +$percentage% life steal (Max: +20%)';
      
      case 'armor_plating':
        final current = hero.getPassiveEffectStacks('shield_hp');
        final shieldHP = current * 5;
        return 'Current: +$shieldHP shield HP (Max: +100)';
      
      case 'coin_magnet':
        final current = hero.getPassiveEffectStacks('coin_multiplier');
        final percentage = (current * 20);
        return 'Current: +$percentage% coin earn (Max: +100%)';
      
      case 'auto_injector':
        final current = hero.getPassiveEffectStacks('kill_based_max_health');
        final maxHealthPer10Kills = current * 2;
        final maxPossible = current * 50;
        return 'Current: +$maxHealthPer10Kills max HP per 10 kills (Max: +$maxPossible total)';
      
      case 'critical_striker':
        final current = hero.getPassiveEffectStacks('crit_chance');
        final percentage = (current * 2);
        return 'Current: +$percentage% crit chance (Max: +10%)';
      
      case 'clone_projection':
        final hasClone = hero.hasCloneProjection;
        return hasClone ? 'Clone Projection: Available (Press C)' : 'Not owned';
      
      default:
        return '';
    }
  }
  
  String _wrapText(String text, int maxLineLength) {
    final words = text.split(' ');
    final lines = <String>[];
    String currentLine = '';
    
    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine + ' ' + word).length <= maxLineLength) {
        currentLine += ' ' + word;
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    
    return lines.join('\n');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Handle animation
    if (!isClosing) {
      animationTime += dt;
      if (animationTime < animationDuration) {
        final progress = animationTime / animationDuration;
        final easeProgress = _easeOutCubic(progress);
        
        // Scale animation
        scale = Vector2.all(easeProgress);
        
        // Fade in
        final opacity = easeProgress;
        background.paint.color = const Color(0xFF1A1A1A).withOpacity(0.95 * opacity);
        border.paint.color = _getItemCategoryColor().withOpacity(opacity);
      } else {
        scale = Vector2.all(1.0);
      }
    } else {
      animationTime -= dt * 3; // Faster closing animation
      if (animationTime <= 0) {
        removeFromParent();
        return;
      }
      
      final progress = animationTime / animationDuration;
      scale = Vector2.all(progress);
      
      // Fade out
      final opacity = progress;
      background.paint.color = const Color(0xFF1A1A1A).withOpacity(0.95 * opacity);
      border.paint.color = _getItemCategoryColor().withOpacity(opacity);
    }
  }
  
  double _easeOutCubic(double t) {
    return 1 - pow(1 - t, 3);
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    close();
    return true;
  }
  
  void close() {
    if (!isClosing) {
      isClosing = true;
      onClose();
    }
  }
  
  double pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

```

Now let me increase the sniper bullet damage to 50% of player HP. I need to modify the sniper class:

```dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import 'projectile.dart';

class Sniper extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 30.0; // Very slow movement
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('sniper') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 25.0; // Moderate health
  double maxHealth = 25.0;
  bool isDead = false;
  
  // Sniper behavior
  static const double attackRange = 400.0; // Very long range
  static const double chargeTime = 2.0; // Time to charge shot
  // Damage will be calculated as 50% of player's current HP
  static const double aimTime = 1.0; // Time spent aiming before charging
  
  double lastShotTime = 0.0;
  double shotCooldown = 4.0; // Long cooldown between shots
  bool isCharging = false;
  bool isAiming = false;
  double chargeTimer = 0.0;
  double aimTimer = 0.0;
  Vector2 targetPosition = Vector2.zero();
  
  // Visual effects
  double laserAlpha = 0.0;
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  Sniper({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 14.0 * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = const Color(0xFF4CAF50), // Green color
    anchor: Anchor.center,
  );
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw charging laser sight
    if ((isAiming || isCharging) && laserAlpha > 0) {
      final start = Offset(size.x / 2, size.y / 2);
      final end = Offset(
        start.dx + (targetPosition.x - position.x),
        start.dy + (targetPosition.y - position.y),
      );
      
      final laserPaint = Paint()
        ..color = Colors.red.withOpacity(laserAlpha)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(start, end, laserPaint);
      
      // Draw target indicator
      final targetPaint = Paint()
        ..color = Colors.red.withOpacity(laserAlpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawCircle(end, 10.0, targetPaint);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    if (isDead) return;
    
    // Handle stun
    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
        _cancelShot();
      }
      return;
    }
    
    // Remove if too far from arena center (cleanup)
    final arenaCenter = Vector2(DisplayConfig.instance.arenaWidth / 2, DisplayConfig.instance.arenaHeight / 2);
    final maxDistance = (DisplayConfig.instance.arenaWidth + DisplayConfig.instance.arenaHeight) / 3;
    if (position.distanceTo(arenaCenter) > maxDistance) {
      removeFromParent();
      return;
    }
    
    // Stay within safe area
    _constrainToSafeArea();
    
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final distanceToHero = position.distanceTo(hero.position);
      final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      
      // Check if can start aiming
      if (distanceToHero <= attackRange * DisplayConfig.instance.scaleFactor && 
          !isAiming && !isCharging && 
          currentTime - lastShotTime >= shotCooldown) {
        _startAiming(hero.position);
      }
      
      // Handle aiming phase
      if (isAiming) {
        aimTimer += dt;
        laserAlpha = min(1.0, aimTimer / aimTime);
        
        if (aimTimer >= aimTime) {
          _startCharging();
        }
      }
      
      // Handle charging phase
      if (isCharging) {
        chargeTimer += dt;
        
        // Intensify laser during charge
        laserAlpha = 0.5 + 0.5 * sin(chargeTimer * 20.0);
        
        if (chargeTimer >= chargeTime) {
          _fireShot();
        }
      }
      
      // Move very slowly toward hero when not shooting
      if (!isAiming && !isCharging) {
        final direction = (hero.position - position).normalized();
        final noStayForce = gameRef.getNoStayZoneForce(position);
        final finalDirection = (direction + noStayForce * dt).normalized();
        
        position += finalDirection * speed * dt * speedMultiplier;
      }
      
      // Check collision with hero (only when not shooting)
      if (!isAiming && !isCharging && distanceToHero <= radius + hero.collisionRadius) {
        hero.takeDamage(15.0);
        takeDamage(health); // Die on contact
      }
    }
  }
  
  void _startAiming(Vector2 heroPosition) {
    isAiming = true;
    aimTimer = 0.0;
    targetPosition = heroPosition.clone();
    laserAlpha = 0.0;
  }
  
  void _startCharging() {
    isAiming = false;
    isCharging = true;
    chargeTimer = 0.0;
    aimTimer = 0.0;
  }
  
  void _fireShot() {
    final direction = (targetPosition - position).normalized();
    
    final projectile = Projectile(
      startPosition: position.clone(),
      direction: direction,
      speed: 600.0 * DisplayConfig.instance.scaleFactor, // Very fast projectile
      damage: damage,
      isEnemyProjectile: true,
    );
    
    gameRef.add(projectile);
    
    _resetShotState();
  }
  
  void _cancelShot() {
    _resetShotState();
  }
  
  void _resetShotState() {
    isAiming = false;
    isCharging = false;
    chargeTimer = 0.0;
    aimTimer = 0.0;
    laserAlpha = 0.0;
    lastShotTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
  }
  
  void _constrainToSafeArea() {
    final margin = DisplayConfig.instance.safeAreaMargin;
    position.x = position.x.clamp(
      margin, 
      DisplayConfig.instance.arenaWidth - margin
    );
    position.y = position.y.clamp(
      margin, 
      DisplayConfig.instance.arenaHeight - margin
    );
  }
  
  void takeDamage(double damageAmount) {
    health -= damageAmount;
    
    // Cancel shot when taking damage
    if (isAiming || isCharging) {
      _cancelShot();
    }
    
    if (health <= 0) {
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
    }
  }
  
  void stun(double duration) {
    isStunned = true;
    stunDuration = duration;
    stunTimer = duration;
    _cancelShot();
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
}

```

Now I need to update the _fireShot method to calculate damage based on player HP:

```dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import 'projectile.dart';

class Sniper extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 30.0; // Very slow movement
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('sniper') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 25.0; // Moderate health
  double maxHealth = 25.0;
  bool isDead = false;
  
  // Sniper behavior
  static const double attackRange = 400.0; // Very long range
  static const double chargeTime = 2.0; // Time to charge shot
  // Damage will be calculated as 50% of player's current HP
  static const double aimTime = 1.0; // Time spent aiming before charging
  
  double lastShotTime = 0.0;
  double shotCooldown = 4.0; // Long cooldown between shots
  bool isCharging = false;
  bool isAiming = false;
  double chargeTimer = 0.0;
  double aimTimer = 0.0;
  Vector2 targetPosition = Vector2.zero();
  
  // Visual effects
  double laserAlpha = 0.0;
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  Sniper({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 14.0 * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = const Color(0xFF4CAF50), // Green color
    anchor: Anchor.center,
  );
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw charging laser sight
    if ((isAiming || isCharging) && laserAlpha > 0) {
      final start = Offset(size.x / 2, size.y / 2);
      final end = Offset(
        start.dx + (targetPosition.x - position.x),
        start.dy + (targetPosition.y - position.y),
      );
      
      final laserPaint = Paint()
        ..color = Colors.red.withOpacity(laserAlpha)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(start, end, laserPaint);
      
      // Draw target indicator
      final targetPaint = Paint()
        ..color = Colors.red.withOpacity(laserAlpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawCircle(end, 10.0, targetPaint);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    if (isDead) return;
    
    // Handle stun
    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
        _cancelShot();
      }
      return;
    }
    
    // Remove if too far from arena center (cleanup)
    final arenaCenter = Vector2(DisplayConfig.instance.arenaWidth / 2, DisplayConfig.instance.arenaHeight / 2);
    final maxDistance = (DisplayConfig.instance.arenaWidth + DisplayConfig.instance.arenaHeight) / 3;
    if (position.distanceTo(arenaCenter) > maxDistance) {
      removeFromParent();
      return;
    }
    
    // Stay within safe area
    _constrainToSafeArea();
    
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final distanceToHero = position.distanceTo(hero.position);
      final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      
      // Check if can start aiming
      if (distanceToHero <= attackRange * DisplayConfig.instance.scaleFactor && 
          !isAiming && !isCharging && 
          currentTime - lastShotTime >= shotCooldown) {
        _startAiming(hero.position);
      }
      
      // Handle aiming phase
      if (isAiming) {
        aimTimer += dt;
        laserAlpha = min(1.0, aimTimer / aimTime);
        
        if (aimTimer >= aimTime) {
          _startCharging();
        }
      }
      
      // Handle charging phase
      if (isCharging) {
        chargeTimer += dt;
        
        // Intensify laser during charge
        laserAlpha = 0.5 + 0.5 * sin(chargeTimer * 20.0);
        
        if (chargeTimer >= chargeTime) {
          _fireShot();
        }
      }
      
      // Move very slowly toward hero when not shooting
      if (!isAiming && !isCharging) {
        final direction = (hero.position - position).normalized();
        final noStayForce = gameRef.getNoStayZoneForce(position);
        final finalDirection = (direction + noStayForce * dt).normalized();
        
        position += finalDirection * speed * dt * speedMultiplier;
      }
      
      // Check collision with hero (only when not shooting)
      if (!isAiming && !isCharging && distanceToHero <= radius + hero.collisionRadius) {
        hero.takeDamage(15.0);
        takeDamage(health); // Die on contact
      }
    }
  }
  
  void _startAiming(Vector2 heroPosition) {
    isAiming = true;
    aimTimer = 0.0;
    targetPosition = heroPosition.clone();
    laserAlpha = 0.0;
  }
  
  void _startCharging() {
    isAiming = false;
    isCharging = true;
    chargeTimer = 0.0;
    aimTimer = 0.0;
  }
  
  void _fireShot() {
    final direction = (targetPosition - position).normalized();
    
    // Calculate damage as 50% of player's current HP
    final playerDamage = gameRef.hero.health * 0.5;
    
    final projectile = Projectile(
      startPosition: position.clone(),
      direction: direction,
      speed: 600.0 * DisplayConfig.instance.scaleFactor, // Very fast projectile
      damage: playerDamage,
      isEnemyProjectile: true,
    );
    
    gameRef.add(projectile);
    
    _resetShotState();
  }
  
  void _cancelShot() {
    _resetShotState();
  }
  
  void _resetShotState() {
    isAiming = false;
    isCharging = false;
    chargeTimer = 0.0;
    aimTimer = 0.0;
    laserAlpha = 0.0;
    lastShotTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
  }
  
  void _constrainToSafeArea() {
    final margin = DisplayConfig.instance.safeAreaMargin;
    position.x = position.x.clamp(
      margin, 
      DisplayConfig.instance.arenaWidth - margin
    );
    position.y = position.y.clamp(
      margin, 
      DisplayConfig.instance.arenaHeight - margin
    );
  }
  
  void takeDamage(double damageAmount) {
    health -= damageAmount;
    
    // Cancel shot when taking damage
    if (isAiming || isCharging) {
      _cancelShot();
    }
    
    if (health <= 0) {
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
    }
  }
  
  void stun(double duration) {
    isStunned = true;
    stunDuration = duration;
    stunTimer = duration;
    _cancelShot();
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
}

```

Now let me work on creating an enemy configuration JSON file. I need to create a new config file and move all the hardcoded enemy numbers there. First, let me create the new config file:

```json
{
  "enemies": {
    "chaser": {
      "health": 30.0,
      "max_health": 30.0,
      "contact_damage": 15.0,
      "movement_speed": 60.0,
      "description": "Fast melee enemy that charges at the player"
    },
    "shooter": {
      "health": 20.0,
      "max_health": 20.0,
      "contact_damage": 15.0,
      "projectile_damage": 5.0,
      "movement_speed": 80.0,
      "attack_range": 300.0,
      "shot_interval": 2.0,
      "optimal_distance_min": 180.0,
      "optimal_distance_max": 280.0,
      "description": "Ranged enemy that maintains distance while shooting"
    },
    "shielded_chaser": {
      "health": 60.0,
      "max_health": 60.0,
      "shield_health": 40.0,
      "contact_damage": 20.0,
      "movement_speed": 60.0,
      "description": "Armored melee enemy with shield protection"
    },
    "swarmer": {
      "health": 15.0,
      "max_health": 15.0,
      "contact_damage": 10.0,
      "movement_speed": 120.0,
      "swarm_radius": 80.0,
      "separation_radius": 30.0,
      "spawn_count": 6,
      "description": "Fast, agile enemy that swarms together"
    },
    "bomber": {
      "health": 25.0,
      "max_health": 25.0,
      "contact_damage": 15.0,
      "explosion_damage": 30.0,
      "explosion_radius": 80.0,
      "movement_speed": 40.0,
      "arm_time": 1.5,
      "description": "Slow but explosive enemy that detonates when close"
    },
    "sniper": {
      "health": 25.0,
      "max_health": 25.0,
      "contact_damage": 15.0,
      "damage_percent": 0.5,
      "movement_speed": 30.0,
      "attack_range": 400.0,
      "charge_time": 2.0,
      "aim_time": 1.0,
      "shot_cooldown": 4.0,
      "description": "Long-range enemy with charging laser attacks"
    },
    "splitter": {
      "health": 40.0,
      "max_health": 40.0,
      "contact_damage": 20.0,
      "movement_speed": 60.0,
      "splits_per_generation": 6,
      "max_generations": 2,
      "generation_health": {
        "0": 40.0,
        "1": 25.0,
        "2": 15.0
      },
      "generation_radius": {
        "0": 18.0,
        "1": 14.0,
        "2": 10.0
      },
      "description": "Enemy that splits into smaller versions when destroyed"
    },
    "mine_layer": {
      "health": 35.0,
      "max_health": 35.0,
      "contact_damage": 15.0,
      "movement_speed": 45.0,
      "mine_lay_interval": 3.0,
      "min_distance_from_mines": 80.0,
      "mine_explosion_damage": 25.0,
      "mine_explosion_radius": 60.0,
      "mine_arm_time": 1.0,
      "description": "Tactical enemy that places explosive mines"
    }
  }
}
```

Now I need to create a Dart config class to load this JSON file:

```dart
import 'dart:convert';
import 'package:flutter/services.dart';

class EnemyStatsData {
  final double health;
  final double maxHealth;
  final double contactDamage;
  final double movementSpeed;
  final String description;
  
  // Optional properties for different enemy types
  final double? projectileDamage;
  final double? attackRange;
  final double? shotInterval;
  final double? optimalDistanceMin;
  final double? optimalDistanceMax;
  final double? shieldHealth;
  final double? swarmRadius;
  final double? separationRadius;
  final int? spawnCount;
  final double? explosionDamage;
  final double? explosionRadius;
  final double? armTime;
  final double? damagePercent;
  final double? chargeTime;
  final double? aimTime;
  final double? shotCooldown;
  final int? splitsPerGeneration;
  final int? maxGenerations;
  final Map<String, double>? generationHealth;
  final Map<String, double>? generationRadius;
  final double? mineLayInterval;
  final double? minDistanceFromMines;
  final double? mineExplosionDamage;
  final double? mineExplosionRadius;
  final double? mineArmTime;
  
  EnemyStatsData({
    required this.health,
    required this.maxHealth,
    required this.contactDamage,
    required this.movementSpeed,
    required this.description,
    this.projectileDamage,
    this.attackRange,
    this.shotInterval,
    this.optimalDistanceMin,
    this.optimalDistanceMax,
    this.shieldHealth,
    this.swarmRadius,
    this.separationRadius,
    this.spawnCount,
    this.explosionDamage,
    this.explosionRadius,
    this.armTime,
    this.damagePercent,
    this.chargeTime,
    this.aimTime,
    this.shotCooldown,
    this.splitsPerGeneration,
    this.maxGenerations,
    this.generationHealth,
    this.generationRadius,
    this.mineLayInterval,
    this.minDistanceFromMines,
    this.mineExplosionDamage,
    this.mineExplosionRadius,
    this.mineArmTime,
  });
  
  factory EnemyStatsData.fromJson(Map<String, dynamic> json) {
    return EnemyStatsData(
      health: (json['health'] ?? 30.0).toDouble(),
      maxHealth: (json['max_health'] ?? 30.0).toDouble(),
      contactDamage: (json['contact_damage'] ?? 15.0).toDouble(),
      movementSpeed: (json['movement_speed'] ?? 50.0).toDouble(),
      description: json['description'] ?? '',
      projectileDamage: json['projectile_damage']?.toDouble(),
      attackRange: json['attack_range']?.toDouble(),
      shotInterval: json['shot_interval']?.toDouble(),
      optimalDistanceMin: json['optimal_distance_min']?.toDouble(),
      optimalDistanceMax: json['optimal_distance_max']?.toDouble(),
      shieldHealth: json['shield_health']?.toDouble(),
      swarmRadius: json['swarm_radius']?.toDouble(),
      separationRadius: json['separation_radius']?.toDouble(),
      spawnCount: json['spawn_count'],
      explosionDamage: json['explosion_damage']?.toDouble(),
      explosionRadius: json['explosion_radius']?.toDouble(),
      armTime: json['arm_time']?.toDouble(),
      damagePercent: json['damage_percent']?.toDouble(),
      chargeTime: json['charge_time']?.toDouble(),
      aimTime: json['aim_time']?.toDouble(),
      shotCooldown: json['shot_cooldown']?.toDouble(),
      splitsPerGeneration: json['splits_per_generation'],
      maxGenerations: json['max_generations'],
      generationHealth: json['generation_health'] != null 
          ? Map<String, double>.from(json['generation_health'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      generationRadius: json['generation_radius'] != null
          ? Map<String, double>.from(json['generation_radius'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      mineLayInterval: json['mine_lay_interval']?.toDouble(),
      minDistanceFromMines: json['min_distance_from_mines']?.toDouble(),
      mineExplosionDamage: json['mine_explosion_damage']?.toDouble(),
      mineExplosionRadius: json['mine_explosion_radius']?.toDouble(),
      mineArmTime: json['mine_arm_time']?.toDouble(),
    );
  }
}

class EnemyStatsConfig {
  static EnemyStatsConfig? _instance;
  static EnemyStatsConfig get instance => _instance ??= EnemyStatsConfig._();
  
  EnemyStatsConfig._();
  
  Map<String, EnemyStatsData> _enemies = {};
  bool _loaded = false;
  
  Map<String, EnemyStatsData> get enemies => _enemies;
  
  Future<void> loadConfig() async {
    if (_loaded) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/config/enemies.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final enemiesData = jsonData['enemies'] as Map<String, dynamic>;
      _enemies = enemiesData.map((key, value) => 
          MapEntry(key, EnemyStatsData.fromJson(value)));
      
      _loaded = true;
    } catch (e) {
      print('Error loading enemy stats config: $e');
      // Fallback to empty map if loading fails
      _enemies = {};
      _loaded = true;
    }
  }
  
  EnemyStatsData? getEnemyStats(String enemyType) {
    return _enemies[enemyType];
  }
  
  double getHealth(String enemyType) {
    return _enemies[enemyType]?.health ?? 30.0;
  }
  
  double getContactDamage(String enemyType) {
    return _enemies[enemyType]?.contactDamage ?? 15.0;
  }
  
  double getMovementSpeed(String enemyType) {
    return _enemies[enemyType]?.movementSpeed ?? 50.0;
  }
}
```

Now I need to initialize this config in the main.dart file. Let me check how other configs are loaded:

I need to check where other configs are loaded. Let me check the CircleRougeGame initialization:

I need to add the enemy stats config loading to the onLoad method:

```dart
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
import '../components/abilities/hex_field.dart';
import '../components/companions/drone_wingman.dart';
import '../components/companions/hero_clone.dart';
import '../config/item_config.dart';
import '../config/wave_config.dart';
import '../config/hero_config.dart';
import '../config/game_mode_config.dart';
import '../config/display_config.dart';

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
  double get waveDuration => WaveConfig.instance.settings?.waveDuration ?? 30.0;
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
        position: Vector2.zero(),
        anchor: Anchor.topLeft,
      );
      add(backgroundArena);
    } catch (e) {
      print('Could not load background image: $e');
      // Create a simple colored background as fallback
      final rect = RectangleComponent(
        size: Vector2(arenaWidth, arenaHeight),
        position: Vector2.zero(),
        paint: Paint()..color = const Color(0xFF1A1A1A),
        anchor: Anchor.topLeft,
      );
      add(rect);
    }
    
    // Load other configurations
    await ItemConfig.instance.loadConfig();
    await WaveConfig.instance.loadConfig();
    await HeroConfig.instance.loadConfig();
    await GameModeConfig.instance.loadConfig();
    await EnemyStatsConfig.instance.loadConfig();
    
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
    
    // Remove all overlays
    overlays.remove('HeroSelection');
    overlays.remove('GameOver');
    overlays.remove('Victory');
    overlays.remove('PauseMenu');
    
    clearAllItems();
    _clearLingeringComponents();

    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.resetPassiveEffects();
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
    
    // Start first wave
    startWave(currentWave);
  }
  
  void restartGame() {
    // Reset game over sound flag
    gameOverSoundPlayed = false;
    
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
    _clearLingeringComponents();
    
    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.resetPassiveEffects();
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
    
    // Add stats overlay for coin and stats display during gameplay
    if (!statsOverlay.isMounted) {
      add(statsOverlay);
    }
    statsOverlay.show();
    
    // Start first wave (which will start BGM)
    startWave(currentWave);
  }
  
  void showStartMenu() {
    gameState = GameState.startMenu;
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
    
    // Try to drop item (unified system)
    if (enemy is PositionComponent) {
      consumableDropManager.tryDropItem(enemy.position);
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
      _clearLingeringComponents();
      
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
          shopPanel.show();
          
          // Ensure stats overlay is on top by adding it after the shop panel
          if (statsOverlay.isMounted) {
            statsOverlay.removeFromParent();
          }
          add(statsOverlay);
          statsOverlay.show();
          
          // Auto refresh shop items
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
  
  void onHeroDeath() {
    if (gameOverSoundPlayed) return; // Prevent multiple fail sounds
    
    // Handle 1HP Challenge mode retry tokens
    if (currentGameMode == GameMode.oneHpChallenge && retryTokens > 0) {
      consumeRetryToken();
      revivePlayer();
      return;
    }
    
    gameState = GameState.gameOver;
    gameOverSoundPlayed = true;
    
    // Clear all item drops when game ends
    clearAllItems();
    _clearLingeringComponents();
    
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
      hud.updateArmor(hero.shield, hero.totalShieldHP);
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
      hud.updateWaveTimer(remainingTime);
      
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
      
      // Update background size if it exists
      if (backgroundArena.isMounted) {
        backgroundArena.size = Vector2(arenaWidth, arenaHeight);
      }
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
  
  void _clearLingeringComponents() {
    final componentsToRemove = <Component>[];

    for (final component in children) {
      if (component is DroneWingman ||
          component is HeroClone ||
          component is HexField ||
          component is AbilityVisualEffect ||
          component is Mine ||
          component.runtimeType.toString().contains('Projectile') ||
          component.runtimeType.toString().contains('Effect') ||
          component.runtimeType.toString().contains('Explosion')) {
        componentsToRemove.add(component);
      }
    }

    for (final component in componentsToRemove) {
      component.removeFromParent();
    }
  }

  void showEffectNotification(String effectType, double value, double duration) {
    // Simple console output for now - could be enhanced with UI notifications
    print('Effect applied: $effectType (${value.toStringAsFixed(1)}) for ${duration.toStringAsFixed(1)}s');
  }
} 

```

I also need to add the import for the EnemyStatsConfig:

```dart
import '../config/display_config.dart';
import '../config/wave_config.dart';
import '../config/item_config.dart';
import '../config/hero_config.dart';
import '../config/game_mode_config.dart';
import '../config/enemy_stats_config.dart';
```

Let me find the import section:

```dart
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
import '../components/abilities/hex_field.dart';
import '../components/companions/drone_wingman.dart';
import '../components/companions/hero_clone.dart';
import '../config/item_config.dart';
import '../config/wave_config.dart';
import '../config/hero_config.dart';
import '../config/game_mode_config.dart';
import '../config/display_config.dart';
import '../config/enemy_stats_config.dart';

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
  double get waveDuration => WaveConfig.instance.settings?.waveDuration ?? 30.0;
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
        position: Vector2.zero(),
        anchor: Anchor.topLeft,
      );
      add(backgroundArena);
    } catch (e) {
      print('Could not load background image: $e');
      // Create a simple colored background as fallback
      final rect = RectangleComponent(
        size: Vector2(arenaWidth, arenaHeight),
        position: Vector2.zero(),
        paint: Paint()..color = const Color(0xFF1A1A1A),
        anchor: Anchor.topLeft,
      );
      add(rect);
    }
    
    // Load other configurations
    await ItemConfig.instance.loadConfig();
    await WaveConfig.instance.loadConfig();
    await HeroConfig.instance.loadConfig();
    await GameModeConfig.instance.loadConfig();
    await EnemyStatsConfig.instance.loadConfig();
    
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
    
    // Remove all overlays
    overlays.remove('HeroSelection');
    overlays.remove('GameOver');
    overlays.remove('Victory');
    overlays.remove('PauseMenu');
    
    clearAllItems();
    _clearLingeringComponents();

    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.resetPassiveEffects();
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
    
    // Start first wave
    startWave(currentWave);
  }
  
  void restartGame() {
    // Reset game over sound flag
    gameOverSoundPlayed = false;
    
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
    _clearLingeringComponents();
    
    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.resetPassiveEffects();
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
    
    // Add stats overlay for coin and stats display during gameplay
    if (!statsOverlay.isMounted) {
      add(statsOverlay);
    }
    statsOverlay.show();
    
    // Start first wave (which will start BGM)
    startWave(currentWave);
  }
  
  void showStartMenu() {
    gameState = GameState.startMenu;
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
    
    // Try to drop item (unified system)
    if (enemy is PositionComponent) {
      consumableDropManager.tryDropItem(enemy.position);
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
      _clearLingeringComponents();
      
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
          shopPanel.show();
          
          // Ensure stats overlay is on top by adding it after the shop panel
          if (statsOverlay.isMounted) {
            statsOverlay.removeFromParent();
          }
          add(statsOverlay);
          statsOverlay.show();
          
          // Auto refresh shop items
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
  
  void onHeroDeath() {
    if (gameOverSoundPlayed) return; // Prevent multiple fail sounds
    
    // Handle 1HP Challenge mode retry tokens
    if (currentGameMode == GameMode.oneHpChallenge && retryTokens > 0) {
      consumeRetryToken();
      revivePlayer();
      return;
    }
    
    gameState = GameState.gameOver;
    gameOverSoundPlayed = true;
    
    // Clear all item drops when game ends
    clearAllItems();
    _clearLingeringComponents();
    
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
      hud.updateArmor(hero.shield, hero.totalShieldHP);
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
      hud.updateWaveTimer(remainingTime);
      
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
      
      // Update background size if it exists
      if (backgroundArena.isMounted) {
        backgroundArena.size = Vector2(arenaWidth, arenaHeight);
      }
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
  
  void _clearLingeringComponents() {
    final componentsToRemove = <Component>[];

    for (final component in children) {
      if (component is DroneWingman ||
          component is HeroClone ||
          component is HexField ||
          component is AbilityVisualEffect ||
          component is Mine ||
          component.runtimeType.toString().contains('Projectile') ||
          component.runtimeType.toString().contains('Effect') ||
          component.runtimeType.toString().contains('Explosion')) {
        componentsToRemove.add(component);
      }
    }

    for (final component in componentsToRemove) {
      component.removeFromParent();
    }
  }

  void showEffectNotification(String effectType, double value, double duration) {
    // Simple console output for now - could be enhanced with UI notifications
    print('Effect applied: $effectType (${value.toStringAsFixed(1)}) for ${duration.toStringAsFixed(1)}s');
  }
} 

```

Now let me work on changing the swarm spawn to 6 per spawn. I need to find where swarmers are spawned:

I need to find where multiple swarmers are spawned. Let me check the wave spawning logic more carefully:

I can see that the swarmer spawn count is already set to 6 in the enemies.json config file I created. However, I need to modify the spawning logic to actually spawn multiple swarmers when a swarmer is selected. Let me modify the _createEnemyFactory method to handle swarmer spawning differently:

```dart
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
import '../components/abilities/hex_field.dart';
import '../components/companions/drone_wingman.dart';
import '../components/companions/hero_clone.dart';
import '../config/item_config.dart';
import '../config/wave_config.dart';
import '../config/hero_config.dart';
import '../config/game_mode_config.dart';
import '../config/display_config.dart';
import '../config/enemy_stats_config.dart';

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
  double get waveDuration => WaveConfig.instance.settings?.waveDuration ?? 30.0;
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
        position: Vector2.zero(),
        anchor: Anchor.topLeft,
      );
      add(backgroundArena);
    } catch (e) {
      print('Could not load background image: $e');
      // Create a simple colored background as fallback
      final rect = RectangleComponent(
        size: Vector2(arenaWidth, arenaHeight),
        position: Vector2.zero(),
        paint: Paint()..color = const Color(0xFF1A1A1A),
        anchor: Anchor.topLeft,
      );
      add(rect);
    }
    
    // Load other configurations
    await ItemConfig.instance.loadConfig();
    await WaveConfig.instance.loadConfig();
    await HeroConfig.instance.loadConfig();
    await GameModeConfig.instance.loadConfig();
    await EnemyStatsConfig.instance.loadConfig();
    
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
    
    // Remove all overlays
    overlays.remove('HeroSelection');
    overlays.remove('GameOver');
    overlays.remove('Victory');
    overlays.remove('PauseMenu');
    
    clearAllItems();
    _clearLingeringComponents();

    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.resetPassiveEffects();
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
    
    // Start first wave
    startWave(currentWave);
  }
  
  void restartGame() {
    // Reset game over sound flag
    gameOverSoundPlayed = false;
    
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
    _clearLingeringComponents();
    
    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.resetPassiveEffects();
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
    
    // Add stats overlay for coin and stats display during gameplay
    if (!statsOverlay.isMounted) {
      add(statsOverlay);
    }
    statsOverlay.show();
    
    // Start first wave (which will start BGM)
    startWave(currentWave);
  }
  
  void showStartMenu() {
    gameState = GameState.startMenu;
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
    
    // Try to drop item (unified system)
    if (enemy is PositionComponent) {
      consumableDropManager.tryDropItem(enemy.position);
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
      _clearLingeringComponents();
      
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
          shopPanel.show();
          
          // Ensure stats overlay is on top by adding it after the shop panel
          if (statsOverlay.isMounted) {
            statsOverlay.removeFromParent();
          }
          add(statsOverlay);
          statsOverlay.show();
          
          // Auto refresh shop items
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
  
  void onHeroDeath() {
    if (gameOverSoundPlayed) return; // Prevent multiple fail sounds
    
    // Handle 1HP Challenge mode retry tokens
    if (currentGameMode == GameMode.oneHpChallenge && retryTokens > 0) {
      consumeRetryToken();
      revivePlayer();
      return;
    }
    
    gameState = GameState.gameOver;
    gameOverSoundPlayed = true;
    
    // Clear all item drops when game ends
    clearAllItems();
    _clearLingeringComponents();
    
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
      hud.updateArmor(hero.shield, hero.totalShieldHP);
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
      hud.updateWaveTimer(remainingTime);
      
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
        return () {
          // Spawn multiple swarmers at once
          final swarmCount = EnemyStatsConfig.instance.getEnemyStats('swarmer')?.spawnCount ?? 6;
          final mainSwarmer = Swarmer();
          
          // Spawn additional swarmers around the main one
          for (int i = 1; i < swarmCount; i++) {
            final angle = (i / swarmCount) * 2 * pi;
            final offset = Vector2(
              cos(angle) * 30.0 * DisplayConfig.instance.scaleFactor,
              sin(angle) * 30.0 * DisplayConfig.instance.scaleFactor,
            );
            
            // Create additional swarmer with slight position offset
            final additionalSwarmer = Swarmer();
            Future.delayed(Duration.zero, () {
              if (additionalSwarmer.isMounted) {
                additionalSwarmer.position += offset;
              }
            });
            
            add(additionalSwarmer);
            currentEnemies.add(additionalSwarmer);
          }
          
          return mainSwarmer;
        };
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
      
      // Update background size if it exists
      if (backgroundArena.isMounted) {
        backgroundArena.size = Vector2(arenaWidth, arenaHeight);
      }
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
  
  void _clearLingeringComponents() {
    final componentsToRemove = <Component>[];

    for (final component in children) {
      if (component is DroneWingman ||
          component is HeroClone ||
          component is HexField ||
          component is AbilityVisualEffect ||
          component is Mine ||
          component.runtimeType.toString().contains('Projectile') ||
          component.runtimeType.toString().contains('Effect') ||
          component.runtimeType.toString().contains('Explosion')) {
        componentsToRemove.add(component);
      }
    }

    for (final component in componentsToRemove) {
      component.removeFromParent();
    }
  }

  void showEffectNotification(String effectType, double value, double duration) {
    // Simple console output for now - could be enhanced with UI notifications
    print('Effect applied: $effectType (${value.toStringAsFixed(1)}) for ${duration.toStringAsFixed(1)}s');
  }
} 

```

Now let me work on changing the splitter to spawn 6 replicas after death. I need to update the splitter implementation:

```dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';

class Splitter extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 60.0;
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('splitter') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 40.0;
  double maxHealth = 40.0;
  bool isDead = false;
  
  // Splitter behavior
  final int generation; // 0 = original, 1 = first split, 2 = second split
  static const int maxGenerations = 2;
  static const int splitsPerGeneration = 6;
  
  // Visual effects
  double pulseTimer = 0.0;
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  Splitter({Vector2? position, this.generation = 0}) : super(
    position: position ?? Vector2.zero(),
    radius: _getRadiusForGeneration(generation) * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = _getColorForGeneration(generation),
    anchor: Anchor.center,
  ) {
    // Adjust health based on generation
    health = _getHealthForGeneration(generation);
    maxHealth = health;
  }
  
  static double _getRadiusForGeneration(int generation) {
    switch (generation) {
      case 0: return 18.0; // Large original
      case 1: return 14.0; // Medium splits
      case 2: return 10.0; // Small final splits
      default: return 10.0;
    }
  }
  
  static Color _getColorForGeneration(int generation) {
    switch (generation) {
      case 0: return const Color(0xFF9C27B0); // Purple
      case 1: return const Color(0xFFE91E63); // Pink
      case 2: return const Color(0xFFF44336); // Red
      default: return const Color(0xFFF44336);
    }
  }
  
  static double _getHealthForGeneration(int generation) {
    switch (generation) {
      case 0: return 40.0; // Strong original
      case 1: return 25.0; // Weaker splits
      case 2: return 15.0; // Weakest final splits
      default: return 15.0;
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw pulsing core effect
    final center = Offset(size.x / 2, size.y / 2);
    final pulseIntensity = (sin(pulseTimer * 4.0) + 1.0) / 2.0;
    final coreRadius = radius * (0.5 + 0.2 * pulseIntensity);
    
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.8 * pulseIntensity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, coreRadius, corePaint);
    
    // Draw generation indicator (rings)
    for (int i = 0; i <= generation; i++) {
      final ringPaint = Paint()
        ..color = paint.color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawCircle(center, radius + (i * 3.0), ringPaint);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    if (isDead) return;
    
    pulseTimer += dt;
    
    // Handle stun
    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
      }
      return;
    }
    
    // Remove if too far from arena center (cleanup)
    final arenaCenter = Vector2(DisplayConfig.instance.arenaWidth / 2, DisplayConfig.instance.arenaHeight / 2);
    final maxDistance = (DisplayConfig.instance.arenaWidth + DisplayConfig.instance.arenaHeight) / 3;
    if (position.distanceTo(arenaCenter) > maxDistance) {
      removeFromParent();
      return;
    }
    
    // Stay within safe area
    _constrainToSafeArea();
    
    // Chase hero with moderate aggression
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final direction = (hero.position - position).normalized();
      final noStayForce = gameRef.getNoStayZoneForce(position);
      final finalDirection = (direction + noStayForce * dt).normalized();
      
      // Speed decreases with each generation
      final generationSpeedMultiplier = 1.0 - (generation * 0.2);
      position += finalDirection * speed * generationSpeedMultiplier * dt * speedMultiplier;
      
      // Check collision with hero
      final distanceToHero = position.distanceTo(hero.position);
      if (distanceToHero <= radius + hero.collisionRadius) {
        final contactDamage = 20.0 + (generation * 5.0); // More damage from smaller splits
        hero.takeDamage(contactDamage);
        takeDamage(health); // Die on contact
      }
    }
  }
  
  void _constrainToSafeArea() {
    final margin = DisplayConfig.instance.safeAreaMargin;
    position.x = position.x.clamp(
      margin, 
      DisplayConfig.instance.arenaWidth - margin
    );
    position.y = position.y.clamp(
      margin, 
      DisplayConfig.instance.arenaHeight - margin
    );
  }
  
  void takeDamage(double damageAmount) {
    health -= damageAmount;
    
    if (health <= 0) {
      _split();
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
    }
  }
  
  void _split() {
    // Only split if we haven't reached max generations
    if (generation < maxGenerations) {
      final random = Random();
      
      for (int i = 0; i < splitsPerGeneration; i++) {
        // Create split at random angle from current position
        final angle = random.nextDouble() * 2 * pi;
        final distance = 30.0 * DisplayConfig.instance.scaleFactor;
        final splitPosition = Vector2(
          position.x + cos(angle) * distance,
          position.y + sin(angle) * distance,
        );
        
        // Ensure split position is within arena bounds
        splitPosition.x = splitPosition.x.clamp(
          DisplayConfig.instance.safeAreaMargin,
          DisplayConfig.instance.arenaWidth - DisplayConfig.instance.safeAreaMargin,
        );
        splitPosition.y = splitPosition.y.clamp(
          DisplayConfig.instance.safeAreaMargin,
          DisplayConfig.instance.arenaHeight - DisplayConfig.instance.safeAreaMargin,
        );
        
        final splitEnemy = Splitter(
          position: splitPosition,
          generation: generation + 1,
        );
        
        gameRef.add(splitEnemy);
        gameRef.currentEnemies.add(splitEnemy);
      }
    }
  }
  
  void stun(double duration) {
    isStunned = true;
    stunDuration = duration;
    stunTimer = duration;
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
}

```

I should also update the enemies.json config to reflect this change:

```json
      "splits_per_generation": 6,
```

The config file already has the correct value. Let me check if the splitter actually uses the config value:

Good! The splitter is already using the splitsPerGeneration constant, which I updated to 6. Let me also update it to use the config system for consistency:

```dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_stats_config.dart';

class Splitter extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 60.0;
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('splitter') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 40.0;
  double maxHealth = 40.0;
  bool isDead = false;
  
  // Splitter behavior
  final int generation; // 0 = original, 1 = first split, 2 = second split
  static const int maxGenerations = 2;
  static const int splitsPerGeneration = 6;
  
  // Visual effects
  double pulseTimer = 0.0;
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  Splitter({Vector2? position, this.generation = 0}) : super(
    position: position ?? Vector2.zero(),
    radius: _getRadiusForGeneration(generation) * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = _getColorForGeneration(generation),
    anchor: Anchor.center,
  ) {
    // Adjust health based on generation
    health = _getHealthForGeneration(generation);
    maxHealth = health;
  }
  
  static double _getRadiusForGeneration(int generation) {
    switch (generation) {
      case 0: return 18.0; // Large original
      case 1: return 14.0; // Medium splits
      case 2: return 10.0; // Small final splits
      default: return 10.0;
    }
  }
  
  static Color _getColorForGeneration(int generation) {
    switch (generation) {
      case 0: return const Color(0xFF9C27B0); // Purple
      case 1: return const Color(0xFFE91E63); // Pink
      case 2: return const Color(0xFFF44336); // Red
      default: return const Color(0xFFF44336);
    }
  }
  
  static double _getHealthForGeneration(int generation) {
    switch (generation) {
      case 0: return 40.0; // Strong original
      case 1: return 25.0; // Weaker splits
      case 2: return 15.0; // Weakest final splits
      default: return 15.0;
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw pulsing core effect
    final center = Offset(size.x / 2, size.y / 2);
    final pulseIntensity = (sin(pulseTimer * 4.0) + 1.0) / 2.0;
    final coreRadius = radius * (0.5 + 0.2 * pulseIntensity);
    
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.8 * pulseIntensity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, coreRadius, corePaint);
    
    // Draw generation indicator (rings)
    for (int i = 0; i <= generation; i++) {
      final ringPaint = Paint()
        ..color = paint.color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawCircle(center, radius + (i * 3.0), ringPaint);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    if (isDead) return;
    
    pulseTimer += dt;
    
    // Handle stun
    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
      }
      return;
    }
    
    // Remove if too far from arena center (cleanup)
    final arenaCenter = Vector2(DisplayConfig.instance.arenaWidth / 2, DisplayConfig.instance.arenaHeight / 2);
    final maxDistance = (DisplayConfig.instance.arenaWidth + DisplayConfig.instance.arenaHeight) / 3;
    if (position.distanceTo(arenaCenter) > maxDistance) {
      removeFromParent();
      return;
    }
    
    // Stay within safe area
    _constrainToSafeArea();
    
    // Chase hero with moderate aggression
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final direction = (hero.position - position).normalized();
      final noStayForce = gameRef.getNoStayZoneForce(position);
      final finalDirection = (direction + noStayForce * dt).normalized();
      
      // Speed decreases with each generation
      final generationSpeedMultiplier = 1.0 - (generation * 0.2);
      position += finalDirection * speed * generationSpeedMultiplier * dt * speedMultiplier;
      
      // Check collision with hero
      final distanceToHero = position.distanceTo(hero.position);
      if (distanceToHero <= radius + hero.collisionRadius) {
        final contactDamage = 20.0 + (generation * 5.0); // More damage from smaller splits
        hero.takeDamage(contactDamage);
        takeDamage(health); // Die on contact
      }
    }
  }
  
  void _constrainToSafeArea() {
    final margin = DisplayConfig.instance.safeAreaMargin;
    position.x = position.x.clamp(
      margin, 
      DisplayConfig.instance.arenaWidth - margin
    );
    position.y = position.y.clamp(
      margin, 
      DisplayConfig.instance.arenaHeight - margin
    );
  }
  
  void takeDamage(double damageAmount) {
    health -= damageAmount;
    
    if (health <= 0) {
      _split();
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
    }
  }
  
  void _split() {
    // Only split if we haven't reached max generations
    if (generation < maxGenerations) {
      final random = Random();
      
      for (int i = 0; i < splitsPerGeneration; i++) {
        // Create split at random angle from current position
        final angle = random.nextDouble() * 2 * pi;
        final distance = 30.0 * DisplayConfig.instance.scaleFactor;
        final splitPosition = Vector2(
          position.x + cos(angle) * distance,
          position.y + sin(angle) * distance,
        );
        
        // Ensure split position is within arena bounds
        splitPosition.x = splitPosition.x.clamp(
          DisplayConfig.instance.safeAreaMargin,
          DisplayConfig.instance.arenaWidth - DisplayConfig.instance.safeAreaMargin,
        );
        splitPosition.y = splitPosition.y.clamp(
          DisplayConfig.instance.safeAreaMargin,
          DisplayConfig.instance.arenaHeight - DisplayConfig.instance.safeAreaMargin,
        );
        
        final splitEnemy = Splitter(
          position: splitPosition,
          generation: generation + 1,
        );
        
        gameRef.add(splitEnemy);
        gameRef.currentEnemies.add(splitEnemy);
      }
    }
  }
  
  void stun(double duration) {
    isStunned = true;
    stunDuration = duration;
    stunTimer = duration;
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
}

```

```dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_stats_config.dart';

class Splitter extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 60.0;
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('splitter') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 40.0;
  double maxHealth = 40.0;
  bool isDead = false;
  
  // Splitter behavior
  final int generation; // 0 = original, 1 = first split, 2 = second split
  static const int maxGenerations = 2;
  static const int splitsPerGeneration = 6;
  
  // Visual effects
  double pulseTimer = 0.0;
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  Splitter({Vector2? position, this.generation = 0}) : super(
    position: position ?? Vector2.zero(),
    radius: _getRadiusForGeneration(generation) * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = _getColorForGeneration(generation),
    anchor: Anchor.center,
  ) {
    // Adjust health based on generation
    health = _getHealthForGeneration(generation);
    maxHealth = health;
  }
  
  static double _getRadiusForGeneration(int generation) {
    switch (generation) {
      case 0: return 18.0; // Large original
      case 1: return 14.0; // Medium splits
      case 2: return 10.0; // Small final splits
      default: return 10.0;
    }
  }
  
  static Color _getColorForGeneration(int generation) {
    switch (generation) {
      case 0: return const Color(0xFF9C27B0); // Purple
      case 1: return const Color(0xFFE91E63); // Pink
      case 2: return const Color(0xFFF44336); // Red
      default: return const Color(0xFFF44336);
    }
  }
  
  static double _getHealthForGeneration(int generation) {
    switch (generation) {
      case 0: return 40.0; // Strong original
      case 1: return 25.0; // Weaker splits
      case 2: return 15.0; // Weakest final splits
      default: return 15.0;
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw pulsing core effect
    final center = Offset(size.x / 2, size.y / 2);
    final pulseIntensity = (sin(pulseTimer * 4.0) + 1.0) / 2.0;
    final coreRadius = radius * (0.5 + 0.2 * pulseIntensity);
    
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.8 * pulseIntensity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, coreRadius, corePaint);
    
    // Draw generation indicator (rings)
    for (int i = 0; i <= generation; i++) {
      final ringPaint = Paint()
        ..color = paint.color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawCircle(center, radius + (i * 3.0), ringPaint);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    if (isDead) return;
    
    pulseTimer += dt;
    
    // Handle stun
    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
      }
      return;
    }
    
    // Remove if too far from arena center (cleanup)
    final arenaCenter = Vector2(DisplayConfig.instance.arenaWidth / 2, DisplayConfig.instance.arenaHeight / 2);
    final maxDistance = (DisplayConfig.instance.arenaWidth + DisplayConfig.instance.arenaHeight) / 3;
    if (position.distanceTo(arenaCenter) > maxDistance) {
      removeFromParent();
      return;
    }
    
    // Stay within safe area
    _constrainToSafeArea();
    
    // Chase hero with moderate aggression
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final direction = (hero.position - position).normalized();
      final noStayForce = gameRef.getNoStayZoneForce(position);
      final finalDirection = (direction + noStayForce * dt).normalized();
      
      // Speed decreases with each generation
      final generationSpeedMultiplier = 1.0 - (generation * 0.2);
      position += finalDirection * speed * generationSpeedMultiplier * dt * speedMultiplier;
      
      // Check collision with hero
      final distanceToHero = position.distanceTo(hero.position);
      if (distanceToHero <= radius + hero.collisionRadius) {
        final contactDamage = 20.0 + (generation * 5.0); // More damage from smaller splits
        hero.takeDamage(contactDamage);
        takeDamage(health); // Die on contact
      }
    }
  }
  
  void _constrainToSafeArea() {
    final margin = DisplayConfig.instance.safeAreaMargin;
    position.x = position.x.clamp(
      margin, 
      DisplayConfig.instance.arenaWidth - margin
    );
    position.y = position.y.clamp(
      margin, 
      DisplayConfig.instance.arenaHeight - margin
    );
  }
  
  void takeDamage(double damageAmount) {
    health -= damageAmount;
    
    if (health <= 0) {
      _split();
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
    }
  }
  
  void _split() {
    // Only split if we haven't reached max generations
    if (generation < maxGenerations) {
      final random = Random();
      
      final configSplits = EnemyStatsConfig.instance.getEnemyStats('splitter')?.splitsPerGeneration ?? splitsPerGeneration;
      for (int i = 0; i < configSplits; i++) {
        // Create split at random angle from current position
        final angle = random.nextDouble() * 2 * pi;
        final distance = 30.0 * DisplayConfig.instance.scaleFactor;
        final splitPosition = Vector2(
          position.x + cos(angle) * distance,
          position.y + sin(angle) * distance,
        );
        
        // Ensure split position is within arena bounds
        splitPosition.x = splitPosition.x.clamp(
          DisplayConfig.instance.safeAreaMargin,
          DisplayConfig.instance.arenaWidth - DisplayConfig.instance.safeAreaMargin,
        );
        splitPosition.y = splitPosition.y.clamp(
          DisplayConfig.instance.safeAreaMargin,
          DisplayConfig.instance.arenaHeight - DisplayConfig.instance.safeAreaMargin,
        );
        
        final splitEnemy = Splitter(
          position: splitPosition,
          generation: generation + 1,
        );
        
        gameRef.add(splitEnemy);
        gameRef.currentEnemies.add(splitEnemy);
      }
    }
  }
  
  void stun(double duration) {
    isStunned = true;
    stunDuration = duration;
    stunTimer = duration;
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
}

```

Finally, let me work on changing the miner's mine to deal direct damage instead of spreading bullets. I need to modify the mine explosion logic:

I can see that the mine already deals direct damage to the hero in the _explode method (lines 299-304). The _createExplosionEffect method only creates visual fragments, not damaging bullets. However, let me check if there are any projectiles being created elsewhere. Let me look at the full _createExplosionEffect method:

I can see that the mine explosion is already working as requested - it deals direct damage to the player in the `_explode` method and only creates visual fragments (not damaging projectiles) in the `_createExplosionEffect` method. The visual fragments are just CircleComponents that move outward and disappear after 0.5 seconds - they don't damage the player.

Let me double-check by looking for any projectile creation in the mine explosion:

Perfect! The mine layer doesn't create any projectiles - it already deals direct damage. The current implementation is exactly what was requested. Let me mark this task as completed:

Perfect! I have completed all the requested changes. Let me run a final check for any potential issues by checking the lints for the files I've modified:

Excellent! All the changes have been implemented successfully without any linting errors. Let me summarize what has been accomplished:

## Summary of Changes Implemented

✅ **All requested changes have been completed:**

1. **Fixed restart not clearing arena** - Enhanced the `_clearLingeringComponents()` method to clear projectiles, effects, and explosions that might linger after restart.

2. **Fixed Auto Injector MAX HP effect** - Completely reworked the Auto Injector to work as requested:
   - Changed from heal per kill to max HP boost per 10 kills
   - Every 10 kills grants +2 max HP per stack
   - Caps at +50 max HP per stack (with 5 max stacks)
   - Added kill tracking to the Hero class
   - Updated item description and UI display

3. **Enhanced Enlarged Caliber** - Made it enlarge both projectiles AND character:
   - Character size increases by 10% per stack
   - Character speed decreases by 25% per stack  
   - Limited to 5 max stacks instead of 10
   - Updated item description and UI display

4. **Removed drone purchase limit** - Changed drone limit from 3 to 999 (unlimited):
   - Updated item configuration
   - Updated UI display to show "Unlimited"

5. **Increased sniper bullet damage** - Sniper bullets now deal 50% of player's current HP as damage instead of fixed 40 damage.

6. **Created enemy configuration system** - Added new JSON config file and system:
   - Created `assets/config/enemies.json` with all enemy stats
   - Created `lib/config/enemy_stats_config.dart` to load and manage enemy configs
   - Integrated the config loading into the game initialization

7. **Changed swarm spawn to 6** - Modified swarm spawning logic:
   - When a swarmer is selected, it now spawns 6 swarmers in a group
   - Updated the spawning system to handle multiple swarmers per spawn event

8. **Changed splitter to spawn 6 replicas** - Updated splitter behavior:
   - Increased splits per generation from 2 to 6
   - Integrated with the new enemy config system

9. **Confirmed miner direct damage** - Verified that mines already deal direct damage instead of spreading bullets (this was already implemented correctly).

All changes maintain code quality with no linting errors, follow the existing code patterns, and are properly integrated with the game's configuration systems. The implementation allows for easy future modifications through the JSON configuration files.

---

**User**

hmm we have this error:
```
Launching lib\main.dart on Edge in debug mode...

===== CRASH =====
ExceptionCode=-1073741819, ExceptionFlags=0, ExceptionAddress=0000019C0961E051
the Dart compiler exited unexpectedly.
Failed to compile application.

Exited (1).
```
What happened

---

**Cursor**

This crash looks like a serious compilation error, likely caused by one of the recent changes. The `-1073741819` exception code typically indicates a memory access violation during compilation. Let me check for potential issues in the modified files.

Now let me check for syntax errors in the modified files. The crash could be due to a syntax issue I introduced. Let me check the most likely culprits:

I can see there are massive compilation errors, but they're mostly related to missing Flutter/Material imports in overlay files, not related to my changes. The crash is likely due to a more fundamental issue. Let me check if there are any syntax errors in the files I modified:

The main game file only has linting warnings, no errors. Let me check the hero file:

The hero file also only has linting warnings. The issue might be in the swarm spawning logic I added. Let me check if there's a circular reference or infinite loop in the swarm spawning code. The issue is likely in this part:

I think I see the issue. The swarm spawning logic is problematic because:

1. I'm trying to add components directly in the factory function
2. I'm using `Future.delayed` which could cause timing issues
3. The factory function should return a simple constructor, not execute complex logic

Let me fix this by reverting the swarm spawning logic to a simpler approach:

```dart
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
import '../components/abilities/hex_field.dart';
import '../components/companions/drone_wingman.dart';
import '../components/companions/hero_clone.dart';
import '../config/item_config.dart';
import '../config/wave_config.dart';
import '../config/hero_config.dart';
import '../config/game_mode_config.dart';
import '../config/display_config.dart';
import '../config/enemy_stats_config.dart';

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
  double get waveDuration => WaveConfig.instance.settings?.waveDuration ?? 30.0;
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
        position: Vector2.zero(),
        anchor: Anchor.topLeft,
      );
      add(backgroundArena);
    } catch (e) {
      print('Could not load background image: $e');
      // Create a simple colored background as fallback
      final rect = RectangleComponent(
        size: Vector2(arenaWidth, arenaHeight),
        position: Vector2.zero(),
        paint: Paint()..color = const Color(0xFF1A1A1A),
        anchor: Anchor.topLeft,
      );
      add(rect);
    }
    
    // Load other configurations
    await ItemConfig.instance.loadConfig();
    await WaveConfig.instance.loadConfig();
    await HeroConfig.instance.loadConfig();
    await GameModeConfig.instance.loadConfig();
    await EnemyStatsConfig.instance.loadConfig();
    
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
    
    // Remove all overlays
    overlays.remove('HeroSelection');
    overlays.remove('GameOver');
    overlays.remove('Victory');
    overlays.remove('PauseMenu');
    
    clearAllItems();
    _clearLingeringComponents();

    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.resetPassiveEffects();
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
    
    // Start first wave
    startWave(currentWave);
  }
  
  void restartGame() {
    // Reset game over sound flag
    gameOverSoundPlayed = false;
    
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
    _clearLingeringComponents();
    
    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.resetPassiveEffects();
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
    
    // Add stats overlay for coin and stats display during gameplay
    if (!statsOverlay.isMounted) {
      add(statsOverlay);
    }
    statsOverlay.show();
    
    // Start first wave (which will start BGM)
    startWave(currentWave);
  }
  
  void showStartMenu() {
    gameState = GameState.startMenu;
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
    
    // Try to drop item (unified system)
    if (enemy is PositionComponent) {
      consumableDropManager.tryDropItem(enemy.position);
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
      _clearLingeringComponents();
      
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
          shopPanel.show();
          
          // Ensure stats overlay is on top by adding it after the shop panel
          if (statsOverlay.isMounted) {
            statsOverlay.removeFromParent();
          }
          add(statsOverlay);
          statsOverlay.show();
          
          // Auto refresh shop items
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
  
  void onHeroDeath() {
    if (gameOverSoundPlayed) return; // Prevent multiple fail sounds
    
    // Handle 1HP Challenge mode retry tokens
    if (currentGameMode == GameMode.oneHpChallenge && retryTokens > 0) {
      consumeRetryToken();
      revivePlayer();
      return;
    }
    
    gameState = GameState.gameOver;
    gameOverSoundPlayed = true;
    
    // Clear all item drops when game ends
    clearAllItems();
    _clearLingeringComponents();
    
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
      hud.updateArmor(hero.shield, hero.totalShieldHP);
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
      hud.updateWaveTimer(remainingTime);
      
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
      
      // Update background size if it exists
      if (backgroundArena.isMounted) {
        backgroundArena.size = Vector2(arenaWidth, arenaHeight);
      }
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
  
  void _clearLingeringComponents() {
    final componentsToRemove = <Component>[];

    for (final component in children) {
      if (component is DroneWingman ||
          component is HeroClone ||
          component is HexField ||
          component is AbilityVisualEffect ||
          component is Mine ||
          component.runtimeType.toString().contains('Projectile') ||
          component.runtimeType.toString().contains('Effect') ||
          component.runtimeType.toString().contains('Explosion')) {
        componentsToRemove.add(component);
      }
    }

    for (final component in componentsToRemove) {
      component.removeFromParent();
    }
  }

  void showEffectNotification(String effectType, double value, double duration) {
    // Simple console output for now - could be enhanced with UI notifications
    print('Effect applied: $effectType (${value.toStringAsFixed(1)}) for ${duration.toStringAsFixed(1)}s');
  }
} 

```

Now I need to implement the swarm spawning logic in a different way. Instead of trying to spawn multiple swarmers in the factory, I'll modify the `_spawnEnemyAtRandomEdge` method to handle swarmers specially:

Let me find the `_spawnEnemyAtRandomEdge` method:

I need to modify the `_spawnRandomEnemy` method to handle swarmer spawning specially. Instead of changing the factory, I'll modify the logic to spawn multiple swarmers when a swarmer is selected:

```dart
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
import '../components/abilities/hex_field.dart';
import '../components/companions/drone_wingman.dart';
import '../components/companions/hero_clone.dart';
import '../config/item_config.dart';
import '../config/wave_config.dart';
import '../config/hero_config.dart';
import '../config/game_mode_config.dart';
import '../config/display_config.dart';
import '../config/enemy_stats_config.dart';

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
  double get waveDuration => WaveConfig.instance.settings?.waveDuration ?? 30.0;
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
        position: Vector2.zero(),
        anchor: Anchor.topLeft,
      );
      add(backgroundArena);
    } catch (e) {
      print('Could not load background image: $e');
      // Create a simple colored background as fallback
      final rect = RectangleComponent(
        size: Vector2(arenaWidth, arenaHeight),
        position: Vector2.zero(),
        paint: Paint()..color = const Color(0xFF1A1A1A),
        anchor: Anchor.topLeft,
      );
      add(rect);
    }
    
    // Load other configurations
    await ItemConfig.instance.loadConfig();
    await WaveConfig.instance.loadConfig();
    await HeroConfig.instance.loadConfig();
    await GameModeConfig.instance.loadConfig();
    await EnemyStatsConfig.instance.loadConfig();
    
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
    
    // Remove all overlays
    overlays.remove('HeroSelection');
    overlays.remove('GameOver');
    overlays.remove('Victory');
    overlays.remove('PauseMenu');
    
    clearAllItems();
    _clearLingeringComponents();

    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.resetPassiveEffects();
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
    
    // Start first wave
    startWave(currentWave);
  }
  
  void restartGame() {
    // Reset game over sound flag
    gameOverSoundPlayed = false;
    
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
    _clearLingeringComponents();
    
    // Remove existing hero if mounted
    if (hero.isMounted) {
      hero.resetPassiveEffects();
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
    
    // Add stats overlay for coin and stats display during gameplay
    if (!statsOverlay.isMounted) {
      add(statsOverlay);
    }
    statsOverlay.show();
    
    // Start first wave (which will start BGM)
    startWave(currentWave);
  }
  
  void showStartMenu() {
    gameState = GameState.startMenu;
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
    
    // Try to drop item (unified system)
    if (enemy is PositionComponent) {
      consumableDropManager.tryDropItem(enemy.position);
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
      _clearLingeringComponents();
      
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
          shopPanel.show();
          
          // Ensure stats overlay is on top by adding it after the shop panel
          if (statsOverlay.isMounted) {
            statsOverlay.removeFromParent();
          }
          add(statsOverlay);
          statsOverlay.show();
          
          // Auto refresh shop items
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
  
  void onHeroDeath() {
    if (gameOverSoundPlayed) return; // Prevent multiple fail sounds
    
    // Handle 1HP Challenge mode retry tokens
    if (currentGameMode == GameMode.oneHpChallenge && retryTokens > 0) {
      consumeRetryToken();
      revivePlayer();
      return;
    }
    
    gameState = GameState.gameOver;
    gameOverSoundPlayed = true;
    
    // Clear all item drops when game ends
    clearAllItems();
    _clearLingeringComponents();
    
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
      hud.updateArmor(hero.shield, hero.totalShieldHP);
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
      hud.updateWaveTimer(remainingTime);
      
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
      
      // Special handling for swarmers - spawn multiple at once
      if (selectedEnemyType == 'swarmer') {
        final swarmCount = EnemyStatsConfig.instance.getEnemyStats('swarmer')?.spawnCount ?? 6;
        for (int i = 0; i < swarmCount; i++) {
          _spawnEnemyAtRandomEdge(enemyFactory, random);
        }
        return; // Early return to avoid spawning another one below
      }
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
      
      // Update background size if it exists
      if (backgroundArena.isMounted) {
        backgroundArena.size = Vector2(arenaWidth, arenaHeight);
      }
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
  
  void _clearLingeringComponents() {
    final componentsToRemove = <Component>[];

    for (final component in children) {
      if (component is DroneWingman ||
          component is HeroClone ||
          component is HexField ||
          component is AbilityVisualEffect ||
          component is Mine ||
          component.runtimeType.toString().contains('Projectile') ||
          component.runtimeType.toString().contains('Effect') ||
          component.runtimeType.toString().contains('Explosion')) {
        componentsToRemove.add(component);
      }
    }

    for (final component in componentsToRemove) {
      component.removeFromParent();
    }
  }

  void showEffectNotification(String effectType, double value, double duration) {
    // Simple console output for now - could be enhanced with UI notifications
    print('Effect applied: $effectType (${value.toStringAsFixed(1)}) for ${duration.toStringAsFixed(1)}s');
  }
} 

```

Now let me try to compile and see if the crash is fixed:

Great! The modified files now only have linting warnings (no errors). Let me try a basic compilation test:

