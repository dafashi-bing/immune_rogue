import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:flutter/material.dart';

class CompanionData {
  final double radius;
  final double fireRate;
  final double orbitRadius;
  final double orbitSpeed;
  final double targetScanInterval;
  final double attackRange;
  final double projectileSpeed;
  final double projectileDamage;
  final Color color;
  final double projectileSizeScale;
  
  CompanionData({
    required this.radius,
    required this.fireRate,
    required this.orbitRadius,
    required this.orbitSpeed,
    required this.targetScanInterval,
    required this.attackRange,
    required this.projectileSpeed,
    required this.projectileDamage,
    required this.color,
    required this.projectileSizeScale,
  });
  
  factory CompanionData.fromJson(Map<String, dynamic> json) {
    return CompanionData(
      radius: json['radius'].toDouble(),
      fireRate: json['fire_rate'].toDouble(),
      orbitRadius: json['orbit_radius'].toDouble(),
      orbitSpeed: json['orbit_speed'].toDouble(),
      targetScanInterval: json['target_scan_interval'].toDouble(),
      attackRange: json['attack_range'].toDouble(),
      projectileSpeed: json['projectile_speed'].toDouble(),
      projectileDamage: json['projectile_damage'].toDouble(),
      color: Color(_parseColor(json['color'])),
      projectileSizeScale: json['projectile_size_scale'].toDouble(),
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

class ItemEffect {
  final String type;
  final double value;
  final int? maxStacks;
  
  ItemEffect({required this.type, required this.value, this.maxStacks});
  
  factory ItemEffect.fromJson(Map<String, dynamic> json) {
    return ItemEffect(
      type: json['type'],
      value: json['value'].toDouble(),
      maxStacks: json['max_stacks'],
    );
  }
}

class ItemData {
  final String id;
  final String name;
  final int cost;
  final String description;
  final String type;
  final String icon;
  final ItemEffect effect;
  final CompanionData? companionConfig;
  
  ItemData({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
    required this.type,
    required this.icon,
    required this.effect,
    this.companionConfig,
  });
  
  factory ItemData.fromJson(Map<String, dynamic> json) {
    return ItemData(
      id: json['id'],
      name: json['name'],
      cost: json['cost'],
      description: json['description'],
      type: json['type'],
      icon: json['icon'] ?? 'ability_mastery_transparent.png', // Default fallback icon
      effect: ItemEffect.fromJson(json['effect']),
      companionConfig: json['companion_config'] != null 
          ? CompanionData.fromJson(json['companion_config'])
          : null,
    );
  }
}

class ItemConfig {
  static ItemConfig? _instance;
  static ItemConfig get instance => _instance ??= ItemConfig._();
  
  ItemConfig._();
  
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
  
  List<ItemData> _items = [];
  bool _loaded = false;
  
  List<ItemData> get items => _items;
  
  Future<void> loadConfig() async {
    if (_loaded) return;
    
    try {
      final String yamlString = await rootBundle.loadString('assets/config/items.yaml');
      final yamlData = loadYaml(yamlString) as Map;
      
      _items = (yamlData['items'] as List)
          .map((item) => ItemData.fromJson(_convertYamlMap(item as Map)))
          .toList();
      
      _loaded = true;
    } catch (e) {
      print('Error loading item config: $e');
      // Fallback to empty list if loading fails
      _items = [];
      _loaded = true;
    }
  }
  
  ItemData? getItemById(String id) {
    return _items.where((item) => item.id == id).firstOrNull;
  }
  
  List<ItemData> getItemsByType(String type) {
    return _items.where((item) => item.type == type).toList();
  }
  
  CompanionData? getCompanionConfigById(String id) {
    final item = getItemById(id);
    return item?.companionConfig;
  }
} 