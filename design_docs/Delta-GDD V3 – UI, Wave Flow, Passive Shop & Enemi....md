# Delta-GDD V3 – UI, Wave Flow, Passive Shop & Enemies Expansion

## 1. Overview  
This update combines cross-platform UI improvements, smoother late-wave pacing, richer drop and shop systems, and five new enemy types with clear infinite-mode spawn thresholds. Passive shop items and consumables let players craft diverse builds without active ability clutter.

**Briefs covered**  
- Adaptive UI Scaling  
- Wave 4–5 Curve Adjustment  
- Streamlined Control Scheme  
- Shop UI Clarity Upgrade  
- Wave Cues & New Ability

## 2. New Features  
- **Responsive Layout & Scaling**  
  – HUD and menus use percentage-based anchors to auto-scale on any resolution.  
  – Hero sprites and hitboxes adjust proportionally.

- **Click-to-Show Tooltips & Help Overlay**  
  – Tap/click any “?” or shop icon for a detail card.  
  – Press “H” in-game to view controls overlay.

- **Enhanced Wave Flow**  
  – Enlarged, centered “WAVE X – SURVIVE!” panel.  
  – Full-screen start/end banners with distinct chimes.  
  – Last 10 s inter-wave timer pulses red and grows.

- **Consumable Drops** (20% base chance; auto-collect; 30 s despawn)  
  1. **Projectile Clear** (10% from W1+) – removes all enemy projectiles  
  2. **Screen Clear** (5% from W3+) – destroys all basic enemies & projectiles  
  3. **Shield Bubble** (8% from W2+) – grants 1-hit absorb shield for 5 s  
  4. **Time Slow** (7% from W4+) – slows enemies by 50% for 5 s  
  5. **Speed Boost** (12% from W1+) – +20% player speed for 10 s

- **Expanded Passive Shop Items**  
  1. **Spread Master** (100 C)  
     – +1 projectile per shot, stack up to +9 (max 10 shots)  
  2. **Bouncing Bullets** (150 C)  
     – +1 projectile bounce per shot, stackable to +3  
  3. **Drone Wingman** (200 C)  
     – Summons one auto-firing drone (0.8 shots/sec), stackable to 3 drones  
  4. **Enlarged Caliber** (100 C)  
     – +10% projectile diameter per stack, stackable to +100%  
  5. **Clone Projection** (300 C)  
     – Spend 50% current HP to spawn a clone that mimics player  
  6. **Vampiric Coating** (250 C)  
     – +5% life steal per stack, max +20%  
  7. **Armor Plating** (150 C)  
     – +5 shield HP per stack, max +100; shields fully regens between waves  
  8. **Coin Magnet** (120 C)  
     – +20% coin earn, max +100%  
  9. **Auto-Injector** (380 C)  
     – +2 HP per kill
  10. **Critical Striker** (220 C)  
      – +2% crit chance per stack, max +10%  

## 3. Modified Features  
- **Wave 5 Curve Adjustment**  
  – Spawn Interval: 1.2 -> 1.5

- **Shop UI**  
  – “Roll” → “Reroll” + coin icon + “Coins” label  
  – Click-to-open detail cards  
  – Disabled purchases greyed-out

- **Controls**  
  – Only “K” triggers abilities; “J/L” removed  
  – Escape closes popups (shop, tooltips, wave panel, help) or backs out

## 4. Removed  
- Hover-based tooltips  
- Deprecated hotkeys “J” and “L”

## 5. Balance Table Diff

### Feature Changes

| Feature                      | Before          | After                      |
| ---------------------------- | --------------- | -------------------------- |
| Wave 5 spawn rate            | 1.0 enemies/sec | 0.9 enemies/sec            |
| Wave 5 health multiplier     | 1.3×            | 1.25×                      |
| Projectile Clear drop chance | 0%              | 10%                        |
| Screen Clear drop chance     | 0%              | 5%                         |
| Shield Bubble drop chance    | 0%              | 8%                         |
| Time Slow drop chance        | 0%              | 7%                         |
| Speed Boost drop chance      | 0%              | 12%                        |
| Max shots per fire           | 1               | 10 via Spread Master       |
| Max bounces per shot         | 0               | 3 via Bouncing Bullets     |
| Max drones                   | 0               | 3 via Drone Wingman        |
| Projectile size bonus        | 0               | +100% via Enlarged Caliber |
| Clone availability           | 0               | 1 active clone             |
| Life steal                   | 0               | 20% via Vampiric Coating   |
| Shield HP                    | 0               | 25 via Armor Plating       |
| Coin radius                  | 0               | 100% via Coin Magnet       |
| HP per kill                  | 0               | 10 via Auto-Injector       |
| Crit chance                  | 0               | 10% via Critical Striker   |
| Fire rate                    | 0               | +25% via Rapid Fire        |

---

## 6. Art & Audio Requests

### 6.1 Art Assets

* `ui/anchor_guides.png`
* `ui/wave_panel_large.png`
* `ui/coin_icon.png`
* `ui/shop_detail_card_bg.png`
* `items/icon_projectile_clear.png`
* `items/icon_screen_clear.png`
* `items/icon_shield_bubble.png`
* `items/icon_time_slow.png`
* `items/icon_speed_boost.png`
* `items/icon_spread_master.png`
* `items/icon_bouncing_bullets.png`
* `items/icon_drone_wingman.png`
* `items/icon_enlarged_caliber.png`
* `items/icon_clone_projection.png`
* `items/icon_vampiric_coating.png`
* `items/icon_armor_plating.png`
* `items/icon_coin_magnet.png`
* `items/icon_auto_injector.png`
* `items/icon_critical_striker.png`
* `items/icon_rapid_fire.png`
* `enemies/swarmer_sprite.png`
* `enemies/bomber_sprite.png`
* `enemies/sniper_sprite.png`
* `enemies/splitter_sprite.png`
* `enemies/mine_layer_sprite_white.png` *(high-contrast tint)*

### 6.2 Sound FX

* `sfx_wave_start_chime.mp3`
* `sfx_drone_deploy.mp3`
* `sfx_bomber_explode.mp3`
* `sfx_sniper_snipe.mp3`
* `sfx_splitter_split.mp3`
* `sfx_mine_deploy.mp3`
* `sfx_mine_explode.mp3`

---

## 7. Infinite Mode Enemy Spawn Waves

* Wave 6+: Swarmer
* Wave 8+: Bomber
* Wave 10+: Sniper
* Wave 12+: Splitter
* Wave 14+: Mine Layer
