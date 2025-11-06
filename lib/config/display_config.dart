import 'dart:math';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// Callback type for display configuration changes
typedef DisplayConfigChangeCallback = void Function(DisplaySettings oldSettings, DisplaySettings newSettings);

class DisplaySettings {
  final double windowWidth;
  final double windowHeight;
  final double arenaWidth;
  final double arenaHeight;
  final double safeAreaMargin;
  final bool maintainAspectRatio;
  final double baseScaleWidth;
  final double baseScaleHeight;
  
  DisplaySettings({
    required this.windowWidth,
    required this.windowHeight,
    required this.arenaWidth,
    required this.arenaHeight,
    required this.safeAreaMargin,
    required this.maintainAspectRatio,
    required this.baseScaleWidth,
    required this.baseScaleHeight,
  });
  
  factory DisplaySettings.fromJson(Map<String, dynamic> json) {
    return DisplaySettings(
      windowWidth: json['window_width'].toDouble(),
      windowHeight: json['window_height'].toDouble(),
      arenaWidth: json['arena_width'].toDouble(),
      arenaHeight: json['arena_height'].toDouble(),
      safeAreaMargin: json['safe_area_margin'].toDouble(),
      maintainAspectRatio: json['maintain_aspect_ratio'] ?? true,
      baseScaleWidth: json['base_scale_width'].toDouble(),
      baseScaleHeight: json['base_scale_height'].toDouble(),
    );
  }
  
  // Calculate scaling factor based on arena size relative to base dimensions
  double get scaleFactor {
    // Use the smaller scaling factor to maintain proportions
    final widthScale = arenaWidth / baseScaleWidth;
    final heightScale = arenaHeight / baseScaleHeight;
    final factor = maintainAspectRatio ? min(widthScale, heightScale) : widthScale;
    
    // Debug output to verify scaling
    // print('Display Config - Arena: ${arenaWidth.toInt()}x${arenaHeight.toInt()}, Base: ${baseScaleWidth.toInt()}x${baseScaleHeight.toInt()}, Scale Factor: ${factor.toStringAsFixed(2)}');
    
    return factor;
  }
  
  // Get aspect ratio
  double get aspectRatio => windowWidth / windowHeight;
}

class DisplayConfig {
  static DisplayConfig? _instance;
  static DisplayConfig get instance => _instance ??= DisplayConfig._();
  
  DisplayConfig._();
  
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
  
  DisplaySettings? _settings;
  bool _loaded = false;
  
  // Listener system for dynamic responsiveness
  final List<DisplayConfigChangeCallback> _listeners = [];
  
  /// Register a callback to be notified when display configuration changes
  void addListener(DisplayConfigChangeCallback callback) {
    _listeners.add(callback);
  }
  
  /// Remove a previously registered callback
  void removeListener(DisplayConfigChangeCallback callback) {
    _listeners.remove(callback);
  }
  
  /// Notify all listeners of configuration changes
  void _notifyListeners(DisplaySettings oldSettings, DisplaySettings newSettings) {
    for (final callback in _listeners) {
      try {
        callback(oldSettings, newSettings);
      } catch (e) {
        print('Error in display config listener: $e');
      }
    }
  }
  
  DisplaySettings? get settings => _settings;
  
  // Convenience getters for commonly used values
  double get windowWidth => _settings?.windowWidth ?? 800.0;
  double get windowHeight => _settings?.windowHeight ?? 600.0;
  double get arenaWidth => _settings?.arenaWidth ?? 800.0;
  double get arenaHeight => _settings?.arenaHeight ?? 600.0;
  double get safeAreaMargin => _settings?.safeAreaMargin ?? 50.0;
  double get scaleFactor => _settings?.scaleFactor ?? 1.0;
  bool get maintainAspectRatio => _settings?.maintainAspectRatio ?? true;
  
  Future<void> loadConfig() async {
    if (_loaded) return;
    
    try {
      final String yamlString = await rootBundle.loadString('assets/config/display.yaml');
      final yamlData = loadYaml(yamlString) as Map;
      
      _settings = DisplaySettings.fromJson(_convertYamlMap(yamlData['display_config'] as Map));
      
      _loaded = true;
    } catch (e) {
      print('Error loading display config: $e');
      // Fallback to default values if loading fails
      _settings = DisplaySettings(
        windowWidth: 800.0,
        windowHeight: 600.0,
        arenaWidth: 800.0,
        arenaHeight: 600.0,
        safeAreaMargin: 50.0,
        maintainAspectRatio: true,
        baseScaleWidth: 800.0,
        baseScaleHeight: 600.0,
      );
      _loaded = true;
    }
  }
  
  // Method to update arena dimensions at runtime (for dynamic sizing)
  void updateArenaDimensions(double width, double height) {
    if (_settings != null) {
      final oldSettings = _settings!;
      final newSettings = DisplaySettings(
        windowWidth: width,  // Update window width to match arena
        windowHeight: height, // Update window height to match arena
        arenaWidth: width,
        arenaHeight: height,
        safeAreaMargin: _settings!.safeAreaMargin,
        maintainAspectRatio: _settings!.maintainAspectRatio,
        baseScaleWidth: _settings!.baseScaleWidth,
        baseScaleHeight: _settings!.baseScaleHeight,
      );
      
      _settings = newSettings;
      
      // Notify all listeners of the change
      _notifyListeners(oldSettings, newSettings);
      
      print('Display config updated: ${width.toInt()}x${height.toInt()}, Scale: ${newSettings.scaleFactor.toStringAsFixed(2)}');
    }
  }
  
  /// Clear all listeners (useful for cleanup)
  void clearListeners() {
    _listeners.clear();
  }
} 