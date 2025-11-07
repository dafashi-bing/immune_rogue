<!-- 23d2477e-50a0-47ca-984c-1d0451f8cba0 4ce5ff98-a405-4000-ac53-5001a3836c60 -->
# Ultimate Ability System Implementation

## Overview

Add ultimate ability system where players charge ultimate by killing enemies (1 charge per kill, 100 charges to cast). Ultimate is activated with L key and displayed via a circular button indicator next to the K button.

## Files to Modify

### 1. `lib/components/hero.dart`

- Add `ultimateCharge` field (int, 0-100) initialized to 0
- Add `maxUltimateCharge` constant (100)
- In `onEnemyKilled()`: increment `ultimateCharge` by 1, clamp to max
- Add `castUltimate()` method that checks if charge is full, resets charge, and prints console message
- In `onKeyEvent()`: add handler for `LogicalKeyboardKey.keyL` that calls `castUltimate()`
- Reset `ultimateCharge` to 0 when hero is reset (in reset methods if they exist)

### 2. `lib/components/hud.dart`

- Add ultimate button components:
- `late CircleComponent ultimateButton;` (similar to skillButton)
- `late TextComponent ultimateHotkeyText;` (shows 'L')
- `late CircularProgressComponent ultimateChargeProgress;` (for charge fill)
- In `onLoad()`: 
- Position ultimate button to the right of K button (calculate position based on skillButton position + spacing)
- Create circular button with same radius as skillButton
- Add hotkey text 'L' below button
- Add circular progress component for charge visualization
- Add `updateUltimateCharge(int charge, int maxCharge)` method:
- Calculate charge percentage
- Update button opacity (50% if not full, 100% if full)
- Update button fill color (hero color when full, gray when not)
- Update circular progress to show charge percentage
- In `update()`: call `updateUltimateCharge()` with hero's current charge

### 3. Implementation Details

- Ultimate button positioned at: `skillButtonX + (skillButtonRadius * 2) + spacing` to the right of K button
- Button uses same radius as skillButton for consistency
- When charge < 100: button opacity = 0.5, border color = gray
- When charge = 100: button opacity = 1.0, filled with hero color
- Circular progress shows charge percentage as a filled arc
- Console output: `print('Ultimate cast!')` for now

## Key Code Locations

- Hero charge tracking: `lib/components/hero.dart` lines ~113-114 (near totalKills)
- Kill increment: `lib/components/hero.dart` line ~1515 (onEnemyKilled)
- Input handling: `lib/components/hero.dart` line ~1135 (K key handler)
- HUD button creation: `lib/components/hud.dart` lines ~213-290 (skillButton setup)
- HUD update loop: `lib/components/hud.dart` line ~667 (update method)

### To-dos

- [ ] Add ultimateCharge field and maxUltimateCharge constant to Hero class, increment charge in onEnemyKilled()
- [ ] Add castUltimate() method to Hero class with console output and charge reset
- [ ] Add L key handler in Hero's onKeyEvent() method to call castUltimate()
- [ ] Add ultimate button components to HUD (CircleComponent, TextComponent, CircularProgressComponent)
- [ ] Position ultimate button to the right of K button in HUD onLoad()
- [ ] Add updateUltimateCharge() method to HUD with opacity and color logic based on charge
- [ ] Call updateUltimateCharge() from HUD update() method with hero charge data