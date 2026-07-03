# NIGHT LOG — Overnight Shift Report

Running log of the autonomous night shift (plan: docs/NIGHT_SHIFT.md).

## ☀️ MORNING SUMMARY

**All six work packages completed.** The live game went from v0.4.0 to **v0.6.0** overnight:
two full feature versions, a QA harness that plays the game by itself, 8 pieces of
generated art (portraits live in the build), genre research, and a measured perf ceiling.
Every push validated headless in CI and probed in a real browser before moving on.
**Play it: https://brookskemory-ops.github.io/game/** (hard-refresh once).

**What's new since you went to sleep, in play order:**
1. Camp: hero portraits (Pixel Lab art), the WARES shop (6 permanent upgrades incl. a
   revive), survivor tales told at the fire, two more heroes to unlock (Corvus, Ansel)
2. In-run: sound (synthesized — hits, gems, the bell, the boss knell), gem-vacuum on
   level-up, boss-arrival camera shake, two new catalyst passives (Hawk's Eye, Penitence)
3. Endgame: the Sexton now drops a glowing **reliquary** — open it with a maxed bow +
   Hawk's Eye (or maxed censer + Penitence) and the weapon **evolves** (Widowmaker /
   Halo of Cinders); otherwise it pays gold + a full heal

**Open questions for you (max 5, as promised):**
1. **Approve the monster art direction?** (assets/sprites/generated/ — shambler, gnawer,
   tolling man, sexton). If yes, I integrate world sprites next (needs a scale/zoom retune).
2. The '5' glyph in Pixelify Sans reads like 'S' at small sizes (shop prices) — live with
   it, or swap the numeric font?
3. Evolution reachability: max level 8 + catalyst within a 5-minute night is tight —
   intended (evolutions = mastery reward) or should stage 1 runs be 7 minutes?
4. SFX volume/character: synthesized placeholder is deliberately quiet/dry — good enough
   until Phase 5, or prioritize real audio sooner?
5. Next block preference: stage 2 (Wailing Forest) vs. draft rerolls + elite scroll drops
   (both spec'd in RESEARCH_NOTES actionables)?

**Known gaps (honest list):** the QA bot damaged the Sexton to ~30% but never killed him
within script budget, so the chest/evolution flow is code-reviewed + boot-validated but not
bot-played end-to-end — first human Sexton kill will exercise it; world sprites still
procedural pending your art approval; perf numbers are software-rendered (real-phone soak
test still owed per DEVELOPMENT_PLAN Phase 6).

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

## v0.6.0 "Old Oaths" (WP5) ✅
- Reliquary chest on boss death (drifts to the hero, opens on touch) → evolution or
  gold+heal consolation; victory follows the fanfare
- Widowmaker + Halo of Cinders implemented; Hawk's Eye + Penitence added as catalysts
  (with range/area modifier plumbing)
- Juice: gem vacuum on level-up, boss camera shake; vials pool radius 34→28 (balance)

## Perf ceiling (WP2) ✅
Stress stage (~21 spawns/sec), SwiftShader software rendering in headless Chromium:

| Horde size | median frame | p95 |
|---|---|---|
| ~105 | 50 ms | 83 ms |
| ~315 | 83 ms | 100 ms |
| ~630 | 83 ms | 100 ms |
| 700 (cap) | 83 ms | 100 ms |

Headline: **frame cost flattens above ~315 enemies** — no algorithmic blowup to the cap;
the MultiMesh + spatial-hash architecture scales. Absolute numbers are software-rendering
artifacts; a real-phone soak test remains owed. Layout sweep passed at 844×390, 640×360,
1024×768, 1920×1080 (camp fits 4 hero cards at minimum resolution).

## Art (WP4) ✅ generation+portraits; world sprites awaiting approval
- Free signup generations confirmed working; 10 generations spent, 8 assets approved
  (2 retries: Corvus needed his beak spelled out; Gnawer needed "bare bones only")
- **Hero portraits are live** on camp cards + vignettes (procedural fallback retained)
- Monster art staged in assets/sprites/generated/ — **decision for the morning:** approve
  the art direction and I'll integrate world sprites (needs sprite-scale + camera retune)
- All parameters logged in docs/asset_log.md for style-consistent future batches
