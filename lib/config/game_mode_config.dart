import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

enum GameMode { normal, endless, oneHpChallenge }

class GameModeData {
  final String id;
  final String name;
  final String description;
  final int maxWaves;
  final double scaling;
  final int scalingInterval;
  final bool retryTokens;
  final int playerHealth;
  final Color primaryColor;
  final Color secondaryColor;

  GameModeData({
    required this.id,
    required this.name,
    required this.description,
    required this.maxWaves,
    required this.scaling,
    required this.scalingInterval,
    required this.retryTokens,
    required this.playerHealth,
    required this.primaryColor,
    required this.secondaryColor,
  });

  factory GameModeData.fromJson(Map<String, dynamic> json) {
    return GameModeData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      maxWaves: json['max_waves'] ?? 5,
      scaling: (json['scaling'] ?? 1.0).toDouble(),
      scalingInterval: json['scaling_interval'] ?? 1,
      retryTokens: json['retry_tokens'] ?? false,
      playerHealth: json['player_health'] ?? 100,
      primaryColor: Color(_parseColor(json['primary_color'] ?? '0xFF4CAF50')),
      secondaryColor: Color(_parseColor(json['secondary_color'] ?? '0xFF45A049')),
    );
  }
  
  static int _parseColor(dynamic colorValue) {
    if (colorValue is int) {
      return colorValue;
    } else if (colorValue is String) {
      // Remove '0x' or '0X' prefix if present
      String cleanColor = colorValue.toUpperCase();
      if (cleanColor.startsWith('0X')) {
        cleanColor = cleanColor.substring(2);
      }
      return int.parse(cleanColor, radix: 16);
    } else {
      throw ArgumentError('Color value must be int or String, got ${colorValue.runtimeType}');
    }
  }
}

class GameModeConfig {
  static final GameModeConfig _instance = GameModeConfig._internal();
  GameModeConfig._internal();
  static GameModeConfig get instance => _instance;

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

  Map<String, GameModeData> _gameModes = {};
  bool _isLoaded = false;

  Future<void> loadConfig() async {
    if (_isLoaded) return;

    try {
      // Try to load from assets first
      final String yamlString = await rootBundle.loadString('assets/config/game_modes.yaml');
      final yamlData = loadYaml(yamlString) as Map;
      
      _gameModes.clear();
      yamlData.forEach((key, value) {
        _gameModes[key.toString()] = GameModeData.fromJson(_convertYamlMap(value as Map));
      });
      
      _isLoaded = true;
    } catch (e) {
      // If loading fails, create default game modes
      print('Failed to load game modes config: $e. Using defaults.');
      _createDefaultGameModes();
      _isLoaded = true;
    }
  }

  void _createDefaultGameModes() {
    _gameModes = {
      'normal': GameModeData(
        id: 'normal',
        name: 'Normal Mode',
        description: 'Classic 5-wave survival experience',
        maxWaves: 5,
        scaling: 1.0,
        scalingInterval: 1,
        retryTokens: false,
        playerHealth: 100,
        primaryColor: const Color(0xFF4CAF50),
        secondaryColor: const Color(0xFF45A049),
      ),
      'endless': GameModeData(
        id: 'endless',
        name: 'Endless Mode',
        description: 'Survive infinite waves with exponential scaling',
        maxWaves: -1,
        scaling: 1.20,
        scalingInterval: 5,
        retryTokens: false,
        playerHealth: 100,
        primaryColor: const Color(0xFF9C27B0),
        secondaryColor: const Color(0xFF7B1FA2),
      ),
      'oneHpChallenge': GameModeData(
        id: 'oneHpChallenge',
        name: '1HP Challenge',
        description: 'One hit kills, but enemies drop Retry Tokens',
        maxWaves: 5,
        scaling: 1.0,
        scalingInterval: 1,
        retryTokens: true,
        playerHealth: 1,
        primaryColor: const Color(0xFFFF5722),
        secondaryColor: const Color(0xFFE64A19),
      ),
    };
  }

  GameModeData? getGameModeById(String id) {
    return _gameModes[id];
  }

  List<GameModeData> getAllGameModes() {
    return _gameModes.values.toList();
  }

  GameModeData get defaultGameMode => _gameModes['normal']!;

  bool get isLoaded => _isLoaded;
} 