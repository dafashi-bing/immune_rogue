# Display Configuration System

## Overview

The window size and battlefield size are now configurable through a JSON configuration file instead of being hardcoded. This makes it easy to adjust the game's display settings without modifying code.

## Configuration Files

### `assets/config/display.json`

This file contains all display-related settings:

```json
{
  "display_config": {
    "window_width": 1200,
    "window_height": 900,
    "arena_width": 1200,
    "arena_height": 900,
    "safe_area_margin": 50,
    "maintain_aspect_ratio": true,
    "base_scale_width": 800,
    "base_scale_height": 600
  }
}
```

### Settings Explanation

- **window_width/window_height**: The target size of the Flutter app window in pixels
- **arena_width/arena_height**: The size of the game battlefield/arena in pixels  
- **safe_area_margin**: Margin around arena edges to keep enemies from getting stuck
- **maintain_aspect_ratio**: Whether to maintain proportional scaling
- **base_scale_width/base_scale_height**: **IMPORTANT** - Keep these at 800x600 (original design resolution)

## ⚠️ Important: Base Scale Dimensions

The `base_scale_width` and `base_scale_height` should **always remain 800x600** regardless of your target window size. These represent the original design resolution that all game elements were designed for.

### Scaling Examples:

- **Original**: 800x600 → Scale Factor = 1.0 (no scaling)
- **50% Larger**: 1200x900 → Scale Factor = 1.5 (everything 50% bigger)
- **Double Size**: 1600x1200 → Scale Factor = 2.0 (everything twice as big)

The scale factor is calculated as: `min(new_width/800, new_height/600)`

## How to Change Window Size

1. **Edit `assets/config/display.json`**:
   ```json
   {
     "display_config": {
       "window_width": 1200,    ← Your desired width
       "window_height": 900,    ← Your desired height  
       "arena_width": 1200,     ← Should match window_width
       "arena_height": 900,     ← Should match window_height
       "base_scale_width": 800, ← KEEP as 800 (original design)
       "base_scale_height": 600 ← KEEP as 600 (original design)
     }
   }
   ```

2. **Restart the game** - The new dimensions will be loaded and applied

## How It Works

1. **Adaptive Window**: The game automatically adapts to available screen space while maintaining the configured aspect ratio
2. **Proportional Scaling**: All game elements (characters, enemies, projectiles, UI) scale proportionally based on the scale factor
3. **Arena Filling**: The game arena fills the entire available window space
4. **Responsive Design**: The system works across different screen sizes and orientations

## Troubleshooting

If you experience scaling issues:

1. **Check base_scale dimensions**: Ensure they're set to 800x600
2. **Verify aspect ratio**: Make sure your window dimensions have a reasonable aspect ratio
3. **Restart the game**: Changes require a game restart to take effect

## Technical Details

- **Scale Factor Calculation**: `min(arena_width/800, arena_height/600)`
- **Element Sizing**: All elements multiply their base size by the scale factor
- **UI Positioning**: UI elements use scaled positions to maintain proper layout
- **Collision Detection**: Collision radii are also scaled to match visual sizes

## Code Usage

### In Dart Code

```dart
import '../config/display_config.dart';

// Access display settings
double width = DisplayConfig.instance.arenaWidth;
double height = DisplayConfig.instance.arenaHeight;
double scaleFactor = DisplayConfig.instance.scaleFactor;
```

### Loading the Config

The config is automatically loaded when the app starts. The main.dart file uses a FutureBuilder to ensure the config is loaded before the game starts.

## Presets

The JSON file includes several preset configurations:

- **small**: 640x480 for compact displays
- **default**: 800x600 standard size
- **large**: 1200x900 for bigger displays  
- **ultrawide**: 1280x720 widescreen format

To use a preset, copy its values to the main `display_config` section.

## Scaling System

The game uses a proportional scaling system:
- All UI elements, movement speeds, and collision detection scale automatically
- Scaling factor = (current_arena_width + current_arena_height) / (base_width + base_height)
- This ensures consistent gameplay regardless of screen size

## Migration Status

✅ **Completed**:
- Display config system created
- Main window size now configurable
- Arena dimensions configurable
- HUD components updated
- Shop panel updated
- Stats overlay updated
- Hero component updated

⚠️ **In Progress**:
- Enemy components still need updates (static access errors)
- Projectile components need updates
- Item pickup components need updates

## Next Steps

1. Update remaining enemy components to use `DisplayConfig.instance` instead of `CircleRougeGame.static_variables`
2. Update projectile components
3. Update item pickup components
4. Test with different screen sizes to ensure proper scaling 