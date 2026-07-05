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

---

## Day session addendum (v0.10.x → v0.11.0)

- **v0.10.0 "Alive at Night"**: generated moon + 6 scenery props (with the "moonlight
  paints moons" prompting lesson), side-profile stills for all 5 heroes, procedural walk
  gait. Frame-cycle animations failed the per-animation QA gate 3/3 — parked for the
  skeleton endpoint.
- **User-reported bug fixed**: all MultiMesh sprites rendered upside down (QuadMesh Y-up
  UVs in the 2D canvas). Every MultiMesh texture now passes through
  `PixelSprites.flipped_for_multimesh()`.
- **v0.11.0 "An Armory of Last Resorts"**: weapon registry complete (12/12) — Throwing
  Axes, Ballista Bolt, Warding Bell, Falcon Companion, Pilgrim's Chain, Saint's Reliquary;
  enemy slow system; Sexton's Spade + The Miasma evolutions (5/6 live); Gravedust +
  Bad Humours; draft family rule. QA bot picked the Reliquary live during verification —
  zero script errors.
- **Next**: Block B "The Court of the Hollow King" (stage 3, hero 6, Cursed Blade thralls,
  the final boss + story resolution), then Block C polish/v1.0-rc.

---

## v0.12.x addendum — "The Ground Beneath" (map tiles, moon cleanup, facing fix)

- **Generated ground shipped** for both stage themes, no TileMap: `GroundLayer` draws one
  world-anchored repeating 64px base quad (z -2) plus a deterministic decal scatter
  (160 decals, seed 777, dimmed). Cost is a handful of draw calls; the 50ms/700-enemy
  stress baseline held.
- **Base tiles took two passes.** v1 tiles passed the 3×3 seam sheet but read as blotchy
  repeating camouflage in-game. v2 = PIL rework: downscale-to-32 grain, brightness crush
  (×0.62–0.68), 55–60% blend toward a flat night color, re-seamed with the roll-blend.
  Verified in-game: graveyard and forest both sit darker/lower-contrast than every actor.
- **7 decals live** (graveyard: cobbles/bones/grave-dirt; forest: roots/moss/mushrooms/
  leaves). Puddle cut after 2 failed generations. 5/8 decals needed the "single isolated
  object, nothing else in frame" retry phrasing.
- **Mob moon cleanup (user report):** 4× audit found baked moon/orb artifacts on shambler,
  sexton, wight, hanged_man — all four regenerated clean with the anti-moon negative set.
  Tolling Man's bell glow and Briar Queen's petals kept as intentional.
- **Facing fix (user report):** gnawer art faces left natively — added per-type `flip_x`
  in enemies.json, mirrored at texture load so all art faces right and the runtime flip
  stays uniform. Hanged Man regenerated facing right.
- **Verified end-to-end:** CI green, QA suite zero script errors, reviewed in-game
  screenshots for graveyard + forest (`?stage=stage2` probe), seam-free while moving,
  persistence reload OK.
- **Next**: Block B "The Court of the Hollow King".

---

## Block B — "The Court of the Hollow King" (v0.13.0 → v0.13.3)

**The story is now finishable.** Castle Vane (stage 3), the sixth hero, the twelfth
weapon, the sixth evolution, the final boss, and the two-choice ending all shipped
and verified in-game.

- **Cursed Blade + Crownsorrow**: on-kill thralls (spectral, seek-and-strike, pooled
  in-weapon); evolution makes them persist and detonate. **QA found a real design
  brick**: pure on-kill means the solo starting weapon can never make the FIRST kill
  (probe: dead at 0:18 with 0 kills). Fixed with a weak point-blank lash that starts
  the killing — raise still takes the cooldown tick when a kill is waiting.
- **The Hollow King**: Deathless (heal() is a no-op; 1 HP leech per kill), unlocked by
  clearing Castle Vane. Portrait, world sprite, side profile all generated + QA'd.
- **Castle Vane bestiary**: risen courtiers (fodder), risen knights (flat plate armor
  in damage_slot), crypt archers (hold-distance AI + a new pooled enemy-bolt system +
  player.take_hit), chapel choristers (hymn pulse heals nearby dead, visible ring),
  and **The Thing in the Chapel** (2600 HP, 5-bolt volleys while advancing, courtier
  trickle) — every one verified alive on screen via Playwright probes.
- **Story resolution**: the Hollow King's tale; beating stage 3 AS him offers the
  final choice — break the bell or keep the vigil — two written epilogues, and the
  chosen epitaph permanently replaces the camp subtitle.
- **QA infrastructure grew**: ?hero=<id> URL override (bots can play locked heroes),
  qa3 castle test stage (10s night → probes reliably reach the boss), fleeing-bot
  pattern for boss capture.
- **For the Block C balance pass** (bot-run observations, not yet human-tuned):
  stage 3 opening was softened once already (courtier 1.0→1.4s); accumulated crypt
  archers produce heavy unavoidable-for-bots bolt rain — watch it in human playtests;
  boss volley (5×12) is lethal to a low-HP hero in one wave — possibly intended.

Verified: CI green on all four pushes; full qa_suite zero script errors; 6-card camp
layout fits 640px; castle ground/decals/props reviewed in-game; hollow-king and boss
probes clean.

---

## The Replayability Push (v0.13.4 → v0.15.0)

Shipped in one arc, per the user's direction: tight builds, hidden unlocks with a codex,
story-tied objectives, more maps, and an endless mode.

- **v0.13.4**: the "their tale"/post-victory freeze — the vignette PanelContainer was
  eating the closing tap (MOUSE_FILTER_STOP). Panels now PASS and carry the close handler.
- **v0.14.0 "Rites of the Vigil"**: ten-minute nights (all three stages retuned, elite
  events ~3:00/6:00/8:30) · the 3+3 build rule with a HUD build tray · 36 generated item
  icons (draft cards, tray, Ledger) · hidden weapons behind deeds + THE LEDGER codex
  (silhouettes + unlock hints, "the ledger grows" notices) · RITES (three data-driven
  archetypes: light_candles / slay_elite / stand_ground) rewarding RELICS (8, one carried
  per night, one hook each, docs/ABILITIES.md §7).
- **v0.15.0 "Many Nights"**: night modifier engine (hp/speed/gold/xp/spawn multipliers +
  fog) · CHOOSE THE NIGHT picker driven by _nights.json (a new map = one json + one index
  line) · four variant nights each carrying a rite + relic (Blood Toll, The Deep Mist,
  The Cold Court, The Bell's Echo) · THE LONG NIGHT endless mode (looping waves, the dark
  deepens every 3:00, elite storms every 5:00, deepest-count record in the picker).
- **QA infra note**: post-container-restart, headless screenshots intermittently wedge
  SwiftShader (probes now carry --disable-dev-shm-usage --disable-gpu-compositing and
  screenshot-timeout catches). NEVER `pkill -f chromium/pw-browsers` — it matches the
  harness's own process; anchor to `^/opt/pw-browsers/chromium`.
- **Verified**: CI green on all six pushes; full qa_suite zero errors on the final build;
  reviewed in-game: build tray + icons, Test-Light rite candle lit, night picker with
  lock hints, Deep Mist fog + shrine, Long Night count-up at 1:48 with 113 kills.

---

## Block C — "The Dawn" (v0.16.0 → v1.0-rc)

- **v0.16.0 "The Sound of the Night"**: four synthesized loops (numpy → WAV, tails
  crossfaded into heads), blended by a Music autoload — camp/night crossfade on routing,
  a danger layer that swells with the living horde, a boss layer that ducks the night
  under the bell. 1.5MB added; Music toggle in the pause menu.
- **v0.16.1 "The Scales Balance"**: archer bolt/wave tuning, an ember telegraph before
  the Thing's volleys, Deathless leech 1.5, Long Night escalation every 2:30 with
  numbered tiers, and the Reliquary Chain — WARES sells a second relic slot (carry list
  with automatic migration from the single-slot save).
- **v0.17.0 "First Night"**: save-persisted one-time hints (begin / move / draft /
  rite), a camp settings overlay, Restart-the-night in the pause menu, rite outcome on
  the results screen, and the unlocked survivors walking the title-screen road.
- **v1.0-rc "The Vigil Holds"**: save_version + a single migration hook, README rewritten
  as a landing page, and the full QA battery (suite + all-night boots + perf + layout)
  run against the final build. The release gate from here is the user's own playtests.

---

## Block D — "The Last Grave" (v1.6 → v2.0)

The biggest single expansion since launch — a fourth act, a seventh hero, weapon
evolutions for the v1.4 trio, two new meta layers, controller support, and the hero
attack swings held back in v1.6. Eleven work blocks, each shipped green.

- **Act IV "The Hollow Beneath"** (stage4, theme `crypt`): the abyss under Castle Vane
  where the curse began. Five animated crypt mobs (two new mechanics — a **blink**
  wraith that closes distance, a **leech** that heals off contact), a mid-boss (the Pale
  Prior) and the **true final boss** (the Unburied), a colder crypt music bed, and the
  **true ending** ("The Last Grave") beyond the Hollow King's bargain.
- **Thessaly, the Sin-Eater** (7th hero): a sustained tether weapon, **Devouring Grief**
  (channel-drain + lifesteal — a genuinely open niche), and *Communion*, a decaying
  kill-fuelled damage stack. Unlocked by the true end.
- **Weapon evolutions** for Fen-Fire → **Corpsefire**, Reaping Hook → **The Reaping**,
  Gallows Toll → **The Gallows** — closing the parity gap (they were the only draftable
  weapons without an evolution).
- **Meta: Medals + Codex** — 15 data-driven achievements over lifetime/run stats, a
  fireside MEDALS panel with live progress, a toast on unlock, and combat stats added to
  the browsable bestiary.
- **Meta: The Deepening + Mastery** — a stackable post-ending ascension (0..10, harder
  dead / richer spoils, folded into the enemy-mods pipeline) and a per-hero mastery track
  (a small permanent edge per night won), both persisted and surfaced at the camp.
- **Controller support** — left stick + D-pad movement, pad-gated menu focus navigation
  across camp / draft / pause / results, title-advance on any button, device-aware copy.
  Keyboard / mouse / touch untouched. (Clears the long-standing v1.2 task.)
- **Hero attack swings** — the six original heroes' Pixel Lab attack frames now play as a
  brief, rate-limited swing on fire, tuned by weapon heft, under the weapons' own VFX.
