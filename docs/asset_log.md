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
