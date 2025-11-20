# Character Design – Additional Enemies  
Version: 1.2  
Date: 2025-11-02  
Author: [TO-DO]

---

## 1.3 Enemies (Pathogens) – Additions

7. Bacteriophage Sniper (Sniper – long-range single-target)  
   - Canvas: 32×32 px  
   - Body: slender grey rod-shape with bulbous head; single red “eye” pixel  
   - Details: 2-px tail-fiber flicker animation  
   - Idle: gentle 4-frame up/down bob  
   - Attack: fires a small 4×8 px “phage dart” (white tip, red shaft)  
   - Death: head cracks open with a 4-px white burst; tail drops (2 frames)  

8. Segmented Virus (“Splitter” – splits on death)  
   - Canvas: 32×32 px (main) → 16×16 px (mini-virions)  
   - Body: medium-grey sphere with darker segmentation lines  
   - Idle: 4-frame slow rotation of segments  
   - Attack: forward charge (contact damage)  
   - Death: splits into 3 mini-virions (16×16 px each) that inherit 1 HP and wander briefly before self-destruct (mini “pop” animation, 3 frames)  

9. Spore Mine Layer (“Mine Layer” – deploys proximity mines)  
   - Canvas: 32×32 px  
   - Body: brown-green oval with 3 small dorsal spore pods  
   - Idle: pods pulse in size (4 frames)  
   - Attack/Behavior: every 5 s, drop up to 2 spore mines at current position  
   - Mine Sprite: 8×8 px spiky sphere, 2-frame glow pulse  
   - Mine Trigger: when player enters 32-unit radius → explode (16×16 px spore-cloud, 4 frames, deals area damage + brief slow)  

---

Please review these entries. If there are any other enemy archetypes missing, let me know before archiving.  

Today’s doc progress:  
[✓] Character Design (base enemies)  
[✓] Added Sniper / Bacteriophage Sniper  
[✓] Added Splitter / Segmented Virus  
[✓] Added Mine Layer / Spore Mine Layer  
[] Verify any additional missing enemy types