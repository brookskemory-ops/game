# NIGHT LOG — Overnight Shift Report

Running log of the autonomous night shift (plan: docs/NIGHT_SHIFT.md). Newest at the bottom.
**Morning summary lives at the top once the shift ends.**

*(morning summary placeholder — filled in at WP6)*

---

## Shipped versions

### v0.5.0 "The Survivors Gather" (WP1) ✅
- WARES shop at the camp: 6 permanent upgrades incl. Mercy (once-per-night revive with
  2.5s flickering invulnerability); purchases persist and apply at run start
- Heroes 3 & 4: **Corvus** (Plague Vials, Malpractice kill-streak healing, unlock: 300
  kills in one night) and **Brother Ansel** (Burning Censer, Mortification missing-HP
  damage, unlock: 5 lifetime deaths)
- Story vignettes at the campfire: 4 hero tales, shown on unlock, replayable
- Procedurally synthesized SFX (13 sounds, zero assets), sound toggle in pause, settings
  persisted; lifetime stats (deaths / total kills / nights survived) in the save

### QA harness (WP2, partial) ✅
- `?stage=qa` loads a 30-second night (data/waves/qa.json) on web builds only
- Playwright suite plays full runs blind: boot → camp → shop → hero select → movement in
  all directions → drafts → death/results → camp → full page reload persistence check,
  while capturing every GDScript runtime error from the console

## QA findings (all fixed same night)

| Finding | Severity | Fix |
|---|---|---|
| Pixelify Sans 'fi' ligature corrupt — "fire" rendered "Are" | High (text everywhere) | FontVariation with liga disabled |
| Shop pips used ●/○ glyphs the font lacks (boxes) | Medium | Plain "n/m" digits |
| Focus ring highlighted a LOCKED hero card | Low | Buttons FOCUS_NONE (touch game) |
| My ligature fix used a static TextServer call → HUD crash | High | **Caught by CI boot validation before deploy** — routed via TextServerManager |
| QA stage too brutal for the blind driver (died 0:17) | Test-only | Retuned qa.json, boss at 0:30 |
| Pixelify '5' glyph reads as 'S'/'8' at small sizes | Cosmetic | Logged; revisit if players misread prices |

**Zero script errors** in the full simulated night on the v0.5.0 build.

## Infrastructure learnings
- GitHub Pages deployments rate-limit (~10/hour): deploy job now retries twice with
  backoff (120s/240s). Two transient failures self-healed since.
- CI cadence discipline: batch commits per work package; every push costs a deploy slot.

## Research (WP3) ✅
docs/RESEARCH_NOTES.md — 6 games, every note ends in an actionable. Headlines:
"the bell is our chest" (map VS's reward beats onto our bell framing), 5-minute nights are
a mobile *feature*, meta should eventually buy options not just stats, elites must drop
excitement (scroll pickup idea → backlog).

## Art (WP4) ✅ generation+portraits; world sprites awaiting approval
- Free signup generations confirmed working; 10 generations spent, 8 assets approved
  (2 retries: Corvus needed his beak spelled out; Gnawer needed "bare bones only")
- **Hero portraits are live** on camp cards + vignettes (procedural fallback retained)
- Monster art staged in assets/sprites/generated/ — **decision for the morning:** approve
  the art direction and I'll integrate world sprites (needs sprite-scale + camera retune)
- All parameters logged in docs/asset_log.md for style-consistent future batches
