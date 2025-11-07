# Change Requirements – Implementation  
Version: 1.0  
Date: 2025-11-02  
Author: [TO-DO]

---

## 1. Character Assets

### 1.1 Heroes (Pixel Sprites)  
- Import new 48×48 px hero sprite sheets (idle/move/attack/hit/death).  
- Place in `/assets/sprites/heroes/{macrophage,plasma_cell,…}/`.  
- Ensure each sheet uses the 16-color “cell biology” palette.  
- Validate animation loops and hit frames in Flame.

### 1.2 Enemies (Pixel Sprites)  
- Add new 32×32(px) sheets for:  
  • Bacteriophage Sniper  
  • Segmented Virus (“Splitter”) + 16×16 mini-virions  
  • Spore Mine Layer + 8×8 mine sprite  
- Update original enemy folders with renamed files.  
- Confirm death animations spawn correct sub-sprites.

---

## 2. Ability VFX

### 2.1 Base Abilities  
- Integrate ParticleSystemComponents for each base ability:  
  • Engulf Surge (12 ingest particles, shake)  
  • Antibody Lance (Y-projectile + trail)  
  • Cytokine Burst (expanding ring + pink dots)  
  • NET Flare (5 filaments + hit sparks)  
  • Antigen Web (tiled zone + drifting lines)  
  • Perforin Punch (inner/outer rings + sparks)  
- Use pooling for particle emitters; cap on-screen particles to 200.

### 2.2 Ultimates VFX  
- Create special ParticleSystems or SpriteAnimations for ultimates:  
  • Engulf Rampage (dash trail + bounce burst)  
  • Immunoglobulin Barrage (360° spray + slow aura)  
  • Cytokine Cataclysm (full-screen tint + ring flashes)  
  • NET Tsunami (rotating zone + burst nodes)  
  • Antigen Storm (strike markers + mini-webs)  
  • Apoptotic Exterminatus (expanding ring + death wave)  
- Implement add-on overlay layer for screen/tint effects.

---

## 3. Ultimate Personification Integration

- Store anime-style portrait assets (e.g. `/assets/portraits/{hero}_ult.png`).  
- On ultimate cast:  
  • Pause game action; display portrait widget over arena.  
  • Play optional voice-line stub.  
  • Fade portrait out after 1.5 s; resume gameplay.  
- Wire prompts → SD1.5 pipeline; deliver final PNGs at 512×512 px with transparent BG.

---

## 4. Data & Configuration

- Update `abilities.json` / GDD-config:  
  • Rename base abilities & ult names.  
  • Add descriptions, cooldowns, cost, effect IDs.  
  • Link VFX component names to ability IDs.  
- Add new enemy definitions in `enemies.json`: health, behavior params, drop logic for splitters/mines.

---

## 5. UI & UX

- Ultimate Energy Bar:  
  • Label “Immune Response.”  
  • Increment +10 per kill; display 0–100.  
  • Flash at ≥90; disable at 0.  
- Portrait Overlay:  
  • Use Flame `PositionComponent` or Flutter widget atop the game canvas.

---

## 6. Backgrounds (Placeholder)

- See upcoming “Backgrounds” doc for parallax layers, tilemaps, and animated debris.  
- Reserve `/assets/backgrounds/` folders now for later art.

---

## 7. Asset & Code Organization

- Follow naming conventions:  
  • Sprites: `{type}_{name}_{action}_{frame}.png`  
  • Particles: `p_{ability}_{effect}.json`  
  • Portraits: `ult_{hero}.png`  
- Use versioned folders (e.g. `v1.0/`) for rollout.

---

## 8. Timeline & Milestones

- Week 1: Art import & sprite-sheet QA  
- Week 2: Base ability VFX + data config  
- Week 3: Ult VFX + portrait integration  
- Week 4: UI polish + final testing

---

Once these requirements are approved, click **Save Doc** to archive and kick off implementation.

Today’s doc progress:  
[✓] Character Design  
[✓] Ability Effects  
[✓] Ultimate Personification  
[] Backgrounds  
[] Implementation Tips  
[✓] Implementation Requirements