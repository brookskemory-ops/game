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
	# The reliquary chest, 13x10
	"chest": {
		"colors": {
			"w": "4a3826", "W": "5c4832", # dark wood
			"g": "d9a441", "G": "f0cd7a", # gold banding
			"k": "16131c",                # keyhole / shadow
			"e": "e08840",                # inner glow
		},
		"rows": [
			"..wwwwwwwww..",
			".wWWWWWWWWWw.",
			"wWWgWWWWWgWWw",
			"wggggggggggGw",
			"wWWgWeeWWgWWw",
			"wWWgWekWWgWWw",
			"wggggggggggGw",
			"wWWgWWWWWgWWw",
			".wwwwwwwwwww.",
			"..kkkkkkkkk..",
		],
	},
	# Gold coin, 5x5
	"coin": {
		"colors": {
			"g": "d9a441", "G": "f0cd7a", "d": "a8752c",
		},
		"rows": [
			".ggg.",
			"gGGgd",
			"gGggd",
			"ggggd",
			".ddd.",
		],
	},
	# Maud, the Gravedigger — bonnet, apron, shovel on her back, 10x14
	"maud": {
		"colors": {
			"b": "b8b2a0", "B": "cfc9b8", # bonnet
			"f": "d8c2a0",                # face
			"d": "5a4a3a", "D": "6b5a46", # dress
			"a": "9a927e",                # apron
			"s": "6b5236", "S": "8b8496", # shovel haft / blade
			"e": "16131c",                # eyes
		},
		"rows": [
			"..bbbb..S.",
			".bBBBBb.S.",
			".bBBBBbss.",
			".befffe.s.",
			".bffffb.s.",
			"..ffff..s.",
			".dDDDDd.s.",
			"ddDaaDdds.",
			"d.DaaD.d..",
			"..DaaD....",
			".dDDDDd...",
			".dd..dd...",
			".dd..dd...",
			".ss..ss...",
		],
	},
	# Corvus, the Plague Doctor — beaked mask, wide hat, dark coat, 10x14
	"corvus": {
		"colors": {
			"h": "1f1b28", "H": "2b2733", # wide hat
			"m": "cfc9b8", "M": "b8b2a0", # beak mask
			"e": "8a3f3f",                # red lens
			"c": "23303a", "C": "2e4150", # oiled teal-black coat
			"g": "6a7a52",                # vial glint
			"b": "3d3830",                # boots
		},
		"rows": [
			".hhhhhhhh.",
			"..hHHHHh..",
			"..MMMMMM..",
			"..MeMMMm..",
			"...mmmMM..",
			"....mm.M..",
			"..cCCCCc..",
			".ccCCCCcc.",
			".c.CCCC.c.",
			".g.CCCC.g.",
			"...CCCC...",
			"...CCCC...",
			"...c..c...",
			"...b..b...",
		],
	},
	# Brother Ansel, the Heretic Monk — tonsure, rough robe, censer chain, 10x14
	"ansel": {
		"colors": {
			"s": "d8c2a0", "S": "c4ab87", # skin / tonsure
			"r": "5a4632", "R": "6b5540", # rough brown robe
			"k": "3a3542",                # rope belt / chain
			"t": "e08840",                # censer coal glow
			"e": "16131c",                # eyes
		},
		"rows": [
			"...ssss...",
			"..sSSSSs..",
			"..Sessse..",
			"..ssssss..",
			"...ssss...",
			"..rRRRRr..",
			".rrRRRRrr.",
			".r.RRRR.r.",
			".k.RRRR.k.",
			"...kkkk...",
			"..rRRRRr..",
			"..rRRRRr..",
			"...r..r...",
			"..tt..rr..",
		],
	},
	# Tolling Man — elite with a bronze bell for a head, 11x14
	"tolling_man": {
		"colors": {
			"n": "8a6d3b", "N": "a8894f", # bronze bell
			"k": "5c4527",                # bell rim / clapper
			"e": "e08840",                # ember glow inside
			"c": "3d3830", "C": "4a4438", # ragged vestments
			"b": "8b8496",                # bone
		},
		"rows": [
			"....nnn....",
			"...nNNNn...",
			"..nNNNNNn..",
			"..nNNNNNn..",
			".nNNNNNNNn.",
			".kkkkkkkkk.",
			"....eke....",
			"..cCCCCCc..",
			".ccCCCCCcc.",
			"cc.CCCCC.cc",
			"b..CCCCC..b",
			"...CC.CC...",
			"...CC.CC...",
			"...bb.bb...",
		],
	},
	# The Sexton — stage 1 boss: hunched gravekeeper wraith with spade, 16x20
	"sexton": {
		"colors": {
			"h": "2b2733", "H": "3a3542", # wide hat / robe shadow
			"e": "e08840",                # ember eyes
			"r": "3d3830", "R": "4a4438", # robes
			"s": "6b5236", "S": "b8b2a0", # spade haft / blade
			"g": "6a7a52",                # grave-mold trim
			"b": "8b8496",                # bone hands
		},
		"rows": [
			"....hhhhhhh.....",
			"..hhHHHHHHHhh...",
			".hHHHHHHHHHHHh..",
			"....hHHHHHh.....",
			"....He...eH..S..",
			"....HHHHHHH.SSS.",
			"...rRRRRRRRr.S..",
			"..rrRRRRRRRrrs..",
			".rrRRRRRRRRRrs..",
			".rRRgRRRRRgRrs..",
			"rrRRRRRRRRRRrs..",
			"rbRRRRRRRRRbrs..",
			"r.RRRRRRRRR.bs..",
			"..RRRRRRRRR.s...",
			"..RRRgRgRRR.s...",
			".rRRRRRRRRRr....",
			".rRRRRRRRRRr....",
			"..RRR...RRR.....",
			"..RRR...RRR.....",
			"..ggg...ggg.....",
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
