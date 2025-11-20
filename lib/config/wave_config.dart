import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class WaveSettings {
  final int maxWaves;
  final double waveDuration;
  final bool debugMode;
  final double debugWaveDuration;
  
  WaveSettings({
    required this.maxWaves,
    required this.waveDuration,
    required this.debugMode,
    required this.debugWaveDuration,
  });
  
  factory WaveSettings.fromJson(Map<String, dynamic> json) {
    return WaveSettings(
      maxWaves: json['max_waves'],
      waveDuration: json['wave_duration'].toDouble(),
      debugMode: json['debug_mode'] ?? false,
      debugWaveDuration: (json['debug_wave_duration'] ?? 1.0).toDouble(),
    );
  }
  
  // Get the effective wave duration based on debug mode
  double get effectiveWaveDuration => debugMode ? debugWaveDuration : waveDuration;
}

class ShopConfig {
  final double waveMultiplier;
  final double randomVariance;
  final int rollCost;
  final String description;
  
  ShopConfig({
    required this.waveMultiplier,
    required this.randomVariance,
    required this.rollCost,
    required this.description,
  });
  
  factory ShopConfig.fromJson(Map<String, dynamic> json) {
    final priceScaling = json['price_scaling'] ?? {};
    return ShopConfig(
      waveMultiplier: (priceScaling['wave_multiplier'] ?? 0.2).toDouble(),
      randomVariance: (priceScaling['random_variance'] ?? 0.05).toDouble(),
      rollCost: priceScaling['roll_cost'] ?? 10,
      description: priceScaling['description'] ?? '',
    );
  }
}

class WaveData {
  final int wave;
  final String name;
  final String description;
  final List<String> enemyTypes;
  final Map<String, double> spawnWeights;
  final double spawnInterval;
  final int spawnCount;
  
  WaveData({
    required this.wave,
    required this.name,
    required this.description,
    required this.enemyTypes,
    required this.spawnWeights,
    required this.spawnInterval,
    required this.spawnCount,
  });
  
  factory WaveData.fromJson(Map<String, dynamic> json) {
    return WaveData(
      wave: json['wave'],
      name: json['name'],
      description: json['description'],
      enemyTypes: List<String>.from(json['enemy_types']),
      spawnWeights: Map<String, double>.from(
        json['spawn_weights'].map((key, value) => MapEntry(key, value.toDouble()))
      ),
      spawnInterval: (json['spawn_interval'] ?? 2.0).toDouble(),
      spawnCount: json['spawn_count'] ?? 1,
    );
  }
}

class EnemyReward {
  final int coins;
  
  EnemyReward({required this.coins});
  
  factory EnemyReward.fromJson(Map<String, dynamic> json) {
    return EnemyReward(
      coins: json['coins'],
    );
  }
}

class EnemyData {
  final double movementSpeed;
  final double itemDropChance;
  final String description;
  
  EnemyData({
    required this.movementSpeed,
    required this.itemDropChance,
    required this.description,
  });
  
  factory EnemyData.fromJson(Map<String, dynamic> json) {
    return EnemyData(
      movementSpeed: (json['movement_speed'] ?? 50.0).toDouble(),
      itemDropChance: (json['item_drop_chance'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
    );
  }
}

class EnemyScaling {
  final double healthMultiplier;
  final double spawnSpeedMultiplier;
  final double damageMultiplier;
  final String description;
  
  EnemyScaling({
    required this.healthMultiplier,
    required this.spawnSpeedMultiplier,
    required this.damageMultiplier,
    required this.description,
  });
  
  factory EnemyScaling.fromJson(Map<String, dynamic> json) {
    return EnemyScaling(
      healthMultiplier: (json['health_multiplier'] ?? 0.0).toDouble(),
      spawnSpeedMultiplier: (json['spawn_speed_multiplier'] ?? 0.0).toDouble(),
      damageMultiplier: (json['damage_multiplier'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
    );
  }
}

class EnemyConfig {
  final Map<String, EnemyData> enemies;
  
  EnemyConfig({
    required this.enemies,
  });
  
  factory EnemyConfig.fromJson(Map<String, dynamic> json) {
    final Map<String, EnemyData> enemies = {};
    
    for (final entry in json.entries) {
      if (entry.value is Map<String, dynamic>) {
        enemies[entry.key] = EnemyData.fromJson(entry.value);
      }
    }
    
    return EnemyConfig(enemies: enemies);
  }
  
  double getMovementSpeed(String enemyType) {
    return enemies[enemyType]?.movementSpeed ?? 50.0; // Default fallback speed
  }
  
  double getRetryDropChance(String enemyType) {
    return enemies[enemyType]?.itemDropChance ?? 0.05; // Default fallback chance
  }
  
  EnemyData? getEnemyData(String enemyType) {
    return enemies[enemyType];
  }
}

class InfiniteSpawns {
  final Map<String, int> spawnThresholds;
  
  InfiniteSpawns({required this.spawnThresholds});
  
  factory InfiniteSpawns.fromJson(Map<String, dynamic> json) {
    final thresholds = json['spawn_thresholds'] as Map<String, dynamic>? ?? {};
    return InfiniteSpawns(
      spawnThresholds: thresholds.map((key, value) => MapEntry(key, value as int)),
    );
  }
  
  List<String> getAvailableEnemyTypes(int currentWave) {
    return spawnThresholds.entries
        .where((entry) => currentWave >= entry.value)
        .map((entry) => entry.key)
        .toList();
  }
}

class BackgroundConfig {
  final String description;
  final Map<String, String> mappings; // wave range -> background path
  final List<String> lateGameBackgrounds;
  final Map<String, String> biomeNames; // background path -> biome name
  
  BackgroundConfig({
    required this.description,
    required this.mappings,
    required this.lateGameBackgrounds,
    required this.biomeNames,
  });
  
  factory BackgroundConfig.fromJson(Map<String, dynamic> json) {
    final mappingsData = json['mappings'] as Map<String, dynamic>? ?? {};
    final lateGameData = json['late_game_backgrounds'] as List? ?? [];
    final biomeNamesData = json['biome_names'] as Map<String, dynamic>? ?? {};
    
    return BackgroundConfig(
      description: json['description'] ?? '',
      mappings: mappingsData.map((key, value) => MapEntry(key.toString(), value.toString())),
      lateGameBackgrounds: lateGameData.map((item) => item.toString()).toList(),
      biomeNames: biomeNamesData.map((key, value) => MapEntry(key.toString(), value.toString())),
    );
  }
  
  String getBackgroundForWave(int wave) {
    // Check if wave matches any range in mappings
    for (final entry in mappings.entries) {
      final range = entry.key;
      final backgroundPath = entry.value;
      
      if (range.contains('-')) {
        // Parse range like "1-2" or "3-4"
        final parts = range.split('-');
        if (parts.length == 2) {
          final start = int.tryParse(parts[0].trim());
          final end = int.tryParse(parts[1].trim());
          if (start != null && end != null && wave >= start && wave <= end) {
            return backgroundPath;
          }
        }
      } else {
        // Parse single wave like "5"
        final waveNumber = int.tryParse(range.trim());
        if (waveNumber != null && wave == waveNumber) {
          return backgroundPath;
        }
      }
    }
    
    // For waves beyond the mapped ranges, use late game backgrounds
    if (lateGameBackgrounds.isNotEmpty) {
      // Rotate every 5 waves: waves 16-20 same, 21-25 same, etc.
      final rotationIndex = ((wave - 16) ~/ 5) % lateGameBackgrounds.length;
      return lateGameBackgrounds[rotationIndex.clamp(0, lateGameBackgrounds.length - 1)];
    }
    
    // Fallback to first mapping if available
    return mappings.values.firstOrNull ?? 'backgrounds/background_skin.png';
  }
  
  String getBiomeName(String backgroundPath) {
    return biomeNames[backgroundPath] ?? 'Unknown Biome';
  }
}

class WaveConfig {
  static WaveConfig? _instance;
  static WaveConfig get instance => _instance ??= WaveConfig._();
  
  WaveConfig._();
  
  // Helper function to convert YAML maps to Map<String, dynamic>
  Map<String, dynamic> _convertYamlMap(Map yamlMap) {
    return yamlMap.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _convertYamlMap(value));
      } else if (value is List) {
        return MapEntry(key.toString(), value.map((item) {
          if (item is Map) {
            return _convertYamlMap(item);
          }
          return item;
        }).toList());
      } else {
        return MapEntry(key.toString(), value);
      }
    });
  }
  
  WaveSettings? _settings;
  ShopConfig? _shopConfig;
  EnemyConfig? _enemyConfig;
  EnemyScaling? _enemyScaling;
  InfiniteSpawns? _infiniteSpawns;
  BackgroundConfig? _backgroundConfig;
  List<WaveData> _waves = [];
  Map<String, EnemyReward> _enemyRewards = {};
  bool _loaded = false;
  
  WaveSettings? get settings => _settings;
  ShopConfig? get shopConfig => _shopConfig;
  EnemyConfig? get enemyConfig => _enemyConfig;
  EnemyScaling? get enemyScaling => _enemyScaling;
  InfiniteSpawns? get infiniteSpawns => _infiniteSpawns;
  BackgroundConfig? get backgroundConfig => _backgroundConfig;
  List<WaveData> get waves => _waves;
  Map<String, EnemyReward> get enemyRewards => _enemyRewards;
  
  Future<void> loadConfig() async {
    if (_loaded) return;
    
    try {
      final String yamlString = await rootBundle.loadString('assets/config/waves.yaml');
      final yamlData = loadYaml(yamlString) as Map;
      
      _settings = WaveSettings.fromJson(_convertYamlMap(yamlData['wave_config'] as Map));
      
      // Load shop configuration if available
      if (yamlData.containsKey('shop_config')) {
        _shopConfig = ShopConfig.fromJson(_convertYamlMap(yamlData['shop_config'] as Map));
      }
      
      // Enemy configuration is now loaded from enemies.yaml
      // No longer needed here
      
      // Load enemy scaling configuration if available
      if (yamlData.containsKey('enemy_scaling')) {
        _enemyScaling = EnemyScaling.fromJson(_convertYamlMap(yamlData['enemy_scaling'] as Map));
      }
      
      // Load infinite mode spawn configuration if available
      if (yamlData.containsKey('infinite_mode_spawns')) {
        _infiniteSpawns = InfiniteSpawns.fromJson(_convertYamlMap(yamlData['infinite_mode_spawns'] as Map));
      }
      
      // Load background configuration if available
      if (yamlData.containsKey('wave_backgrounds')) {
        _backgroundConfig = BackgroundConfig.fromJson(_convertYamlMap(yamlData['wave_backgrounds'] as Map));
      }
      
      _waves = (yamlData['waves'] as List)
          .map((wave) => WaveData.fromJson(_convertYamlMap(wave as Map)))
          .toList();
      
      // Load enemy rewards if available (for backward compatibility)
      if (yamlData.containsKey('enemy_rewards')) {
        _enemyRewards = (yamlData['enemy_rewards'] as Map)
            .map((key, value) => MapEntry(key.toString(), EnemyReward.fromJson(_convertYamlMap(value as Map))));
      } else {
        _enemyRewards = {}; // Empty map if no enemy rewards section
      }
      
      _loaded = true;
    } catch (e) {
      print('Error loading wave config: $e');
      // Fallback to default values if loading fails
      _settings = WaveSettings(
        maxWaves: 5,
        waveDuration: 30.0,
        debugMode: false,
        debugWaveDuration: 1.0,
      );
      _shopConfig = ShopConfig(
        waveMultiplier: 0.2,
        randomVariance: 0.05,
        rollCost: 10,
        description: 'Default shop configuration',
      );
      _enemyConfig = EnemyConfig(
        enemies: {
          'chaser': EnemyData(movementSpeed: 50.0, itemDropChance: 0.0, description: ''),
          'shooter': EnemyData(movementSpeed: 80.0, itemDropChance: 0.0, description: ''),
          'shielded_chaser': EnemyData(movementSpeed: 60.0, itemDropChance: 0.0, description: ''),
        },
      );
      _waves = [];
      _enemyRewards = {};
      _loaded = true;
    }
  }
  
  WaveData? getWaveData(int waveNumber) {
    return _waves.where((wave) => wave.wave == waveNumber).firstOrNull;
  }
  
  EnemyReward? getEnemyReward(String enemyType) {
    return _enemyRewards[enemyType];
  }
  
  // Get spawn interval for a specific wave
  double getSpawnInterval(int waveNumber) {
    final waveData = getWaveData(waveNumber);
    return waveData?.spawnInterval ?? 2.0; // Default fallback
  }
  
  // Get spawn count for a specific wave
  int getSpawnCount(int waveNumber) {
    final waveData = getWaveData(waveNumber);
    return waveData?.spawnCount ?? 1; // Default fallback
  }
  
  // Calculate scaled health based on current wave
  double getScaledHealth(double baseHealth, int currentWave) {
    if (_enemyScaling == null || _enemyScaling!.healthMultiplier <= 0) {
      return baseHealth; // No scaling if config not available or multiplier is 0
    }
    
    // Apply scaling: baseHealth * (1 + healthMultiplier * (wave - 1))
    // Wave 1: no scaling, Wave 2: +50%, Wave 3: +100%, etc.
    final scalingFactor = 1.0 + (_enemyScaling!.healthMultiplier * (currentWave - 1));
    return baseHealth * scalingFactor;
  }
  
  // Calculate scaled damage based on current wave
  double getScaledDamage(double baseDamage, int currentWave) {
    if (_enemyScaling == null || _enemyScaling!.damageMultiplier <= 0) {
      return baseDamage; // No scaling if config not available or multiplier is 0
    }
    
    // Apply scaling: baseDamage * (1 + damageMultiplier * (wave - 1))
    // Wave 1: no scaling, Wave 2: +30%, Wave 3: +60%, etc.
    final scalingFactor = 1.0 + (_enemyScaling!.damageMultiplier * (currentWave - 1));
    return baseDamage * scalingFactor;
  }
  
  // Get background path for a specific wave
  String getBackgroundForWave(int wave) {
    if (_backgroundConfig != null) {
      return _backgroundConfig!.getBackgroundForWave(wave);
    }
    // Fallback to default background
    return 'backgrounds/background_skin.png';
  }
} 