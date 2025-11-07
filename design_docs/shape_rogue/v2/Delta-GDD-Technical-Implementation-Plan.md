# Technical Implementation Plan - Delta GDD Enhanced Experience Update

Based on the code map and GDD requirements, here's a comprehensive technical implementation plan for the Enhanced Experience Update:

## Technical Implementation Plan - Delta GDD

### 1. Core Architecture Extensions

#### 1.1 Game Mode System
**New Files:**
- `lib/config/game_mode_config.dart` - Game mode definitions and settings
- `lib/overlays/game_mode_selection_overlay.dart` - Mode selection UI

**Modifications:**
- `lib/game/circle_rouge_game.dart`:
  - Add `GameMode gameMode` property
  - Add `retryTokenCount` property  
  - Modify wave progression logic for Endless Mode
  - Add exponential scaling (1.20x every 5 waves)
  - Implement 1HP challenge mode mechanics

#### 1.2 Enhanced Wave System
**Modifications:**
- `lib/config/wave_config.dart`:
  - Add endless mode wave generation
  - Add scaling multipliers for enemy stats
  - Extend beyond current 5-wave limit

### 2. New Hero Implementation

#### 2.1 Heptagon Hero
**Modifications:**
- `assets/config/heroes.json`:
  ```json
  {
    "heptagon": {
      "health": 100,
      "attack_damage": 15,
      "attack_cooldown": 0.8,
      "ability": {
        "name": "Resonance Knockback",
        "damage": 50,
        "knockback_distance": 30,
        "cooldown": 10.0
      }
    }
  }
  ```

**New Files:**
- `lib/components/abilities/resonance_knockback.dart` - Heptagon's ability implementation

**Modifications:**
- `lib/components/shapes/custom_shapes.dart`:
  - Add `drawHeptagon()` method for 7-sided polygon rendering

### 3. New Enemy Implementation

#### 3.1 Shielded Chaser
**New Files:**
- `lib/components/enemies/shielded_chaser.dart`:
  ```dart
  class ShieldedChaser extends PositionComponent {
    double baseHealth = 60;
    double shieldHealth = 40;
    double speed = 350;
    bool shieldActive = true;
    
    void takeDamage(double damage) {
      if (shieldActive) {
        shieldHealth -= damage;
        if (shieldHealth <= 0) {
          shieldActive = false;
          // Play shield break sound
        }
      } else {
        baseHealth -= damage;
      }
    }
  }
  ```

**Modifications:**
- `lib/config/wave_config.dart` - Add shielded chaser spawn patterns
- `assets/config/waves.json` - Include new enemy type in wave definitions

### 4. Item Drop System

#### 4.1 Drop Mechanics
**New Files:**
- `lib/components/items/item_pickup.dart` - Base pickup component
- `lib/components/items/health_shard.dart` - Health restoration pickup
- `lib/components/items/weapon_overclock.dart` - Temporary fire rate boost
- `lib/components/items/retry_token.dart` - 1HP mode revival token

**Modifications:**
- `lib/components/enemies/enemy_chaser.dart`:
  - Add `onDestroy()` method with 20% drop chance logic
- `lib/components/enemies/enemy_shooter.dart`:
  - Add same drop logic
- `lib/components/enemies/shielded_chaser.dart`:
  - Add 5% retry token drop chance for 1HP mode

#### 4.2 Item Effects System
**New Files:**
- `lib/systems/effect_manager.dart` - Temporary effect tracking
- `lib/effects/weapon_overclock_effect.dart` - +25% fire rate for 10s

### 5. Enhanced Shop System

#### 5.1 Range Upgrade Implementation
**Modifications:**
- `lib/config/item_config.dart`:
  - Add "Extended Reach" item definition
- `assets/config/items.json`:
  ```json
  {
    "extended_reach": {
      "name": "Extended Reach",
      "price": 150,
      "effect": "range_boost",
      "value": 50
    }
  }
  ```

**New Properties:**
- `lib/components/hero.dart`:
  - Add `rangeMultiplier` property
  - Modify projectile/ability range calculations

### 6. UI System Enhancements

#### 6.1 Paged Hero Selection
**Modifications:**
- `lib/overlays/hero_selection_overlay.dart`:
  ```dart
  class HeroSelectionOverlay extends StatefulWidget {
    int currentPage = 0;
    final int heroesPerPage = 5;
    
    Widget buildPagedHeroSelection() {
      // Implement pagination logic
      // Add left/right arrow navigation
    }
  }
  ```

#### 6.2 Game Mode Selection UI
**New Files:**
- `lib/overlays/game_mode_selection_overlay.dart`:
  - Normal Mode button
  - Endless Mode button  
  - 1HP Challenge Mode button

### 7. Audio System Extensions

**New Audio Assets:**
- `assets/audio/heptagon_resonance.wav`
- `assets/audio/chaser_shield_break.wav`
- `assets/audio/retry_token_collect.wav`

**Modifications:**
- `lib/components/sound_manager.dart`:
  ```dart
  Future<void> playHeptagonResonance() async { ... }
  Future<void> playShieldBreak() async { ... }
  Future<void> playRetryTokenCollect() async { ... }
  ```

### 8. State Management Updates

#### 8.1 Game State Extensions
**Modifications:**
- `lib/game/circle_rouge_game.dart`:
  ```dart
  enum GameMode { normal, endless, oneHpChallenge }
  
  class CircleRougeGame extends FlameGame {
    GameMode currentGameMode = GameMode.normal;
    int retryTokens = 0;
    
    void handlePlayerDeath() {
      if (currentGameMode == GameMode.oneHpChallenge && retryTokens > 0) {
        consumeRetryToken();
        revivePlayer();
      } else {
        gameOver();
      }
    }
  }
  ```

### 9. Implementation Priority & Timeline

#### Phase 1 (Core Systems)
1. Game mode framework and selection UI
2. Endless mode wave scaling logic
3. 1HP challenge mode mechanics

#### Phase 2 (New Content)
1. Heptagon hero implementation
2. Shielded Chaser enemy
3. Item drop system foundation

#### Phase 3 (Polish & Integration)
1. Range upgrade system
2. Paged hero selection UI
3. Audio integration
4. Balance testing

### 10. Testing Considerations

#### 10.1 Mode-Specific Testing
- Endless mode scaling verification (1.20x multiplier accuracy)
- 1HP mode retry token mechanics
- Drop rate validation (20% items, 5% retry tokens)

#### 10.2 UI/UX Testing
- Paged hero selection navigation
- Game mode selection flow
- Item pickup feedback

#### 10.3 Performance Testing
- Endless mode memory management with increasing enemy counts
- Effect system performance with multiple temporary buffs

### 11. Configuration Data Structure

#### 11.1 New JSON Configurations
**`assets/config/game_modes.json`:**
```json
{
  "normal": { "max_waves": 5, "scaling": 1.0 },
  "endless": { "max_waves": -1, "scaling": 1.20, "scaling_interval": 5 },
  "oneHpChallenge": { "player_health": 1, "retry_tokens": true }
}
```

### 12. Risk Assessment & Mitigation

#### 12.1 Technical Risks
- **Endless Mode Performance**: Risk of memory leaks with unlimited waves
  - Mitigation: Implement object pooling for enemies/projectiles
- **UI Complexity**: Paged hero selection may complicate navigation
  - Mitigation: User testing and iterative design refinement
- **Save State Complexity**: Game mode persistence across sessions
  - Mitigation: Extend existing configuration system

#### 12.2 Design Risks  
- **1HP Mode Balance**: May be too punishing even with retry tokens
  - Mitigation: Playtesting with varying retry token drop rates
- **Heptagon Ability Balance**: Knockback may disrupt gameplay flow
  - Mitigation: Tunable knockback distance and damage values

This plan maintains the existing architecture while cleanly integrating all new features through targeted extensions and new components. 