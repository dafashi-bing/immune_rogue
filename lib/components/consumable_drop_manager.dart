import 'dart:math';
import 'package:flame/components.dart';

import '../game/circle_rouge_game.dart';
import '../config/item_drop_config.dart';
import '../config/enemy_config.dart';
import 'items/consumable_item.dart';
import 'items/health_shard.dart';
import 'items/retry_token.dart';

class ConsumableDropManager extends Component with HasGameRef<CircleRougeGame> {
  final Random _random = Random();
  
  // Drop statistics tracking
  final Map<String, int> _dropCounts = {};
  int _totalDropAttempts = 0;
  int _successfulDrops = 0;
  
  // Config will be loaded from JSON
  bool _configLoaded = false;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    await _ensureConfigLoaded();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Clean up expired consumables
    _cleanupExpiredConsumables();
  }

  Future<void> _ensureConfigLoaded() async {
    if (!_configLoaded) {
      await ItemDropConfig.instance.loadConfig();
      _configLoaded = true;
    }
  }
  
  void tryDropItem(Vector2 position, {String? enemyType}) async {
    await _ensureConfigLoaded();
    
    _totalDropAttempts++;
    
    // Get drop chance - use enemy-specific chance if available, otherwise use base chance
    double dropChance = ItemDropConfig.instance.baseDropChance;
    if (enemyType != null) {
      dropChance = EnemyConfigManager.instance.getEnemyItemDropChance(enemyType, dropChance);
    }
    
    // Check if we should drop an item
    if (_random.nextDouble() > dropChance) {
      return;
    }
    
    // Select random item based on weights
    final selectedItem = _selectRandomItem();
    if (selectedItem == null) return;
    
    // Create appropriate item based on category
    Component? item;
    final category = selectedItem.category;
    final effectType = selectedItem.effectType;
    
    if (category == 'consumable') {
      // Temporary effects (including weapon overclock)
      item = ConsumableItem(
        position: position,
        effectType: effectType,
        effectValue: selectedItem.effectValue,
        duration: selectedItem.duration,
      );
    } else if (category == 'instant') {
      // Instant consumables (health shard, retry token)
      switch (effectType) {
        case 'health_shard':
          item = HealthShard(position: position);
          break;
        case 'retry_token':
          item = RetryToken(position: position);
          break;
      }
    }
    
    if (item != null) {
      // Add to game
      gameRef.add(item);
      
      // Track drop statistics
      _updateDropStats(effectType);
      
      // Log drop for debugging
      print('Dropped $category: $effectType at $position');
    }
  }
  
  ItemDropData? _selectRandomItem() {
    final itemDrops = ItemDropConfig.instance.itemDrops;
    
    // Filter out retry tokens unless in 1HP Challenge mode
    final availableItems = itemDrops.where((item) {
      if (item.effectType == 'retry_token') {
        return gameRef.currentGameMode.name == 'oneHpChallenge';
      }
      return true;
    }).toList();
    
    if (availableItems.isEmpty) return null;
    
    final totalWeight = availableItems.fold(0.0, (sum, item) => sum + item.weight);
    
    if (totalWeight <= 0) return null;
    
    final randomValue = _random.nextDouble() * totalWeight;
    double currentWeight = 0.0;
    
    for (final item in availableItems) {
      currentWeight += item.weight;
      if (randomValue <= currentWeight) {
        return item;
      }
    }
    
    // Fallback to first available item
    return availableItems.isNotEmpty ? availableItems.first : null;
  }
  
  void _cleanupExpiredConsumables() {
    // This is handled by the ItemPickup base class with its lifetime system
    // No additional cleanup needed here
  }
  
  // Clear all item drops from the game
  void clearAllDrops() {
    final itemsToRemove = <Component>[];
    
    // Find all ItemPickup components in the game (includes all item types)
    for (final child in gameRef.children) {
      if (child is ConsumableItem || child is HealthShard || child is RetryToken) {
        itemsToRemove.add(child);
      }
    }
    
    // Remove all found items
    for (final item in itemsToRemove) {
      item.removeFromParent();
    }
    
    print('Cleared ${itemsToRemove.length} item drops');
  }
  
  // Method to get drop chance for UI display
  double get dropChance => ItemDropConfig.instance.baseDropChance;
  
  // Statistics update method
  void _updateDropStats(String itemType) {
    _successfulDrops++;
    _dropCounts[itemType] = (_dropCounts[itemType] ?? 0) + 1;
  }
  
  // Getter methods for statistics
  double get actualDropRate => _totalDropAttempts > 0 ? _successfulDrops / _totalDropAttempts : 0.0;
  int get totalDropAttempts => _totalDropAttempts;
  int get successfulDrops => _successfulDrops;
  Map<String, int> get dropCounts => Map.unmodifiable(_dropCounts);
  
  // Method to get available item types for UI
  List<String> get availableItemTypes {
    return ItemDropConfig.instance.itemDrops.map((item) => item.effectType).toList();
  }
}
