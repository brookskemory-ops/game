# VIGIL

> *Hold the night.*

A medieval horde-survival roguelike (Vampire Survivors × Megabonk) with unique heroes and a
story about why the dead rise in the Vale of Hollowmere. Mobile-first, 2D pixel art,
built in Godot 4.

## ▶️ Play the latest test build

**https://brookskemory-ops.github.io/game/**

Every push to the dev branch auto-builds and deploys there (see
`.github/workflows/web.yml`). Works on desktop and phone browsers — on desktop use arrow
keys or click-drag; on a phone just drag your thumb.

## Documentation

| File | What it is |
|---|---|
| `GAME_OVERVIEW.md` | The creative identity: premise, tone, heroes, the horde, visual spec |
| `DEVELOPMENT_PLAN.md` | The 6-phase roadmap with exit criteria and content budgets |
| `ENGINE_RECOMMENDATION.md` | Why Godot 4, and the horde architecture doctrine |
| `docs/ABILITIES.md` | The no-overlap registry for all weapons & passives |
| `docs/ASSET_PIPELINE.md` | Pixel Lab + Ideogram AI art pipeline |
| `SETUP.md` | Zero-to-phone walkthrough (Godot install, Android deploy) |
| `IDEAS.md` | Scope-creep parking lot |

## Running locally

1. Install [Godot 4.4+](https://godotengine.org/download) (standard, not .NET)
2. Open `project.godot`, press **F5**

## Project layout

- `scenes/` + `scripts/` — engine scenes and code; `scripts/weapons/` is the weapon framework
- `data/` — ALL game content as JSON (characters, weapons, enemies, waves): content is data
- `assets/` — fonts (OFL), later sprites/audio; placeholders are generated procedurally in code
- `autoload/game.gd` — global singleton (scene routing, data loading)
