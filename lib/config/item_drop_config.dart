import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class ItemDropData {
  final String effectType;
  final double effectValue;
  final double duration;
  final double weight;
  final String category;
  final String description;

  const ItemDropData({
    required this.effectType,
    required this.effectValue,
    required this.duration,
    required this.weight,
    required this.category,
    required this.description,
  });

  factory ItemDropData.fromJson(Map<String, dynamic> json) {
    return ItemDropData(
      effectType: json['effectType'] as String,
      effectValue: (json['effectValue'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'effectType': effectType,
      'effectValue': effectValue,
      'duration': duration,
      'weight': weight,
      'category': category,
      'description': description,
    };
  }
}

class ItemDropConfig {
  static ItemDropConfig? _instance;
  static ItemDropConfig get instance => _instance ??= ItemDropConfig._();
  
  ItemDropConfig._();
  
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

  double _baseDropChance = 0.2;
  List<ItemDropData> _itemDrops = [];
  bool _isLoaded = false;

  double get baseDropChance => _baseDropChance;
  List<ItemDropData> get itemDrops => List.unmodifiable(_itemDrops);
  bool get isLoaded => _isLoaded;

  Future<void> loadConfig() async {
    if (_isLoaded) return;

    try {
      final String configString = await rootBundle.loadString('assets/config/item_drops.yaml');
      final configData = loadYaml(configString) as Map;

      _baseDropChance = (configData['baseDropChance'] as num).toDouble();
      
      final List<dynamic> itemDropsJson = configData['itemDrops'] as List<dynamic>;
      _itemDrops = itemDropsJson
          .map((json) => ItemDropData.fromJson(_convertYamlMap(json as Map)))
          .toList();

      _isLoaded = true;
      print('Item drop config loaded: ${_itemDrops.length} items, base drop chance: ${(_baseDropChance * 100).round()}%');
    } catch (e) {
      print('Error loading item drop config: $e');
      // Use default values if config fails to load
      _useDefaultConfig();
    }
  }

  void _useDefaultConfig() {
    _baseDropChance = 0.2;
    _itemDrops = [
      const ItemDropData(
        effectType: 'speed_boost',
        effectValue: 0.5,
        duration: 8.0,
        weight: 3.0,
        category: 'consumable',
        description: '50% speed increase',
      ),
      const ItemDropData(
        effectType: 'damage_boost',
        effectValue: 0.3,
        duration: 10.0,
        weight: 2.0,
        category: 'consumable',
        description: '30% damage increase',
      ),
      const ItemDropData(
        effectType: 'health_regen',
        effectValue: 2.0,
        duration: 12.0,
        weight: 2.0,
        category: 'consumable',
        description: '2 HP per second regeneration',
      ),
      const ItemDropData(
        effectType: 'shield',
        effectValue: 25.0,
        duration: 15.0,
        weight: 1.5,
        category: 'consumable',
        description: '25 shield points',
      ),
      const ItemDropData(
        effectType: 'invincibility',
        effectValue: 1.0,
        duration: 3.0,
        weight: 0.5,
        category: 'consumable',
        description: 'Full invincibility',
      ),
      const ItemDropData(
        effectType: 'weapon_overclock',
        effectValue: 0.25,
        duration: 10.0,
        weight: 2.0,
        category: 'consumable',
        description: '25% fire rate increase',
      ),
      const ItemDropData(
        effectType: 'health_shard',
        effectValue: 20.0,
        duration: 0.0,
        weight: 4.0,
        category: 'instant',
        description: 'Instant 20 HP heal',
      ),
      const ItemDropData(
        effectType: 'retry_token',
        effectValue: 1.0,
        duration: 0.0,
        weight: 0.5,
        category: 'instant',
        description: 'Extra life token',
      ),
    ];
    _isLoaded = true;
  }

  // Helper methods for easy access
  List<ItemDropData> get consumableItems => _itemDrops.where((item) => item.category == 'consumable').toList();
  List<ItemDropData> get instantItems => _itemDrops.where((item) => item.category == 'instant').toList();
  
  ItemDropData? getItemByType(String effectType) {
    try {
      return _itemDrops.firstWhere((item) => item.effectType == effectType);
    } catch (e) {
      return null;
    }
  }

  double getTotalWeight() {
    return _itemDrops.fold(0.0, (sum, item) => sum + item.weight);
  }
}
