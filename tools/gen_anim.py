#!/usr/bin/env python3
"""Generate coherent character animation frames from a reference sprite via
Pixel Lab's `animate-with-text` endpoint.

Unlike the naive pixflux 2-frame approach (which returns a different creature
per call), this conditions every frame on the reference image, so the design is
preserved across the cycle. Endpoint requires exactly 64x64.

Usage:
  PIXELLAB_API_KEY=... python3 tools/gen_anim.py \
      --ref assets/sprites/generated/side/wren.png \
      --out /tmp/.../wren_walk --action "walking" \
      --desc "hooded ranger in green cloak and leather, dark fantasy" \
      --frames 4 --view side --direction east

Saves <out>_0.png .. <out>_{n-1}.png. Prints usage cost.
"""
import argparse, base64, json, os, sys, time, urllib.request, urllib.error

API = "https://api.pixellab.ai/v1/animate-with-text"


def b64(path: str) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode()


def _despeckle(path: str) -> None:
    """Clear near-transparent fuzz and floating single opaque pixels (the AI
    frames occasionally scatter stray specks around the sprite)."""
    try:
        from PIL import Image
    except ImportError:
        return
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    # 1) near-transparent -> fully transparent
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 40:
                px[x, y] = (0, 0, 0, 0)
    # 2) remove isolated opaque pixels (no opaque 4-neighbour)
    opaque = [[px[x, y][3] > 60 for y in range(h)] for x in range(w)]
    for x in range(w):
        for y in range(h):
            if not opaque[x][y]:
                continue
            nb = 0
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and opaque[nx][ny]:
                    nb += 1
            if nb == 0:
                px[x, y] = (0, 0, 0, 0)
    im.save(path)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ref", required=True, help="reference sprite PNG (64x64)")
    ap.add_argument("--out", required=True, help="output path prefix")
    ap.add_argument("--desc", required=True, help="character description")
    ap.add_argument("--action", required=True, help="action, e.g. 'walking'")
    ap.add_argument("--frames", type=int, default=4)
    ap.add_argument("--view", default="side",
                    choices=["side", "low top-down", "high top-down"])
    ap.add_argument("--direction", default="east")
    ap.add_argument("--neg", default="blurry, extra limbs, different character")
    ap.add_argument("--img-guidance", type=float, default=None)
    ap.add_argument("--text-guidance", type=float, default=None)
    ap.add_argument("--seed", type=int, default=0)
    # Presets carry the guidance recipe found in the C0 POC. Heroes (clear
    # upright humanoids) tolerate looser image guidance; enemies (varied
    # creatures) drift at 8 and go noisy at 16 — 11/3 with a gentle action is
    # the sweet spot. NEVER use "walk cycle" as the action for enemies: it
    # triggers motion-blur swoosh artifacts. Use "taking slow steps forward".
    ap.add_argument("--preset", choices=["hero", "enemy"], default=None)
    ap.add_argument("--clean", action="store_true",
                    help="despeckle: drop near-transparent fuzz + floating pixels")
    args = ap.parse_args()
    if args.preset == "hero":
        if args.img_guidance is None: args.img_guidance = 8.0
        if args.text_guidance is None: args.text_guidance = 7.0
    elif args.preset == "enemy":
        if args.img_guidance is None: args.img_guidance = 11.0
        if args.text_guidance is None: args.text_guidance = 3.0
    if args.img_guidance is None: args.img_guidance = 8.0
    if args.text_guidance is None: args.text_guidance = 7.0

    key = os.environ.get("PIXELLAB_API_KEY")
    if not key:
        print("PIXELLAB_API_KEY missing", file=sys.stderr)
        return 2

    body = {
        "image_size": {"width": 64, "height": 64},
        "description": args.desc,
        "action": args.action,
        "negative_description": args.neg,
        "reference_image": {"type": "base64", "base64": b64(args.ref)},
        "n_frames": args.frames,
        "view": args.view,
        "direction": args.direction,
        "image_guidance_scale": args.img_guidance,
        "text_guidance_scale": args.text_guidance,
        "seed": args.seed,
    }
    req = urllib.request.Request(
        API, data=json.dumps(body).encode(),
        headers={"Authorization": "Bearer " + key,
                 "Content-Type": "application/json"})
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            data = json.loads(r.read())
    except urllib.error.HTTPError as e:
        print("HTTP", e.code, e.read().decode()[:500], file=sys.stderr)
        return 1

    imgs = data.get("images", [])
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    for i, im in enumerate(imgs):
        raw = base64.b64decode(im["base64"])
        path = f"{args.out}_{i}.png"
        with open(path, "wb") as f:
            f.write(raw)
        if args.clean:
            _despeckle(path)
    usage = data.get("usage", {})
    print(f"OK {len(imgs)} frames -> {args.out}_*.png  "
          f"usage={usage}  {time.time()-t0:.1f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
