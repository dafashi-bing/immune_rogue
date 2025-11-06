# Delta-GDD V3 – Technical Implementation Plan

## 1. Overview
This document outlines the high-level technical implementation plan for the Delta-GDD V3 update, focusing on UI improvements, wave flow enhancements, passive shop expansion, and new enemy types.

**Target Architecture**: Flutter + Flame 1.18.0 with Component-Entity System
**Estimated Development Time**: 4-6 weeks
**Priority**: High (cross-platform compatibility improvements)

## 2. High-Level Feature Breakdown

### 2.1 Enhanced Wave Flow & UI Feedback
**Priority**: High
**Dependencies**: None
**Estimated Effort**: 1 week

#### New Components:
- `lib/components/wave_announcement.dart`
- `lib/components/ui/wave_timer.dart`
- `lib/overlays/wave_transition_overlay.dart`

#### Key Tasks:
- Create centered "WAVE X – SURVIVE!" announcement system
- Implement full-screen start/end banners with animations
- Add inter-wave countdown timer with visual feedback
- Integrate audio cues (chimes/fanfares) via `SoundManager`
- Add pulsing red timer for last 10 seconds

### 2.2 Consumable Drop System
**Priority**: High
**Dependencies**: Item system refactor
**Estimated Effort**: 1.5 weeks

#### Key Tasks:
- Implement 20% base drop chance system
- Add auto-collect mechanism with 30s despawn timer
- Create temporary effect management system
- Integrate with existing enemy defeat logic
- Add visual/audio feedback for consumable activation

### 2.3 Expanded Passive Shop System
**Priority**: High
**Dependencies**: Item system
**Estimated Effort**: 2 weeks

#### New Item Categories:
- **Combat Enhancement**: Spread Master, Bouncing Bullets, Enlarged Caliber
- **Support Systems**: Drone Wingman, Clone Projection
- **Survivability**: Vampiric Coating, Armor Plating, Auto-Injector
- **Utility**: Coin Magnet, Critical Striker

#### Key Tasks:
- Redesign shop UI with "Reroll" button and coin display
- Implement click-to-show detail cards system
- Create stackable passive effect system
- Add drone AI and clone mechanics
- Implement life steal and shield regeneration systems
- Create critical hit system with visual feedback

### 2.4 Interactive Help & Tooltip System
**Priority**: Medium
**Dependencies**: None
**Estimated Effort**: 1 week

#### Key Tasks:
- Replace hover tooltips with click-to-show system
- Create "H" key help overlay with control scheme
- Implement context-sensitive help cards
- Add "?" icons throughout UI
- Integrate with existing escape key navigation

### 2.5 New Enemy Types & Infinite Mode
**Priority**: Medium
**Dependencies**: Wave system, enemy base classes
**Estimated Effort**: 1.5 weeks

#### Key Tasks:
- Design unique AI behaviors for each enemy type
- Implement infinite mode spawn management
- Create enemy-specific projectiles and effects
- Add visual differentiation and animations
- Balance health/damage scaling for late waves

### 2.6 Control Scheme Streamlining
**Priority**: Low
**Dependencies**: Input system review
**Estimated Effort**: 0.5 weeks

#### Key Tasks:
- Remove "J" and "L" hotkey bindings
- Consolidate ability triggering to "K" key only
- Implement universal escape key navigation
- Update help text and UI prompts
- Test cross-platform input compatibility

### 2.7 Responsive Layout & UI Scaling System
**Priority**: Critical
**Dependencies**: All other features
**Estimated Effort**: 1-2 weeks

#### Key Tasks:
- Enhance `ResponsiveMixin` with percentage-based anchor system
- Implement auto-scaling for hero sprites and hitboxes
- Create responsive breakpoints for mobile/desktop/web
- Update all UI components to use percentage positioning
- Add resolution detection and scaling factor calculation

## 3. Implementation Phases

### Phase 1: Foundation (Weeks 1-2)
- Enhanced wave flow & UI feedback
- Consumable drop system
- Basic shop improvements

### Phase 2: Core Features (Weeks 3-4)
- Expanded passive shop system
- New item effects implementation

### Phase 3: Content & Polish (Weeks 5-6)
- New enemy types
- Control scheme updates


### Phase 4: Responsive Layout (Final)
- Interactive help system
- Audio integration
- Responsive layout system enhancement
- UI scaling implementation
