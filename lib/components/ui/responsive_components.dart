import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../config/display_config.dart';
import 'responsive_layout.dart';

/// A responsive rectangle component that automatically scales and positions
class ResponsiveRectangleComponent extends RectangleComponent with ResponsiveMixin {
  final Vector2 baseSize;
  final AnchorType? anchorType;
  final Vector2? anchorOffset;
  final double? xPercent;
  final double? yPercent;
  final ResponsiveScaleMode scaleMode;

  ResponsiveRectangleComponent({
    required this.baseSize,
    Vector2? basePosition,
    this.anchorType,
    this.anchorOffset,
    this.xPercent,
    this.yPercent,
    this.scaleMode = ResponsiveScaleMode.proportional,
    Paint? paint,
    Anchor anchor = Anchor.topLeft,
  }) : super(
          size: baseSize,
          position: basePosition ?? Vector2.zero(),
          paint: paint,
          anchor: anchor,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    initializeResponsive(
      baseSize: baseSize,
      anchorType: anchorType,
      anchorOffset: anchorOffset,
      xPercent: xPercent,
      yPercent: yPercent,
      scaleMode: scaleMode,
    );
  }

  @override
  void onRemove() {
    cleanupResponsive();
    super.onRemove();
  }
}

/// A responsive text component that automatically scales font size and position
class ResponsiveTextComponent extends TextComponent with ResponsiveMixin {
  final double baseFontSize;
  final AnchorType? anchorType;
  final Vector2? anchorOffset;
  final double? xPercent;
  final double? yPercent;
  final ResponsiveScaleMode scaleMode;

  ResponsiveTextComponent({
    required String text,
    required this.baseFontSize,
    Vector2? basePosition,
    this.anchorType,
    this.anchorOffset,
    this.xPercent,
    this.yPercent,
    this.scaleMode = ResponsiveScaleMode.fontScale,
    TextStyle? textStyle,
    Anchor anchor = Anchor.topLeft,
  }) : super(
          text: text,
          position: basePosition ?? Vector2.zero(),
          anchor: anchor,
          textRenderer: TextPaint(
            style: (textStyle ?? const TextStyle()).copyWith(
              fontSize: baseFontSize,
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    initializeResponsive(
      anchorType: anchorType,
      anchorOffset: anchorOffset,
      xPercent: xPercent,
      yPercent: yPercent,
      scaleMode: scaleMode,
    );
    _updateFontSize();
    
    // Listen for display config changes to update font size
    DisplayConfig.instance.addListener(_onDisplayConfigChanged);
  }

  @override
  void onRemove() {
    DisplayConfig.instance.removeListener(_onDisplayConfigChanged);
    cleanupResponsive();
    super.onRemove();
  }

  void _onDisplayConfigChanged(DisplaySettings oldSettings, DisplaySettings newSettings) {
    _updateFontSize();
  }

  void _updateFontSize() {
    final responsiveFontSize = _calculateResponsiveFontSize();
    final currentStyle = (textRenderer as TextPaint).style;
    textRenderer = TextPaint(
      style: currentStyle.copyWith(fontSize: responsiveFontSize),
    );
  }

  double _calculateResponsiveFontSize() {
    final displayConfig = DisplayConfig.instance;
    
    switch (scaleMode) {
      case ResponsiveScaleMode.proportional:
      case ResponsiveScaleMode.fontScale:
        return baseFontSize * displayConfig.scaleFactor;
      case ResponsiveScaleMode.stretch:
        return baseFontSize * (screenSize.x / displayConfig.settings!.baseScaleWidth);
      case ResponsiveScaleMode.absolute:
        return baseFontSize;
      case ResponsiveScaleMode.percentage:
        return screenSize.x * (baseFontSize / 100.0);
    }
  }
}

/// A responsive sprite component that automatically scales and positions
class ResponsiveSpriteComponent extends SpriteComponent with ResponsiveMixin {
  final Vector2 baseSize;
  final AnchorType? anchorType;
  final Vector2? anchorOffset;
  final double? xPercent;
  final double? yPercent;
  final ResponsiveScaleMode scaleMode;

  ResponsiveSpriteComponent({
    required Sprite sprite,
    required this.baseSize,
    Vector2? basePosition,
    this.anchorType,
    this.anchorOffset,
    this.xPercent,
    this.yPercent,
    this.scaleMode = ResponsiveScaleMode.proportional,
    Anchor anchor = Anchor.topLeft,
  }) : super(
          sprite: sprite,
          size: baseSize,
          position: basePosition ?? Vector2.zero(),
          anchor: anchor,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    initializeResponsive(
      baseSize: baseSize,
      anchorType: anchorType,
      anchorOffset: anchorOffset,
      xPercent: xPercent,
      yPercent: yPercent,
      scaleMode: scaleMode,
    );
  }

  @override
  void onRemove() {
    cleanupResponsive();
    super.onRemove();
  }
}

/// A responsive container-like component for grouping other responsive components
class ResponsiveContainer extends PositionComponent with ResponsiveMixin {
  final Vector2 baseSize;
  final AnchorType? anchorType;
  final Vector2? anchorOffset;
  final double? xPercent;
  final double? yPercent;
  final ResponsiveScaleMode scaleMode;

  ResponsiveContainer({
    required this.baseSize,
    Vector2? basePosition,
    this.anchorType,
    this.anchorOffset,
    this.xPercent,
    this.yPercent,
    this.scaleMode = ResponsiveScaleMode.proportional,
    Anchor anchor = Anchor.topLeft,
    List<Component>? children,
  }) : super(
          size: baseSize,
          position: basePosition ?? Vector2.zero(),
          anchor: anchor,
          children: children,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    initializeResponsive(
      baseSize: baseSize,
      anchorType: anchorType,
      anchorOffset: anchorOffset,
      xPercent: xPercent,
      yPercent: yPercent,
      scaleMode: scaleMode,
    );
  }

  @override
  void onRemove() {
    cleanupResponsive();
    super.onRemove();
  }
}

/// Utility class for creating common responsive UI patterns
class ResponsiveUIBuilder {
  /// Create a responsive button with background and text
  static ResponsiveContainer createButton({
    required String text,
    required Vector2 baseSize,
    required VoidCallback onTap,
    AnchorType? anchorType,
    Vector2? anchorOffset,
    double? xPercent,
    double? yPercent,
    Color backgroundColor = const Color(0xFF4A9EFF),
    Color textColor = Colors.white,
    double baseFontSize = 16.0,
    double borderRadius = 8.0,
    ResponsiveScaleMode scaleMode = ResponsiveScaleMode.proportional,
  }) {
    final container = ResponsiveContainer(
      baseSize: baseSize,
      anchorType: anchorType,
      anchorOffset: anchorOffset,
      xPercent: xPercent,
      yPercent: yPercent,
      scaleMode: scaleMode,
      anchor: Anchor.center,
    );

    // Background
    final background = ResponsiveRectangleComponent(
      baseSize: baseSize,
      paint: Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill,
      anchor: Anchor.center,
      scaleMode: scaleMode,
    );

    // Text
    final buttonText = ResponsiveTextComponent(
      text: text,
      baseFontSize: baseFontSize,
      textStyle: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      anchor: Anchor.center,
      scaleMode: scaleMode,
    );

    container.add(background);
    container.add(buttonText);

    return container;
  }

  /// Create a responsive panel with background and border
  static ResponsiveContainer createPanel({
    required Vector2 baseSize,
    AnchorType? anchorType,
    Vector2? anchorOffset,
    double? xPercent,
    double? yPercent,
    Color backgroundColor = const Color(0xFF2D2D4A),
    Color borderColor = const Color(0xFF4A9EFF),
    double borderWidth = 2.0,
    ResponsiveScaleMode scaleMode = ResponsiveScaleMode.proportional,
    List<Component>? children,
  }) {
    final container = ResponsiveContainer(
      baseSize: baseSize,
      anchorType: anchorType,
      anchorOffset: anchorOffset,
      xPercent: xPercent,
      yPercent: yPercent,
      scaleMode: scaleMode,
      children: children,
    );

    // Background
    final background = ResponsiveRectangleComponent(
      baseSize: baseSize,
      paint: Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill,
      scaleMode: scaleMode,
    );

    // Border
    final border = ResponsiveRectangleComponent(
      baseSize: baseSize,
      paint: Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
      scaleMode: scaleMode,
    );

    container.add(background);
    container.add(border);

    return container;
  }
}
