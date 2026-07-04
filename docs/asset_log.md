# Asset Generation Log (Pixel Lab)

Every generated asset with its parameters, so anything can be regenerated or
style-matched later. Endpoint: `POST /v1/generate-image-pixflux`.

## Locked style parameters (the style-lock, night shift WP4)

- **Style suffix appended to every prompt:**
  `dark fantasy pixel art, moonlit night palette of deep blue-black and mud brown with
  warm torch-orange accents and cold moonlight, crisp readable silhouette, full body character`
- `image_size`: 64×64, `no_background`: true, `text_guidance_scale`: 8.0
  (8.5 + `negative_description: "witch hat, wizard, staff, flesh, fur, colorful"` for retries)

## Generated & approved (v1 batch)

| Asset | Location | Prompt core | QA verdict |
|---|---|---|---|
| wren | assets/portraits/ | hooded medieval poacher hero, hunting bow on back, mossy dark green cloak | ✅ first try — the style reference |
| maud | assets/portraits/ | stout older gravedigger woman, white bonnet, apron, shovel over shoulder | ✅ first try |
| corvus | assets/portraits/ | plague doctor, iconic long-beaked bird mask, prominent pale curved beak, flat wide-brim hat | ✅ v2 (v1 read as witch; beak emphasized + negative prompt) |
| ansel | assets/portraits/ | tonsured monk, rough brown robe, smoking censer with glowing coals | ✅ first try |
| shambler | assets/sprites/generated/ | risen undead villager, rotting grey-green flesh, ember eyes | ✅ first try (minor: floating glow orb quirk, acceptable) |
| gnawer | assets/sprites/generated/ | undead skeleton of a dog, bleached bare bones, exposed ribcage, skull with ember eye | ✅ v2 (v1 came out fleshy/striped) |
| tolling_man | assets/sprites/generated/ | undead elite, large bronze bell for a head, glowing ember light inside | ✅ first try — standout piece |
| sexton | assets/sprites/generated/ | undead gravekeeper wraith boss, wide-brim hat, grave-mold trim, long spade | ✅ first try (same glow-orb quirk) |

## Integration status

- **Hero portraits: LIVE** — camp cards + vignette overlays prefer
  `assets/portraits/<id>.png` when present (see `camp.gd::_portrait_texture`).
- **Monster art: STAGED** in `assets/sprites/generated/` awaiting the user's approval of
  the art direction before world-sprite integration (requires sprite-scale + camera-zoom
  retune — see NIGHT_LOG notes). In-run sprites remain procedural until then.

## Learnings for future batches

1. Pixflux free-tier generations work with the signup allocation (usd balance stays 0.00 —
   quota is tracked separately).
2. "plague doctor" needs the beak spelled out or it drifts to witch/wizard.
3. "skeletal X" needs "bare bones only, no flesh no fur" + a negative prompt.
4. The model likes adding a small floating moon/glow orb inside character canvases —
   harmless at portrait size; crop or negative-prompt it for world sprites.

## v0.10.0 environment + directional set
- Moon + 6 props (pixflux 64/32px): PASS after 1 retry round. **Prompting lesson: any
  mention of "moonlight" in a prop prompt paints a literal moon into the canvas — add
  "moon, sky, background scenery" to negatives and describe light as "dim cool night
  lighting" instead.**
- Side-profile stills, all 5 heroes: PASS (Ansel needed 1 retry with "we see only his
  right side, one visible eye" phrasing).
- animate-with-text walk cycles: **FAILED the QA gate 3/3 attempts** (front-facing copies,
  a turnaround instead of a cycle, then hallucinated shapes). Verdict: text-driven frame
  animation is not reliable enough to ship; revisit with /animate-with-skeleton (pose
  keypoints) in a future block. Shipped instead: per-direction stills + procedural gait
  (bob/sway/footfall squash) — genre-standard and deterministic.

## v0.12.x ground tiles + decals
- Base tiles (grave_base, forest_base, 64px seamless): pixflux output passed the 3×3 seam
  sheet only after the PIL roll-blend; **in-game QA then failed them anyway** — large
  mid-frequency blobs read as repeating camouflage at zoom 2. Fix was deterministic
  post-processing, not regeneration: downscale to 32px for fine grain, brightness ×0.62–
  0.68, blend 55–60% toward a flat night color, re-seam. **Lesson: for ground textures the
  contrast/frequency budget matters more than the render — always screenshot in-game
  before shipping a tile.**
- Decals ×7 approved, puddle cut after 2 fails (kept rendering as a framed scene).
  **Lesson: isolation phrasing ("single isolated object, nothing else in frame, plain
  transparent background") rescued 5 of 8 first-round failures; moss + mushrooms still
  needed a PIL dim to sit into the night palette.**
- Mob regenerations (shambler, sexton, wight, hanged_man): anti-moon negative set
  ("moon, moon disc, sky, floating orb, glowing sphere, background scenery, fireflies,
  sparkles") is now standard for every creature prompt.

## v0.13.x Castle Vane set (Block B)
- 15 assets in one batch, 10 first-try passes: courtier, risen_knight, chorister, thrall,
  hollow_king (portrait + strict side profile), decal_rubble, prop_pillar, prop_rubble
  (statue arm as asked), prop_candelabra (torch-orange accent piece).
- Retries: crypt_archer (v1 baked a rock outcrop under its feet — fixed with "floating
  cleanly, no ground under its feet" + rock/base negatives); chapel_thing (v1 came out
  bright glossy blue slime — fixed with "solid matte near-black violet shadow" + negatives
  "bright blue, glossy, slime"; v2 faces LEFT → flip_x in enemies.json).
- castle_base v1 painted GLOWING EMBER MORTAR between every stone ("dim cool night tones"
  did not stop it). v2 + PIL (warm-hue kill, ×0.72 darken, 38% flatten to #1b1824,
  roll-blend seams) passed the 3×3 sheet. **Lesson: negatives must name the failure
  ("glowing cracks, lava, embers") — style adjectives alone don't prevent it.**
- decal_flagstone_crack took 3 rounds (v1 hallucinated a campfire, v2 a lava-crystal
  isometric slab). v3 as "flat 2d spiderweb crack lines" filled the square — salvaged
  with a radial alpha fade + darken, ships as a soft cracked-floor patch.
- decal_banner_scrap CUT after 3 fails (kept hanging the banner on a wall / cobble scene;
  the word "banner" appears to force wall-mounted composition). Castle decal slot filled
  by reusing decal_bones — bones in a fallen court read perfectly.

## v0.14.x item icon set
- 28 icons (12 weapons + 6 evolutions + 10 keepsakes, 32px) in one batch: 24 first-try
  passes. Retries: crownsorrow (crown absent — fixed by making the crown "the biggest
  element"), pilgrims_chain (rendered a staff — fixed with "large visible oval links
  coiled in a spiral"), sextons_spade (too thin — "broad pale bone-white blade, thick
  readable shape"), widowmaker (didn't read as a bow — "clearly a bow shape, drawn wide").
  **Lesson: at 32px, name the dominant silhouette explicitly ("the crown is the biggest
  element", "clearly a bow shape") — style words alone don't control composition.**

## v1.1 The Living Night — enemy animation spike
- Retried a 2-frame enemy walk via pixflux (generate a "mid-stride" second frame per
  enemy, alternate A/B). **FAILED the same way as v0.10's text animation:** the two
  independent generations produce *different creatures*, not two poses of one — the
  shambler spike gave a hooded front-facing robe (A) vs. an unhooded side-profile green
  zombie (B). Alternating them reads as morphing, not walking. pixflux has no
  same-sprite frame coherence; only `/animate-with-skeleton` (per-sprite keypoint
  rigging, still unrun) could, at large manual cost.
- Shipped instead: a **procedural walk cycle** in the enemy multimesh transform
  (lean + footfall squash + between-step hop, one sin per enemy) — deterministic,
  zero-art, holds the 700-enemy perf budget. The horde now shambles rather than slides.
