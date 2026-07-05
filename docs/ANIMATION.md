# ANIMATION — Pixel Lab character frames (the recipe that works)

Character walk/attack frames in VIGIL come from Pixel Lab's **`animate-with-text`**
endpoint, driven by `tools/gen_anim.py`. This file records what actually works,
because the naive path fails and it's easy to forget why.

## Why not the obvious approach
The old attempt called `generate-image-pixflux` twice and hoped for two frames of
the same creature. It returns a *different* creature each time — no coherence.
`animate-with-text` conditions **every frame on a reference image**, so the
design (colors, silhouette, gear) is preserved across the cycle. It also returns
**4 frames for 1 generation** — cheap.

Hard constraint: `animate-with-text` requires the image exactly **64×64** (our
sprite size). Frames come back 64×64 with transparent background.

## The recipe (found in the v1.6 C0 POC)
- **Heroes** (clear upright humanoids): `--preset hero` → image-guidance 8,
  text-guidance 7, `--action "walking"` / `"swinging a sword"`. Came out clean
  6/6 on the first pass.
- **Enemies** (varied creatures) are finicky: guidance 8 lets the design *drift*
  (a shambler grew bright-green arms); guidance 16 goes *noisy* (rainbow speckle).
  The sweet spot is `--preset enemy` → image-guidance 11, text-guidance 3, with a
  **gentle** action: `--action "taking slow steps forward"`.
- **NEVER** use `"walk cycle"` as the action — the model draws motion-blur swoosh
  arcs instead of legs. Enemies that carry a weapon (knight/archer/bell) are the
  most prone to baking in attack VFX; strong negatives help but some just won't
  cooperate.
- `--clean` despeckles stray pixels after generation.
- Always **visual-QA every set** (build a montage, eyeball coherence). Cherry-pick
  the clean frames; if a character won't hold, **fail soft** — that type keeps the
  procedural bob. A mixed roster is fine. (v1.6 shipped 6/6 heroes and 8/10 crowd
  enemies as real frames; shambler + risen_knight kept the bob.)

## How frames are wired in-game
- **Heroes** (`player.gd`): `assets/sprites/generated/side/<hero>_walk_0..3.png`.
  When present they fully replace the front↔side texture swap — one consistent
  side design, flipped for direction, gentle bob, no rotation/squash. Fallback:
  clean static sprite + bob.
- **Enemies** (`enemy_manager.gd`): `assets/sprites/generated/<sprite>_walk_0..N.png`,
  loaded per type with the same flip pipeline as the base sprite. A shared clock
  swaps each type's MultiMesh texture (`ENEMY_WALK_FPS`) — lockstep per type, one
  texture assignment per type per frame, so the 700/50ms budget is untouched.
  Two directions come from the existing velocity mirror.

## Cost
1 generation = 4 frames. v1.6's full animation pass (6 heroes × walk+attack + ~14
enemy attempts + retries) was well under 100 generations of the 5,000 quota.
