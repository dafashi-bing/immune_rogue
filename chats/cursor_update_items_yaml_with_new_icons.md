# Update @items.yaml with new icons
_Exported on 9/26/2025 at 22:13:27 PDT from Cursor (1.6.45)_

---

**User**

I've updated all icons for items in /assets/images/. Please update the @items.yaml to the new updated image. The names should be pretty straight forward, if you are not sure about any, just ask me

---

**Cursor**

I'll help you update the item icons in the `items.yaml` file to match the new images. Let me first check what image files are available in the `/assets/images/` directory to see the new icon names.

Perfect! I can see all the new icon files. Now I'll update the `items.yaml` file to use the correct icon names. Looking at the current file and the available images, I can see the mappings are quite straightforward. Let me update all the icon references:

```yaml
items:
  - id: health_potion
    name: Health Potion
    cost: 30
    description: Restore 50 HP
    type: health
    icon: health_potion_transparent.png
    effect:
      type: heal
      value: 50

  - id: ability_mastery
    name: Ability Mastery
    cost: 60
    description: -20% Ability Cooldown
    type: ability
    icon: ability_mastery_transparent.png
    effect:
      type: dash_cooldown_multiplier
      value: 0.8

  - id: max_health_up
    name: Max Health Up
    cost: 50
    description: +25 Max Health
    type: health
    icon: max_health_up_transparent.png
    effect:
      type: max_health_increase
      value: 25

  - id: attack_speed_up
    name: Attack Speed Up
    cost: 60
    description: +25% Attack Speed
    type: attack
    icon: attack_speed_up_transparent.png
    effect:
      type: attack_speed_multiplier
      value: 0.25

  - id: speed_boost
    name: Speed Boost
    cost: 40
    description: +25% Movement Speed
    type: other
    icon: speed_boost_transparent.png
    effect:
      type: speed_multiplier
      value: 0.25

  - id: extended_reach
    name: Extended Reach
    cost: 150
    description: +50% Range for all attacks and abilities
    type: ability
    icon: extended_reach_transparent.png
    effect:
      type: range_multiplier
      value: 0.5

  - id: spread_master
    name: Spread Master
    cost: 70
    description: +1 projectile per shot, stack up to +9 (max 10 shots)
    type: attack
    icon: spread_master_transparent.png
    effect:
      type: projectile_count
      value: 1
      max_stacks: 9

  - id: bouncing_bullets
    name: Bouncing Bullets
    cost: 80
    description: +1 projectile bounce per shot, stackable to +3
    type: attack
    icon: bouncing_bullet_transparent.png
    effect:
      type: projectile_bounces
      value: 1
      max_stacks: 3

  - id: drone_wingman
    name: Drone Wingman
    cost: 90
    description: Summons one auto-firing drone (0.8 shots/sec), infinite stacks
    type: other
    icon: drone_wingman_transparent.png
    effect:
      type: drone_count
      value: 1
      max_stacks: 999
    companion_config:
      radius: 8.0
      fire_rate: 0.8  # shots per second
      orbit_radius: 60.0
      orbit_speed: 2.0  # radians per second
      target_scan_interval: 0.5  # seconds
      attack_range: 800.0
      projectile_speed: 600.0
      projectile_damage: 30.0
      color: 0xFF2196F3  # Blue
      projectile_size_scale: 0.7

  - id: enlarged_caliber
    name: Enlarged Caliber
    cost: 60
    description: +25% projectile & character size, -25% speed per stack (max 5 stacks)
    type: other
    icon: enlarged_caliber_transparent.png
    effect:
      type: enlarged_caliber
      value: 0.25
      max_stacks: 5

  - id: vampiric_coating
    name: Vampiric Coating
    cost: 80
    description: Recover 1 HP per kill
    type: health
    icon: vampiric_coating_transparent.png
    effect:
      type: heal_per_kill
      value: 1.0
      max_stacks: 1000

  # ARMOR ITEMS TEMPORARILY DISABLED
  # - id: armor_plating
  #   name: Armor Plating
  #   cost: 70
  #   description: +5 shield HP per stack, max +100; shields fully regens between waves
  #   type: passive
  #   icon: max_health_up_transparent.png
  #   effect:
  #     type: shield_hp
  #     value: 5
  #     max_stacks: 20

  - id: coin_magnet
    name: Coin Magnet
    cost: 50
    description: +20% coin earn, max +100%
    type: other
    icon: coin_magnet_transparent.png
    effect:
      type: coin_multiplier
      value: 0.2
      max_stacks: 5

  - id: auto_injector
    name: Auto-Injector
    cost: 100
    description: +2 Max HP per 10 kills (max +50 HP per stack)
    type: health
    icon: auto_injector_transparent.png
    effect:
      type: auto_injector
      value: 2
      max_stacks: 999

  - id: critical_striker
    name: Critical Striker
    cost: 75
    description: +2% crit chance per stack, max +10%
    type: attack
    icon: critical_striker_transparent.png
    effect:
      type: crit_chance
      value: 0.02
      max_stacks: 5

```

Perfect! I've updated all the item icons in the `items.yaml` file to match the new image files. Here's a summary of the changes made:

1. **attack_speed_up**: `attack_speed_transparent.png` → `attack_speed_up_transparent.png`
2. **spread_master**: `attack_speed_transparent.png` → `spread_master_transparent.png`
3. **bouncing_bullets**: `attack_speed_transparent.png` → `bouncing_bullet_transparent.png`
4. **drone_wingman**: `ability_mastery_transparent.png` → `drone_wingman_transparent.png`
5. **enlarged_caliber**: `extended_reach_transparent.png` → `enlarged_caliber_transparent.png`
6. **vampiric_coating**: `health_potion_transparent.png` → `vampiric_coating_transparent.png`
7. **coin_magnet**: `speed_boost_transparent.png` → `coin_magnet_transparent.png`
8. **auto_injector**: `health_potion_transparent.png` → `auto_injector_transparent.png`
9. **critical_striker**: `attack_speed_transparent.png` → `critical_striker_transparent.png`

The following items already had the correct icon names and didn't need changes:
- **health_potion**: `health_potion_transparent.png` ✓
- **ability_mastery**: `ability_mastery_transparent.png` ✓
- **max_health_up**: `max_health_up_transparent.png` ✓
- **speed_boost**: `speed_boost_transparent.png` ✓
- **extended_reach**: `extended_reach_transparent.png` ✓

All icon references now match the actual image files in your `/assets/images/` directory. The mappings were straightforward as you mentioned!

