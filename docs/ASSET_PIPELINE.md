# AI Asset Pipeline — Pixel Lab

All AI-generated art comes from **Pixel Lab** (pixellab.ai). This doc is the contract for
how art gets made so the game stays visually coherent and assets drop straight into the
project.

## Setup status

- ✅ `PIXELLAB_API_KEY` is configured as an environment variable in this Claude Code
  environment and verified working against `api.pixellab.ai`.
- ⚠️ Generation is pay-per-image: the account needs credits at pixellab.ai before
  production runs (balance check: `GET /v1/balance`).
- ❌ Ideogram was considered and dropped — one tool, one style, less drift.

## What Pixel Lab produces

| Asset class | Notes |
|---|---|
| Hero sprites + animations | idle / walk / attack, ~16×24 px |
| Enemy & boss sprites | basics ~16×16, bosses up to 64×64 |
| Tiles & props | graves, cottages, forest, castle set pieces |
| Weapon FX & pickups | arrows, vials, auras, gems |
| **Dialogue portraits** | generated at Pixel Lab's larger canvas sizes in the same pixel style — a portrait that matches the sprites beats a mismatched painted one |
| Key art / store art | attempted in-style first; commission later only if store assets need more |

Everything else (UI nine-slices, fonts, audio) comes from CC0 packs or later commissions.
Until Phase 5, the game uses the procedural placeholder sprites in
`scripts/pixel_sprites.gd`.

## Style-lock strategy (do this before mass production)

AI art drifts. We prevent that by locking style *once*, then reusing it:

1. **One reference hero first:** generate Wren the Poacher until he's *right*
   (silhouette test: readable in pure black; palette per `GAME_OVERVIEW.md` §6 —
   near-black blues/browns, torch-orange + cold moonlight accents).
2. **Record everything:** every parameter of the approved generation is logged in
   `docs/asset_log.md` (created when generation starts).
3. **Lock and reuse:** all subsequent generations reuse those exact parameters /
   reference images. Any asset that doesn't match gets regenerated, not hand-fixed.
4. **Portrait pass:** same process at portrait size with one character before
   generating all six.

## Conventions

- **Sprites:** `assets/sprites/<category>/<name>_<anim>.png`
  e.g. `assets/sprites/heroes/wren_walk.png`, `assets/sprites/enemies/shambler_idle.png`
- **Portraits:** `assets/portraits/<name>_<expression>.png` e.g. `maud_smirk.png`
- Generation prompts/parameters worth keeping get logged in `docs/asset_log.md` so any
  asset can be regenerated or style-matched later.

## Timing

- **Now → Phase 4:** placeholders only. Do NOT burn credits on art for mechanics that
  might change.
- **Exception:** the style-lock exercise (1 reference hero + 1 portrait) can happen any
  time once the account has credits — it's cheap and de-risks Phase 5.
- **Phase 5:** full production pass, in visibility order: heroes → enemies → bosses →
  tiles → FX → portraits.

## ⚠️ Key hygiene

Never commit the API key to the repo, paste it into chat, or write it into any file.
Environment variable only. If it leaks: revoke at pixellab.ai and rotate.
