# Delta-GDD – Enhanced Experience Update

## 1. Overview
This update deepens strategic choice and replayability by introducing two distinct challenge modes, a resilient new hero and armored foe, flexible range-boost upgrades, and streamlined UI navigation. Random loot drops during combat enhance risk/reward, while paged hero selection improves usability. Enemy scaling in Endless Mode is exponential for mounting tension. A one-time **Retry Token** grants an extra life with full-health revival.  
**Brief covered**  
- Expand characters & items  
- Introduce more game modes  
- Refine hero selection UI  

## 2. New Features
- **Endless Mode**  
  - Enemy count & HP multiply by 1.20 every 5 waves (exponential scaling).  
- **1HP Challenge Mode + Retry Token**  
  - Player dies in one hit but each enemy kill has a 5% chance to drop a **Retry Token** (max one held at a time).  
  - On death, if holding a Retry Token: consume it, fully restore health, and continue.  
- **New Hero: Heptagon**  
  - **Appearance**: Neon-glowing seven-sided polygon avatar.  
  - **Stats**:  
    - Health: 100 HP  
    - Basic Attack: 15 damage/projectile, 0.8 s cooldown  
    - Ability “Resonance Knockback”:  
      - Effect: 50 damage + 30-unit radial push  
      - Cooldown: 10 s  
- **New Enemy: Shielded Chaser**  
  - **Appearance**: Fast orb with a solid blue hexagonal energy shield overlay.  
  - **Stats**:  
    - Base Health: 60 HP  
    - Shield Health: 40 HP (breaks after two standard hits)  
    - Speed: 350 units/s  
    - Contact Damage: 10  
- **Range Upgrade “Extended Reach”**  
  - Shop item grants +50 units to all hero projectile/ability ranges.  
- **Item Pickups (random drops on kill, 20% chance)**  
  - **Health Shard**: Restores 20 HP instantly.  
  - **Weapon Overclock**: +25% fire-rate for 10 s.  

## 3. Modified Features
- **Hero Selection UI**  
  - Paged gallery showing 5 heroes per page; navigate with left/right arrow buttons.  

## 4. Removed
- None  

## 5. Balance Table Diff (if any)
```csv
feature,before,after
-- balancing deferred to dedicated session --,,
```

## 6. Art & Audio Requests (if any)
### 6.1 Art Assets
- icon_range_upgrade.png
- icon_retry_token.png

### 6.2 Sound FX
- heptagon_resonance.wav
- chaser_shield_break.wav
- retry_token_collect.wav 
