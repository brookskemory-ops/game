# Development Plan

**Working title:** *(TBD — medieval horde-survival roguelike)*
**Genre:** 2D narrative horde-survival roguelike (Vampire Survivors × Megabonk)
**Platform:** Mobile-first (Android first for testing, iOS at release), portrait or landscape TBD in Phase 1
**Engine:** Godot 4 (see `ENGINE_RECOMMENDATION.md`)
**Team:** Solo dev + AI walkthrough support

---

## 0. The Vision (write it once, defend it forever)

> You are one of a band of medieval survivors — knight, plague doctor, poacher, heretic monk —
> each with their own weapon, their own curse, and their own story. Every night the horde comes.
> Survive the night, learn who you are, unlock who's next.

### Design pillars (every decision gets tested against these 4)

1. **The horde is the spectacle.** Hundreds of enemies on screen, silky on a mid-range phone.
2. **Characters are the content.** Each hero plays differently AND tells a story. Roster = replayability = narrative delivery vehicle.
3. **One thumb.** Movement-only controls. If a feature needs a second input, it's wrong for this game.
4. **Every run ends with "one more."** Runs are 15–20 min, death always pays out meta-progress, and something new is always 1–2 runs away.

### What this game is NOT (the cut line — scope creep dies here)

- ❌ No multiplayer. ❌ No procedural story generation. ❌ No ball physics. ❌ No open world.
- ❌ No more than 3 stages at v1.0. ❌ No custom dialogue engine (use Dialogic).
- ❌ No real-money economy design until the game is fun without it.

---

## 1. How we attack it efficiently (the meta-strategy)

These five rules are why this plan works. Break them and the timeline doubles.

1. **Vertical slice before content.** Build ONE character, ONE weapon, ONE map, ONE enemy until the loop is *fun*. Content multiplication (more heroes/weapons/enemies) only starts after the fun is proven. Content on a bad loop is wasted work.
2. **Placeholder art until Phase 5.** Colored shapes and free asset packs (Kenney, itch.io CC0 medieval packs) all the way through systems development. Art is the LAST thing polished because it's the easiest to swap and the most tempting time-sink.
3. **Data-driven everything.** Characters, weapons, enemies, waves, upgrades, and story beats are all data files (Godot `Resource`s / JSON). After Phase 2, adding content should require zero new code. This is the single biggest efficiency multiplier.
4. **Phone-test every phase.** Every phase ends with a build running on a real mid-range Android device. Perf problems found late are rewrites; found early they're tweaks.
5. **Fixed exit criteria per phase.** Each phase below has a "Done when" checklist. Don't start the next phase until it's checked. This prevents the classic death spiral of ten half-finished systems.

---

## 2. The Roadmap

Estimates assume part-time solo dev (~10–15 hrs/week). Full-time roughly halves them.

---

### **PHASE 0 — Foundations** *(~1 week)*

Get the workshop set up so nothing ever blocks you mid-flow.

- [ ] Install Godot 4.x (latest stable), create project, commit to this repo
- [ ] Project settings: target resolution, pixel-art snapping (if pixel art), portrait vs landscape decision
- [ ] Android export pipeline working end-to-end: **empty project → APK → runs on your phone**
- [ ] Folder structure: `/scenes`, `/scripts`, `/data`, `/assets`, `/ui`
- [ ] Grab placeholder assets: 1 free medieval sprite pack, 1 UI pack, 3–4 CC0 sound effects

**Done when:** you can change one line, export, and see it on your phone in under 5 minutes.

---

### **PHASE 1 — The Naked Loop (find the fun)** *(~3–4 weeks)* ⭐ most important phase

One hero, one weapon, one enemy, one empty field. No menus, no story, no upgrades. The question this phase answers: **is walking around while auto-attacking a horde fun on a touchscreen?**

- [ ] Touch joystick movement (floating joystick, one thumb) + player scene
- [ ] One auto-firing weapon (e.g., a sword sweep or thrown dagger at nearest enemy)
- [ ] Enemy: pooled, physics-free, position-math movement toward player (per `ENGINE_RECOMMENDATION.md` §5)
- [ ] Spatial grid for hit detection; `MultiMeshInstance2D` (or batched sprites) for rendering
- [ ] Wave spawner: enemies spawn off-screen in escalating waves from a data file
- [ ] Player HP, enemy contact damage, death & instant restart
- [ ] XP gems drop → pickup magnet → level-up counter (no upgrade choices yet)
- [ ] **Stress test on phone: push enemy count until frames drop. Record the ceiling.** That number is your content budget forever.

**Done when:** 300+ enemies at 60fps on a mid-range phone, and a stranger picks up your phone and plays for 3 minutes without instructions.

---

### **PHASE 2 — The Systems Skeleton** *(~4–5 weeks)*

Turn the loop into a roguelike. Everything built here is **data-driven** — this phase builds the machines; Phase 3 just feeds them.

- [ ] **Upgrade system:** level-up pauses game → pick 1 of 3 cards (weapon upgrade / new weapon / passive stat). Data-driven upgrade pool with rarity weights
- [ ] **Weapon framework:** weapons as data (damage, cooldown, projectile count, pattern, evolution target). Build 3 mechanically distinct weapons to prove the framework (melee arc, projectile, aura)
- [ ] **Character framework (the Megabonk layer):** `CharacterResource` = stats, starting weapon, passive, sprite, unlock condition, story-arc id. Build hero #2 *only by writing a data file* — if that needs code, fix the framework
- [ ] **Run structure:** 15–20 min timer, escalating wave table from data, mini-boss at 10 min, final boss at timer end, victory/defeat screens
- [ ] **Meta-progression:** gold survives death → permanent upgrade shop (VS-style) + character unlocks
- [ ] **Save system:** unlocks, gold, settings, story flags
- [ ] Basic menu flow: title → character select → run → results → title

**Done when:** a full run (start → boss → results → shop → unlock → new character → new run) works with zero placeholder-crash, and adding a test weapon takes <30 min with no new code.

---

### **PHASE 3 — Content Expansion** *(~5–6 weeks)*

Feed the machines. Fixed content budget for v1.0 — do not exceed it, do not undercut it:

| Content | v1.0 Budget | Notes |
|---|---|---|
| Playable characters | **6** (8 max) | Each: unique starting weapon + passive + unlock + story arc |
| Weapons | **12** + 6 evolutions | Evolutions = weapon + matching passive at max level (the VS dopamine hook) |
| Passive items | **10** | Stat modifiers, pickup range, luck, etc. |
| Enemy types | **12–15** | ~5 per stage: swarmer, tank, ranged, fast, special |
| Mini-bosses / bosses | **6 / 3** | 1 final boss per stage |
| Stages | **3** | Village at night → Cursed forest → Castle of the Ash King |
| Run length | 15–20 min | Tuned in Phase 5 |

- [ ] Author all content as data files; sanity-pass balance (spreadsheet the DPS curves)
- [ ] Stage hazards / one gimmick per stage (e.g., burning houses, fog that hides enemies, castle arrow traps)
- [ ] Treasure chests, ground pickups (food, gold bag, rosary/screen-clear)
- [ ] Achievements/unlock conditions wired to the unlock framework

**Done when:** all 6 characters are playable and *feel* different, and every unlock in the game is reachable by playing.

---

### **PHASE 4 — Narrative Layer** *(~3 weeks, overlaps Phase 3)*

Story that respects the run structure: delivered in small bites, never blocking the action.

- [ ] Install **Dialogic**; wire it to the story-flag save system
- [ ] **Frame story:** the camp/hub between runs (character select IS the camp). Survivors gather at the fire; the roster grows as the story grows
- [ ] **Per-character arcs:** 3 beats each (intro on unlock → mid-arc after first boss kill → resolution after winning stage 3 with them). 6 characters × 3 beats = 18 short scenes. Keep each under 60 seconds
- [ ] **World mystery spine:** why does the horde come every night? Breadcrumbed via item descriptions, boss intro lines, and camp dialogue; answered by the final character's resolution
- [ ] In-run flavor: 1-line character barks on level-up/boss-spawn (text popup, skippable)

**Done when:** a player who reads everything understands the world; a player who skips everything loses nothing mechanically.

---

### **PHASE 5 — Polish & Juice** *(~4 weeks)* ⭐ this is where "great" happens

Polish is a *checklist*, not a vibe. Work through it top-down; each item is cheap alone, devastating together.

**Game feel (the juice list):**
- [ ] Hit flash (white flash shader on damaged enemies) + hit-stop (2–3 frame freeze on big hits)
- [ ] Damage numbers (pooled, batched)
- [ ] Screen shake (subtle, scaled to impact) + haptic pulse on level-up/boss/death
- [ ] Death effects: enemies pop with particles + gem burst, never just vanish
- [ ] Level-up fanfare: pause flash, sound sting, card slide-in animation
- [ ] XP-magnet vacuum feel, gold pickup ding escalation
- [ ] Boss intros: name banner + screen darken + roar

**Audio:**
- [ ] Music: 1 camp theme + 1 per stage + boss layer (licensed or commissioned; medieval-dark)
- [ ] SFX pass on EVERY interaction; round-robin variations on frequent sounds (hits especially)
- [ ] Audio ducking on level-up/dialogue

**Final art pass (only now):**
- [ ] Commit to one style (pixel art strongly recommended: cheap, fast, genre-appropriate, hides on mobile)
- [ ] Replace placeholders: heroes → enemies → bosses → stages → UI → portraits (in that order of visibility)
- [ ] Character portraits for dialogue (6 + narrator)

**Balance & tuning:**
- [ ] 10+ full playtest runs per character; kill dominant strategies, buff dead picks
- [ ] Difficulty curve: first run should end in death around minute 8–12; first win around run 5–8

**Done when:** a 30-second gameplay clip looks *shippable* with the sound on, and playtesters stop giving feedback about feel and start giving feedback about builds.

---

### **PHASE 6 — Mobile Hardening & Release** *(~3 weeks)*

- [ ] **Thermal soak test:** 3 consecutive full runs on a mid-range phone; fps must hold. Add graphics quality toggle (particle density, resolution scale) if needed
- [ ] Safe-area / notch / aspect-ratio pass on all UI; test tablet ratio
- [ ] Interruption handling: phone call mid-run, backgrounding, auto-pause, battery saver mode
- [ ] Onboarding: first-run 60-second guided intro (move, survive, level, die well)
- [ ] Settings: SFX/music sliders, haptics toggle, joystick position, damage-number toggle
- [ ] Store prep: icon, screenshots, 30s trailer (Phase 5 clip pays off here), store copy
- [ ] Closed beta (Google Play internal track) → 2 weeks of feedback → fix pass
- [ ] Android launch → stability window → iOS submission
- [ ] Monetization (only now, and only if desired): premium price OR cosmetic/supporter IAP. **No energy systems, no pay-for-power** — they kill this genre's reviews

**Done when:** crash-free rate >99.5% in beta and you'd hand the store link to a stranger without apologizing.

---

## 3. Timeline summary

| Phase | Focus | Est. (part-time) | Cumulative |
|---|---|---|---|
| 0 | Foundations | 1 wk | 1 wk |
| 1 | Naked loop / find the fun | 3–4 wks | ~5 wks |
| 2 | Systems skeleton | 4–5 wks | ~10 wks |
| 3 | Content expansion | 5–6 wks | ~16 wks |
| 4 | Narrative (overlaps 3) | +1–2 wks net | ~18 wks |
| 5 | Polish & juice | 4 wks | ~22 wks |
| 6 | Hardening & release | 3 wks | **~25 wks (~6 months)** |

Six months part-time to a polished v1.0 is aggressive but honest **if** the cut line in §0 holds.

---

## 4. Risk register (what kills projects like this)

| Risk | Likelihood | Mitigation |
|---|---|---|
| **Scope creep** | 🔴 High | The NOT list in §0. New ideas go in `IDEAS.md` for v1.1, not into v1.0 |
| **Phase 1 isn't fun** | 🟡 Medium | Cheapest possible failure — 4 weeks in with no content built. Iterate the feel or pivot the loop *before* Phase 2 |
| **Mobile perf wall** | 🟡 Medium | Architecture rules from day 1 + phone test every phase + Phase 1 ceiling number as hard budget |
| **Art time-sink** | 🟡 Medium | Placeholders until Phase 5; pixel art; commission portraits if drawing stalls |
| **Motivation dip (weeks 8–14)** | 🔴 High (solo dev law) | Phase exit criteria give visible wins; post a weekly clip publicly (builds audience AND accountability) |
| **Narrative bloat** | 🟢 Low | Hard cap: 18 scenes × 60s. Dialogic, not a custom system |

---

## 5. Immediate next actions (this week)

1. Install Godot 4 (latest stable) and create the project in this repo
2. Get the Android export → phone pipeline working (Phase 0's whole point)
3. Decide portrait vs landscape (recommendation: **landscape** — more horde on screen, matches genre expectations; revisit after Phase 1 phone tests)
4. Start Phase 1: touch joystick + one weapon + pooled horde

From here, each phase can be built step-by-step with a walkthrough — Phase 0 and 1 are exactly where to start.
