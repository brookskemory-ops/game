# Engine Recommendation

**Project:** A mobile-first, 2D **narrative horde-survival roguelike** — a fusion of
**Vampire Survivors** (auto-attack survival against hundreds of enemies) and **Megabonk**
(a roster of unique playable characters, each with signature weapons/passives and its own
playstyle), wrapped in a **medieval** theme with a **narrative layer**.

**No ball / rigid-body physics.** That element is dropped, which removes the single heaviest
technical requirement and widens our options.

---

## TL;DR — the pick

> **Build it in Godot 4.**

- **Godot 4 — primary recommendation.** Free and MIT-licensed (zero royalties, ever),
  first-class 2D, a beginner-friendly language (GDScript) that's easy to walk through, solid
  iOS + Android export, and it comfortably reaches Vampire-Survivors-scale enemy counts if you
  follow one architecture rule (see §5).
- **GameMaker — strong runner-up / safest bet for the genre.** Vampire Survivors *itself* was
  built in GameMaker, so it is the most proven engine for this exact core loop. Slightly less
  modern than Godot and its free tier is more limited, but you cannot pick a "wrong" tool here.
- **Unity — pick it later, only if** you prioritize maximum mobile scale, a huge asset store,
  and plug-in ads/IAP SDKs — at the cost of more complexity and a heavier toolchain.
- **Defold — honorable mention.** Best raw performance and battery life on mobile, tiny build
  sizes. Smaller community and fewer tutorials, so it's a worse fit for a "walk me through it"
  workflow.

**Bottom line:** Godot 4 gives you the best mix of *free*, *approachable*, *good on mobile*,
and *proven for 2D survivors-likes*. Start there.

---

## 1. Why the horde is the hard part

Everything glamorous about this game — the medieval art, the story, the roster of characters —
is comparatively *easy*. The thing that actually decides whether the game ships and runs on a
phone is this:

> Hundreds of enemies **plus** a stream of projectiles, all updating **every single frame**,
> on a device with a battery and a thermal limit.

That is the entire engineering problem. If you get the horde architecture right (§5), almost
any modern 2D engine works. If you get it wrong, no engine saves you. So choose the engine
around *this*, not around art or narrative.

---

## 2. What each candidate brings

- **Godot 4** — Open-source, 2D-native (it's not "3D with a 2D mode"), GDScript reads like
  Python, exports to iOS/Android, and has `MultiMeshInstance2D` + `Area2D` that are exactly
  what a horde game needs. Massive and growing community with survivors-like tutorials.
- **GameMaker** — Purpose-built for 2D action games; the genre's flagship (Vampire Survivors)
  runs on it. GML is simple. Weaker on modern data-driven content patterns and its licensing
  tiers are less generous than Godot's fully-free model.
- **Unity** — The most battle-tested mobile engine, with the deepest asset store and the best
  monetization/analytics SDKs. Its ECS/DOTS path can push absurd entity counts. Downsides:
  heavier editor, C# ceremony, and a trust/licensing history worth being aware of.
- **Defold** — Extremely lightweight and fast on mobile, Lua-scripted, tiny binaries and great
  battery behavior. The trade-off is a smaller ecosystem and thinner tutorial coverage.

---

## 3. Comparison at a glance

| Criterion | **Godot 4** | GameMaker | Unity | Defold |
|---|---|---|---|---|
| **Cost / royalties** | Free, MIT, no royalties | Paid tiers for export; limited free | Free tier; seat/licensing terms | Free |
| **Beginner-friendliness** | High (GDScript ≈ Python) | High (GML) | Medium (C#) | Medium (Lua) |
| **2D fit** | Excellent (2D-native) | Excellent (2D-only) | Good | Good |
| **Mobile performance** | Good–Very good | Good | Excellent | Excellent |
| **Horde-scaling ceiling** | High (with MultiMesh) | High | Highest (DOTS) | High |
| **Data-driven content (roster)** | Excellent (Resources) | OK | Excellent (ScriptableObjects) | Good |
| **Narrative tooling** | Excellent (Dialogic plugin) | Add-ons | Add-ons (Ink, Yarn) | DIY |
| **Ads / IAP SDKs** | Community plugins | Built-in options | Best-in-class | Limited |
| **Community / tutorials** | Very large, growing | Large | Largest | Small |
| **Proven for this genre** | Yes (many VS-likes) | **Yes (VS itself)** | Yes | Rare |

---

## 4. The recommendation and the reasoning

Choose **Godot 4** because it wins on the axes that matter most for *this* project and *your*
situation:

1. **Free forever, no royalties.** For a solo/indie roguelike this removes all financial risk.
2. **Truly 2D-native.** Less fighting the engine than a 3D-first tool set to 2D.
3. **Walk-through-friendly.** GDScript is close to Python; there's a large library of Godot
   survivors-like tutorials to follow step by step.
4. **Mobile export is solid** for iOS and Android.
5. **It scales to the horde** using the same technique the good VS-likes use (§5).

Pick **GameMaker instead** only if you'd rather stand on the exact toolchain that shipped
Vampire Survivors and don't mind the licensing tiers. Pick **Unity later** only if
monetization SDKs and maximum entity counts become the priority.

---

## 5. The one architecture decision that matters most (engine-agnostic)

This is bigger than the engine choice. **Do not give each enemy a physics body.** Hundreds of
colliding rigid bodies will melt a phone. Instead:

- **Move enemies with plain position math**, not the physics engine. Each frame: step toward
  the player. That's it.
- **Use a spatial hash / grid (or lightweight `Area2D` queries in Godot)** to answer "what's
  near me?" for hits and separation — never all-pairs checks.
- **Render the horde with batching / `MultiMeshInstance2D`** so hundreds of enemies cost a
  handful of draw calls, not hundreds.
- **Pool everything.** Pre-allocate enemies and projectiles and recycle them; never spawn/free
  at runtime during a wave.

Get these four right and the horde is a solved problem on any engine here. Get them wrong and
no engine will save you.

---

## 6. Unique characters as data (the Megabonk part)

Don't hand-code each character. Model a character as a **data resource** (in Godot, a custom
`Resource`; in Unity, a `ScriptableObject`):

```
Character:
  id, name, portrait
  base_stats: { hp, move_speed, damage, pickup_range, ... }
  starting_weapon: <weapon_id>
  passives: [ modifier, modifier, ... ]   # e.g. +15% attack speed, -10% hp
  unlock_condition: <flag or achievement>
```

The game reads these files; adding a new hero becomes "author one data file (+ sprite)," not
"write new code." This scales the roster cleanly and plugs straight into meta-progression
(unlocks, currency between runs) — the loop that makes Megabonk and VS-likes sticky.

---

## 7. Narrative on Godot

- Use the **Dialogic** plugin (a mature Godot addon) for dialogue, branching, portraits, and
  choices — no need to build a dialogue system from scratch.
- **Attach story beats to characters and unlocks:** each hero carries a short arc revealed
  through play and meta-progression, which is how you get "narrative" without fighting the
  procedural, run-based structure.
- **Keep story as data** (JSON / dialogue timelines) so runs stay randomized while the
  narrative frame is authored.

---

## 8. Mobile-specific gotchas

- **Battery & thermal throttling** are your real perf budget — a phone that hits 60fps for two
  minutes then throttles is a fail. Test long sessions, not just short bursts.
- **Draw-call budget** matters more on mobile GPUs; batching (see §5) is non-negotiable.
- **Controls are a gift here.** VS/Megabonk are movement-only with auto-attacks, which maps
  perfectly to a single touch joystick — no complex touch UI needed.
- **Screen sizes & safe areas.** Design UI for notches and a range of aspect ratios from day
  one.
- **Test on a real mid-range Android device early** — not just a flagship or the desktop
  editor. That's where entity counts get honest.

---

## 9. Suggested first steps (prototype milestones)

Do these in order; stop and stress-test before adding polish:

1. **Install Godot 4** and make one arena with a **touch-joystick player**.
2. Add **one weapon that auto-fires** at the nearest enemy.
3. Spawn a **small pooled horde** with cheap position-based movement toward the player.
4. Add a **second character that differs only by data** (§6) — proves the roster architecture.
5. **Stress-test enemy count on a real phone.** Push the number until it drops frames; that
   ceiling tells you your design budget before you build anything else.

Only after the horde holds up on a device should you invest in the medieval art pass, the
Dialogic narrative, and meta-progression.

---

### One-line answer
**Make it in Godot 4 (free, 2D-native, mobile-ready, beginner-friendly). GameMaker is the
proven fallback. Whatever you pick, the game lives or dies on keeping the enemy horde
physics-free and batched.**
