# Research Notes — Genre References → VIGIL Actionables

Compiled during the night shift (docs/NIGHT_SHIFT.md WP3). Rule: every note ends in a
concrete actionable, or it doesn't belong here.

## Vampire Survivors (mobile port)

- Mobile VS is praised for **one-thumb portrait play**; landscape recommended only with a
  physical controller. Touch targets that mirror PC scaling read as *small* on phones.
  → **Actionable:** our draft cards / camp buttons must stay ≥ 44 px CSS on phones —
  verify in WP2's layout sweep at 390-width portrait if we ever add portrait; keep
  landscape-first but recheck button sizes on small screens.
- Limited choices per level-up make **chests** (multi-upgrade bundles) exciting.
  → **Actionable (WP5):** Sexton's reliquary chest should feel like a jackpot moment —
  slow-open animation, multiple rewards when possible, not just the evolution.
- Evolution rule (max weapon + catalyst passive + boss chest, applied automatically,
  predictable-but-uncertain timing) is THE aspirational mechanic loop.
  → **Actionable (WP5):** copy the structure exactly (docs/ABILITIES.md §3 already maps
  pairs); telegraph progress: when a weapon is maxed and catalyst held, show a subtle
  "ready to evolve" glint on the HUD.

## Brotato

- Wave-based structure (20s → 60s waves) with a **shop between waves**, reroll costs that
  escalate within a shop and reset each wave. Currency income deliberately exceeds spending
  capacity early so rerolls become the late-game gold sink.
  → **Actionable:** our single-run nights don't have between-wave shops, but the *reroll*
  idea maps to the draft: add a "reroll the draft (N gold)" button in Phase 3 — a gold sink
  that converts meta-currency into in-run agency. Log to IDEAS.md → promoted to backlog.
- Item tiers gated by wave number (T2 from wave 2, T3 from 4, T4 from 8) keeps early drafts
  simple and late drafts spicy.
  → **Actionable:** when the draft pool grows, gate rarer options by run-minute (e.g.
  evolut­ion-adjacent passives only after 2:00) — data field on the option defs.

## 20 Minutes Till Dawn

- Its identity vs VS: **shorter runs** + manual aim. The short-run framing ("survive 20
  minutes" vs 30) is considered a feature, not a cut — respects mobile session lengths.
  → **Actionable:** our 5-minute nights are a *strength* for mobile; keep stage 1 at ≤7
  minutes even at full difficulty; save 10-15 min runs for stage 3 / endgame.
- 21 upgrade *trees* of 84 upgrades give perceived depth from few systems.
  → **Actionable:** our per-weapon `_on_upgrade` levels are effectively micro-trees;
  surface them — draft cards for weapon upgrades should show WHAT the next rank does
  (already done via up_desc — keep it specific per level in Phase 3).

## Megabonk

- **Almost no permanent stat boosts**; meta-progression = unlocking tools, slots, rerolls,
  banishes — player *knowledge* is the real progression. Slow unlock cadence reads grindy
  at first, deep later.
  → **Actionable:** our WARES shop sells raw stats (fine for now), but the roadmap should
  shift later meta-purchases toward *options* (draft slots+1, banish, reroll, starting
  weapon choice) rather than ever-higher stat stacking — keeps runs skill-forward.
  Logged to IDEAS.md.
- "One more run" comes from feeling weak→god within minutes.
  → **Actionable:** audit our power curve in WP5 balance: by minute 4 of a good run the
  player should be *visibly* mulching the horde (projectile count, evolutions).

## Halls of Torment

- **600 quests** each granting tiny permanent bonuses (+0.3% XP) — an achievement web where
  everything feeds progression; abilities drop as scrolls from champions (in-run pickups),
  not only from level-ups.
  → **Actionable:** mini-boss (Tolling Man) should drop something *special* beyond gold —
  Phase 3: a scroll pickup granting a bonus draft. Cheap, thematic, makes elites exciting.
- Its differentiator is ARPG-style character stats depth on the VS chassis.
  → **Actionable:** not our lane — VIGIL's differentiator is *narrative* (hero tales, the
  bell mystery). Double down there instead; don't chase stat-sheet depth.

## Cross-cutting takeaways

1. **The bell is our chest.** VS's strongest loop beats (chest reveal, evolution) map onto
   our bell/boss framing — every "reward moment" should ring, toll, or glow.
2. **Session length is a mobile feature** — 5-minute nights are correct; market it.
3. **Meta should buy options, not just numbers** — plan the WARES v2 accordingly.
4. **Elites must drop excitement, not just gold.**

Sources: gamepressure.com, toucharcade.com, thegamer.com, pocketgamer.com (VS mobile);
brotato.wiki.spellsandguns.com, rogueliker.com (Brotato); steamcommunity.com,
gamingonlinux.com (20MTD); megabonk.org, fullcleared.com, technetbooks.com (Megabonk);
hot.fandom.com, softpedia.com, rogueliker.com (Halls of Torment);
vampire.survivors.wiki, pcgamesn.com, gamerant.com (VS evolutions).
