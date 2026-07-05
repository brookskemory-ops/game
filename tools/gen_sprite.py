#!/usr/bin/env python3
"""Generate a single pixel-art sprite via Pixel Lab's pixflux endpoint.

Used for new enemy/prop art (64px transparent, dark-fantasy). Reusable so art
generation is repeatable, not one-off curl calls. Every asset must pass visual
QA before it ships (doctrine).

Usage:
  PIXELLAB_API_KEY=... python3 tools/gen_sprite.py \
      --out /tmp/.../carrion_crow.png --size 64 \
      --desc "a gaunt undead crow with tattered wings, side view, dark fantasy"
"""
import argparse, base64, json, os, sys, time, urllib.request, urllib.error

API = "https://api.pixellab.ai/v1/generate-image-pixflux"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--desc", required=True)
    ap.add_argument("--size", type=int, default=64)
    ap.add_argument("--neg", default="text, watermark, border, frame, multiple characters")
    ap.add_argument("--detail", default="highly detailed")
    ap.add_argument("--outline", default="single color black outline")
    ap.add_argument("--seed", type=int, default=0)
    args = ap.parse_args()

    key = os.environ.get("PIXELLAB_API_KEY")
    if not key:
        print("PIXELLAB_API_KEY missing", file=sys.stderr)
        return 2
    body = {
        "image_size": {"width": args.size, "height": args.size},
        "description": args.desc,
        "negative_description": args.neg,
        "detail": args.detail,
        "outline": args.outline,
        "text_guidance_scale": 8.0,
        "no_background": True,
        "seed": args.seed,
    }
    req = urllib.request.Request(
        API, data=json.dumps(body).encode(),
        headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            data = json.loads(r.read())
    except urllib.error.HTTPError as e:
        print("HTTP", e.code, e.read().decode()[:400], file=sys.stderr)
        return 1
    img = data.get("image", {})
    b64 = img.get("base64") if isinstance(img, dict) else None
    if not b64:
        print("no image in response:", str(data)[:300], file=sys.stderr)
        return 1
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    with open(args.out, "wb") as f:
        f.write(base64.b64decode(b64))
    print(f"OK -> {args.out}  usage={data.get('usage')}  {time.time()-t0:.1f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
