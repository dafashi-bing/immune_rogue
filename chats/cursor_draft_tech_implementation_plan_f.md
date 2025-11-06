# Draft tech implementation plan from GDD
_Exported on 9/26/2025 at 22:11:25 PDT from Cursor (1.6.45)_

---

**User**

 Given this GDD, draft a tech implementaion plan and output it under `design_docs/` @Delta-GDD V3 – UI, Wave Flow, Passive Shop & Enemi....md . As a starter, you only need to do high level feature splits and we will add onto details latel

---

**Cursor**

I'll analyze the GDD and create a high-level technical implementation plan. Let me first examine the current codebase structure to understand the existing architecture.

Now let me check the current shop and UI components to understand the existing systems:

Now let me create a comprehensive technical implementation plan based on the GDD and current architecture:

```markdown
# Delta-GDD V3 – Technical Implementation Plan

## 1. Overview
This document outlines the high-level technical implementation plan for the Delta-GDD V3 update, focusing on UI improvements, wave flow enhancements, passive shop expansion, and new enemy types.

**Target Architecture**: Flutter + Flame 1.18.0 with Component-Entity System
**Estimated Development Time**: 4-6 weeks
**Priority**: High (cross-platform compatibility improvements)

## 2. High-Level Feature Breakdown

### 2.1 Responsive Layout & UI Scaling System
**Priority**: Critical
**Dependencies**: None
**Estimated Effort**: 1-2 weeks

#### Components to Modify:
- `lib/components/ui/responsive_layout.dart` (enhance existing)
- `lib/components/hud.dart` (refactor positioning)
- `lib/components/shop_panel.dart` (responsive redesign)
- `lib/overlays/*` (all overlay components)

#### Key Tasks:
- Enhance `ResponsiveMixin` with percentage-based anchor system
- Implement auto-scaling for hero sprites and hitboxes
- Create responsive breakpoints for mobile/desktop/web
- Update all UI components to use percentage positioning
- Add resolution detection and scaling factor calculation

### 2.2 Enhanced Wave Flow & UI Feedback
**Priority**: High
**Dependencies**: UI Scaling System
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

### 2.3 Consumable Drop System
**Priority**: High
**Dependencies**: Item system refactor
**Estimated Effort**: 1.5 weeks

#### New Components:
- `lib/components/items/consumable_drop.dart`
- `lib/components/items/projectile_clear.dart`
- `lib/components/items/screen_clear.dart`
- `lib/components/items/shield_bubble.dart`
- `lib/components/items/time_slow.dart`
- `lib/components/effects/` (various temporary effects)

#### Configuration Updates:
- Extend `assets/config/items.json` with consumable definitions
- Add drop rate configuration to `assets/config/waves.json`
- Create consumable effect system in `ItemConfig`

#### Key Tasks:
- Implement 20% base drop chance system
- Add auto-collect mechanism with 30s despawn timer
- Create temporary effect management system
- Integrate with existing enemy defeat logic
- Add visual/audio feedback for consumable activation

### 2.4 Expanded Passive Shop System
**Priority**: High
**Dependencies**: Item system, UI scaling
**Estimated Effort**: 2 weeks

#### Components to Enhance:
- `lib/components/shop_panel.dart` (major refactor)
- `lib/config/item_config.dart` (expand item types)
- `lib/components/hero.dart` (add passive effect system)

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

### 2.5 Interactive Help & Tooltip System
**Priority**: Medium
**Dependencies**: UI scaling system
**Estimated Effort**: 1 week

#### New Components:
- `lib/components/ui/tooltip_manager.dart`
- `lib/components/ui/help_overlay.dart`
- `lib/overlays/controls_help_overlay.dart`

#### Key Tasks:
- Replace hover tooltips with click-to-show system
- Create "H" key help overlay with control scheme
- Implement context-sensitive help cards
- Add "?" icons throughout UI
- Integrate with existing escape key navigation

### 2.6 New Enemy Types & Infinite Mode
**Priority**: Medium
**Dependencies**: Wave system, enemy base classes
**Estimated Effort**: 1.5 weeks

#### New Components:
- `lib/components/enemies/swarmer.dart` (Wave 6+)
- `lib/components/enemies/bomber.dart` (Wave 8+)
- `lib/components/enemies/sniper.dart` (Wave 10+)
- `lib/components/enemies/splitter.dart` (Wave 12+)
- `lib/components/enemies/mine_layer.dart` (Wave 14+)

#### Configuration Updates:
- Extend `assets/config/waves.json` with infinite mode spawn rules
- Add enemy behavior configurations
- Define spawn thresholds and scaling parameters

#### Key Tasks:
- Design unique AI behaviors for each enemy type
- Implement infinite mode spawn management
- Create enemy-specific projectiles and effects
- Add visual differentiation and animations
- Balance health/damage scaling for late waves

### 2.7 Control Scheme Streamlining
**Priority**: Low
**Dependencies**: Input system review
**Estimated Effort**: 0.5 weeks

#### Components to Modify:
- `lib/game/circle_rouge_game.dart` (input handling)
- All overlay components (escape key handling)

#### Key Tasks:
- Remove "J" and "L" hotkey bindings
- Consolidate ability triggering to "K" key only
- Implement universal escape key navigation
- Update help text and UI prompts
- Test cross-platform input compatibility

## 3. Implementation Phases

### Phase 1: Foundation (Weeks 1-2)
- Responsive layout system enhancement
- UI scaling implementation
- Basic wave flow improvements

### Phase 2: Core Features (Weeks 3-4)
- Consumable drop system
- Passive shop expansion
- New item effects implementation

### Phase 3: Content & Polish (Weeks 5-6)
- New enemy types
- Interactive help system
- Control scheme updates
- Audio integration
- Cross-platform testing

## 4. Technical Considerations

### 4.1 Performance Impact
- **Moderate**: Additional UI components and effects
- **Mitigation**: Object pooling for consumables and effects
- **Monitoring**: Frame rate testing across platforms

### 4.2 Cross-Platform Compatibility
- **Critical**: Responsive design must work on mobile, desktop, web
- **Testing**: Comprehensive testing on multiple screen sizes
- **Fallbacks**: Graceful degradation for unsupported features

### 4.3 Save System Impact
- **Minor**: New item effects need persistence
- **Approach**: Extend existing JSON configuration system
- **Backward Compatibility**: Maintain compatibility with existing saves

### 4.4 Asset Management
- **New Assets**: ~25 new images, ~7 new audio files
- **Organization**: Maintain existing `assets/` structure
- **Optimization**: Compress assets for web deployment

## 5. Risk Assessment

### High Risk
- **Responsive layout complexity**: Multiple screen sizes and aspect ratios
- **Performance on mobile**: Additional UI elements and effects

### Medium Risk
- **Passive effect stacking**: Complex interaction between multiple effects
- **New enemy AI**: Balancing challenge without frustration

### Low Risk
- **Audio integration**: Existing `SoundManager` well-established
- **Control scheme changes**: Minimal impact on core gameplay

## 6. Success Metrics

### Technical Metrics
- Consistent 60 FPS across all platforms
- UI scales correctly on screens from 480p to 4K
- Memory usage increase <20% from baseline

### Gameplay Metrics
- Shop interaction time reduced by 30%
- Player retention through Wave 10+ increased
- Positive feedback on new enemy variety

## 7. Next Steps

1. **Detailed Design Phase**: Break down each feature into specific tasks
2. **Asset Creation**: Coordinate with art team for required assets
3. **Prototype Development**: Create minimal viable versions of key systems
4. **Iterative Testing**: Regular playtesting throughout development
5. **Platform Testing**: Ensure compatibility across all target platforms

---

**Document Version**: 1.0
**Last Updated**: 2025-09-19
**Owner**: Development Team
**Status**: Draft - Awaiting Approval
```

I've created a comprehensive high-level technical implementation plan for the Delta-GDD V3 update. The plan breaks down the major features into manageable components and provides:

## Key Highlights:

1. **Structured Approach**: Organized into 7 main feature areas with clear dependencies and effort estimates
2. **Phased Implementation**: 3-phase rollout over 4-6 weeks to manage complexity
3. **Risk Assessment**: Identified potential challenges and mitigation strategies
4. **Technical Considerations**: Performance, compatibility, and asset management concerns

## Major Feature Areas:

- **Responsive Layout System** (1-2 weeks) - Foundation for all UI improvements
- **Enhanced Wave Flow** (1 week) - Better player feedback and transitions  
- **Consumable Drop System** (1.5 weeks) - New temporary power-ups
- **Expanded Passive Shop** (2 weeks) - 10 new stackable items with complex effects
- **Interactive Help System** (1 week) - Click-based tooltips and help overlay
- **New Enemy Types** (1.5 weeks) - 5 new enemies for infinite mode
- **Control Streamlining** (0.5 weeks) - Simplified input scheme

The plan leverages the existing Flutter + Flame architecture and builds upon the current component system. Each feature area includes specific file modifications and new components needed.

Would you like me to elaborate on any particular section or start detailing the implementation for a specific feature area?

