import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:flutter/material.dart';

class HeroAbility {
  final String name;
  final String description;
  final double cooldown;
  final String type;
  final double damage;
  final double range;
  final double? stunDuration;
  final int? projectileCount;
  final double? duration;
  final double? slowPercent;
  final double? projectileSize;
  final double? knockbackDistance;
  
  HeroAbility({
    required this.name,
    required this.description,
    required this.cooldown,
    required this.type,
    required this.damage,
    required this.range,
    this.stunDuration,
    this.projectileCount,
    this.duration,
    this.slowPercent,
    this.projectileSize,
    this.knockbackDistance,
  });
  
  factory HeroAbility.fromJson(Map<String, dynamic> json) {
    return HeroAbility(
      name: json['name'],
      description: json['description'],
      cooldown: json['cooldown'].toDouble(),
      type: json['type'],
      damage: json['damage'].toDouble(),
      range: json['range'].toDouble(),
      stunDuration: json['stun_duration']?.toDouble(),
      projectileCount: json['projectile_count'],
      duration: json['duration']?.toDouble(),
      slowPercent: json['slow_percent']?.toDouble(),
      projectileSize: json['projectile_size']?.toDouble(),
      knockbackDistance: json['knockback_distance']?.toDouble(),
    );
  }
}

class HeroData {
  final String id;
  final String name;
  final String shape;
  final double moveSpeed;
  final double health;
  final HeroAbility ability;
  final Color color;
  
  HeroData({
    required this.id,
    required this.name,
    required this.shape,
    required this.moveSpeed,
    required this.health,
    required this.ability,
    required this.color,
  });
  
  factory HeroData.fromJson(Map<String, dynamic> json) {
    return HeroData(
      id: json['id'],
      name: json['name'],
      shape: json['shape'],
      moveSpeed: json['move_speed'].toDouble(),
      health: json['health'].toDouble(),
      ability: HeroAbility.fromJson(json['ability']),
      color: Color(_parseColor(json['color'])),
    );
  }
  
  static int _parseColor(dynamic colorValue) {
    if (colorValue is int) {
      return colorValue;
    } else if (colorValue is String) {
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

class HeroConfig {
  static HeroConfig? _instance;
  static HeroConfig get instance => _instance ??= HeroConfig._();
  
  HeroConfig._();
  
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
  
  List<HeroData> _heroes = [];
  bool _loaded = false;
  
  List<HeroData> get heroes => _heroes;
  
  Future<void> loadConfig() async {
    if (_loaded) return;
    
    try {
      final String yamlString = await rootBundle.loadString('assets/config/heroes.yaml');
      final yamlData = loadYaml(yamlString) as Map;
      
      _heroes = (yamlData['heroes'] as List)
          .map((hero) => HeroData.fromJson(_convertYamlMap(hero as Map)))
          .toList();
      
      _loaded = true;
    } catch (e) {
      print('Error loading hero config: $e');
      // Fallback to default circle hero if loading fails
      _heroes = [
        HeroData(
          id: 'circle',
          name: 'Circle',
          shape: 'circle',
          moveSpeed: 320.0,
          health: 100.0,
          ability: HeroAbility(
            name: 'Rolling Surge',
            description: 'Unleash a high-speed roll that damages all enemies in your path.',
            cooldown: 6.0,
            type: 'dash_damage',
            damage: 40.0,
            range: 200.0,
            projectileSize: 60.0,
          ),
          color: const Color(0xFF4CAF50),
        ),
      ];
      _loaded = true;
    }
  }
  
  HeroData? getHeroById(String id) {
    return _heroes.where((hero) => hero.id == id).firstOrNull;
  }
  
  HeroData get defaultHero => _heroes.isNotEmpty ? _heroes.first : _heroes[0];
}