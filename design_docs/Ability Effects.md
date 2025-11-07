# Ability Effects  
Version: 1.0  
Date: 2025-11-01  
Author: [TO-DO]

---

## 1. General Particle & Animation Guidelines  
- Art Style: Pixel‐only; 1–2 px particles; 16-color palette from “cell biology.”  
- Canvas / Frame Sizes:  
  • Small particles: 4×4 px  
  • Medium filaments/bursts: 8×8–16×16 px  
  • Ring overlays: 64×64–128×128 px  
- Animation: 3–6 frames per effect; looped where appropriate  
- Performance:  
  • Batch particles into single `ParticleSystemComponent`  
  • Limit total particle count to ~200 on screen  
  • Reuse and pool emitters  
- Layering & Blend Modes:  
  • Base effects (behind character): normal blend  
  • Highlights/glows: additive blend  
  • Screen‐wide overlays (ultimates): over UI layer, alpha‐fade  

---

## 2. Base Abilities

1. Engulf Surge (Macrophage)  
   • Animation:  
     - Frame 1–2: cell sprite stretches forward 25% on X axis  
     - Frame 3–4: retract to normal  
   • Particle Burst: on impact, emit 12 “ingest” particles (4×4 px beige swirl), lifetime 0.3s, radial velocity 50–100 px/s, fade out.  
   • Screen Shake: 0.05s × 2 at 2 px amplitude.

2. Antibody Lance (Plasma Cell)  
   • Projectile Sprite: 8×16 px Y-shape, white with aqua outline  
   • Trail: continuous emitter (rate 20/s) behind lance, 4×4 px pixel dot, lifetime 0.2s, alpha fade.  
   • Impact: single 16×16 px splash for 0.15s (2 frames), white flash.

3. Cytokine Burst (Helper T-cell)  
   • Ring Animation: 5-frame 8-px-thick ring expanding from 0→120 px in 0.3s; palette: pink→white fade.  
   • Particles: emit 16 tiny pink dots (4×4 px), velocity random ±(50–80 px/s), lifetime 0.5s.

4. NET Flare (Neutrophil)  
   • Web Projectiles: five 6×6 px filament sprites, light‐grey lines  
   • Emitter: spawn 5 at once in 360° evenly; move at 120 px/s, lifetime 0.4s  
   • On hit: show 4×4 px white spark; slow‐cloud overlay (8×8 px soft‐edge) lasting 0.5s.

5. Antigen Web (Dendritic Cell)  
   • Zone Tile: tiled 16×16 px semi-transparent mint-green texture, 30% alpha  
   • Fade‐In/Out: 4 frames over 0.2s each  
   • Static Particles: emit 8 dendrite‐line particles (1×8 px) drifting outward at 20 px/s

6. Perforin Punch (Cytotoxic T-cell)  
   • Ring Blast: two concentric 64×64 px rings  
     – Inner: white, 4-px thick, expands 0→64 px in 0.3s  
     – Outer: red, 2-px thick, expands 0→96 px in 0.4s  
   • Particles: 12 small red dots (3×3 px) ejected along circumference.

---

## 3. Ultimate Effects

1. Engulf Rampage (Macrophage)  
   • Continuous Dash Trail: emitter at hero’s feet, 8×8 px beige swirl, rate 40/s, lifetime 0.2s  
   • Bounce Burst: on each edge hit, spawn 24 “devour” particles (6×6 px, rapid fade).  
   • Duration: 3s; auto-kill collision flag.

2. Immunoglobulin Barrage (Plasma Cell)  
   • 360° Spray: emitter spawns 20 Y-projectiles over 3s (≈6/s)  
   • Slow Aura: overlay a 128×128 px semi-transparent blue circle at hero for channel duration  
   • Channel Indicator: 16×16 px fuse icon above hero, pulse 4×4 px flame particles.

3. Cytokine Cataclysm (Helper T-cell)  
   • Battlefield Overlay: full-screen pink tint (RGBA 255,200,220,0.2) for 3s  
   • Pulse Events: every 0.5s spawn 32 pink ring flashes (see Cytokine Burst ring) at random enemy locations  
   • Final Buff Icon: 16×16 px shield widget with sparkling particles (8×8 px) for 5s

4. NET Tsunami (Neutrophil)  
   • Swirl Zone: rotating 192×192 px NET texture, 20 px/s rotation, 4s duration  
   • Burst Nodes: every 0.5s, 6 explosive NET blasts (100 damage) along zone circumference (16×16 px explosion sprite)

5. Antigen Storm (Dendritic Cell)  
   • Strike Markers: 32×32 px red target icon at each strike location (flash 3×3 px)  
   • Mini-Web Animations: same as Antigen Web but 100-unit radius, 0.2s fade-in  
   • Final Zone: persistent 200×200 px mat for 2s; reuse Antigen Web tile.

6. Apoptotic Exterminatus (Cytotoxic T-cell)  
   • Expanding Ring: single 256×256 px perforin ring, expands 0→256 px in 0.5s, red→white fade  
   • Push Effect: upon contact, emit 16 knockback sparks (4×4 px) along ring  
   • Death Wave: after expansion, full-screen white flash (RGBA 255,255,255,0.3) for 0.2s

---

## 4. Flutter/Flame Implementation Tips  
- Use `SpriteAnimationComponent` for frame‐based bursts and rings.  
- Build a reusable `ParticleSystemComponent` class with configurable rate, velocity, lifetime, color.  
- Tilemaps for “Antigen Web” backgrounds; toggle collision only at center.  
- Overlays: place full-screen `PositionComponent` with alpha tween for ult tints.  
- Pool components (particles, projectiles) to minimize GC — use `ComponentPool` mixin.  
- Leverage `ParallaxComponent` for background layers (to be defined in next doc).

---

Once this section is approved, we’ll proceed to “3. Ultimate Personification.”

Click **Save Doc** to archive and share with the art/engineering teams.

Today’s doc progress:  
[✓] Character Design  
[✓] Ability Effects  
[] Ultimate Personification  
[] Backgrounds  
[] Implementation Tips