# BALANCE — measured, not guessed

Balance changes in VIGIL are grounded in measurement, not vibes. This file
records the method and the last reading so the next tuning pass starts from data.

## The instrument (`?debug=1`)

On web builds, `?debug=1` makes the HUD publish live state to `window.__vigil`
(~5 Hz): `{t, alive, kills, level, hp, boss}`. Automated Playwright probes read
exact numbers instead of scraping pixels. Gated, cached, web-only — real players
never touch it. See `Game.debug_telemetry()` + `HUD._push_telemetry()`.

Probe scripts live in the session scratchpad (not committed):
- `balance_probe.mjs` — samples the horde curve + survival across difficulties.
- `weapon_dps_probe.mjs` — per-weapon **kill-rate** on stage1/normal.

## Method: per-weapon kill-rate

Boot `?stage=stage1&hero=wren&weapon=<id>&debug=1`, stand still, let the horde
gather, then measure `kills / elapsed` over a fixed window (auto-dismissing
level-up drafts so the clock keeps running). Standing still holds enemy exposure
constant so the numbers are apples-to-apples.

This is a deliberate **worst case**: one weapon, no movement, no other slots,
often on the "wrong" hero. It rewards AoE/space-making weapons and punishes
single-target/slow/defensive ones — exactly the axis the niche doctrine
(`ABILITIES.md`) varies along. So absolute kill-rate ranks weapons by *how much
they carry a surrounded, standing player*, not by overall power in a real build.

## Last reading (v1.5, stage1 / normal)

| kills/s | weapon | read |
|---|---|---|
| 2.42 | Reliquary aura | slow + aura buys the most survival |
| 2.20 | Throwing Axes | crowd chaos |
| 2.11 | Gallows Toll | telegraphed AoE (v1.4) |
| 1.87 | Greatsword | heavy cleave |
| 1.73 | Iron Shovel | arc + knockback |
| 1.50 | Plague Vials | DoT zone |
| 1.39 | Pilgrim's Chain | fast lash |
| 1.17 | Reaping Hook | returning throw (v1.4) |
| 0.91 | Fen-Fire | bouncing chain (v1.4) — **was low for a crowd weapon** |
| 0.89 | Cursed Blade | summon, feeble solo (by design) |
| 0.85 | Falcon | single-target seeker |
| 0.82 | Hunting Bow | Wren's baseline starter |
| 0.81 | Ballista | one narrow lane |
| 0.28 | Warding Bell | crowd control, not a killer (by design) |
| 0.00 | Burning Censer | very low ticks, Ansel's — ramps with his missing-HP passive |

**Conclusion: the roster is healthy.** The spread tracks niche, and the two
lowest are explicitly *not* killers. No blind buffs.

**One change made:** Fen-Fire sat lowest among the crowd-oriented weapons while
its whole pitch is "leaps through a crowd" — undertuned for its own niche. Nudged
`damage 14 → 16`, `falloff 0.80 → 0.85` so the first jump one-shots a shambler
and later jumps stay lethal (16 / 13.6 / 11.6 vs 14 / 11.2 / 9). Aim: mid-pack,
not top-tier.

## Horde density (stage1 / normal)

On-screen count builds fast — ~56 alive by 26s, ~90 by 32s on hard. The opening
is **not** thin; no thickening needed (an earlier hypothesis the data killed).

## The Deepening (v2.0 ascension curve)

Post-true-ending replay knob, 0..10, folded into the enemy-mods pipeline on top
of night + difficulty. Per level: enemy **hp ×(1 + 0.18·n)**, **damage ×(1 +
0.08·n)**, **speed ×(1 + 0.03·n)**; rewards **gold ×(1 + 0.15·n)**, **xp ×(1 +
0.10·n)**. At the cap (10): foes ~2.8× flesh, 1.8× bite, 1.3× pace for ~2.5×
gold / 2× xp — punishing but not a wall, and the reward curve keeps the run's
own power scaling roughly apace. Per-hero mastery grants a small flat edge
(+2% damage, +2 max HP per night won, capped at 5 tiers) so a well-walked hero
opens the deeper Deepenings with a real, earned head start.
