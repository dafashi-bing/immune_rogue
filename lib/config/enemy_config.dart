import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class EnemyConfigData {
  final double health;
  final double speed;
  final double damage;
  final Map<String, dynamic> properties;
  
  EnemyConfigData({
    required this.health,
    required this.speed,
    required this.damage,
    required this.properties,
  });
  
  factory EnemyConfigData.fromJson(Map<String, dynamic> json) {
    return EnemyConfigData(
      health: (json['health'] ?? 30.0).toDouble(),
      speed: (json['speed'] ?? 50.0).toDouble(),
      damage: (json['contact_damage'] ?? 15.0).toDouble(),
      properties: Map<String, dynamic>.from(json),
    );
  }
  
  double getProperty(String key, double defaultValue) {
    final value = properties[key];
    if (value is num) {
      return value.toDouble();
    }
    return defaultValue;
  }
  
  int getIntProperty(String key, int defaultValue) {
    final value = properties[key];
    if (value is num) {
      return value.toInt();
    }
    return defaultValue;
  }
  
  List<double> getListProperty(String key, List<double> defaultValue) {
    final value = properties[key];
    if (value is List) {
      return value.map((e) => (e as num).toDouble()).toList();
    }
    return defaultValue;
  }
}

class EnemyConfigManager {
  static EnemyConfigManager? _instance;
  static EnemyConfigManager get instance => _instance ??= EnemyConfigManager._();
  
  EnemyConfigManager._();
  
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
  
  Map<String, EnemyConfigData> _enemyConfigs = {};
  bool _loaded = false;
  
  Future<void> loadConfig() async {
    if (_loaded) return;
    
    try {
      final String yamlString = await rootBundle.loadString('assets/config/enemies.yaml');
      final yamlData = loadYaml(yamlString) as Map;
      
      _enemyConfigs = yamlData.map((key, value) => 
        MapEntry(key.toString(), EnemyConfigData.fromJson(_convertYamlMap(value as Map)))
      );
      
      _loaded = true;
      print('Enemy config loaded with ${_enemyConfigs.length} enemy types');
    } catch (e) {
      print('Error loading enemy config: $e');
      _loaded = true; // Set to true to prevent repeated attempts
    }
  }
  
  EnemyConfigData? getEnemyConfig(String enemyType) {
    return _enemyConfigs[enemyType];
  }
  
  double getEnemyHealth(String enemyType, double defaultValue) {
    return _enemyConfigs[enemyType]?.health ?? defaultValue;
  }
  
  double getEnemySpeed(String enemyType, double defaultValue) {
    return _enemyConfigs[enemyType]?.speed ?? defaultValue;
  }
  
  double getEnemyDamage(String enemyType, double defaultValue) {
    return _enemyConfigs[enemyType]?.damage ?? defaultValue;
  }
  
  double getEnemyProperty(String enemyType, String property, double defaultValue) {
    return _enemyConfigs[enemyType]?.getProperty(property, defaultValue) ?? defaultValue;
  }
  
  int getEnemyIntProperty(String enemyType, String property, int defaultValue) {
    return _enemyConfigs[enemyType]?.getIntProperty(property, defaultValue) ?? defaultValue;
  }
  
  List<double> getEnemyListProperty(String enemyType, String property, List<double> defaultValue) {
    return _enemyConfigs[enemyType]?.getListProperty(property, defaultValue) ?? defaultValue;
  }
  
  double getEnemyItemDropChance(String enemyType, double defaultValue) {
    return _enemyConfigs[enemyType]?.getProperty('item_drop_chance', defaultValue) ?? defaultValue;
  }
}
