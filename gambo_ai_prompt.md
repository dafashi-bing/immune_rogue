# Immune Rogue - Game Recreation Prompt for Gambo.ai

Create a top-down arena roguelite survival game called **"Immune Rogue"** where players control immune cells fighting waves of pathogens in a biological battlefield.

## Core Gameplay Loop

**Wave-Based Survival System:**
- Each wave lasts 30 seconds with a countdown timer
- Survive 5 waves in Normal Mode (or infinite waves in Endless Mode)
- Enemies spawn at increasing rates (every 2.5 seconds initially, down to 0.5 seconds)
- Between waves, players enter a shop to purchase upgrades with coins earned from kills
- Background changes between waves with biome transition animations

## Player Character (Hero System)

**Hero Selection:**
- Multiple playable heroes (immune cells) with unique abilities:
  - **Circle (Macrophage)**: Fast movement (320 speed), 100 HP. Ability: "Engulf Surge" - dash forward 200 units dealing 40 damage to enemies passed through (6s cooldown). Ultimate: "Engulf Rampage" - 3 seconds of continuous dashing that instantly kills enemies on contact
  - **Triangle (Plasma Cell)**: 290 speed, 90 HP. Ability: "Spike Shot" - piercing projectile dealing 999 damage across entire screen (5s cooldown)
  - **Square (Helper T-cell)**: 260 speed, 120 HP. Ability: "Shield Bash" - 150 unit radius stun dealing 25 damage (7s cooldown)
  - **Pentagon (Neutrophil)**: 280 speed, 110 HP. Ability: "Star Flare" - 5-projectile radial burst dealing 30 damage each (8s cooldown)
  - **Hexagon (Dendritic Cell)**: 250 speed, 100 HP. Ability: "Hex Field" - area damage field (9s cooldown)

**Core Mechanics:**
- **Movement**: 8-directional movement using WASD or arrow keys
- **Auto-Shooting**: Hero automatically targets and shoots at nearest enemy within range
- **Dash/Ability System**: Each hero has a unique ability on cooldown (Space or E key)
- **Ultimate System**: Ultimate abilities charge up by dealing damage/killing enemies. Press Q to activate when charged
- **Energy System**: Dash abilities consume energy (25 energy per dash, 2-second cooldown). Energy regenerates over time

## Enemy Types

**8 Enemy Varieties with Unique Behaviors:**

1. **Chaser (Influenza Virus)**: Fast melee enemy (60 speed) that charges directly at player. 30 HP, 5 contact damage, 10 coins reward
2. **Shooter (Pseudomonas Bacterium)**: Ranged enemy (30 speed) that maintains distance and fires projectiles. 25 HP, 15 projectile damage, 300 attack range, 2s cooldown, 20 coins reward, 10% item drop chance
3. **Shielded Chaser (Biofilm-Encased Bacterium)**: Armored melee enemy (50 speed) with 20 HP shield that regenerates after 5 seconds. 45 HP total, 10 contact damage, 30 coins reward
4. **Swarmer (E. coli Swarm)**: Fast, agile enemies (120 speed) that spawn in groups of 9. 25 HP each, 10 contact damage, 1 coin each. Swarm together with 80-unit radius, 30-unit separation
5. **Bomber (Spore-Forming Bacterium)**: Slow explosive enemy (40 speed) that detonates when close. 100 HP, 7.5 contact damage, 100-unit explosion radius dealing 30 damage + 6 projectiles, 2s fuse time, 5 coins reward
6. **Sniper**: Long-range enemy (30 speed) with charging laser attacks. 125 HP, 400 attack range, 2s charge time, deals 150% of player's max health, 600 projectile speed, 5 coins reward, 10% item drop chance
7. **Splitter**: Enemy that splits into smaller versions on death. 40 HP, moderate speed
8. **Mine Layer**: Tactical enemy that places explosive mines while maintaining 150-250 unit distance. 1s mine arm time, 100-unit explosion radius, 50% player damage, 3s mine frequency, 10% item drop chance

**Enemy Scaling:**
- Enemy health increases 40% per wave
- Enemy damage increases 20% per wave
- Spawn rates increase throughout each wave (from 2.5s to 0.5s intervals)
- Spawn counts increase per wave (2 → 3 → 4 → 5 → 6 enemies per spawn)

## Wave Progression

**Wave Structure:**
- Wave 1: Chasers only (learning phase)
- Wave 2: Shooters only (ranged combat)
- Wave 3: Mixed chasers and shooters
- Wave 4: Heavy assault with shielded chasers
- Wave 5: All enemy types with maximum intensity

**Endless Mode:**
- Waves continue infinitely after wave 5
- Every 5 waves, difficulty scales by 20%
- Spawn intervals reduce by 10% per wave (minimum 0.2s)
- New enemy types unlock at specific wave thresholds

## Shop System

**Between-Wave Shopping:**
- Shop opens automatically after each wave completion
- Players spend coins earned from enemy kills
- Shop shows 6 random items from the item pool
- Reroll system: Pay increasing cost (10 + wave number) to refresh shop items
- Prices scale with wave progression (20% increase per wave) with ±5% random variance

**Item Categories:**

**Health & Survival:**
- Health Potion (30 coins): Instant +50 HP
- Max Health Up (50 coins): Permanent +25 max HP (stackable)
- Vampiric Coating (80 coins): +1 HP per kill (stackable up to 1000)

**Combat Enhancements:**
- Attack Speed Up (60 coins): +25% attack speed (stackable)
- Spread Master (70 coins): +1 projectile per shot (max 10 shots, stackable to +9)
- Bouncing Bullets (80 coins): +1 projectile bounce (max 3 bounces, stackable)
- Critical Striker (75 coins): +2% crit chance (max 10%, stackable)

**Tactical & Utility:**
- Ability Mastery (60 coins): -20% ability cooldown (stackable)
- Speed Boost (40 coins): +25% movement speed (temporary, stackable)
- Extended Reach (150 coins): +50% range for all attacks/abilities (stackable)
- Drone Wingman (90 coins): Summons auto-firing drone orbiting player (0.8 shots/sec, infinite stacks)
- Coin Magnet (50 coins): +20% coin earnings (max +100%, stackable to 5)

## UI/HUD Elements

**Gameplay HUD:**
- Health bar with numerical display (current/max HP)
- Energy bar for dash ability (0-100)
- Wave timer countdown (30 seconds per wave)
- Wave number display
- Coin counter (golden coin icon + number)
- Ability cooldown indicator
- Ultimate charge meter (fills as player deals damage)

**Shop Interface:**
- Grid layout showing 6 items
- Each item shows: icon, name, description, cost
- "REROLL" button with cost display
- "CONTINUE" button to proceed to next wave

**Game Over Screen:**
- Shows death message based on enemy type that killed player
- Displays final wave reached, coins earned, kills
- "Restart" and "Main Menu" buttons

## Game Modes

1. **Normal Mode**: Classic 5-wave survival experience
2. **Endless Mode**: Infinite waves with exponential scaling every 5 waves
3. **1HP Challenge**: One-hit kills, but enemies drop Retry Tokens for second chances

## Visual Style

- **Art Style**: Pixel art with biological/cell theme
- **Color Palette**: Beige, aqua, pink, orange, mint, red + neutrals
- **Heroes**: 48×48px sprites with idle animations (gentle pulse/wobble)
- **Enemies**: 32×32px sprites (64×64px for larger enemies)
- **Backgrounds**: Biome-themed backgrounds that change between waves (skin, gut lumen, bloodstream, etc.)
- **Projectiles**: Distinct visual styles per hero/enemy type
- **Effects**: Particle effects for explosions, stuns, damage numbers

## Audio

- Battle BGM that plays during waves
- Wave clear sound effect
- Victory sound effect
- Game over/fail sound effect
- Enemy death sounds
- Ability activation sounds
- Shop purchase sounds
- Background music stops during shop phase

## Technical Requirements

- Top-down camera view
- Smooth 60 FPS gameplay
- Collision detection for projectiles, enemies, player
- Safe area system: enemies pushed away from screen edges (10% margin)
- Responsive UI scaling for different screen sizes
- Pause menu (ESC key)
- Start menu with game mode selection
- Hero selection screen

## Key Gameplay Features

- **Invincibility frames**: Brief invincibility after wave completion
- **Shield regeneration**: Shields regenerate between waves
- **Item drops**: Enemies have chance to drop consumable items (health shards, weapon overclocks, retry tokens)
- **Status effects**: Stun, slow effects on enemies
- **Companion system**: Drones orbit player and auto-fire at enemies
- **Passive effects**: Stackable passive bonuses from items
- **Biome transitions**: 2-second transition animation when background changes

## Controls

- **Movement**: WASD or Arrow Keys
- **Dash/Ability**: Space or E (consumes energy, has cooldown)
- **Ultimate**: Q (when charged)
- **Pause**: ESC
- **Shop Navigation**: Mouse clicks

## Victory Condition

- Complete all 5 waves in Normal Mode
- Survive as long as possible in Endless Mode
- Complete 5 waves with 1 HP in Challenge Mode

---

**Game Feel**: Fast-paced, action-packed arena combat with strategic upgrade decisions. Players must balance offense, defense, and mobility while managing resources (health, energy, coins) across increasingly difficult waves. The roguelite progression creates varied runs based on item combinations and hero selection.



