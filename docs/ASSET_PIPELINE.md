# AI Asset Pipeline — Pixel Lab + Ideogram

We have API access to two generators. This doc is the contract for how art gets made so the
game stays visually coherent and assets drop straight into the project.

## Division of labor

| Tool | Produces | Used for |
|---|---|---|
| **Pixel Lab** (pixellab.ai) | Pixel-art sprites + animations | Heroes (idle/walk/attack), enemies, bosses, tiles/props, weapon fx, pickups |
| **Ideogram** | High-res illustrated images | Dialogue portraits (woodcut style), key art, store screenshots/feature graphic, mood boards, title-screen art |

Everything else (UI nine-slices, fonts, audio) comes from CC0 packs or later commissions.

## Hooking up the keys (one-time, ~5 min)

Add the keys as **environment secrets** so I can call the APIs from my sessions without the
keys ever entering the repo:

1. Open **claude.ai/code** (Claude Code on the web) → your **Environment** settings for this
   repo's environment.
2. Add two environment variables:
   - `PIXELLAB_API_KEY` = your Pixel Lab key
   - `IDEOGRAM_API_KEY` = your Ideogram key
3. That's it — next session I can verify both with a small test call and generate a sample.

⚠️ Never commit keys to the repo. If a key ever lands in a file, revoke and rotate it.

## Style-lock strategy (do this before mass production)

AI art drifts. We prevent that by locking style *once*, then reusing it:

1. **Mood board first (Ideogram):** ~6 images of the vale at night — palette per
   `GAME_OVERVIEW.md` §6 (near-black blues/browns + torchlight orange + cold moonlight).
   User picks the winner; it becomes the style reference.
2. **One reference hero (Pixel Lab):** generate Wren the Poacher until he's *right*
   (silhouette test: readable in pure black). Record every style parameter used.
3. **Lock and reuse:** all subsequent Pixel Lab generations reuse those exact parameters /
   reference images. Any asset that doesn't match gets regenerated, not hand-fixed.
4. **Portrait style pass (Ideogram):** same process for the woodcut portrait style with one
   character before generating all six.

## Conventions

- **Sprites:** `assets/sprites/<category>/<name>_<anim>.png`
  e.g. `assets/sprites/heroes/wren_walk.png`, `assets/sprites/enemies/shambler_idle.png`
- **Portraits:** `assets/portraits/<name>_<expression>.png` e.g. `maud_smirk.png`
- Hero sprites ~16×24 px, basic enemies ~16×16, bosses up to 64×64; portraits 512×512
  source (scaled in-engine).
- Generation prompts/parameters worth keeping get logged in `docs/asset_log.md` (created when
  generation starts) so any asset can be regenerated or style-matched later.

## Timing

- **Now → Phase 4:** placeholders only (shapes + CC0 packs). Do NOT burn time generating art
  for mechanics that might change.
- **Exception:** the style-lock exercise above (1 mood board + 1 hero + 1 portrait) can happen
  any time after keys are connected — it's cheap and de-risks Phase 5.
- **Phase 5:** full production pass, in visibility order: heroes → enemies → bosses → tiles →
  UI → portraits.
