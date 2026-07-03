# ABILITIES — The No-Overlap Registry

Every weapon and passive in VIGIL must occupy a **distinct mechanical niche**. This file is
the registry that enforces it. **The rule: before adding or changing an ability, check its
row here — if its (Delivery × Targeting) cell or its scaling identity collides with an
existing one, redesign it.** Two abilities that feel the same are one ability plus bloat.

## 1. The 12 weapons (v1.0)

Niche = Delivery method × Targeting rule × Damage profile. No two weapons share a cell.

| # | Weapon | Hero tie | Delivery | Targeting | Damage profile | Scaling identity (levels lean into…) | Built-in weakness |
|---|---|---|---|---|---|---|---|
| 1 | **Hunting Bow** | Wren (start) | Projectile, straight | Nearest enemy | Medium single-hit, pierces 2 | More arrows, more pierce | Weak when fully surrounded |
| 2 | **Iron Shovel** | Maud (start) | Melee arc | Facing (move direction) | Medium burst + knockback | Wider arc, stronger knockback | No reach; must face the threat |
| 3 | **Plague Vials** | Corvus (start) | Lobbed zone (pool) | Densest cluster | Low DoT over area, lingers | Bigger pools, longer linger | Slow kill; no burst, no knockback |
| 4 | **Burning Censer** | Ansel (start) | Orbiting bodies | Self (orbit) | Constant contact ticks | More orbs, wider orbit | Can't aim it at all |
| 5 | **Greatsword** | Roland (start) | Heavy frontal cleave | Facing, slow wind-up | Very high burst + heavy knockback | Bigger cleave, armor-shred | Long cooldown gaps between swings |
| 6 | **Cursed Blade** | Hollow King (start) | Summon (thrall) | On-kill trigger (a weak point-blank lash starts the killing) | Converts slain foes to 6s allies | More thralls, longer service | Feeble until the court assembles |
| 7 | **Throwing Axes** | — | Tumbling arc projectile | Random directions | High single-hit, falls short/long | More axes, bigger tumble | Unreliable — rewards repositioning |
| 8 | **Ballista Bolt** | — | Line shot, infinite pierce | Facing, long charge | Huge damage down one lane | Faster charge, wider bolt | A single narrow line |
| 9 | **Warding Bell** | — | Nova pulse (ring) | Self, radial | Low damage, strong push-back | Bigger ring, harder push | Crowd control, not a killer |
| 10 | **Falcon Companion** | Wren's arc | Seeker (flies itself) | Farthest / elite first | Medium repeated strikes | Faster hunts, bleed on elite | One target at a time |
| 11 | **Pilgrim's Chain** | — | Thin long lash | Alternating left/right | Fast medium line hits | Longer reach, faster lash | Only ever horizontal |
| 12 | **Reliquary of the Unquiet Saint** | — | Aura (steady field) | Self, uniform circle | Very low constant ticks + slow | Wider field, stronger slow | Never spikes; pure attrition |

**Coverage check** — every archetype is covered exactly once: straight projectile (1),
melee arc (2), thrown zone (3), orbit (4), heavy cleave (5), summon (6), random chaos (7),
line pierce (8), radial push (9), seeker (10), lash (11), aura (12). Slots for the DLC/v1.1
list live in `IDEAS.md`, and they must pass the same test.

## 2. The 10 passives

Each passive touches **exactly one stat** no other passive touches.

| Passive | Effect | Evolution catalyst for |
|---|---|---|
| **Whetstone** | +15% damage | Greatsword |
| **Fleet Boots** | +10% move speed | — |
| **Oaken Shield** | Flat −1 per contact tick (armor) | — |
| **Hawk's Eye** | +20% range, +10% crit | Hunting Bow |
| **Gravedust** | +25% gold | Iron Shovel |
| **Bad Humours** | +30% effect duration | Plague Vials |
| **Penitence** | +20% aura & orbit area | Burning Censer |
| **Hourglass** | −10% cooldowns | Cursed Blade |
| **Iron Rations** | +20 max HP, slow regen | — |
| **Lodestone** | +30% pickup radius | — |

## 3. The 6 evolutions (max weapon + its catalyst passive → boss chest)

| Evolution | From | What changes |
|---|---|---|
| **Widowmaker** | Hunting Bow + Hawk's Eye | Arrows pierce everything; crits ricochet to a new target |
| **Sexton's Spade** | Iron Shovel + Gravedust | Swings raise brief tombstone walls that block the horde |
| **The Miasma** | Plague Vials + Bad Humours | Pools merge into one roaming plague cloud that follows the fight |
| **Halo of Cinders** | Burning Censer + Penitence | Second, counter-rotating ring; orbs leave ember trails |
| **Oathkeeper** | Greatsword + Whetstone | Cleave becomes a full-circle shockwave slam |
| **Crownsorrow** | Cursed Blade + Hourglass | Thralls persist until death — and detonate when they fall |

## 4. Character starting kits (uniqueness ladder)

Each hero = one signature weapon + one signature passive **not available in the general
pool while playing them** (so their identity can't be replicated by another hero's build):

| Hero | Starting weapon | Signature passive |
|---|---|---|
| Wren | Hunting Bow | *Light Foot* — +15% speed while unthreatened |
| Maud | Iron Shovel | *Wages of Death* — elites drop +50% gold |
| Corvus | Plague Vials | *Malpractice* — kill streaks heal |
| Ansel | Burning Censer | *Mortification* — +1% damage per 1% missing HP |
| Roland | Greatsword | *Bulwark* — flat damage reduction, −10% speed |
| Hollow King | Cursed Blade | *Deathless* — no natural healing; leech on kill |

Signature passives follow the same one-stat rule against the general passive pool
(Light Foot is conditional speed vs Fleet Boots' flat speed — different niche; Bulwark is
percentage reduction vs Oaken Shield's flat tick armor — different niche).

## 5. Implementation contract

- Weapons are JSON in `data/weapons/` + a small script extending `scripts/weapons/weapon.gd`
  implementing one `_try_fire()`. The JSON carries a `niche` field naming its row here.
- Passives are pure stat modifiers in data (Phase 2) — never bespoke logic per passive.
- When Phase 2's upgrade draft is built, the pool must never offer two weapons from the same
  Delivery family in one draft of three (small quality rule that keeps choices interesting).

## 6. The 3+3 rule (v0.14)

A build is **3 weapons + 3 keepsakes, no more** (`Player.MAX_WEAPONS` /
`Player.MAX_PASSIVES`). Once three distinct keepsakes are held, drafts only offer
deepening those three. Evolutions remain reachable by design: a weapon and its catalyst
fit inside 3+3. The HUD build tray (under the HP bar) shows all six slots.
