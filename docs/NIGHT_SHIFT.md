# NIGHT SHIFT — Autonomous Overnight Work Plan

The standing orders for the overnight session(s). Work proceeds top-to-bottom through the
work packages. **Every package ends with its own verification gate — nothing ships
unverified.** Progress is logged in `docs/NIGHT_LOG.md` as work happens, so the morning
review is one file.

## Ground rules (apply to every package)

1. **One package = one or more commits, pushed, CI green, live link verified** before the
   next package starts. Never leave the deployed game broken overnight.
2. **Playwright is the QA hand**: after every deploy, the headless-browser probe must pass
   (boot → camp → run → drag-move → screenshot review). Screenshots get *looked at*, not
   just taken.
3. **Data-driven or it doesn't happen**: new content goes in `data/`, never hardcoded.
4. Anything cut or deferred gets a line in `IDEAS.md` or the log — no silent drops.
5. If something can't be fixed in ~3 attempts, log it, revert to last good state, move on.
6. Pixel Lab spend: **check `GET /v1/balance` before any generation.** If the account is
   unfunded, produce generation *manifests* instead of images (see WP4) — never block.

---

## WP1 — v0.5.0 "The Survivors Gather" (the big feature block)

**A. The camp shop (gold sink).**
- `data/shop.json`: permanent upgrades with escalating costs — Vigor (+10 max HP ×5),
  Whetting (+5% damage ×5), Haste (+4% speed ×3), Fortune (+10% gold ×3), Reach
  (+10% pickup ×3), Mercy (revive once per run, ×1, expensive).
- Shop panel at the camp (UITheme cards, same visual language). Purchases persist in the
  save; `player.setup()` applies them as base-stat modifiers before signature passives.
- HUD treasury already exists; camp treasury label updates on purchase.

**B. Heroes 3 & 4 (their weapons already exist — data + sprites + unlocks only).**
- **Corvus, the Plague Doctor**: Plague Vials start. Signature *Malpractice* — kills within
  a 3s streak restore 1 HP each. Unlock: 300 kills in a single night.
- **Brother Ansel, the Heretic Monk**: Burning Censer start. Signature *Mortification* —
  +1% damage per 1% missing HP. Unlock: die 5 times (lifetime; add `deaths` to save stats).
- New ASCII sprites (beaked plague mask; tonsured monk with censer chain), roster order:
  wren, maud, corvus, ansel.
- Save gains lifetime stats: `{deaths, total_kills, nights_survived}`.

**C. First story beats (the narrative layer begins).**
- `data/story/vignettes.json`: 4 hero-intro vignettes (3–5 lines each, tone guide from
  GAME_OVERVIEW.md §2 — grim world, warm people, no lore dumps).
- On unlock: vignette overlay at the camp (parchment panel, tap to dismiss). Tapping a
  hero's portrait at camp replays theirs.

**D. Procedural SFX (no external assets — synthesized `AudioStreamWAV` at boot).**
- A small synth helper (square/noise/decay envelopes): arrow loose, hit thock, kill pop,
  gem chime (rising), coin clink, level-up sting, hurt thud, bell toll (deep + long),
  boss death knell, UI tap.
- Wire volume to `Game.settings.sfx_volume`; add a mute toggle to the pause menu.
- Keep it *quiet and dry* — placeholder character, not annoying.

**Gate:** full Playwright pass; buy a shop upgrade and verify it applies + persists across
reload; verify both new heroes' cards, unlock hints, and (via a QA save) their weapons.

---

## WP2 — QA harness + full sweep

- **`data/waves/qa.json`**: 45-second stage (boss at 0:30) so full-run flows are testable.
  Loaded only when the URL has `?stage=qa` (read via `JavaScriptBridge` on web, ignored on
  native). This is the key that unlocks automated full-run testing.
- Playwright suite (`scratchpad`, not shipped): boot → camp → select hero → move in all 4
  directions → survive to boss → win → results → camp → **reload page → save persisted**.
  Also: draft appears on level-up and picking each option type works; pause/resume;
  abandon run; joystick releases cleanly when menus open (the tonight-bug, as a regression
  test).
- **Layout sweep**: screenshots at 844×390 (phone), 640×360 (min), 1024×768 (tablet),
  1920×1080 (desktop) for title/camp/run/draft/results — reviewed for overlap/clipping,
  fixes applied.
- **Perf probe**: QA stage variant with heavy waves; measure frame times via JS
  `requestAnimationFrame` deltas at ~300, ~500, ~700 enemies; record the ceiling in the log
  (this is the "content budget" number from DEVELOPMENT_PLAN Phase 1 we still owe ourselves).
- Findings → fixed or logged; summary table in `docs/QA_LOG.md`.

---

## WP3 — Genre research pass (WebSearch/WebFetch; skip gracefully if blocked by proxy)

Targets: Vampire Survivors (mobile port UX + evolution rules), Brotato (draft/shop pacing,
character gimmicks), Megabonk (unlocks/meta pacing), Halls of Torment (abilities & bosses),
Death Must Die (god-boon drafts), 20 Minutes Till Dawn (short-run pacing — closest to our
5-min nights).

For each: what their level-up draft offers, run length & difficulty curve, meta-progression
prices, what makes weapon choices *feel* distinct. Output: `docs/RESEARCH_NOTES.md` —
**each note must end in a concrete actionable for VIGIL** (balance number, UX change, or
backlog item), not trivia.

---

## WP4 — Art pipeline (STRICTLY conditional on Pixel Lab credits)

1. Check balance. **If $0.00:** write `docs/asset_manifest.md` — the complete generation
   plan: every sprite (4 heroes, 4+ enemies, 2 bosses, pickups, 6 portraits), exact pixel
   sizes, animation lists (idle 2f, walk 4f, attack 2f), style parameters, and per-asset
   prompts honoring the palette + silhouette rules (GAME_OVERVIEW §6). Result: funding the
   account makes generation a same-day, zero-thought task. **Do not generate. Move on.**
2. **If funded:** style-lock first (Wren until approved-quality per the silhouette test,
   parameters logged to `docs/asset_log.md`), then batch-generate per manifest, QA each
   sprite (palette conformity, silhouette readability at 1×, size correctness), integrate
   via an `AnimatedSprite2D` pipeline with the procedural sprites as automatic fallback.
   Animation QA: every animation viewed in a Playwright screenshot sequence before merge.

---

## WP5 — v0.6.0 "Old Oaths" (evolutions + juice + balance)

- **Weapon evolutions** (docs/ABILITIES.md §3): Sexton drops a **reliquary chest**; opening
  it evolves a max-level weapon whose catalyst passive is held. Implement **Widowmaker**
  (bow: pierce-all + ricochet crits) and **Halo of Cinders** (censer: counter-rotating
  second ring + ember trails). Chest UI beat: slow-open, big reveal toast.
- **Juice pass**: 2-frame hit-stop on heavy hits, gem-vacuum on level-up (all gems fly in),
  boss intro screen shake + darken, evolution fanfare.
- **Balance pass** using WP2's perf/pacing data + WP3 research: XP curve, wave table,
  boss HP, shop prices. Deltas logged with reasoning in `docs/QA_LOG.md`.

---

## WP6 — Morning handoff

- `docs/NIGHT_LOG.md` finalized: what shipped (with version tags), what was found/fixed in
  QA, research takeaways, art status, open questions **max 5** for the user.
- `DEVELOPMENT_PLAN.md` checkboxes updated to reflect reality.
- Final CI green + live-link probe + a fresh set of screenshots in the log.
- Everything committed and pushed. Nothing local-only.

## Priority if time runs short
WP1 > WP2 > WP5-evolutions > WP3 > WP4-manifest > WP5-balance. Quality gates are never the
thing that gets cut.
