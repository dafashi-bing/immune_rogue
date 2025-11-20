# Backgrounds  
Version: 1.1  
Date: 2025-11-03  
Author: [TO-DO]

---

## 1. Overview  
Layered pixel-art scenes evoke the body’s interior and now tie into wave progression. Each biome not only looks distinct but matches the pathogens you face at that stage.

## 2. Biome Themes  

1. Skin Barrier  
   • Palette: warm tans, creams, soft reds  
   • Use for Wave 1–2 (Influenza Virus Particles & Pseudomonas Bacteria)  
   • Foreground: uneven cell wall tiles, micro-crack highlights  
   • Midground: drifting keratin flakes, 1–2 px particles  
   • Background: soft tissue gradient  

2. Bloodstream  
   • Palette: deep reds, maroons, white accents  
   • Use for Wave 3–4 (mix of Virus + Bacterium swarms) and Wave 12 (Segmented Virus)  
   • Foreground: curved vessel‐wall tiles, capillary nodes  
   • Midground: drifting blood cells (8×8 px), plasma bubbles  
   • Background: dark red gradient  

3. Lymph Node  
   • Palette: pale greens, muted olives  
   • Use for Wave 5 (Biofilm-Encased Bacteria)  
   • Foreground: hex-tile sinus floor  
   • Midground: floating lymphocyte sprites, tiny motes  
   • Background: pulsing nodal walls  

4. Gut Lumen  
   • Palette: muted browns, oranges, yellows  
   • Use for Wave 6 (E. coli Swarm)  
   • Foreground: villi-tile patterns, mucus drip pixels  
   • Midground: drifting 4×4 px microbes, nutrient droplet particles  
   • Background: darker gradient with folds  

5. Lung Tissue  
   • Palette: soft blues, whites  
   • Use for Wave 8 (Spore-Forming Bacteria)  
   • Foreground: alveolar sac outlines, air-pocket tiles  
   • Midground: drifting air bubbles, faint mist lines  
   • Background: pale blue gradient with vascular shadows  

6. Blood–Brain Barrier  
   • Palette: grays, slate blues, neon accents  
   • Use for Wave 10 (Bacteriophage Sniper)  
   • Foreground: tight endothelial‐cell tiles  
   • Midground: drifting ion particles, occasional sparks  
   • Background: dark gray gradient with neural-network lines  

---

## 3. Technical Specs

- Tile Size: 16×16 px for floor/tiles; 32×32 px for large props  
- Layers & Parallax:  
  • Background (z = –3): static/slow (0.1×)  
  • Midground (z = –2): drifting sprites (0.5×)  
  • Foreground (z = –1): collision/debris (1.0×)  
- Animations: 4–6 frames at 8–12 FPS  
- Performance: preload tilemaps, pool particles, cap parallax layers to 3

---

## 4. Wave-to-Background Mapping

| Wave  | Enemy Types                                  | Suggested Biome          | Reason                                                                 |
|-------|-----------------------------------------------|--------------------------|------------------------------------------------------------------------|
| 1     | Chaser (Influenza Virus Particle)             | Skin Barrier             | First‐contact pathogens breach the skin’s surface                      |
| 2     | Shooter (Pseudomonas Bacterium)               | Skin Barrier             | Bacterial colonizers often start on skin or wounds                     |
| 3–4   | Chaser + Shooter mix                          | Bloodstream              | Systemic spread via capillaries––more open “flow” environment          |
| 5     | Shield (Biofilm-Encased Bacterium)            | Lymph Node               | Biofilms trap inside lymph nodes; filtering & immune response location |
| 6     | Swarm (E. coli Swarm)                         | Gut Lumen                | E. coli thrives in the gut lumen                                       |
| 8     | Bomber (Spore-Forming Bacterium)              | Lung Tissue              | Spore-formers often infect respiratory tracts                           |
| 10    | Sniper (Bacteriophage Sniper)                 | Blood–Brain Barrier      | Phage therapy and neural interfaces––link to the brain barrier         |
| 12    | Splitter (Segmented Virus)                    | Bloodstream              | Viruses circulate in blood; high-stakes late wave                      |

---

## 5. Next Steps

1. Confirm these wave-to-biome assignments.  
2. Hand off palettes, tile templates, and parallax specs to the pixel artist.  
3. Prototype each scene in Flame using `ParallaxComponent` + `TileMapComponent`.  
4. Performance test on target devices.

---

Once approved, click **Save Doc** to archive and sync with asset trackers.

Today’s doc progress:  
[✓] Character Design  
[✓] Ability Effects  
[✓] Ultimate Personification  
[✓] Implementation Requirements  
[✓] Backgrounds  
[] Implementation Tips