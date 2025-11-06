import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../config/display_config.dart';

/// Scale modes for responsive components
enum ResponsiveScaleMode {
  /// Scale proportionally maintaining aspect ratio
  proportional,
  /// Scale width and height independently
  stretch,
  /// Scale based on font size scaling
  fontScale,
  /// No scaling, use absolute values
  absolute,
  /// Scale based on percentage of screen size
  percentage,
}

/// Responsive layout utility for cross-platform UI scaling and positioning
class ResponsiveLayout {
  /// Get scaled width based on display configuration and context
  static double getScaledWidth(double baseWidth, BuildContext? context) {
    final displayConfig = DisplayConfig.instance;
    return baseWidth * displayConfig.scaleFactor;
  }

  /// Get scaled height based on display configuration and context
  static double getScaledHeight(double baseHeight, BuildContext? context) {
    final displayConfig = DisplayConfig.instance;
    return baseHeight * displayConfig.scaleFactor;
  }

  /// Get scaled padding based on display configuration and context
  static EdgeInsets getScaledPadding(EdgeInsets basePadding, BuildContext? context) {
    final displayConfig = DisplayConfig.instance;
    final scaleFactor = displayConfig.scaleFactor;
    
    return EdgeInsets.only(
      left: basePadding.left * scaleFactor,
      top: basePadding.top * scaleFactor,
      right: basePadding.right * scaleFactor,
      bottom: basePadding.bottom * scaleFactor,
    );
  }

  /// Get anchored position based on anchor type and offset
  static Vector2 getAnchoredPosition(AnchorType anchor, Vector2 offset, Vector2 screenSize) {
    switch (anchor) {
      case AnchorType.topLeft:
        return Vector2(offset.x, offset.y);
      case AnchorType.topCenter:
        return Vector2(screenSize.x / 2 + offset.x, offset.y);
      case AnchorType.topRight:
        return Vector2(screenSize.x - offset.x, offset.y);
      case AnchorType.centerLeft:
        return Vector2(offset.x, screenSize.y / 2 + offset.y);
      case AnchorType.center:
        return Vector2(screenSize.x / 2 + offset.x, screenSize.y / 2 + offset.y);
      case AnchorType.centerRight:
        return Vector2(screenSize.x - offset.x, screenSize.y / 2 + offset.y);
      case AnchorType.bottomLeft:
        return Vector2(offset.x, screenSize.y - offset.y);
      case AnchorType.bottomCenter:
        return Vector2(screenSize.x / 2 + offset.x, screenSize.y - offset.y);
      case AnchorType.bottomRight:
        return Vector2(screenSize.x - offset.x, screenSize.y - offset.y);
    }
  }

  /// Get percentage-based position within screen bounds
  static Vector2 getPercentagePosition(double xPercent, double yPercent, Vector2 screenSize) {
    return Vector2(
      screenSize.x * (xPercent / 100.0),
      screenSize.y * (yPercent / 100.0),
    );
  }

  /// Get scaled size based on screen dimensions
  static Vector2 getScaledSize(Vector2 baseSize, Vector2 screenSize) {
    final displayConfig = DisplayConfig.instance;
    final scaleFactor = displayConfig.scaleFactor;
    
    return Vector2(
      baseSize.x * scaleFactor,
      baseSize.y * scaleFactor,
    );
  }

  /// Get responsive font size based on screen size
  static double getResponsiveFontSize(double baseFontSize, Vector2 screenSize) {
    final displayConfig = DisplayConfig.instance;
    return baseFontSize * displayConfig.scaleFactor;
  }

  /// Get safe area margins adjusted for screen size
  static EdgeInsets getSafeAreaMargins(Vector2 screenSize) {
    final displayConfig = DisplayConfig.instance;
    final margin = displayConfig.safeAreaMargin * displayConfig.scaleFactor;
    
    return EdgeInsets.all(margin);
  }

  /// Check if screen is in landscape orientation
  static bool isLandscape(Vector2 screenSize) {
    return screenSize.x > screenSize.y;
  }

  /// Check if screen is in portrait orientation
  static bool isPortrait(Vector2 screenSize) {
    return screenSize.y > screenSize.x;
  }

  /// Get aspect ratio of screen
  static double getAspectRatio(Vector2 screenSize) {
    return screenSize.x / screenSize.y;
  }

  /// Calculate minimum scale factor to fit content within bounds
  static double getMinScaleToFit(Vector2 contentSize, Vector2 containerSize) {
    final scaleX = containerSize.x / contentSize.x;
    final scaleY = containerSize.y / contentSize.y;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  /// Calculate maximum scale factor while maintaining aspect ratio
  static double getMaxScaleToFill(Vector2 contentSize, Vector2 containerSize) {
    final scaleX = containerSize.x / contentSize.x;
    final scaleY = containerSize.y / contentSize.y;
    return scaleX > scaleY ? scaleX : scaleY;
  }
}

/// Anchor types for positioning UI elements
enum AnchorType {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Extension to add responsive capabilities to Vector2
extension ResponsiveVector2 on Vector2 {
  /// Scale this vector by display configuration
  Vector2 scaled() {
    final displayConfig = DisplayConfig.instance;
    return this * displayConfig.scaleFactor;
  }

  /// Convert this vector to percentage of screen size
  Vector2 toPercentage(Vector2 screenSize) {
    return Vector2(
      (x / screenSize.x) * 100.0,
      (y / screenSize.y) * 100.0,
    );
  }

  /// Convert this vector from percentage to actual screen coordinates
  Vector2 fromPercentage(Vector2 screenSize) {
    return Vector2(
      screenSize.x * (x / 100.0),
      screenSize.y * (y / 100.0),
    );
  }
}

/// Mixin for components that need responsive behavior with dynamic updates
mixin ResponsiveMixin on Component {
  // Configuration for responsive behavior
  Vector2? _baseSize;
  Vector2? _basePosition;
  AnchorType? _anchorType;
  Vector2? _anchorOffset;
  double? _xPercent;
  double? _yPercent;
  ResponsiveScaleMode _scaleMode = ResponsiveScaleMode.proportional;
  
  // Display config listener
  DisplayConfigChangeCallback? _displayConfigListener;
  
  /// Get the current screen size from the game
  Vector2 get screenSize {
    if (parent is HasGameRef) {
      final game = (parent as HasGameRef).gameRef;
      return game.size;
    }
    // Fallback to display config
    final displayConfig = DisplayConfig.instance;
    return Vector2(displayConfig.arenaWidth, displayConfig.arenaHeight);
  }

  /// Initialize responsive behavior - call this in onLoad()
  void initializeResponsive({
    Vector2? baseSize,
    Vector2? basePosition,
    AnchorType? anchorType,
    Vector2? anchorOffset,
    double? xPercent,
    double? yPercent,
    ResponsiveScaleMode scaleMode = ResponsiveScaleMode.proportional,
  }) {
    _baseSize = baseSize;
    _basePosition = basePosition;
    _anchorType = anchorType;
    _anchorOffset = anchorOffset;
    _xPercent = xPercent;
    _yPercent = yPercent;
    _scaleMode = scaleMode;
    
    // Set up listener for display config changes
    _displayConfigListener = (oldSettings, newSettings) {
      _updateResponsiveLayout();
    };
    DisplayConfig.instance.addListener(_displayConfigListener!);
    
    // Apply initial layout
    _updateResponsiveLayout();
  }
  
  /// Clean up responsive behavior - call this in onRemove()
  void cleanupResponsive() {
    if (_displayConfigListener != null) {
      DisplayConfig.instance.removeListener(_displayConfigListener!);
      _displayConfigListener = null;
    }
  }
  
  /// Update the responsive layout based on current configuration
  void _updateResponsiveLayout() {
    if (this is! PositionComponent) return;
    
    final positionComponent = this as PositionComponent;
    
    // Update size if base size is configured
    if (_baseSize != null) {
      positionComponent.size = _calculateResponsiveSize(_baseSize!);
    }
    
    // Update position based on configured method
    if (_anchorType != null && _anchorOffset != null) {
      positionComponent.position = ResponsiveLayout.getAnchoredPosition(
        _anchorType!, 
        _anchorOffset! * DisplayConfig.instance.scaleFactor, 
        screenSize
      );
    } else if (_xPercent != null && _yPercent != null) {
      positionComponent.position = ResponsiveLayout.getPercentagePosition(
        _xPercent!, 
        _yPercent!, 
        screenSize
      );
    } else if (_basePosition != null) {
      positionComponent.position = _calculateResponsivePosition(_basePosition!);
    }
  }
  
  /// Calculate responsive size based on scale mode
  Vector2 _calculateResponsiveSize(Vector2 baseSize) {
    final displayConfig = DisplayConfig.instance;
    
    switch (_scaleMode) {
      case ResponsiveScaleMode.proportional:
        return baseSize * displayConfig.scaleFactor;
      case ResponsiveScaleMode.stretch:
        return Vector2(
          baseSize.x * (screenSize.x / displayConfig.settings!.baseScaleWidth),
          baseSize.y * (screenSize.y / displayConfig.settings!.baseScaleHeight),
        );
      case ResponsiveScaleMode.fontScale:
        return baseSize * displayConfig.scaleFactor;
      case ResponsiveScaleMode.absolute:
        return baseSize;
      case ResponsiveScaleMode.percentage:
        return Vector2(
          screenSize.x * (baseSize.x / 100.0),
          screenSize.y * (baseSize.y / 100.0),
        );
    }
  }
  
  /// Calculate responsive position
  Vector2 _calculateResponsivePosition(Vector2 basePosition) {
    return basePosition * DisplayConfig.instance.scaleFactor;
  }

  /// Update position based on anchor and offset (legacy method)
  void updateAnchoredPosition(AnchorType anchor, Vector2 offset) {
    _anchorType = anchor;
    _anchorOffset = offset;
    _updateResponsiveLayout();
  }

  /// Update size based on scaling (legacy method)
  void updateScaledSize(Vector2 baseSize) {
    _baseSize = baseSize;
    _updateResponsiveLayout();
  }

  /// Update position based on percentage (legacy method)
  void updatePercentagePosition(double xPercent, double yPercent) {
    _xPercent = xPercent;
    _yPercent = yPercent;
    _updateResponsiveLayout();
  }
  
  /// Force update the responsive layout (useful for manual updates)
  void updateResponsiveLayout() {
    _updateResponsiveLayout();
  }
}
