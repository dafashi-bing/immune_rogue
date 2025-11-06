# Improve game over mechanics
_Exported on 9/26/2025 at 22:14:17 PDT from Cursor (1.6.45)_

---

**User**

game over should first deduce the hp, and then claim game over. Additionally, instead of always saying "The shape have claimed another hero...", have a unique line for each kind of enemy who dealt the last lethal damage to the hero.

---

**Cursor**

I'll search for where the hero's damage and game over flow are handled, and locate the current game over message string to implement per-enemy messaging after HP deduction.

I'll look for all places that trigger player death or apply damage to ensure HP is reduced before ending the game, and find where hero damage is inflicted by enemies to attach the killer context for the Game Over message.

I'll search for where `hero.takeDamage` is called to capture the damage source and ensure we can set a killer reference for the Game Over overlay.

I'll open the relevant files to see how projectiles are structured, how the overlay is built/passed data, and how we can thread through the killer info and a custom death message.

I'll open enemy files that call `hero.takeDamage` to see how to pass the killer type; and I'll open `game_over_overlay.dart` to update the subtitle to use a message from the game state.

I'll update the code to track the killer type and cause through damage, change the game over handler to accept and store this info, and update the overlay to display a per-enemy message. Then I'll modify all damage call sites and enemy projectiles to pass the killer context.

I'll create a short task list and start by adding killer tracking and message mapping in the game state, then wire it through damage and projectiles, and finally update the overlay to show the custom message.

I'm going to implement killer tracking and custom death messages in `circle_rouge_game.dart`, then wire the killer source through `hero.takeDamage`, enemy projectiles, and enemy contact/explosions, and finally update the Game Over overlay to display the message.

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
          shopPanel.resetForNewWave(); // Reset roll count for new wave
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
```

I'll update `Hero.takeDamage` to accept an optional source type and propagate this killer info through all enemy contact and projectile damage paths. Then I'll modify `Projectile` (and `ShapeProjectile` for completeness) to carry the enemy owner type and update the Game Over overlay to use `game.lastDeathMessage`.

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/circle_rouge_game.dart';
import '../config/hero_config.dart';
import '../config/display_config.dart';
import '../config/wave_config.dart';
import '../config/item_config.dart';
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
  double get moveSpeed => ((heroData.moveSpeed / 320.0 * baseMoveSpeed) * DisplayConfig.instance.scaleFactor) * (1.0 - enlargedCaliberSpeedReduction);
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
  
  // Kill tracking for auto-injector
  int totalKills = 0;
  int autoInjectorBonusHP = 0; // Track bonus HP from auto-injector
  
  // Drone companion system
  final List<DroneWingman> _activeDrones = [];
  
  // Clone system
  HeroClone? _activeClone;
  
  // Shield system
  double shield = 0.0;
  double maxShield = 0.0;
  
  // Input tracking
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  
  // Display config listener for dynamic scaling
  DisplayConfigChangeCallback? _displayConfigListener;
  
  // Base values for responsive scaling
  static const double baseHeroRadius = 15.0;
  static const double baseHeroSize = 30.0;

  Hero({required Vector2 position, required this.heroId}) : super(
    position: position,
    size: Vector2.all(baseHeroSize * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    heroRadius = baseHeroRadius * DisplayConfig.instance.scaleFactor * totalCharacterSize;
    heroPaint = Paint()..color = const Color(0xFF4CAF50);
    _initializeHero(heroId);
    _setupDynamicScaling();
  }
  
  /// Set up dynamic scaling listener
  void _setupDynamicScaling() {
    _displayConfigListener = (oldSettings, newSettings) {
      _updateHeroScale();
    };
    DisplayConfig.instance.addListener(_displayConfigListener!);
  }
  
  /// Update hero scale based on current display config
  void _updateHeroScale() {
    final scaleFactor = DisplayConfig.instance.scaleFactor;
    size = Vector2.all(baseHeroSize * scaleFactor);
    heroRadius = baseHeroRadius * scaleFactor * totalCharacterSize;
    
    // Keep hero centered in arena (don't let it drift to edges)
    final arenaWidth = DisplayConfig.instance.arenaWidth;
    final arenaHeight = DisplayConfig.instance.arenaHeight;
    position = Vector2(arenaWidth / 2, arenaHeight / 2);
    
    print('Hero scale updated: size=${size.x.toInt()}, radius=${heroRadius.toInt()}, scaleFactor=${scaleFactor.toStringAsFixed(2)}, position=${position.x.toInt()},${position.y.toInt()}');
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
    
    // Always-on hero visibility glow (helps locate hero in crowds)
    // Pulses subtly at ~2 Hz and matches hero color
    final nowSeconds = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final basePulse = 0.5 + 0.5 * sin(nowSeconds * pi * 2.0); // 0..1
    final visibilityGlowIntensity = 0.35 + 0.45 * basePulse; // 0.35..0.8
    final visibilityGlowRadius = 10.0 + 14.0 * basePulse; // 10..24
    final visibilityGlowPaint = Paint()
      ..color = heroPaint.color.withOpacity(0.35 * visibilityGlowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    final visibilityCenter = Offset(size.x / 2, size.y / 2);
    // Draw below everything else
    switch (heroData.shape) {
      case 'circle':
        canvas.drawCircle(visibilityCenter, heroRadius + visibilityGlowRadius, visibilityGlowPaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, size.x, visibilityGlowPaint, visibilityGlowRadius);
        break;
      case 'square':
        _drawSquare(canvas, visibilityCenter, visibilityGlowPaint, visibilityGlowRadius);
        break;
      case 'pentagon':
        _drawPentagon(canvas, size.x, visibilityGlowPaint, visibilityGlowRadius);
        break;
      case 'hexagon':
        _drawHexagon(canvas, size.x, visibilityGlowPaint, visibilityGlowRadius);
        break;
      case 'heptagon':
        _drawHeptagon(canvas, size.x, visibilityGlowPaint, visibilityGlowRadius);
        break;
    }
    
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
      final effectTime = (DateTime.now().millisecondsSinceEpoch / 1000.0) % 1.2; // slightly faster
      final glowIntensity = (sin(effectTime * pi * 2) * 0.35 + 0.85); // 0.5..1.2 clamped by opacity
      final glowRadius = 18.0 * glowIntensity; // larger radius for visibility
      
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
        ..color = effectColor.withOpacity((0.6 * glowIntensity).clamp(0.0, 0.9))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      
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
            // Handle all other enemy types using reflection-like approach
            try {
              final takeDamageMethod = enemy.runtimeType.toString();
              if (takeDamageMethod.contains('Swarmer') || 
                  takeDamageMethod.contains('Bomber') || 
                  takeDamageMethod.contains('Sniper') || 
                  takeDamageMethod.contains('Splitter') || 
                  takeDamageMethod.contains('MineLayer')) {
                (enemy as dynamic).takeDamage(heroData.ability.damage);
              } else {
                // Fallback for unknown enemy types - remove them directly
                if (enemy.parent != null) {
                  gameRef.onEnemyDestroyed(enemy);
                }
              }
            } catch (e) {
              // If dynamic call fails, fallback to direct removal
              if (enemy.parent != null) {
                gameRef.onEnemyDestroyed(enemy);
              }
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
    
    // Trigger hit effect on HUD
    gameRef.hud.triggerHitEffect();
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
    // Calculate dash distance with both range and ability size scaling
    final baseRange = heroData.ability.range * DisplayConfig.instance.scaleFactor;
    final scaledRange = baseRange * rangeMultiplier * totalAbilitySize;
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
    
    // Create massive triangle projectile with hero color and ability size scaling
    final projectile = TriangleProjectile(
      startPosition: position.clone(),
      direction: direction,
      speed: 500.0 * DisplayConfig.instance.scaleFactor,
      damage: heroData.ability.damage,
      isEnemyProjectile: false,
      heroColor: heroData.color, // Pass hero color
      rangeMultiplier: totalAbilitySize, // Scale with enlarged caliber upgrades
      projectileSize: heroData.ability.projectileSize, // Use config size
    );
    
    gameRef.add(projectile);
  }
  
  void _executeAreaStun() {
    // Play sound effect for square hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Calculate effective range with both range and ability size scaling
    final baseRange = heroData.ability.range * DisplayConfig.instance.scaleFactor;
    final effectiveRange = baseRange * rangeMultiplier * totalAbilitySize;
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
          } else {
            // Handle all other enemy types using reflection-like approach
            try {
              final enemyTypeName = enemy.runtimeType.toString();
              if (enemyTypeName.contains('Swarmer') || 
                  enemyTypeName.contains('Bomber') || 
                  enemyTypeName.contains('Sniper') || 
                  enemyTypeName.contains('Splitter') || 
                  enemyTypeName.contains('MineLayer')) {
                (enemy as dynamic).stun(stunDuration);
              }
            } catch (e) {
              // If dynamic call fails, ignore this enemy
              print('Failed to stun enemy: ${enemy.runtimeType}');
            }
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
      
      // Create pentagon-shaped projectiles with pentagon color
      final projectile = ShapeProjectile(
        startPosition: position.clone(),
        direction: direction,
        speed: 400.0 * DisplayConfig.instance.scaleFactor,
        damage: heroData.ability.damage,
        isEnemyProjectile: false,
        shapeType: 'pentagon', // Use pentagon shape
        heroColor: heroData.color, // Use pentagon's purple color
        bounces: 0,
        sizeScale: totalAbilitySize, // Scale with enlarged caliber
        isCritical: false,
      );
      
      gameRef.add(projectile);
    }
  }
  
  void _executeAreaField() {
    // Play sound effect for hexagon hero
    SoundManager().playHeroAbilitySound(heroData.shape);
    
    // Create visual hex field effect with both range and ability size scaling
    final baseRange = heroData.ability.range * DisplayConfig.instance.scaleFactor;
    final scaledRange = baseRange * rangeMultiplier * totalAbilitySize;
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
    
    // Calculate range and knockback with both range and ability size scaling
    final baseRange = heroData.ability.range * DisplayConfig.instance.scaleFactor;
    final scaledRange = baseRange * rangeMultiplier * totalAbilitySize;
    final baseKnockback = (heroData.ability.knockbackDistance ?? 30.0) * DisplayConfig.instance.scaleFactor;
    final knockbackDistance = baseKnockback * rangeMultiplier * totalAbilitySize;
    
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
        } else {
          // Handle all other enemy types using reflection-like approach
          try {
            final enemyTypeName = enemy.runtimeType.toString();
            if (enemyTypeName.contains('Swarmer') || 
                enemyTypeName.contains('Bomber') || 
                enemyTypeName.contains('Sniper') || 
                enemyTypeName.contains('Splitter') || 
                enemyTypeName.contains('MineLayer')) {
              (enemy as dynamic).takeDamage(heroData.ability.damage);
            }
          } catch (e) {
            // If dynamic call fails, ignore this enemy
            print('Failed to damage enemy: ${enemy.runtimeType}');
          }
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
    
    // Update HUD WASD button states
    final wasdKeys = <String>{};
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW)) wasdKeys.add('W');
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA)) wasdKeys.add('A');
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS)) wasdKeys.add('S');
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD)) wasdKeys.add('D');
    gameRef.hud.updateWASDButtons(wasdKeys);
    
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
  
  void takeDamage(double damage, {String? sourceType}) {
    if (isInvincible || isDamageInvincible || isUsingAbility) {
      return; // No damage while invincible, damage invincible, or using ability
    }
    
    // Scale damage based on current wave
    final scaledDamage = WaveConfig.instance.getScaledDamage(damage, gameRef.currentWave);
    double remainingDamage = scaledDamage;
    
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
      gameRef.onHeroDeath(killerType: sourceType);
    }
  }
  
  void heal(double amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
  
  void addCoins(int amount) {
    final multiplier = totalCoinMultiplier;
    final finalAmount = (amount * multiplier).round();
    coins = (coins + finalAmount).clamp(0, 9999); // Cap coins at 9999
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
    final enlargedCaliberValue = ItemConfig.instance.getItemById('enlarged_caliber')?.effect.value ?? 0.25;
    return 1.0 + (getPassiveEffectStacks('projectile_size') * 0.5) + (getPassiveEffectStacks('enlarged_caliber') * enlargedCaliberValue);
  }
  
  double get totalAbilitySize {
    final enlargedCaliberValue = ItemConfig.instance.getItemById('enlarged_caliber')?.effect.value ?? 0.25;
    return 1.0 + (getPassiveEffectStacks('enlarged_caliber') * enlargedCaliberValue);
  }
  
  double get totalCharacterSize {
    final enlargedCaliberValue = ItemConfig.instance.getItemById('enlarged_caliber')?.effect.value ?? 0.25;
    return 1.0 + (getPassiveEffectStacks('enlarged_caliber') * enlargedCaliberValue);
  }
  
  double get enlargedCaliberSpeedReduction {
    final enlargedCaliberValue = ItemConfig.instance.getItemById('enlarged_caliber')?.effect.value ?? 0.25;
    return getPassiveEffectStacks('enlarged_caliber') * enlargedCaliberValue;
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
    totalKills++;
    
    final healAmount = totalHealPerKill;
    if (healAmount > 0) {
      heal(healAmount);
      print('Healed ${healAmount} HP from kill');
    }
    
    // Auto-injector: +2 max HP per 10 kills, max 50 HP per stack
    final autoInjectorStacks = getPassiveEffectStacks('auto_injector');
    if (autoInjectorStacks > 0 && totalKills % 10 == 0) {
      final maxBonusPerStack = 50;
      final currentBonusPerStack = (totalKills ~/ 10) * 2;
      
      // Calculate how much bonus HP each stack should contribute
      final targetBonusPerStack = currentBonusPerStack.clamp(0, maxBonusPerStack);
      final totalTargetBonus = targetBonusPerStack * autoInjectorStacks;
      
      if (totalTargetBonus > autoInjectorBonusHP) {
        final hpIncrease = totalTargetBonus - autoInjectorBonusHP;
        maxHealth += hpIncrease;
        health += hpIncrease; // Also increase current health
        autoInjectorBonusHP = totalTargetBonus;
        print('Auto-Injector: +${hpIncrease} Max HP! Total kills: ${totalKills}, Max HP: ${maxHealth}');
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
  
  void updateHeroSize() {
    heroRadius = 15.0 * DisplayConfig.instance.scaleFactor * totalCharacterSize;
    // Update component size as well
    size = Vector2.all(heroRadius * 2);
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
  
  @override
  void onRemove() {
    // Clean up display config listener
    if (_displayConfigListener != null) {
      DisplayConfig.instance.removeListener(_displayConfigListener!);
      _displayConfigListener = null;
    }
    super.onRemove();
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

```dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;
import 'dart:math';

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import 'enemy_chaser.dart';
import 'enemy_shooter.dart';
import 'shielded_chaser.dart';
import 'swarmer.dart';
import 'bomber.dart';
import 'sniper.dart';
import 'splitter.dart';
import 'mine_layer.dart';

class Projectile extends CircleComponent with HasGameRef<CircleRougeGame> {
  Vector2 direction;
  double speed;
  double damage;
  bool isEnemyProjectile;
  String? ownerEnemyType; // which enemy fired/owned this projectile
  final Color? heroColor; // Optional hero color for hero projectiles
  
  double lifeTime = 0.0;
  static const double maxLifeTime = 3.0; // Seconds before auto-destroy
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0; // Slow lasts 3 seconds
  double speedMultiplier = 1.0;
  
  // Visual properties
  late Paint projectilePaint;
  late Paint glowPaint;
  
  Projectile({
    required Vector2 startPosition,
    required this.direction,
    required this.speed,
    required this.damage,
    this.isEnemyProjectile = false,
    this.ownerEnemyType,
    this.heroColor,
    double? scaledRadius,
  }) : super(
    position: startPosition,
    radius: scaledRadius ?? (4.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    // Different colors for different projectile types
    final color = getProjectileColor(isEnemyProjectile, heroColor);
    
    projectilePaint = Paint()..color = color;
    glowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  }
  
  @override
  void onMount() {
    super.onMount();
    // Register projectile with game
    gameRef.addProjectile(this);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Update slow timer
    if (isSlowed) {
      slowTimer += dt;
      if (slowTimer >= slowDuration) {
        isSlowed = false;
        slowTimer = 0.0;
        speedMultiplier = 1.0;
        // Reset color
        projectilePaint.color = getProjectileColor(isEnemyProjectile, heroColor);
      } else {
        // Blink transparency between 70% and 100% while slowed
        final blinkTime = (slowTimer * 3) % 1.0; // 3 blinks per second
        final alpha = (0.7 + 0.3 * sin(blinkTime * 2 * pi)).clamp(0.7, 1.0);
        final originalColor = getProjectileColor(isEnemyProjectile, heroColor);
        projectilePaint.color = Color.fromRGBO(
          originalColor.red, 
          originalColor.green, 
          originalColor.blue, 
          alpha
        );
      }
    }
    
    // Move projectile with speed multiplier
    position += direction * speed * speedMultiplier * dt;
    
    // Update lifetime
    lifeTime += dt;
    
    // Check collision with hero (if enemy projectile)
    if (isEnemyProjectile) {
      final distanceToHero = position.distanceTo(gameRef.hero.position);
      if (distanceToHero < radius + gameRef.hero.collisionRadius) {
        gameRef.hero.takeDamage(damage, sourceType: ownerEnemyType ?? 'shooter');
        _destroyProjectile();
        return;
      }
    } else {
      // Hero projectile - check collision with enemies
      for (final enemy in gameRef.currentEnemies) {
        if (enemy is PositionComponent) {
          final distanceToEnemy = position.distanceTo(enemy.position);
          
          if (enemy is CircleComponent) {
            final enemyRadius = enemy.radius;
            if (distanceToEnemy < radius + enemyRadius) {
              // Hit enemy
              if (enemy is EnemyChaser) {
                enemy.takeDamage(damage);
              } else if (enemy is EnemyShooter) {
                enemy.takeDamage(damage);
              } else if (enemy is Swarmer) {
                enemy.takeDamage(damage);
              } else if (enemy is Bomber) {
                enemy.takeDamage(damage);
              } else if (enemy is Sniper) {
                enemy.takeDamage(damage);
              } else if (enemy is Splitter) {
                enemy.takeDamage(damage);
              } else if (enemy is MineLayer) {
                enemy.takeDamage(damage);
              }
              _destroyProjectile();
              return;
            }
          } else if (enemy is ShieldedChaser) {
            // ShieldedChaser has its own radius property
            if (distanceToEnemy < radius + enemy.radius) {
              enemy.takeDamage(damage); // Regular damage to shield
              _destroyProjectile();
              return;
            }
          }
        }
      }
    }
    
    // Remove if out of bounds or too old
    if (lifeTime > maxLifeTime || _isOutOfBounds()) {
      _destroyProjectile();
    }
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
  
  void _destroyProjectile() {
    gameRef.onProjectileDestroyed(this);
    removeFromParent();
  }
  
  @override
  void removeFromParent() {
    gameRef.onProjectileDestroyed(this);
    super.removeFromParent();
  }
  
  bool _isOutOfBounds() {
    return position.x < -radius || 
           position.x > DisplayConfig.instance.arenaWidth + radius ||
           position.y < -radius || 
           position.y > DisplayConfig.instance.arenaHeight + radius;
  }
  
  static Color getProjectileColor(bool isEnemyProjectile, Color? heroColor) {
    if (isEnemyProjectile) {
      return const Color(0xFFFF1744); // Red for enemy projectiles
    } else if (heroColor != null) {
      return heroColor; // Use hero's color
    } else {
      return const Color(0xFF00BCD4); // Default cyan for hero projectiles
    }
  }
} 
```

```dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;
import 'dart:math';

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import 'enemy_chaser.dart';
import 'enemy_shooter.dart';
import 'shielded_chaser.dart';
import 'swarmer.dart';
import 'bomber.dart';
import 'sniper.dart';
import 'splitter.dart';
import 'mine_layer.dart';

class ShapeProjectile extends PositionComponent with HasGameRef<CircleRougeGame> {
  Vector2 direction;
  double speed;
  double damage;
  bool isEnemyProjectile;
  String? ownerEnemyType;
  String shapeType;
  
  // Visual properties
  late Paint projectilePaint;
  late Paint glowPaint;
  late double projectileSize;
  
  double lifeTime = 0.0;
  static const double maxLifeTime = 3.0; // Seconds before auto-destroy
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0; // Slow lasts 3 seconds
  double speedMultiplier = 1.0;
  
  // Bouncing system
  int remainingBounces;
  
  // Enhanced visual effects
  final double sizeScale;
  final bool isCritical;
  
  ShapeProjectile({
    required Vector2 startPosition,
    required this.direction,
    required this.speed,
    required this.damage,
    this.isEnemyProjectile = false,
    this.ownerEnemyType,
    this.shapeType = 'square',
    Color? heroColor,
    int bounces = 0,
    this.sizeScale = 1.0,
    this.isCritical = false,
  }) : remainingBounces = bounces,
       super(
    position: startPosition,
    anchor: Anchor.center,
  ) {
    projectileSize = 8.0 * DisplayConfig.instance.scaleFactor * sizeScale;
    size = Vector2.all(projectileSize);
    
    // Different colors for different projectile types
    Color color;
    if (isEnemyProjectile) {
      color = const Color(0xFFFF4444); // Red for enemy projectiles
    } else if (isCritical) {
      color = const Color(0xFFFFD700); // Gold for critical hits
    } else {
      color = heroColor ?? const Color(0xFF44FF44); // Use hero color or default green
    }
    
    projectilePaint = Paint()..color = color;
    glowPaint = Paint()
      ..color = color.withOpacity(isCritical ? 0.8 : 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isCritical ? 12 : 4);
    
    // Add extra glow for critical hits
    if (isCritical) {
      print('💥 CRITICAL HIT PROJECTILE CREATED!');
    }
  }
  
  @override
  void onMount() {
    super.onMount();
    // Register projectile with game
    gameRef.addProjectile(this);
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Add glow effect
    final glowPaint = Paint()
      ..color = projectilePaint.color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    switch (shapeType) {
      case 'circle':
        // Draw glow
        canvas.drawCircle(center, projectileSize + 2, glowPaint);
        // Draw shape
        canvas.drawCircle(center, projectileSize, projectilePaint);
        break;
      case 'triangle':
        _drawTriangle(canvas, center, glowPaint);
        _drawTriangle(canvas, center, projectilePaint);
        break;
      case 'square':
        _drawSquare(canvas, center, glowPaint);
        _drawSquare(canvas, center, projectilePaint);
        break;
      case 'pentagon':
        _drawPentagon(canvas, center, glowPaint);
        _drawPentagon(canvas, center, projectilePaint);
        break;
      case 'hexagon':
        _drawHexagon(canvas, center, glowPaint);
        _drawHexagon(canvas, center, projectilePaint);
        break;
      default:
        // Default to circle
        canvas.drawCircle(center, projectileSize + 2, glowPaint);
        canvas.drawCircle(center, projectileSize, projectilePaint);
    }
    
    // Add sparkle effect for critical hits
    if (isCritical) {
      final sparkleTime = DateTime.now().millisecondsSinceEpoch / 100.0;
      for (int i = 0; i < 4; i++) {
        final angle = (sparkleTime + i * pi / 2) % (2 * pi);
        final sparkleDistance = projectileSize + 8;
        final sparkleX = center.dx + cos(angle) * sparkleDistance;
        final sparkleY = center.dy + sin(angle) * sparkleDistance;
        
        final sparklePaint = Paint()
          ..color = const Color(0xFFFFFFFF).withOpacity(0.8)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(Offset(sparkleX, sparkleY), 2.0, sparklePaint);
      }
    }
  }
  
  void _drawTriangle(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final radius = paint == projectilePaint ? projectileSize : projectileSize + 2;
    
    path.moveTo(center.dx, center.dy - radius); // Top point
    path.lineTo(center.dx - radius * cos(pi / 6), center.dy + radius / 2); // Bottom left
    path.lineTo(center.dx + radius * cos(pi / 6), center.dy + radius / 2); // Bottom right
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawSquare(Canvas canvas, Offset center, Paint paint) {
    final radius = paint == projectilePaint ? projectileSize : projectileSize + 2;
    final size = radius * 1.4; // Make square a bit larger than circle
    
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      ),
      paint,
    );
  }
  
  void _drawPentagon(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final radius = paint == projectilePaint ? projectileSize : projectileSize + 2;
    final angleStep = 2 * pi / 5;
    
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + i * angleStep;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawHexagon(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final radius = paint == projectilePaint ? projectileSize : projectileSize + 2;
    final angleStep = 2 * pi / 6;
    
    for (int i = 0; i < 6; i++) {
      final angle = -pi / 2 + i * angleStep;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Update slow timer
    if (isSlowed) {
      slowTimer += dt;
      if (slowTimer >= slowDuration) {
        isSlowed = false;
        slowTimer = 0.0;
        speedMultiplier = 1.0;
        // Reset color
        projectilePaint.color = projectilePaint.color;
      } else {
        // Blink transparency between 70% and 100% while slowed
        final blinkTime = (slowTimer * 3) % 1.0; // 3 blinks per second
        final alpha = (0.7 + 0.3 * sin(blinkTime * 2 * pi)).clamp(0.7, 1.0);
        projectilePaint.color = Color.fromRGBO(
          projectilePaint.color.red, 
          projectilePaint.color.green, 
          projectilePaint.color.blue, 
          alpha
        );
      }
    }
    
    // Move projectile with speed multiplier
    position += direction * speed * speedMultiplier * dt;
    
    // Update lifetime
    lifeTime += dt;
    
    // Check collision with hero (if enemy projectile)
    if (isEnemyProjectile) {
      final distanceToHero = position.distanceTo(gameRef.hero.position);
      if (distanceToHero < projectileSize + gameRef.hero.collisionRadius) {
        gameRef.hero.takeDamage(damage, sourceType: ownerEnemyType ?? 'shooter');
        _destroyProjectile();
        return;
      }
    } else {
      // Hero projectile - check collision with enemies
      for (final enemy in gameRef.currentEnemies) {
        if (enemy is PositionComponent) {
          final distanceToEnemy = position.distanceTo(enemy.position);
          
          if (enemy is CircleComponent) {
            final enemyRadius = enemy.radius;
            if (distanceToEnemy < projectileSize + enemyRadius) {
              // Hit enemy
              if (enemy is EnemyChaser) {
                // Critical strike = instant kill
                if (isCritical) {
                  enemy.takeDamage(enemy.health); // Deal exactly their current health
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                // Apply life steal if hero has it
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                // Trigger heal per kill if enemy dies
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              } else if (enemy is EnemyShooter) {
                // Critical strike = instant kill
                if (isCritical) {
                  enemy.takeDamage(enemy.health); // Deal exactly their current health
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                // Apply life steal if hero has it
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                // Trigger heal per kill if enemy dies
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              } else if (enemy is Swarmer) {
                if (isCritical) {
                  enemy.takeDamage(enemy.health);
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              } else if (enemy is Bomber) {
                if (isCritical) {
                  enemy.takeDamage(enemy.health);
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              } else if (enemy is Sniper) {
                if (isCritical) {
                  enemy.takeDamage(enemy.health);
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              } else if (enemy is Splitter) {
                if (isCritical) {
                  enemy.takeDamage(enemy.health);
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              } else if (enemy is MineLayer) {
                if (isCritical) {
                  enemy.takeDamage(enemy.health);
                  print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
                } else {
                  enemy.takeDamage(damage);
                }
                final lifeSteal = gameRef.hero.totalLifeSteal;
                if (lifeSteal > 0 && !isEnemyProjectile) {
                  final healAmount = damage * lifeSteal;
                  gameRef.hero.heal(healAmount);
                }
                if (!isEnemyProjectile && enemy.health <= 0) {
                  gameRef.hero.onEnemyKilled();
                }
              }
              
              // Handle bouncing or destruction
              if (remainingBounces > 0 && !isEnemyProjectile) {
                _handleBounce(enemy.position);
              } else {
                _destroyProjectile();
              }
              return;
            }
          } else if (enemy is ShieldedChaser) {
            // ShieldedChaser has its own radius property
            if (distanceToEnemy < projectileSize + enemy.radius) {
              // Critical strike = instant kill (but only after shield is broken)
              if (isCritical && !enemy.hasShield) {
                enemy.takeDamage(enemy.health); // Deal exactly their current health
                print('💥 CRITICAL STRIKE! Instant kill on ${enemy.runtimeType}');
              } else {
                enemy.takeDamage(damage); // Regular damage to shield or health
              }
              // Apply life steal if hero has it
              final lifeSteal = gameRef.hero.totalLifeSteal;
              if (lifeSteal > 0 && !isEnemyProjectile) {
                final healAmount = damage * lifeSteal;
                gameRef.hero.heal(healAmount);
              }
              // Trigger heal per kill if enemy dies
              if (!isEnemyProjectile && enemy.health <= 0) {
                gameRef.hero.onEnemyKilled();
              }
              
              // Handle bouncing or destruction
              if (remainingBounces > 0 && !isEnemyProjectile) {
                _handleBounce(enemy.position);
              } else {
                _destroyProjectile();
              }
              return;
            }
          }
        }
      }
    }
    
    // Remove if out of bounds or too old
    if (lifeTime > maxLifeTime || _isOutOfBounds()) {
      _destroyProjectile();
    }
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
  
  void _handleBounce(Vector2 hitPosition) {
    remainingBounces--;
    
    // Find the nearest enemy to bounce to
    Component? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is PositionComponent && enemy.position != hitPosition) {
        final distance = position.distanceTo(enemy.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = enemy;
        }
      }
    }
    
    // If we found an enemy to bounce to, redirect towards it
    if (nearestEnemy != null && nearestEnemy is PositionComponent) {
      direction = (nearestEnemy.position - position).normalized();
      
      // Visual feedback for bounce
      final bounceGlow = Paint()
        ..color = projectilePaint.color.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      glowPaint = bounceGlow;
      
      // Play bounce sound (if available)
      // SoundManager().playBulletBounceSound();
      
      print('Projectile bounced! Remaining bounces: $remainingBounces');
    } else {
      // No enemy to bounce to, destroy projectile
      _destroyProjectile();
    }
  }
  
  void _destroyProjectile() {
    gameRef.onProjectileDestroyed(this);
    removeFromParent();
  }
  
  @override
  void removeFromParent() {
    gameRef.onProjectileDestroyed(this);
    super.removeFromParent();
  }
  
  bool _isOutOfBounds() {
    return position.x < -projectileSize || 
           position.x > DisplayConfig.instance.arenaWidth + projectileSize ||
           position.y < -projectileSize || 
           position.y > DisplayConfig.instance.arenaHeight + projectileSize;
  }
} 
```

```dart
*** Begin Patch
*** Update File: lib/components/enemies/enemy_shooter.dart
@@
   void _fireProjectile(Vector2 direction) {
@@
-    final projectile = Projectile(
+    final projectile = Projectile(
       startPosition: position.clone(),
       direction: direction,
       speed: projectileSpeed * DisplayConfig.instance.scaleFactor,
       damage: projectileDamage,
-      isEnemyProjectile: true,
+      isEnemyProjectile: true,
+      ownerEnemyType: 'shooter',
     );
@@
-      if (distanceToHero <= radius + hero.collisionRadius) {
+      if (distanceToHero <= radius + hero.collisionRadius) {
         final contactDamage = EnemyConfigManager.instance.getEnemyDamage('sniper', 7.5);
-        hero.takeDamage(contactDamage);
+        hero.takeDamage(contactDamage, sourceType: 'sniper');
         takeDamage(health); // Die on contact
       }
*** End Patch
```

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
// Item drop imports removed - now handled by ConsumableDropManager
import 'projectile.dart';

class EnemyShooter extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 30.0; // Default fallback speed
  
  // Configuration-based properties
  double get baseAttackRange => EnemyConfigManager.instance.getEnemyProperty('shooter', 'attack_range', 300.0);
  double get fireRate => 1.0 / EnemyConfigManager.instance.getEnemyProperty('shooter', 'shoot_cooldown', 2.0); // Convert cooldown to rate
  double get projectileSpeed => EnemyConfigManager.instance.getEnemyProperty('shooter', 'projectile_speed', 200.0);
  
  // Optimal distance management - derived from attack range
  double get optimalDistanceMin => baseAttackRange * 0.6; // 60% of attack range
  double get optimalDistanceMax => baseAttackRange * 0.9; // 90% of attack range
  
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('shooter') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  double get attackRange => baseAttackRange * DisplayConfig.instance.scaleFactor;
  double get optimalMinDistance => optimalDistanceMin * DisplayConfig.instance.scaleFactor;
  double get optimalMaxDistance => optimalDistanceMax * DisplayConfig.instance.scaleFactor;
  
  double health = 25.0;
  double maxHealth = 25.0;
  double lastShotTime = 0.0;
  
  // AI behavior variables
  double lastDirectionChange = 0.0;
  Vector2 currentDirection = Vector2.zero();
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0; // Slow lasts 3 seconds
  double speedMultiplier = 1.0;
  
  EnemyShooter({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 12.0 * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = const Color(0xFF9C27B0),
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
  }
  
  void _initializeHealth() {
    // Get base health from enemy config
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('shooter', 25.0);
    // Apply wave-based scaling
    final scaledHealth = WaveConfig.instance.getScaledHealth(baseHealth, gameRef.currentWave);
    health = scaledHealth;
    maxHealth = scaledHealth;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    // Handle stun
    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
      }
      return; // Don't move or attack while stunned
    }
    
    // Remove if too far from arena center (cleanup)
    final arenaCenter = Vector2(DisplayConfig.instance.arenaWidth / 2, DisplayConfig.instance.arenaHeight / 2);
    final maxDistance = (DisplayConfig.instance.arenaWidth + DisplayConfig.instance.arenaHeight) / 3;
    if (position.distanceTo(arenaCenter) > maxDistance) {
      removeFromParent();
    }
    
    // Stay within safe area
    _constrainToSafeArea();
    
    // Smart AI behavior with hero
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final distanceToHero = position.distanceTo(hero.position);
      
      // Can shoot while moving - check if in range and ready to fire
      if (distanceToHero <= attackRange && _canFire()) {
        final direction = (hero.position - position).normalized();
        _fireProjectile(direction);
      }
      
      // Smart movement to maintain optimal distance
      Vector2 movementDirection = Vector2.zero();
      
      if (distanceToHero < optimalMinDistance) {
        // Too close - move away from hero
        movementDirection = (position - hero.position).normalized();
      } else if (distanceToHero > optimalMaxDistance) {
        // Too far - move towards hero
        movementDirection = (hero.position - position).normalized();
      } else {
        // In optimal range - add some side-to-side movement to make it harder to hit
        final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
        if (currentTime - lastDirectionChange > 1.5) {
          // Change direction every 1.5 seconds for unpredictable movement
          final perpendicular = Vector2(
            -(hero.position - position).normalized().y,
            (hero.position - position).normalized().x,
          );
          final random = Random();
          movementDirection = perpendicular * (random.nextBool() ? 1.0 : -1.0);
          lastDirectionChange = currentTime;
          currentDirection = movementDirection;
        } else {
          movementDirection = currentDirection;
        }
      }
      
      // Apply no-stay zone force to keep enemies away from edges
      final noStayForce = gameRef.getNoStayZoneForce(position);
      
      // Combine tactical movement with no-stay force
      final finalDirection = movementDirection + (noStayForce * dt);
      if (finalDirection.length > 0) {
        finalDirection.normalize();
        position += finalDirection * speed * dt * speedMultiplier;
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
  
  bool _canFire() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    return currentTime - lastShotTime >= (1.0 / fireRate);
  }
  
  void _fireProjectile(Vector2 direction) {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    lastShotTime = currentTime;
    
    final projectileDamage = EnemyConfigManager.instance.getEnemyProperty('shooter', 'projectile_damage', 15.0);
    final projectile = Projectile(
      startPosition: position.clone(),
      direction: direction,
      speed: projectileSpeed * DisplayConfig.instance.scaleFactor,
      damage: projectileDamage,
      isEnemyProjectile: true,
      ownerEnemyType: 'shooter',
    );
    
    gameRef.add(projectile);
  }
  
  void takeDamage(double damageAmount) {
    health -= damageAmount;
    
    if (health <= 0) {
      // Item drops are now handled by the unified ConsumableDropManager
      // via gameRef.onEnemyDestroyed(this)
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
    }
  }
  
  void stun(double duration) {
    isStunned = true;
    stunDuration = duration;
    stunTimer = duration; // Fixed: should start at full duration
  }
  
  void applySlowEffect(double multiplier) {
    isSlowed = true;
    speedMultiplier = multiplier;
    slowTimer = 0.0;
  }
} 
```

```dart
*** Begin Patch
*** Update File: lib/components/enemies/sniper.dart
@@
-    final projectile = Projectile(
+    final projectile = Projectile(
       startPosition: position.clone(),
       direction: direction,
       speed: projectileSpeed * DisplayConfig.instance.scaleFactor,
       damage: playerDamage,
-      isEnemyProjectile: true,
+      isEnemyProjectile: true,
+      ownerEnemyType: 'sniper',
     );
@@
-      if (!isAiming && !isCharging && distanceToHero <= radius + hero.collisionRadius) {
-        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('sniper', 7.5);
-        hero.takeDamage(contactDamage);
+      if (!isAiming && !isCharging && distanceToHero <= radius + hero.collisionRadius) {
+        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('sniper', 7.5);
+        hero.takeDamage(contactDamage, sourceType: 'sniper');
         takeDamage(health); // Die on contact
       }
*** End Patch
```

```dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
import '../sound_manager.dart';
import 'projectile.dart';

class Sniper extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 30.0; // Very slow movement
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('sniper') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 125.0; // Moderate health
  double maxHealth = 125.0;
  bool isDead = false;
  
  // Sniper behavior - now configurable
  double get attackRange => EnemyConfigManager.instance.getEnemyProperty('sniper', 'attack_range', 400.0);
  double get chargeTime => EnemyConfigManager.instance.getEnemyProperty('sniper', 'charge_time', 2.0);
  double get damagePercent => EnemyConfigManager.instance.getEnemyProperty('sniper', 'damage_percent', 0.5);
  double get aimTime => EnemyConfigManager.instance.getEnemyProperty('sniper', 'aim_time', 0.5);
  
  double lastShotTime = 0.0;
  double get shotCooldown => EnemyConfigManager.instance.getEnemyProperty('sniper', 'shot_cooldown', 4.0);
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
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
  }
  
  void _initializeHealth() {
    // Get base health from enemy config
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('sniper', 125.0);
    // Apply wave-based scaling
    final scaledHealth = WaveConfig.instance.getScaledHealth(baseHealth, gameRef.currentWave);
    health = scaledHealth;
    maxHealth = scaledHealth;
  }
  
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
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('sniper', 7.5);
        hero.takeDamage(contactDamage, sourceType: 'sniper');
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
    // Play sniper shot sound
    SoundManager().playSniperSnipeSound();
    
    final direction = (targetPosition - position).normalized();
    
    // Calculate damage as 50% of player's current HP
    final playerDamage = gameRef.hero.maxHealth * damagePercent;
    
    final projectileSpeed = EnemyConfigManager.instance.getEnemyProperty('sniper', 'projectile_speed', 600.0);
    final projectile = Projectile(
      startPosition: position.clone(),
      direction: direction,
      speed: projectileSpeed * DisplayConfig.instance.scaleFactor,
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

```dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
import '../sound_manager.dart';
import 'projectile.dart';

class Sniper extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 30.0; // Very slow movement
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('sniper') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 125.0; // Moderate health
  double maxHealth = 125.0;
  bool isDead = false;
  
  // Sniper behavior - now configurable
  double get attackRange => EnemyConfigManager.instance.getEnemyProperty('sniper', 'attack_range', 400.0);
  double get chargeTime => EnemyConfigManager.instance.getEnemyProperty('sniper', 'charge_time', 2.0);
  double get damagePercent => EnemyConfigManager.instance.getEnemyProperty('sniper', 'damage_percent', 0.5);
  double get aimTime => EnemyConfigManager.instance.getEnemyProperty('sniper', 'aim_time', 0.5);
  
  double lastShotTime = 0.0;
  double get shotCooldown => EnemyConfigManager.instance.getEnemyProperty('sniper', 'shot_cooldown', 4.0);
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
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
  }
  
  void _initializeHealth() {
    // Get base health from enemy config
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('sniper', 125.0);
    // Apply wave-based scaling
    final scaledHealth = WaveConfig.instance.getScaledHealth(baseHealth, gameRef.currentWave);
    health = scaledHealth;
    maxHealth = scaledHealth;
  }
  
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
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('sniper', 7.5);
        hero.takeDamage(contactDamage, sourceType: 'sniper');
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
    // Play sniper shot sound
    SoundManager().playSniperSnipeSound();
    
    final direction = (targetPosition - position).normalized();
    
    // Calculate damage as 50% of player's current HP
    final playerDamage = gameRef.hero.maxHealth * damagePercent;
    
    final projectileSpeed = EnemyConfigManager.instance.getEnemyProperty('sniper', 'projectile_speed', 600.0);
    final projectile = Projectile(
      startPosition: position.clone(),
      direction: direction,
      speed: projectileSpeed * DisplayConfig.instance.scaleFactor,
      damage: playerDamage,
      isEnemyProjectile: true,
      ownerEnemyType: 'sniper',
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

```dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
import '../sound_manager.dart';
import 'projectile.dart';

class Bomber extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 40.0; // Slow but dangerous
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('bomber') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 50.0; // Tanky
  double maxHealth = 50.0;
  bool isDead = false;
  
  // Bombing behavior - now using config
  double get explosionRadius => EnemyConfigManager.instance.getEnemyProperty('bomber', 'explosion_radius', 100.0);
  double get explosionDamage => EnemyConfigManager.instance.getEnemyProperty('bomber', 'explosion_damage', 30.0);
  double get fuseTime => EnemyConfigManager.instance.getEnemyProperty('bomber', 'fuse_time', 3.0);
  double fuseTimer = 0.0;
  bool fuseActive = false;
  
  // Visual effects
  double pulseTimer = 0.0;
  double pulseIntensity = 0.0;
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  Bomber({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 16.0 * DisplayConfig.instance.scaleFactor, // Larger than basic enemies
    paint: Paint()..color = const Color(0xFFFF5722), // Orange-red color
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
  }
  
  void _initializeHealth() {
    // Get base health from enemy config
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('bomber', 100.0);
    // Apply wave-based scaling
    final scaledHealth = WaveConfig.instance.getScaledHealth(baseHealth, gameRef.currentWave);
    health = scaledHealth;
    maxHealth = scaledHealth;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw pulsing effect when fuse is active
    if (fuseActive) {
      final center = Offset(size.x / 2, size.y / 2);
      final pulseRadius = radius * (1.0 + pulseIntensity * 0.5);
      
      final pulsePaint = Paint()
        ..color = Colors.red.withOpacity(0.3 * pulseIntensity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, pulseRadius, pulsePaint);
      
      // Draw warning ring
      final ringPaint = Paint()
        ..color = Colors.red.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawCircle(center, explosionRadius * DisplayConfig.instance.scaleFactor, ringPaint);
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
      
      // Activate fuse when close to hero
      if (distanceToHero <= explosionRadius * DisplayConfig.instance.scaleFactor && !fuseActive) {
        fuseActive = true;
        fuseTimer = fuseTime;
      }
      
      // Handle fuse countdown
      if (fuseActive) {
        fuseTimer -= dt;
        pulseTimer += dt;
        
        // Increase pulse intensity as explosion approaches
        final timeProgress = 1.0 - (fuseTimer / fuseTime);
        pulseIntensity = sin(pulseTimer * 10.0) * timeProgress;
        
        if (fuseTimer <= 0.0) {
          _explode();
          return;
        }
      }
      
      // Move toward hero (slower when fuse is active)
      final direction = (hero.position - position).normalized();
      final noStayForce = gameRef.getNoStayZoneForce(position);
      final finalDirection = (direction + noStayForce * dt).normalized();
      
      final effectiveSpeed = fuseActive ? speed * 0.5 : speed; // Slow down when about to explode
      position += finalDirection * effectiveSpeed * dt * speedMultiplier;
      
      // Check collision with hero (only if not exploding)
      if (!fuseActive && distanceToHero <= radius + hero.collisionRadius) {
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('bomber', 7.5);
        hero.takeDamage(contactDamage, sourceType: 'bomber');
        takeDamage(health); // Die on contact
      }
    }
  }
  
  void _explode() {
    // Play bomber explosion sound
    SoundManager().playBomberExplodeSound();
    
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final distanceToHero = position.distanceTo(hero.position);
      final explosionRange = explosionRadius * DisplayConfig.instance.scaleFactor;
      
      if (distanceToHero <= explosionRange) {
        // Damage falls off with distance
        final damageFalloff = 1.0 - (distanceToHero / explosionRange);
        final actualDamage = explosionDamage * damageFalloff;
        hero.takeDamage(actualDamage, sourceType: 'bomber');
      }
    }
    
    // Create explosion visual effect (multiple projectiles in all directions)
    _createExplosionEffect();
    
    // Remove self
    gameRef.onEnemyDestroyed(this);
    removeFromParent();
  }
  
  void _createExplosionEffect() {
    // Get projectile count and speed from config
    final numProjectiles = EnemyConfigManager.instance.getEnemyIntProperty('bomber', 'explosion_projectiles', 6);
    final projectileSpeed = EnemyConfigManager.instance.getEnemyProperty('bomber', 'explosion_projectile_speed', 150.0);
    
    for (int i = 0; i < numProjectiles; i++) {
      final angle = (i * 360.0 / numProjectiles) * (pi / 180.0);
      final direction = Vector2(cos(angle), sin(angle));
      
      final projectileDamage = EnemyConfigManager.instance.getEnemyProperty('bomber', 'explosion_projectile_damage', 8.0);
      final projectile = Projectile(
        startPosition: position.clone(),
        direction: direction,
        speed: projectileSpeed * DisplayConfig.instance.scaleFactor,
        damage: projectileDamage,
        isEnemyProjectile: true,
        ownerEnemyType: 'bomber',
      );
      
      gameRef.add(projectile);
      
      // Explosion projectiles will auto-destroy via their normal lifetime mechanism
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
      // Explode immediately when killed
      _explode();
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
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
// Item drop imports removed - now handled by ConsumableDropManager

class EnemyChaser extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 50.0; // Default fallback speed
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('chaser') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  double health = 30.0;
  double maxHealth = 30.0;
  bool isDead = false;
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0; // Slow lasts 3 seconds
  double speedMultiplier = 1.0;
  
  EnemyChaser({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 12.0 * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = const Color(0xFFFF5722),
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
  }
  
  void _initializeHealth() {
    // Get base health from enemy config
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('chaser', 30.0);
    // Apply wave-based scaling
    final scaledHealth = WaveConfig.instance.getScaledHealth(baseHealth, gameRef.currentWave);
    health = scaledHealth;
    maxHealth = scaledHealth;
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
      }
      return; // Don't move or do anything while stunned
    }
    
    // Remove if too far from arena center (cleanup)
    final arenaCenter = Vector2(DisplayConfig.instance.arenaWidth / 2, DisplayConfig.instance.arenaHeight / 2);
    final maxDistance = (DisplayConfig.instance.arenaWidth + DisplayConfig.instance.arenaHeight) / 3;
    if (position.distanceTo(arenaCenter) > maxDistance) {
      removeFromParent();
    }
    
    // Stay within safe area to prevent getting stuck at edges
    _constrainToSafeArea();
    
    // Chase hero
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final direction = (hero.position - position).normalized();
      
      // Apply no-stay zone force to keep enemies away from edges
      final noStayForce = gameRef.getNoStayZoneForce(position);
      
      // Combine chase direction with no-stay force
      final finalDirection = direction + (noStayForce * dt);
      if (finalDirection.length > 0) {
        finalDirection.normalize();
      }
      
      position += finalDirection * speed * dt * speedMultiplier;
      
      // Check collision with hero
      final distanceToHero = position.distanceTo(hero.position);
      if (distanceToHero <= radius + hero.collisionRadius) {
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('chaser', 5.0);
        hero.takeDamage(contactDamage, sourceType: 'chaser');
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
      // Item drops are now handled by the unified ConsumableDropManager
      // via gameRef.onEnemyDestroyed(this)
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
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
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';

class Swarmer extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 120.0; // Fast and agile
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('swarmer') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 25.0; // Low health but fast
  double maxHealth = 25.0;
  bool isDead = false;
  
  // Swarming behavior - now using config
  late Vector2 swarmTarget;
  double get swarmRadius => EnemyConfigManager.instance.getEnemyProperty('swarmer', 'swarm_radius', 80.0);
  double get separationRadius => EnemyConfigManager.instance.getEnemyProperty('swarmer', 'separation_radius', 30.0);
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  Swarmer({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 8.0 * DisplayConfig.instance.scaleFactor, // Smaller than other enemies
    paint: Paint()..color = const Color(0xFFFFEB3B), // Yellow color
    anchor: Anchor.center,
  ) {
    swarmTarget = position ?? Vector2.zero();
  }
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
  }
  
  void _initializeHealth() {
    // Get base health from enemy config
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('swarmer', 25.0);
    // Apply wave-based scaling
    final scaledHealth = WaveConfig.instance.getScaledHealth(baseHealth, gameRef.currentWave);
    health = scaledHealth;
    maxHealth = scaledHealth;
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
    
    // Swarming AI behavior
    final hero = gameRef.hero;
    if (hero.isMounted) {
      Vector2 swarmDirection = _calculateSwarmDirection();
      Vector2 heroDirection = (hero.position - position).normalized();
      
      // Combine swarming behavior with hero chasing (weighted toward hero)
      Vector2 finalDirection = (heroDirection * 0.7 + swarmDirection * 0.3).normalized();
      
      // Apply no-stay zone force
      final noStayForce = gameRef.getNoStayZoneForce(position);
      finalDirection = (finalDirection + noStayForce * dt).normalized();
      
      position += finalDirection * speed * dt * speedMultiplier;
      
      // Check collision with hero
      final distanceToHero = position.distanceTo(hero.position);
      if (distanceToHero <= radius + hero.collisionRadius) {
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('swarmer', 10.0);
        hero.takeDamage(contactDamage, sourceType: 'swarmer');
        takeDamage(health); // Die on contact
      }
    }
  }
  
  Vector2 _calculateSwarmDirection() {
    Vector2 swarmForce = Vector2.zero();
    Vector2 separationForce = Vector2.zero();
    int nearbyCount = 0;
    
    // Find other swarmers nearby
    for (final enemy in gameRef.currentEnemies) {
      if (enemy is Swarmer && enemy != this) {
        final distance = position.distanceTo(enemy.position);
        
        if (distance < swarmRadius) {
          // Attraction to nearby swarmers
          swarmForce += (enemy.position - position).normalized() * 0.3;
          nearbyCount++;
        }
        
        if (distance < separationRadius) {
          // Separation from too-close swarmers
          separationForce += (position - enemy.position).normalized() * 0.5;
        }
      }
    }
    
    if (nearbyCount > 0) {
      swarmForce = swarmForce / nearbyCount.toDouble();
    }
    
    return (swarmForce + separationForce).normalized();
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
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
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
import '../../config/enemy_config.dart';
import '../sound_manager.dart';

class Splitter extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 60.0;
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('splitter') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 140.0;
  double maxHealth = 140.0;
  bool isDead = false;
  
  // Splitter behavior
  final int generation; // 0 = original, 1 = first split, 2 = second split
  int get maxGenerations => EnemyConfigManager.instance.getEnemyIntProperty('splitter', 'max_generations', 2);
  int get splitsPerGeneration => EnemyConfigManager.instance.getEnemyIntProperty('splitter', 'split_count', 6);
  
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
    // Adjust health based on generation using config
    final healthList = EnemyConfigManager.instance.getEnemyListProperty('splitter', 'generation_health', [40.0, 25.0, 15.0]);
    health = generation < healthList.length ? healthList[generation] : 15.0;
    maxHealth = health;
  }
  
  static double _getRadiusForGeneration(int generation) {
    final radiusList = EnemyConfigManager.instance.getEnemyListProperty('splitter', 'generation_radius', [18.0, 14.0, 10.0]);
    return generation < radiusList.length ? radiusList[generation] : 10.0;
  }
  
  static Color _getColorForGeneration(int generation) {
    switch (generation) {
      case 0: return const Color(0xFF9C27B0); // Purple
      case 1: return const Color(0xFFE91E63); // Pink
      case 2: return const Color(0xFFF44336); // Red
      default: return const Color(0xFFF44336);
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
      
      // Speed decreases with each generation using config
      final speedMultiplierList = EnemyConfigManager.instance.getEnemyListProperty('splitter', 'generation_speed_multiplier', [1.0, 0.8, 0.6]);
      final generationSpeedMultiplier = generation < speedMultiplierList.length ? speedMultiplierList[generation] : 0.6;
      position += finalDirection * speed * generationSpeedMultiplier * dt * speedMultiplier;
      
      // Check collision with hero
      final distanceToHero = position.distanceTo(hero.position);
      if (distanceToHero <= radius + hero.collisionRadius) {
        final baseContactDamage = EnemyConfigManager.instance.getEnemyDamage('splitter', 10.0);
        final contactDamage = baseContactDamage + (generation * 2.5); // More damage from smaller splits
        hero.takeDamage(contactDamage, sourceType: 'splitter');
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
      // Play splitter split sound
      SoundManager().playSplitterSplitSound();
      
      final random = Random();
      
      for (int i = 0; i < splitsPerGeneration; i++) {
        // Create split at random angle from current position
        final angle = random.nextDouble() * 2 * pi;
        final distance = EnemyConfigManager.instance.getEnemyProperty('splitter', 'split_distance', 30.0) * DisplayConfig.instance.scaleFactor;
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
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' hide Hero;

import '../../game/circle_rouge_game.dart';
import '../../config/display_config.dart';
import '../../config/wave_config.dart';
import '../../config/enemy_config.dart';
import '../sound_manager.dart';

class MineLayer extends CircleComponent with HasGameRef<CircleRougeGame> {
  static const double baseSpeed = 45.0;
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('mine_layer') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  double health = 150.0;
  double maxHealth = 150.0;
  bool isDead = false;
  
  // Mine laying behavior - now using config
  double get mineLayInterval => EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'mine_lay_interval', 3.0);
  double get minDistanceFromMines => EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'min_distance_from_mines', 80.0);
  double lastMineTime = 0.0;
  List<Vector2> minePositions = [];
  
  // Stun system
  bool isStunned = false;
  double stunTimer = 0.0;
  double stunDuration = 0.0;
  
  // Slow effect system
  bool isSlowed = false;
  double slowTimer = 0.0;
  double slowDuration = 3.0;
  double speedMultiplier = 1.0;
  
  MineLayer({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 15.0 * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = const Color(0xFF607D8B), // Blue-grey color
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
  }
  
  void _initializeHealth() {
    // Get base health from enemy config
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('mine_layer', 150.0);
    // Apply wave-based scaling
    final scaledHealth = WaveConfig.instance.getScaledHealth(baseHealth, gameRef.currentWave);
    health = scaledHealth;
    maxHealth = scaledHealth;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw mine layer indicator (small dots around the enemy)
    final center = Offset(size.x / 2, size.y / 2);
    final dotPaint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60.0) * (pi / 180.0);
      final dotRadius = 2.0;
      final distance = radius + 8.0;
      
      final dotX = center.dx + cos(angle) * distance;
      final dotY = center.dy + sin(angle) * distance;
      
      canvas.drawCircle(Offset(dotX, dotY), dotRadius, dotPaint);
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
      final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      
      // Try to lay mine
      if (currentTime - lastMineTime >= mineLayInterval) {
        _tryLayMine();
      }
      
      // Always move around when not laying mines - more aggressive movement
      final distanceToHero = position.distanceTo(hero.position);
      Vector2 movementDirection = Vector2.zero();
      
      // Always be moving - combine defensive positioning with random movement
      final defensiveDistanceMin = EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'defensive_distance_min', 150.0) * DisplayConfig.instance.scaleFactor;
      final defensiveDistanceMax = EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'defensive_distance_max', 250.0) * DisplayConfig.instance.scaleFactor;
      
      if (distanceToHero < defensiveDistanceMin) {
        // Too close to hero - retreat
        movementDirection = (position - hero.position).normalized();
      } else if (distanceToHero > defensiveDistanceMax) {
        // Too far from hero - advance
        movementDirection = (hero.position - position).normalized();
      } else {
        // Good distance - move perpendicular to hero for defensive positioning
        final perpendicular = Vector2(
          -(hero.position - position).normalized().y,
          (hero.position - position).normalized().x,
        );
        final random = Random();
        movementDirection = perpendicular * (random.nextBool() ? 1.0 : -1.0);
      }
      
      // Add random movement component to keep miner active
      final random = Random();
      final randomMovement = Vector2(
        (random.nextDouble() - 0.5) * 2.0,
        (random.nextDouble() - 0.5) * 2.0,
      );
      movementDirection = (movementDirection + randomMovement * 0.3).normalized();
      
      // Apply no-stay zone force
      final noStayForce = gameRef.getNoStayZoneForce(position);
      final finalDirection = (movementDirection + noStayForce * dt).normalized();
      
      position += finalDirection * speed * dt * speedMultiplier;
      
      // Check collision with hero
      if (distanceToHero <= radius + hero.collisionRadius) {
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('mine_layer', 7.5);
        hero.takeDamage(contactDamage, sourceType: 'mine_layer');
        takeDamage(health); // Die on contact
      }
    }
  }
  
  void _tryLayMine() {
    // Check if current position is far enough from existing mines
    bool canLayMine = true;
    final minDistance = minDistanceFromMines * DisplayConfig.instance.scaleFactor;
    
    for (final minePos in minePositions) {
      if (position.distanceTo(minePos) < minDistance) {
        canLayMine = false;
        break;
      }
    }
    
    if (canLayMine) {
      _layMine();
    }
  }
  
  void _layMine() {
    // Play mine deployment sound
    SoundManager().playMineDeploySound();
    
    final mine = Mine(position: position.clone());
    gameRef.add(mine);
    
    minePositions.add(position.clone());
    lastMineTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Limit number of tracked mine positions to prevent memory buildup
    if (minePositions.length > 10) {
      minePositions.removeAt(0);
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
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
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

class Mine extends CircleComponent with HasGameRef<CircleRougeGame> {
  double get explosionRadius => EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'mine_explosion_radius', 60.0);
  double get damagePercent => EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'mine_damage_percent', 0.5);
  double get armTime => EnemyConfigManager.instance.getEnemyProperty('mine_layer', 'mine_arm_time', 1.0);
  
  double armTimer = 0.0;
  bool isArmed = false;
  double pulseTimer = 0.0;
  
  Mine({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    radius: 8.0 * DisplayConfig.instance.scaleFactor,
    paint: Paint()..color = const Color(0xFF795548), // Brown color
    anchor: Anchor.center,
  );
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    if (!isArmed) {
      // Draw arming indicator
      final armProgress = armTimer / armTime;
      final armPaint = Paint()
        ..color = Colors.orange.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 5.0),
        -pi / 2,
        2 * pi * armProgress,
        false,
        armPaint,
      );
    } else {
      // Draw pulsing armed indicator
      final pulseIntensity = (sin(pulseTimer * 6.0) + 1.0) / 2.0;
      final pulsePaint = Paint()
        ..color = Colors.red.withOpacity(0.3 + 0.3 * pulseIntensity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, radius + 3.0, pulsePaint);
      
      // Draw danger zone indicator (faint)
      final dangerPaint = Paint()
        ..color = Colors.red.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawCircle(center, explosionRadius * DisplayConfig.instance.scaleFactor, dangerPaint);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    pulseTimer += dt;
    
    // Handle arming
    if (!isArmed) {
      armTimer += dt;
      if (armTimer >= armTime) {
        isArmed = true;
      }
      return;
    }
    
    // Check for hero proximity
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final distanceToHero = position.distanceTo(hero.position);
      final triggerDistance = explosionRadius * DisplayConfig.instance.scaleFactor;
      
      if (distanceToHero <= triggerDistance) {
        _explode();
      }
    }
  }
  
  void _explode() {
    // Play mine explosion sound
    SoundManager().playMineExplodeSound();
    
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final distanceToHero = position.distanceTo(hero.position);
      final explosionRange = explosionRadius * DisplayConfig.instance.scaleFactor;
      
      if (distanceToHero <= explosionRange) {
        // Deal direct damage as percentage of player's max HP
        final directDamage = hero.maxHealth * damagePercent;
        hero.takeDamage(directDamage, sourceType: 'mine_layer');
        print('Mine explosion! Dealt ${directDamage.toStringAsFixed(1)} damage (${(damagePercent * 100).toStringAsFixed(0)}% of max HP)');
      }
    }
    
    // Create visual explosion effect
    _createExplosionEffect();
    
    removeFromParent();
  }
  
  void _createExplosionEffect() {
    // Create a simple explosion effect with multiple small projectiles
    const numFragments = 8;
    
    for (int i = 0; i < numFragments; i++) {
      final angle = (i * 360.0 / numFragments) * (pi / 180.0);
      final direction = Vector2(cos(angle), sin(angle));
      
      // Create small visual fragments (could be simple components)
      final fragment = CircleComponent(
        position: position.clone(),
        radius: 3.0,
        paint: Paint()..color = Colors.orange,
      );
      
      gameRef.add(fragment);
      
      // Remove fragment after short time
      fragment.add(RemoveEffect(delay: 0.5));
      
      // Add movement to fragment
      fragment.add(MoveByEffect(
        direction * 40.0 * DisplayConfig.instance.scaleFactor,
        EffectController(duration: 0.5),
      ));
    }
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
import '../../config/enemy_config.dart';
import '../sound_manager.dart';
// Item drop imports removed - now handled by ConsumableDropManager

class ShieldedChaser extends PositionComponent with HasGameRef<CircleRougeGame> {
  // Visual properties
  late Paint bodyPaint;
  late Paint shieldPaint;
  late double radius;
  
  // Movement speed configuration
  static const double baseSpeed = 60.0; // Default fallback speed
  double get speed {
    final configSpeed = WaveConfig.instance.enemyConfig?.getMovementSpeed('shielded_chaser') ?? baseSpeed;
    return configSpeed * DisplayConfig.instance.scaleFactor;
  }
  
  // Shield system
  double shieldHealth = 60.0; // Separate shield health
  double maxShieldHealth = 60.0;
  bool hasShield = true;
  
  // Combat properties
  double health = 30.0;
  double maxHealth = 30.0;
  bool isDead = false;
  
  // AI behavior
  double lastDirectionChange = 0.0;
  Vector2 currentDirection = Vector2.zero();
  
  // Visual effects
  double shieldRotation = 0.0;
  
  // Stun mechanics
  bool isStunned = false;
  double stunTimer = 0.0;
  
  // Slow effect mechanics
  bool isSlowed = false;
  double speedMultiplier = 1.0;
  
  ShieldedChaser({Vector2? position}) : super(
    position: position ?? Vector2.zero(),
    size: Vector2.all(30.0 * DisplayConfig.instance.scaleFactor),
    anchor: Anchor.center,
  ) {
    radius = 15.0 * DisplayConfig.instance.scaleFactor;
    bodyPaint = Paint()..color = const Color(0xFF795548); // Brown color for armored look
    
    // Shield paint with transparency based on shield health
    _updateShieldVisuals();
  }
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize health from config with wave scaling
    _initializeHealth();
  }
  
  void _initializeHealth() {
    // Get base health from enemy config
    final baseHealth = EnemyConfigManager.instance.getEnemyHealth('shielded_chaser', 45.0);
    // Apply wave-based scaling
    final scaledHealth = WaveConfig.instance.getScaledHealth(baseHealth, gameRef.currentWave);
    health = scaledHealth;
    maxHealth = scaledHealth;
    
    // Also scale shield health
    final baseShieldHealth = EnemyConfigManager.instance.getEnemyProperty('shielded_chaser', 'shield_health', 20.0);
    final scaledShieldHealth = WaveConfig.instance.getScaledHealth(baseShieldHealth, gameRef.currentWave);
    shieldHealth = scaledShieldHealth;
    maxShieldHealth = scaledShieldHealth;
  }
  
  void _updateShieldVisuals() {
    if (hasShield) {
      final alpha = (shieldHealth / maxShieldHealth * 0.8 + 0.2).clamp(0.2, 1.0);
      shieldPaint = Paint()
        ..color = const Color(0xFF2196F3).withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final center = Offset(size.x / 2, size.y / 2);
    
    // Draw main enemy body (gray orb)
    canvas.drawCircle(center, radius, bodyPaint);
    
    // Draw shield overlay if active
    if (hasShield) {
      _drawHexagonalShield(canvas, center);
    }
  }
  
  void _drawHexagonalShield(Canvas canvas, Offset center) {
    final path = Path();
    final shieldRadius = radius + 8.0; // Shield is larger than the body
    
    // Create hexagonal shield shape
    for (int i = 0; i < 6; i++) {
      final angle = (shieldRotation + i * 60) * (pi / 180); // Convert to radians
      final x = center.dx + shieldRadius * cos(angle);
      final y = center.dy + shieldRadius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    // Draw shield with glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFF4169E1).withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, shieldPaint);
    
    // Draw shield health bar if shield is damaged
    if (shieldHealth < maxShieldHealth) {
      _drawShieldHealthBar(canvas, center);
    }
  }
  
  void _drawShieldHealthBar(Canvas canvas, Offset center) {
    final barWidth = radius * 2;
    final barHeight = 4.0;
    final barY = center.dy - radius - 15.0;
    
    // Background
    final backgroundRect = Rect.fromLTWH(
      center.dx - barWidth / 2,
      barY,
      barWidth,
      barHeight,
    );
    canvas.drawRect(backgroundRect, Paint()..color = Colors.black.withOpacity(0.5));
    
    // Shield health fill
    final shieldPercent = shieldHealth / maxShieldHealth;
    final shieldRect = Rect.fromLTWH(
      center.dx - barWidth / 2,
      barY,
      barWidth * shieldPercent,
      barHeight,
    );
    canvas.drawRect(shieldRect, Paint()..color = const Color(0xFF4169E1));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip update when game is paused
    if (gameRef.gameState == GameState.paused) {
      return;
    }
    
    if (isDead) return;
    
    // Update shield rotation for visual effect
    shieldRotation += 45.0 * dt; // Rotate 45 degrees per second
    if (shieldRotation >= 360.0) {
      shieldRotation -= 360.0;
    }
    
    // Update shield visuals
    if (hasShield) {
      _updateShieldVisuals();
    }
    
    // Handle stun
    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
      }
      return; // Don't move while stunned
    }
    
    // Move towards hero
    final hero = gameRef.hero;
    if (hero.isMounted) {
      final directionToHero = (hero.position - position).normalized();
      
      // Apply no-stay zone force to keep enemies away from edges
      final noStayForce = gameRef.getNoStayZoneForce(position);
      
      // Add some randomness to movement to avoid clustering
      final random = Random();
      if (DateTime.now().millisecondsSinceEpoch / 1000.0 - lastDirectionChange > 1.0) {
        currentDirection = directionToHero + Vector2(
          (random.nextDouble() - 0.5) * 0.5,
          (random.nextDouble() - 0.5) * 0.5,
        );
        currentDirection.normalize();
        lastDirectionChange = DateTime.now().millisecondsSinceEpoch / 1000.0;
      }
      
      // Combine current direction with no-stay force
      final finalDirection = currentDirection + (noStayForce * dt);
      if (finalDirection.length > 0) {
        finalDirection.normalize();
      }
      
      // Apply speed multiplier for slow effects
      final effectiveSpeed = speed * speedMultiplier;
      position += finalDirection * effectiveSpeed * dt;
      
      // Keep within arena bounds
      _constrainToArena();
      
      // Check collision with hero
      final distanceToHero = position.distanceTo(hero.position);
      if (distanceToHero < radius + hero.collisionRadius) {
        final contactDamage = EnemyConfigManager.instance.getEnemyDamage('shielded_chaser', 10.0);
        hero.takeDamage(contactDamage, sourceType: 'shielded_chaser');
      }
    }
  }
  
  void takeDamage(double damage, {bool isAbility = false}) {
    if (hasShield) {
      if (isAbility) {
        // Hero abilities instantly break shields
        _breakShield();
      } else {
        // Regular damage affects shield health
        shieldHealth -= damage;
        if (shieldHealth <= 0) {
          _breakShield();
        }
      }
    } else {
      // No shield - damage goes to health
      health -= damage;
      if (health <= 0) {
        _destroyEnemy();
      }
    }
  }
  
  void _breakShield() {
    hasShield = false;
    shieldHealth = 0;
    
    // Play shield break sound
    SoundManager().playShieldBreakSound();
    print('Shield broken!');
  }
  
  void _destroyEnemy() {
    // Item drops are now handled by the unified ConsumableDropManager
    // via gameRef.onEnemyDestroyed(this)
    
    // Enemy destroyed
    if (parent != null) {
      gameRef.onEnemyDestroyed(this);
      removeFromParent();
    }
  }
  
  void stun(double duration) {
    isStunned = true;
    stunTimer = duration;
  }
  
  double get totalHealth => health + (hasShield ? shieldHealth : 0);
  
  void _constrainToArena() {
    position.x = position.x.clamp(radius, DisplayConfig.instance.arenaWidth - radius);
    position.y = position.y.clamp(radius, DisplayConfig.instance.arenaHeight - radius);
  }

  void applySlowEffect(double multiplier) {
    if (!isSlowed) {
      isSlowed = true;
      speedMultiplier = multiplier;
      // Change color to indicate slowed state
      bodyPaint.color = const Color(0xFF4A4A4A); // Darker gray when slowed
    }
  }
} 
```

```dart
import 'package:flutter/material.dart';
import '../game/circle_rouge_game.dart';

class GameOverOverlay extends StatefulWidget {
  final CircleRougeGame game;
  final bool isVictory;

  const GameOverOverlay({
    super.key,
    required this.game,
    required this.isVictory,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isVictory ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final secondaryColor = widget.isVictory ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              primaryColor.withOpacity(0.1),
              const Color(0xFF0F0F1F).withOpacity(0.8),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(40.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2D2D4A),
                    const Color(0xFF1E1E3A),
                    const Color(0xFF151528),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: primaryColor.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
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
                  // Icon with glow effect
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                primaryColor.withOpacity(0.8),
                                primaryColor.withOpacity(0.3),
                                primaryColor.withOpacity(0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.isVictory ? Icons.emoji_events : Icons.close,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Title with gradient text
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        primaryColor,
                        secondaryColor,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      widget.isVictory ? 'VICTORY!' : 'GAME OVER',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Subtitle with better styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.isVictory
                          ? '🎊 You survived all 5 waves! Incredible job!'
                          : widget.game.lastDeathMessage,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 35),
                  
                  // Play Again button with enhanced styling
                  Container(
                    width: 240,
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor,
                          secondaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: primaryColor.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        widget.game.overlays.remove('GameOver');
                        widget.game.restartGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'PLAY AGAIN',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Main Menu button with secondary styling
                  Container(
                    width: 240,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF424242),
                          Color(0xFF303030),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        widget.game.overlays.remove('GameOver');
                        widget.game.showStartMenu();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'MAIN MENU',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
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
} 
```

- I added killer tracking on the game state and mapped it to flavorful death messages. Now, the game will deduce HP first and then set `killerType` at the moment of lethal damage, and the Game Over screen will show the appropriate message.
- I threaded a `sourceType` through damage paths:
  - `Hero.takeDamage(double, {String? sourceType})` sets `killerType` when death occurs.
  - Enemy contact and explosions now pass a specific `sourceType` to `hero.takeDamage`.
  - Enemy `Projectile` and `ShapeProjectile` carry `ownerEnemyType` and pass it as `sourceType` on hit.
- I updated `GameOverOverlay` to display `game.lastDeathMessage` instead of the generic line.

Status: All edits compile clean per lints. Let’s run a quick build on your side and test deaths from each enemy to confirm messages:
- Chaser contact
- Shooter projectile
- Shielded Chaser contact
- Swarmer contact
- Bomber contact and explosion (and its explosion projectiles)
- Sniper contact and projectile
- Splitter contact
- MineLayer contact and mine explosion

If any enemy has a missing or unexpected message, I can extend the mapping.

