class_name PixelSprites
extends RefCounted
## Procedural pixel-art placeholders, generated at runtime from ASCII art.
## Zero binary assets — works identically on desktop, Android, and web.
## Phase 5 swaps these for Pixel Lab sprites with the same ids/sizes
## (see docs/ASSET_PIPELINE.md).

static var _cache := {}

# Each character maps to a hex color; "." is transparent.
const SPRITES := {
	# Wren, the Poacher — hooded hunter, 10x14
	"wren": {
		"colors": {
			"h": "4a4636", "H": "5a5642", # hood (mossy leather)
			"f": "d8c2a0", # face
			"c": "3d3830", "C": "4a4438", # cloak
			"b": "6b5236", # boots/bow arm
			"e": "16131c", # eye shadow
		},
		"rows": [
			"...hhhh...",
			"..hHHHHh..",
			"..hHHHHh..",
			"..heffeh..",
			"..hffffh..",
			"...ffff...",
			"..cCCCCc..",
			".ccCCCCcc.",
			".c.CCCC.c.",
			".b.CCCC.b.",
			"...CCCC...",
			"...c..c...",
			"...c..c...",
			"...b..b...",
		],
	},
	# Shambler — risen villager, hunched, one arm out, 9x12
	"shambler": {
		"colors": {
			"r": "6a7a52", "R": "5a684a", # rotting flesh
			"e": "e08840",                # ember eyes
			"c": "4a4438", "C": "3d3830", # grave clothes
			"b": "8b8496",                # exposed bone
		},
		"rows": [
			"..rrrr...",
			".rrRRrr..",
			".rerRer..",
			".rrrrrr..",
			"..rrrr...",
			".cCCCCrr.",
			"cCCCCCrbr",
			"cCCCCC.r.",
			".CCCC....",
			".CC.CC...",
			".CC..CC..",
			".bb...bb.",
		],
	},
	# Gnawer — skeletal dog, low and fast, 10x6
	"gnawer": {
		"colors": {
			"b": "cfc9b8", "B": "b8b2a0", # bone
			"e": "e08840",                # ember eye
			"d": "8b8496",                # dark bone
		},
		"rows": [
			".......bb.",
			"bbbbbbbBeb",
			"dBBBBBBbbb",
			".bBBBBb.b.",
			".b....b...",
			".d....d...",
		],
	},
	# Arrow — points +X, 8x3
	"arrow": {
		"colors": {
			"s": "6b5236",                # shaft
			"h": "cfc9b8",                # bone head
			"f": "8b8496",                # fletching
		},
		"rows": [
			"f.....h.",
			"fssssshh",
			"f.....h.",
		],
	},
	# XP gem — cold blue shard, 5x7
	"gem": {
		"colors": {
			"g": "6f9fd8", "G": "9dc1ec", "d": "4a6ea0",
		},
		"rows": [
			"..G..",
			".GGg.",
			"GGggg",
			".Gggd",
			".ggd.",
			"..d..",
			".....",
		],
	},
	# Tiny skull for the kill counter, 7x7
	"skull": {
		"colors": {
			"b": "cfc9b8", "e": "16131c",
		},
		"rows": [
			".bbbbb.",
			"bbbbbbb",
			"bebbbeb",
			"bbbbbbb",
			".bb.bb.",
			".bbbbb.",
			".b.b.b.",
		],
	},
}

static func get_tex(id: String) -> ImageTexture:
	if _cache.has(id):
		return _cache[id]
	assert(SPRITES.has(id), "Unknown sprite id: " + id)
	var def: Dictionary = SPRITES[id]
	var rows: Array = def["rows"]
	var colors: Dictionary = def["colors"]
	var h: int = rows.size()
	var w: int = String(rows[0]).length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var row := String(rows[y])
		for x in w:
			var ch := row[x]
			if colors.has(ch):
				img.set_pixel(x, y, Color(String(colors[ch])))
	var tex := ImageTexture.create_from_image(img)
	_cache[id] = tex
	return tex

static func size_of(id: String) -> Vector2:
	var tex := get_tex(id)
	return Vector2(tex.get_width(), tex.get_height())
