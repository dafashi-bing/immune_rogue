# Immune Rogue

A fast-paced top-down arena roguelite built with Flutter and Flame engine. Control immune cells fighting waves of pathogens in a biological battlefield. Survive, upgrade, and master the art of cellular warfare!

## 🎮 Game Overview

**Immune Rogue** is an evolution of the geometric arena brawler concept, transformed into a biological battlefield where players control immune cells (Macrophages, Plasma Cells, Helper T-cells, Neutrophils, Dendritic Cells) fighting against waves of pathogens (Influenza Virus, Pseudomonas Bacterium, E. coli Swarm, and more).

> **Note**: This game evolved from **Shape Rogue**, maintaining the core gameplay loop while transforming the theme from geometric shapes to biological immune system warfare. See `design_docs/Immune Rogue - Game Introduction.md` for the complete game introduction and mutation details.

## Game Features

### Core Gameplay
- **Hero Movement**: WASD or arrow keys for smooth 8-directional movement
- **Unique Abilities**: Each immune cell hero has a distinct ability (Space or E key, costs energy)
- **Ultimate Abilities**: Charge up powerful ultimates by dealing damage (Q key when charged)
- **Auto-Shooting**: Hero automatically targets and shoots at nearest enemy within range
- **Time-Based Waves**: Survive for 30 seconds per wave with increasing enemy spawn rates
- **Progressive Difficulty**: 5 waves in Normal Mode, infinite waves in Endless Mode

### Immune Cell Heroes
Choose from 6 unique immune cells, each with distinct abilities:
- **Circle (Macrophage)**: Fast movement, Engulf Surge dash ability
- **Triangle (Plasma Cell)**: Precision strikes with Antibody Lance
- **Square (Helper T-cell)**: Support role with Cytokine Burst stun
- **Pentagon (Neutrophil)**: Explosive NET Flare radial attacks
- **Hexagon (Dendritic Cell)**: Tactical Antigen Web area control
- **Heptagon (Natural Killer Cell)**: Cytotoxic Shock knockback abilities

### Pathogen Enemies
Face 8 distinct enemy types with unique behaviors:
- **Chaser (Influenza Virus)**: Fast melee pursuers
- **Shooter (Pseudomonas Bacterium)**: Ranged attackers that maintain distance
- **Shielded Chaser (Biofilm-Encased Bacterium)**: Armored enemies with regenerating shields
- **Swarmer (E. coli Swarm)**: Fast, agile enemies that spawn in groups
- **Bomber (Spore-Forming Bacterium)**: Explosive enemies that detonate on proximity
- **Sniper**: Long-range enemies with charging laser attacks
- **Splitter**: Enemies that multiply when destroyed
- **Mine Layer**: Tactical enemies that place explosive mines

### Upgrade Shop
Between waves, spend coins on 14 strategic upgrades:
- **Health & Survival**: Health Potion, Max Health Up, Vampiric Coating, Auto-Injector
- **Combat Enhancements**: Attack Speed Up, Spread Master, Bouncing Bullets, Critical Striker
- **Tactical Items**: Ability Mastery, Speed Boost, Extended Reach, Enlarged Caliber
- **Advanced Systems**: Drone Wingman, Coin Magnet

### Game Modes
- **Normal Mode**: Classic 5-wave survival experience
- **Endless Mode**: Infinite waves with exponential scaling every 5 waves
- **1HP Challenge**: One-hit kills with retry token drops for second chances

### Enhanced UI
- **Health Bar**: Visual bar with numerical display
- **Energy Bar**: Visual bar for ability energy (0-100)
- **Ability Cooldown**: Visual indicator for hero abilities
- **Ultimate Charge Meter**: Fills as you deal damage
- **Wave Timer**: Countdown showing remaining time in current wave
- **Coin Counter**: Track earnings for shop purchases
- **Biome Transitions**: Visual transitions between different body system backgrounds

## Controls

- **Movement**: WASD or Arrow Keys
- **Ability/Dash**: Space or E (costs energy, has cooldown)
- **Ultimate**: Q (when charged)
- **Pause**: ESC
- **Menu Navigation**: Click buttons to start game, purchase items, etc.

## Game Progression

### Wave System
Each wave lasts 30 seconds with enemies spawning at increasing rates:

1. **Wave 1**: Chasers only - Learn basic movement and combat
2. **Wave 2**: Shooters only - Practice dodging projectiles  
3. **Wave 3**: Mixed chasers and shooters
4. **Wave 4**: Heavy assault with shielded chasers
5. **Wave 5**: All enemy types with maximum intensity

### Strategy Tips
- Use abilities strategically to escape or deal damage
- Prioritize ranged enemies (Shooters, Snipers) as they can attack from distance
- Manage energy carefully - abilities consume energy
- Invest in attack speed upgrades for faster enemy clearing
- Health upgrades provide both immediate healing and permanent benefits
- Discover item synergies (e.g., Drone Wingman + Attack Speed)
- Different heroes excel in different situations - experiment!

## Technical Details

- **Engine**: Flutter 3.24.3 + Flame 1.18.0
- **Platform**: Windows (with potential for cross-platform deployment)
- **Resolution**: 1600x1200 game area (doubled from original for better visibility)
- **Performance**: 60 FPS target with optimized collision detection

## Installation & Running

1. Ensure Flutter SDK is installed and configured
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Launch with `flutter run` for development or `flutter build windows` for release

## Development Notes

This game evolved from **Shape Rogue**, a geometric arena brawler, into **Immune Rogue** through a thematic mutation that transformed:
- Geometric shapes → Immune cells
- Abstract enemies → Biological pathogens
- Mathematical arenas → Biological biomes
- Shape abilities → Cellular functions

The codebase emphasizes:
- Clean component architecture using Flame's ECS system
- Responsive UI scaling for different screen sizes
- Modular enemy AI systems for easy expansion
- Comprehensive game state management
- Performance-optimized collision detection and rendering
- Config-driven game design (YAML-based hero, enemy, wave, and item configurations)

## Design Documents

Comprehensive design documentation is available in the `design_docs/` directory:
- **Immune Rogue - Game Introduction.md**: Complete game introduction with mutation details
- **Shape Rogue v3 - Game Introduction.md**: Original game design (for reference)
- Various technical and design specifications

## Evolution History

This project represents the evolution from abstract geometric combat to biological warfare:
- **Shape Rogue v1-v3**: Original geometric arena brawler concept
- **Immune Rogue**: Thematic mutation maintaining core gameplay while transforming narrative and visual identity

## Web Build & Deploy

- **Enable web (once):**
```bash
flutter config --enable-web
```

- **Build for web (release):**
```bash
flutter build web --release
```

- **Deploying under a subpath (e.g., GitHub Pages):**
```bash
flutter build web --release --base-href=/your-subpath/
```

- **Output:** built files are in `build/web/`. Deploy that folder to any static host (GitHub Pages, Netlify, Vercel, S3, etc.).