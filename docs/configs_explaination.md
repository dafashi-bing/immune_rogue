# Configuration Files Guide

This document explains how to use and modify the configuration files in Shape Rogue.

## Core Configuration Files

### `display.json`
Controls window size and display settings.
- `window_width/height`: App window dimensions
- `arena_width/height`: Game battlefield size
- `safe_area_margin`: Margin around arena edges
- `maintain_aspect_ratio`: Whether to keep aspect ratio when resizing

### `game_modes.json`
Defines different game modes.
- `max_waves`: Number of waves (-1 for infinite)
- `scaling`: Difficulty multiplier per scaling interval
- `scaling_interval`: How often scaling applies
- `retry_tokens`: Whether enemies can drop retry tokens
- `player_health`: Starting player HP

### `heroes.json`
Character definitions and abilities.
- `move_speed`: Base movement speed
- `health`: Starting health
- `ability`: Special ability properties (cooldown, damage, range, etc.)

### `enemies.json`
Enemy stats and behaviors. **Now includes all enemy types including basic ones.**
- `health`: Base HP
- `speed`: Movement speed
- `damage`: Contact/attack damage
- `coins`: Gold reward when killed (**newly configurable**)
- Special properties per enemy type (explosion radius, split count, etc.)
- Basic enemies (chaser, shooter, shielded_chaser) now configured here instead of hardcoded

### `items.json`
Shop items and upgrades.
- `cost`: Base purchase price
- `type`: Item category (consumable, upgrade, passive, etc.)
- `effect`: What the item does (type and value)
- `max_stacks`: Maximum times item can be purchased

### `item_drops.json`
Random drops from enemies.
- `baseDropChance`: Base chance for any drop (0.1 = 10%)
- `weight`: How likely this drop is relative to others
- `effectType`: What effect the drop provides
- `duration`: How long temporary effects last

### `waves.json`
Wave progression and scaling settings.

#### Key Scaling Settings (Easily Configurable):
- `enemy_scaling.health_multiplier`: How much enemy HP increases per wave (0.5 = 50% per wave)
- `enemy_scaling.spawn_speed_multiplier`: How much faster enemies spawn per wave (0.15 = 15% faster per wave)
- `shop_config.price_scaling.wave_multiplier`: How much shop prices increase per wave (0.5 = 50% per wave)

#### Wave Definitions:
- `enemy_types`: Which enemies spawn
- `spawn_weights`: Relative spawn chances
- `spawn_interval`: Base time between spawns
- `spawn_count`: How many enemies per spawn

## Quick Configuration Tips

### Make Game Harder/Easier:
- **Enemy Health**: Increase `enemy_scaling.health_multiplier` in `waves.json`
- **Spawn Rate**: Increase `enemy_scaling.spawn_speed_multiplier` in `waves.json`
- **Shop Prices**: Adjust `shop_config.price_scaling.wave_multiplier` in `waves.json`

### Add New Enemy to Wave:
1. Add enemy stats to `enemies.json`
2. Add enemy to `enemy_types` array in desired wave in `waves.json`
3. Set spawn weight in `spawn_weights` for that wave
4. Add abbreviation to stats overlay in `lib/components/stats_overlay.dart`

### Modify Item Effects:
- Change `cost`, `effect.value`, or `max_stacks` in `items.json`
- For permanent changes, modify `type: "upgrade"` items
- For temporary effects, modify `type: "consumable"` items
- **Shop affordability now updates immediately after purchases**

### Adjust Enemy Rewards:
- Modify `coins` value for any enemy type in `enemies.json`
- All enemies now have configurable gold rewards
- Values are per-kill, not affected by scaling (unless implemented in code)

### Adjust Drop Rates:
- Change `baseDropChance` in `item_drops.json` for overall drop frequency
- Modify individual item `weight` values to make specific drops more/less common

## File Relationships

- `waves.json` references enemy types defined in `enemies.json`
- `enemies.json` now contains **all** enemy definitions including basic ones (chaser, shooter, shielded_chaser)
- `game_modes.json` affects how scaling from `waves.json` is applied
- `items.json` effects are processed by the game engine
- `item_drops.json` creates temporary versions of some `items.json` effects
- `heroes.json` defines the player characters available
- `display.json` affects how everything is rendered
- **Enemy gold rewards removed from `waves.json`, now configured per-enemy in `enemies.json`**

## Testing Changes

After modifying configs:
1. Save the files
2. Restart the game to load new settings
3. Test in Normal mode first, then other modes
4. Check that scaling feels appropriate across multiple waves

Remember: Higher multipliers = faster difficulty scaling!