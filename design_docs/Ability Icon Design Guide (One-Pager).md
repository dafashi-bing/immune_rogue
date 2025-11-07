# Ability Icon Design Guide (One-Pager)

Version: 1.3 | SD1.5 Checkpoint: Institute_mode 3.0 | LORA: GameIconResearch_bwflat_Lora  
Date: 2025-11-XX | Author: [TO-DO]

---

1. Purpose & Scope  
- Establish a consistent circle-masked icon style for all base and ultimate abilities  
- Flat black-and-white line art plus single accent hue, 512×512 px PNG with transparency

2. Asset Specs  
- Canvas: 512×512 px @ 300 DPI  
- Format: PNG (RGBA)  
- Mask: perfect circle, 16 px safe margin  
- Naming: Icon_<Shape>_<AbilityName>_v01.png

3. Prompt Structure  
Pipeline: SD1.5 → Institute_mode 3.0 → GameIconResearch_bwflat_Lora  
Template:  
  circular icon, flat black-and-white line art, minimal shading, single accent color HEX, VISUAL CUE, centered, high contrast, vector style, crisp outlines, no background

4. Ability-Specific Prompts

Circle – Engulf Surge (Base)  
• Original effect: Lunge forward up to 200 units, dealing 40 damage to each enemy passed through and briefly staggering them. (6 s cooldown)  
• Visual cues: bold right-pointing arrow, small front burst star, short radial shock-lines  
• Prompt:  
  circular icon, flat black-and-white line art, minimal shading, single accent color #FF4500, bold right-pointing arrow with front burst star and short radial shock-lines, centered, high contrast, vector style, crisp outlines, no background

Circle – Engulf Rampage (Ultimate)  
• Original effect: For 3 s, dash continuously, bouncing off battlefield edges. Any enemy you collide with is instantly devoured (instant kill).  
• Visual cues: three overlapped arrows, small swirl puffs at each tip, subtle blur trails  
• Prompt:  
  circular icon, flat black-and-white line art, minimal shading, single accent color #FF4500, three overlapped arrows fanning right-to-left with small swirl puffs at each tip and subtle blur trails, centered, high contrast, vector style, crisp outlines, no background

Triangle – Antibody Lance (Base)  
• Original effect: Fire one high-velocity, piercing antibody projectile that travels the entire screen and deals 999 damage on hit. (5 s cooldown)  
• Visual cues: sharp spear-like shaft piercing at a 45° angle, tiny shard particles  
• Prompt:  
  circular icon, flat black-and-white line art, minimal shading, single accent color #00BFFF, sharp spear-like shaft piercing at a 45° angle with tiny shard particles, centered, high contrast, vector style, crisp outlines, no background

Triangle – Immunoglobulin Barrage (Ultimate)  
• Original effect: Over 3 s, unleash a 360° rapid-fire spray of 20 antibodies (≈6 per second). Each deals 60 damage and applies a 30% slow for 2 s. Movement speed is reduced by 50% while channeling.  
• Visual cues: central burst, many small pointed shards radiating outward  
• Prompt:  
  circular icon, flat black-and-white line art, minimal shading, single accent color #00BFFF, central burst of small pointed shards spraying outward in all directions, centered, high contrast, vector style, crisp outlines, no background

Square – Cytokine Burst (Base)  
• Original effect: Emit a pulse in a 150-unit radius, dealing 25 damage and stunning enemies for 1.5 s. (7 s cooldown)  
• Visual cues: stylized shield outline, soft radial pulse waves  
• Prompt:  
  circular icon, flat black-and-white line art, minimal shading, single accent color #32CD32, stylized shield outline emitting soft radial pulse waves, centered, high contrast, vector style, crisp outlines, no background

Square – Cytokine Cataclysm (Ultimate)  
• Original effect: Instantly blanket the entire battlefield in a raging cytokine storm for 3 s. Every 0.5 s, all enemies take 50 damage and are stunned for 1 s. At the end of the storm, gain a 5 s buff: +30% damage reduction.  
• Visual cues: swirling storm cloud, small ring flashes scattered inside  
• Prompt:  
  circular icon, flat black-and-white line art, minimal shading, single accent color #32CD32, swirling storm cloud with small ring flashes inside, centered, high contrast, vector style, crisp outlines, no background

Pentagon – NET Flare (Base)  
• Original effect: Release a radial burst of five NET projectiles, each dealing 30 damage and slowing hit enemies by 30% for 2 s. (8 s cooldown)  
• Visual cues: central starburst, five orbiting dots  
• Prompt:  
  circular icon, flat black-and-white line art, minimal shading, single accent color #FFD700, central starburst with five orbiting dots, centered, high contrast, vector style, crisp outlines, no background

Pentagon – NET Tsunami (Ultimate)  
• Original effect: For 4 s, create a 300-unit swirling NET zone that deals 20 damage/sec and stacks slows (up to 40%). Enemies entering the zone trigger explosive NET blasts for 100 damage each.  
• Visual cues: spiral vortex core, small droplet shapes erupting outward  
• Prompt:  
  circular icon, flat black-and-white line art, minimal shading, single accent color #FFD700, spiral vortex core with droplet shapes erupting outward, centered, high contrast, vector style, crisp outlines, no background

Hexagon – Antigen Web (Base)  
• Original effect: Spawn a static 200-unit zone that deals 10 damage/sec and slows enemies by 30% for 4 s. (9 s cooldown)  
• Visual cues: hexagon frame, internal web lines and anchor nodes  
• Prompt:  
  circular icon, flat black-and-white line art, minimal shading, single accent color #BA55D3, hexagon frame with internal web lines and anchor nodes, centered, high contrast, vector style, crisp outlines, no background

Hexagon – Antigen Storm (Ultimate)  
• Original effect: Over 3 s, call down 6 radial “dendrite strikes.” Each strike spawns a mini-web (100-unit radius) that deals 40 damage and roots enemies for 1 s. The combined zone lingers for 2 s afterward.  
• Visual cues: six radial spikes, each ending in a small web-node shape  
• Prompt:  
  circular icon, flat black-and-white line art, minimal shading, single accent color #BA55D3, six radial spikes each ending in a small web-node shape, centered, high contrast, vector style, crisp outlines, no background

Heptagon – Perforin Punch (Base)  
• Original effect: Send out a ring blast at 100-unit range, dealing 25 damage and knocking enemies back 30 units. (10 s cooldown)  
• Visual cues: concentric ring blast, outward knock-back arrows  
• Prompt:  
  circular icon, flat black-and-white line art, minimal shading, single accent color #FF69B4, concentric ring blast with outward arrows at edges, centered, high contrast, vector style, crisp outlines, no background

Heptagon – Apoptotic Exterminatus (Ultimate)  
• Original effect: Unleash an ever-expanding perforin ring with unlimited range. Any enemy it touches is forced outward toward the map border; upon hitting the border, they are instantly eliminated.  
• Visual cues: expanding concentric rings, tiny impact speckles at edges  
• Prompt:  
  circular icon, flat black-and-white line art, minimal shading, single accent color #FF69B4, expanding concentric rings with tiny impact speckles at edges, centered, high contrast, vector style, crisp outlines, no background

---

5. Next Steps  
- Run all prompts through SD1.5 pipeline → export PNG → refine in Illustrator/Photoshop  
- Apply version tags (v01, v02, etc.)  
- Save finalized icons to the art repository

---

Today’s doc progress:  
[X] Full set of effect-driven prompts  
[] Asset pipeline steps  
[] Final QA checklist