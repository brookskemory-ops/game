# VIGIL

> *Hold the night.*

A medieval horde-survival roguelike about why the dead rise in the Vale of Hollowmere.
One thumb moves your hero; your weapons fight for themselves; the story is finishable —
and the choice at the end is yours. Mobile-first, 2D pixel art, built in Godot 4.

## ▶️ Play

**https://brookskemory-ops.github.io/game/**

Works in desktop and phone browsers — on desktop use arrow keys or click-drag; on a
phone just drag your thumb. Every push to the dev branch auto-builds and deploys.

## What's in the game (v1.0-rc)

- **8 nights**: three story stages (Hollowmere Village → the Wailing Forest → Castle
  Vane), four variant nights with their own rules, and **The Long Night** — endless,
  escalating, with a deepest-count record to chase.
- **6 heroes**, each with a signature weapon and passive — from Wren the poacher to the
  Hollow King himself, who cannot heal except by killing.
- **12 weapons + 6 evolutions**, all occupying distinct mechanical niches
  (`docs/ABILITIES.md` is the registry that enforces it). Half unlock with heroes,
  half behind deeds — browse them all in **the Ledger** at camp.
- **Tight 3+3 builds**: three weapons, three keepsakes, no more. Every draft matters.
- **Rites & Relics**: every night asks an optional objective; keeping it earns a relic
  (start a draft ahead, thorns, a free reroll...). Carry one into the night — two with
  the Reliquary Chain.
- **A finishable story**: clear Castle Vane as the Hollow King and choose how the curse
  ends. Two endings, and the camp remembers which you chose.
- **Layered synthesized music** that darkens with the horde, procedural SFX, generated
  pixel art throughout (Pixel Lab + per-asset QA gates).

## Documentation

| File | What it is |
|---|---|
| `GAME_OVERVIEW.md` | The creative identity: premise, tone, heroes, the horde, visual spec |
| `DEVELOPMENT_PLAN.md` | The phased roadmap the project was built against |
| `ENGINE_RECOMMENDATION.md` | Why Godot 4, and the horde architecture doctrine |
| `docs/ABILITIES.md` | The no-overlap registry: weapons, passives, evolutions, relics |
| `docs/ASSET_PIPELINE.md` | The Pixel Lab art pipeline and QA gates |
| `docs/NIGHT_LOG.md` | The development log, block by block |
| `SETUP.md` | Zero-to-phone walkthrough (Godot install, Android deploy) |
| `IDEAS.md` | Scope-creep parking lot |

## Running locally

1. Install [Godot 4.4+](https://godotengine.org/download) (standard, not .NET)
2. Open `project.godot`, press **F5**

## Project layout

- `scenes/` + `scripts/` — engine scenes and code; `scripts/weapons/` is the weapon framework
- `data/` — ALL game content as JSON (characters, weapons, enemies, nights, relics, story)
- `assets/` — generated pixel art, icons, synthesized music, fonts (OFL)
- `autoload/` — `game.gd` (state/routing/saves), `sfx.gd`, `music.gd`

## QA

Headless CI boots every scene on each push before deploying. A Playwright suite plays
full runs against the deployed build (`?stage=qa` swaps in a 30-second test night;
`?stage=<id>` and `?hero=<id>` URL overrides exist for every night and hero).
