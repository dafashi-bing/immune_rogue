# Visual Upgrade Plan  
Version: 1.0  
Date: 2025-11-01  
Author: [TO-DO]

---

## 1. Character Designs (Pixel Art)

### 1.1 General Guidelines  
- Canvas Size: 48×48 px for heroes and 32×32 px for standard enemies (64×64 for larger “boss” foes).  
- Palette: 16-color max per sprite; use a shared “cell biology” palette (beige, aqua, pink, orange, mint, red + neutrals).  
- Animation Frames:  
  • Idle: 4 frames (gentle scale/membrane wobble)  
  • Move/Attack: 6–8 frames (distinct pose at midpoint)  
  • Hit/Death: 4 frames (flash + fade or burst)  
- Style: clean silhouettes, slightly rounded edges, single-pixel outline in darker tone for readability.

### 1.2 Heroes (Immune Cells)

1. Macrophage (Circle → 48×48)  
   - Body: amorphous beige sphere with subtle pseudopod protrusions.  
   - Details: 2–3 light-tan granules on surface; dark-tan outline.  
   - Idle wiggle: slow 1 px “pulse” radial scale.  
   - Attack pose: extended forward pseudopod.  

2. Plasma Cell (Triangle → 48×48)  
   - Body: rounded aqua teardrop shape.  
   - Details: tiny Y-shaped antibody icons (2 px tall) floating around.  
   - Idle wiggle: gentle up-and-down bob.  
   - Attack pose: cell tips “nose-down” firing projection.  

3. Helper T-cell (Square → 48×48)  
   - Body: soft pink square with beveled corners.  
   - Details: 3 small circular “cytokine” particles orbiting perimeter.  
   - Idle wiggle: slight rotation (±2°).  
   - Attack pose: arms (membrane folds) thrust outward.  

4. Neutrophil (Pentagon → 48×48)  
   - Body: pale orange pentagon with granular texture pixels.  
   - Details: tiny white “NET” filaments drifting off edges.  
   - Idle wiggle: jittery 1 px random offset.  
   - Attack pose: star-burst shape expansion.  

5. Dendritic Cell (Hexagon → 48×48)  
   - Body: mint-green hexagon with branching dendrite lines in lighter green.  
   - Details: faint glow (2 px) at each vertex.  
   - Idle wiggle: slow pulsing glow intensity.  
   - Attack pose: branches extend outward.  

6. Cytotoxic T-cell (Heptagon → 48×48)  
   - Body: deep-red heptagon with small perforin-pore dots along edge.  
   - Details: 4–5 white pore highlights.  
   - Idle wiggle: subtle rotational sway.  
   - Attack pose: ring shape “contracts” then “expands” outward.

### 1.3 Enemies (Pathogens)

1. Influenza Virus Particle (Fast Swarm – 32×32)  
   - Body: grey sphere with 6 red spikes.  
   - Animation: rotate spikes slowly; 4-frame “roll” movement.  

2. Pseudomonas Bacterium (Shooter – 32×32)  
   - Body: purple rod; 2 toxin-orb shadows below.  
   - Idle: toxin orbs pulse.  

3. Biofilm-Encased Bacterium (Shielded Chaser – 32×32)  
   - Body: dark green blob covered in sticky biofilm (semi-opaque layer).  
   - Idle: oozing drip animation (4 frames).  

4. E. coli Swarm (Swarmer – group of 3× 28×28)  
   - Body: pink rods with darker segments.  
   - Movement: 4-frame swarm wiggle.  

5. Spore-Forming Bacterium (Bomber – 32×32)  
   - Body: brown-green sphere with 5 spike-pods.  
   - Death: each pod bursts into a tiny 8×8 spore sprite.

---

Once this section is approved, we’ll move on to “2. Ability Effects.”  
Click **Save Doc** to archive and share with the art team.

Today’s doc progress:  
[✓] 1. Character Designs  
[] 2. Ability Effects  
[] 3. Ultimate Personification  
[] 4. Backgrounds  
[] 5. Implementation Tips