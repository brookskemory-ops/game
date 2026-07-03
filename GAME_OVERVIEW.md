# GRAVEWAKE — Game Overview

> *Working title. Alternates considered: **Nightfall Keep**, **Hollowmere**. "Gravewake" wins
> for now: it's one word, easy to say, and means both "the wake held for the dead" and
> "staying awake among graves" — which is literally the game.*

**Genre:** 2D horde-survival roguelike with narrative (Vampire Survivors × Megabonk)
**Platform:** Mobile (landscape), pixel art
**Tone:** Grim dark-fantasy world, human warmth — Darkest Dungeon dread + campfire gallows humor

---

## 1. The Premise

The Vale of Hollowmere is cursed. Every dusk, the great bell of Castle Vane tolls — no one
rings it — and the dead climb out of their graves. Every dawn, whoever survived drags the
bodies back.

A handful of survivors hold a fortified camp on the hill above the village. They are not
heroes. They are a poacher, a gravedigger, a plague doctor — ordinary people who happen to
still be alive, later joined by fallen legends with reasons to stay dead-adjacent. Each night,
one of them goes down into the vale to push the horde back. Each dawn, they learn a little
more about **why the bell tolls**.

The answer is the story spine, revealed piece by piece across the character arcs, and answered
completely by the final unlockable hero — because he's the one who caused it.

---

## 2. Tone Guide (how everything should be written)

**The world is grim. The people are not.**

- ✅ The vale is genuinely bleak: plague, cold, endless dead. Never undercut the *world*.
- ✅ The survivors cope with gallows humor. Dry, deadpan, warm underneath. Maud the
  Gravedigger complains that the dead "keep checking out early — no respect for craftsmanship."
- ✅ Humor comes **from character**, never from breaking the fourth wall or modern references.
- ❌ No quips *during* horror beats. When the story goes dark, let it be dark.
- ❌ No lore dumps. Nobody explains the world; they live in it. Mystery > exposition.
- **Register:** Darkest Dungeon's dread + the campfire warmth of a party in a bad spot.

---

## 3. The Heroes (the Megabonk layer)

Six at v1.0. The unlock ladder climbs from commoner to legend — the power fantasy and the
story both escalate. Each hero = unique starting weapon + signature passive + 3-beat arc
(intro on unlock → mid-beat after their first boss kill → resolution after clearing Stage 3
with them). Every resolution hands the player one piece of the mystery.

| # | Hero | Weapon | Signature passive | Unlock |
|---|---|---|---|---|
| 1 | **Wren, the Poacher** | Hunting bow (auto-shoots nearest) | *Light Foot* — +15% move speed while no enemy is within melee range | Starter |
| 2 | **Maud, the Gravedigger** | Shovel (wide melee sweep) | *Wages of Death* — elites & bosses drop +50% gold | Survive 10 minutes |
| 3 | **Corvus, the Plague Doctor** | Thrown vials (poison pools) | *Malpractice* — kill streaks restore HP | 500 kills in one run |
| 4 | **Brother Ansel, the Heretic Monk** | Burning censer (orbiting aura) | *Mortification* — +1% damage per 1% missing HP | Die 5 times (martyrdom) |
| 5 | **Ser Roland, the Disgraced Knight** | Greatsword (heavy arc + knockback) | *Bulwark* — flat damage reduction, −10% move speed | Defeat the Stage 1 boss |
| 6 | **The Hollow King** | Cursed blade (slain foes briefly rise and fight FOR you) | *Deathless* — cannot heal naturally; leeches life on kill | Clear Stage 3 with any hero |

### Story hooks (3 beats each)

- **Wren** — poached to feed a starving village; now the village is trying to eat *him*.
  Resolution: learns the first risen came from the castle crypts, not the churchyard.
- **Maud** — knows every grave in the vale by name. Beat 2: realizes certain graves are
  *empty from the inside* but the churchyard dead rose *last*, not first. The curse radiates
  from Castle Vane.
- **Corvus** — came to cure the plague; his notes prove the "plague" preceded nothing — the
  deaths and the curse have the same cause. It isn't a disease. It's a *summons*.
- **Ansel** — excommunicated for preaching that the church *knew*. Resolution: he's right —
  the priests sealed the castle chapel the night the bell first tolled, and never said why.
- **Roland** — the king's own knight, branded a coward for fleeing Castle Vane the night it
  fell. Beat 2: he didn't flee the horde. He fled *what the king was doing in the chapel.*
- **The Hollow King** — the king himself, still half-alive inside the curse he bought. His
  queen and daughter died of fever in a single week; he rang a bell that should never be rung
  and bargained for their return. Something answered. It returns *everyone*, every night,
  forever. His arc is the ending: the player chooses how the curse — and he — is put to rest.

---

## 4. The Horde (the restless dead)

Undead-only keeps silhouettes readable in pixel art and gives a coherent bestiary with
headroom. ~5 enemy types per stage, escalating:

| Stage | Setting | The dead there |
|---|---|---|
| 1 — **Hollowmere Village** | Burning cottages, mud lanes, the churchyard | Shamblers (villagers), Gnawers (fast dogs), Tolling Men (bell-headed elite), plague husks that pop |
| 2 — **The Wailing Forest** | Fog, black trees, drowned creek | Wights, hanged men (drop from trees), bone stags, will-o'-wisps that buff other dead |
| 3 — **Castle Vane** | The court of the Hollow King | Risen knights (shielded), crypt archers, the sealed chapel's choir, courtiers |
| Bosses | 1 per stage | The Sexton (St.1) → The Briar Queen (St.2) → **The Thing in the Chapel** (St.3, final) |

---

## 5. Core Loop (recap — full detail in `DEVELOPMENT_PLAN.md`)

1. **Camp (hub):** pick a hero at the campfire (character select IS the camp — story scenes
   happen here), spend gold on permanent upgrades.
2. **The night (a run, 15–20 min):** one thumb moves the hero; weapons fire themselves.
   Kill → XP gems → level up → pick 1 of 3 upgrades → build snowballs → mini-boss at 10:00 →
   stage boss at timer's end.
3. **Dawn:** win or die, gold and unlock progress persist. New heroes, weapons, and story
   beats are always 1–2 runs away.

---

## 6. Visual Identity

- **Pixel art**, base resolution **640×360** (16:9, integer-scales to 720p/1080p).
- **Palette:** near-black blues and mud browns, lit by warm torchlight oranges and the cold
  white of the moon — the two light temperatures are the visual signature.
- **Silhouette-first characters:** every hero and enemy must be identifiable in pure black
  shape (poacher's hood + bow, gravedigger's shovel, doctor's beak, monk's censer chain,
  knight's tower profile, king's broken crown).
- **The horde reads as texture,** the hero reads as a beacon: heroes get rim-light and higher
  contrast than any enemy.
- UI: parchment + iron; dialogue portraits in a woodcut style (Ideogram-generated, see
  `docs/ASSET_PIPELINE.md`).

---

## 7. What ships in v1.0 (contract with ourselves)

6 heroes · 12 weapons + 6 evolutions · 10 passives · ~15 enemy types · 3 stages · 3 bosses +
6 mini-bosses · 18 story scenes (60s max each) · 15–20 min runs.
Anything beyond this goes to `IDEAS.md` for v1.1. See the cut line in `DEVELOPMENT_PLAN.md` §0.
