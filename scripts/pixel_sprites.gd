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
	# Elite scroll — rolled parchment, 8x8
	"scroll": {
		"colors": {
			"p": "d9d3c0", "P": "c4bfa8", # parchment
			"r": "8c2f2f",                # wax seal
			"d": "8a8060",                # shadowed roll
		},
		"rows": [
			".pppppp.",
			"pPPPPPPp",
			"pPdddPPp",
			"pPPPPPPp",
			"pPPrrPPp",
			"pPPrrPPp",
			"pPdddPPp",
			".pppppp.",
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
	# Wight — tall gaunt barrow-dweller, 11x16
	"wight": {
		"colors": {
			"p": "8b8496", "P": "9a94a6", # pallid flesh
			"e": "6f9fd8",                # cold blue eyes
			"r": "2b2733", "R": "3a3542", # barrow rags
			"g": "6a7a52",                # grave mold
		},
		"rows": [
			"...ppppp...",
			"..pPPPPPp..",
			"..PePPPeP..",
			"..PPPPPPP..",
			"...PPPPP...",
			"..rRRRRRr..",
			".rrRRRRRrr.",
			".r.RRRRR.r.",
			".p.RRRRR.p.",
			"...RRgRR...",
			"...RRRRR...",
			"...RRRRR...",
			"...RRgRR...",
			"...RR.RR...",
			"...RR.RR...",
			"...gg.gg...",
		],
	},
	# Hanged Man — ambusher trailing his rope, 10x14
	"hanged_man": {
		"colors": {
			"f": "7a8468", "F": "8a9478", # bloated flesh
			"e": "16131c",                # sunken eyes
			"n": "8a6d3b",                # noose rope
			"c": "2e2a38", "C": "3a3542", # burial suit
		},
		"rows": [
			"....nn....",
			"....nn....",
			"...ffff...",
			"..fFFFFf..",
			"..FeFFeF..",
			"..FFFFFF..",
			"...ffff...",
			"..cCCCCc..",
			".ccCCCCcc.",
			".c.CCCC.c.",
			"...CCCC...",
			"...CCCC...",
			"...c..c...",
			"...c..c...",
		],
	},
	# Bone Stag — antlered skeletal charger, 14x12
	"bone_stag": {
		"colors": {
			"b": "cfc9b8", "B": "b8b2a0", # bone
			"a": "9a8f78",                # antlers
			"e": "e08840",                # ember eye
			"d": "8b8496",                # shadowed bone
		},
		"rows": [
			"a..a......a...",
			".aa.a....a....",
			"..aaa...ab....",
			"...abbbbbBe...",
			"...dBBBBBbb...",
			"..bBBBBBBb....",
			".bBBBBBBBb....",
			".bBdBBBBdb....",
			".b.BBBBB.b....",
			".b.d..d..b....",
			".d.b..b..d....",
			"...d..d.......",
		],
	},
	# The Briar Queen — stage 2 boss: thorn wraith crowned in briars, 16x20
	"briar_queen": {
		"colors": {
			"t": "3d4a2e", "T": "4d5c3a", # briar thorns
			"e": "b8542f",                # ember-rose eyes
			"v": "2b332b", "V": "364036", # mossy veil/gown
			"w": "8b8496",                # pale wraith face
			"r": "6a3a4a",                # dead roses
		},
		"rows": [
			".t..tttttt..t...",
			"t.tttTTTTttt.t..",
			".tttTTTTTTttt...",
			"..tTTrTTrTTt....",
			"...wwwwwwww.....",
			"...wewwwwew.....",
			"...wwwwwwww.....",
			"..vVVVVVVVVv....",
			".vvVVVVVVVVvv...",
			".v.VVVVVVVV.v...",
			"tv.VVrVVVVV.vt..",
			".t.VVVVVVVV.t...",
			"...VVVVrVVV.....",
			"...VVVVVVVV.....",
			"..vVVVVVVVVv....",
			"..vVVVVVVVVv....",
			"...VVV..VVV.....",
			"...VVV..VVV.....",
			"...ttt..ttt.....",
			"..t.t....t.t....",
		],
	},
	# Ser Roland — armored knight, 10x14
	"roland": {
		"colors": {
			"s": "8b8496", "S": "9a94a6", # steel plate
			"k": "5a5464",                # dark steel
			"f": "d8c2a0",                # face
			"e": "16131c",                # visor slit / eyes
			"c": "8c2f2f",                # tabard (faded crimson)
			"g": "6b5236",                # sword grip
		},
		"rows": [
			"...ssss...",
			"..sSSSSs..",
			"..Seffes..",
			"..sffffs..",
			"...ssss..g",
			"..sSSSSs.g",
			".ssScCsssg",
			".s.ScCS.sg",
			".k.ScCS.k.",
			"...ScCS...",
			"..sSSSSs..",
			"..kk..kk..",
			"..kk..kk..",
			"..ss..ss..",
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
	# The Hollow King — hero 6: gaunt king in a tarnished crown, 10x14
	"hollow_king": {
		"colors": {
			"g": "8a6d3b", "G": "a8894f", # tarnished gold crown
			"f": "9a94a6",                # hollowed grey face
			"e": "6f9fd8",                # cold blue eyes
			"r": "2e2233", "R": "3a2c42", # funeral-purple robes
			"c": "8c2f2f",                # dead royal crimson sash
			"s": "b8b2a0",                # the cursed blade, pale steel
		},
		"rows": [
			".g.gGGg.g.",
			"..gGGGGg..",
			"..ffffff..",
			"..fefefe..",
			"...ffff..s",
			"..rRRRRr.s",
			".rrRcRRrrs",
			".r.RcRRR.s",
			".r.RcRRR.s",
			"...RRRRR..",
			"...RRRRR..",
			"..rRRRRRr.",
			"..RR..RR..",
			"..RR..RR..",
		],
	},
	# Thrall — a slain foe risen in the King's service, 10x12 spectral wisp
	"thrall": {
		"colors": {
			"w": "9dc1ec", "W": "c5ddf5", # grave-light body
			"e": "e8f4ff",                # burning pale eyes
			"d": "6f9fd8",                # deep spectral folds
		},
		"rows": [
			"...wwww...",
			"..wWWWWw..",
			"..WeWWeW..",
			"..WWWWWW..",
			"...WWWW...",
			"..wWWWWw..",
			".wwWWWWww.",
			".w.WWWW.w.",
			"...WWWW...",
			"...dWWd...",
			"....dd....",
			"....d.....",
		],
	},
	# Risen Courtier — court fodder in rotted finery, 10x14
	"courtier": {
		"colors": {
			"f": "8a8474",                # grey-green dead flesh
			"e": "e08840",                # ember eyes
			"v": "3a2c42", "V": "473652", # moth-eaten velvet
			"c": "8a6d3b",                # torn gilt trim
			"b": "8b8496",                # bone
		},
		"rows": [
			"...ffff...",
			"..ffffff..",
			"..fefefe..",
			"...ffff...",
			"..vVVVVv..",
			".vvVcVVvv.",
			".v.VcVVV.v",
			".b.VVVVV.b",
			"...VVVVV..",
			"...VcVVV..",
			"..vVVVVVv.",
			"..VV..VV..",
			"..VV..VV..",
			"..bb..bb..",
		],
	},
	# Risen Knight — shielded tank in grave-plate, 11x15
	"risen_knight": {
		"colors": {
			"s": "5a5464", "S": "6a6474", # tarnished plate
			"k": "3a3542",                # dark steel joints
			"e": "e08840",                # ember visor glow
			"c": "8c2f2f",                # rotted tabard
			"h": "8b8496",                # shield face
			"H": "9a94a6",                # shield boss
		},
		"rows": [
			"....ssss...",
			"...sSSSSs..",
			"...Se..eS..",
			"...sSSSSs..",
			"hh..ssss...",
			"hHh.sSSs...",
			"hHhssScCss.",
			"hHhs.ScCs..",
			"hHhk.ScCk..",
			"hh...ScC...",
			".....SSS...",
			"...sSSSSs..",
			"...kk.kk...",
			"...kk.kk...",
			"...ss.ss...",
		],
	},
	# Crypt Archer — skeletal bowman who holds his distance, 11x14
	"crypt_archer": {
		"colors": {
			"b": "cfc9b8", "B": "b8b2a0", # bone
			"e": "6f9fd8",                # cold eye sockets
			"h": "2b2733", "H": "3a3542", # crypt-shroud hood
			"w": "6b5236",                # yew bow
			"s": "8a6d3b",                # bowstring / quiver
		},
		"rows": [
			"...hhhh....",
			"..hHHHHh...",
			"..HbBBbH..w",
			"..HeBBeH..w",
			"...BBBB..sw",
			"..hHHHHh.sw",
			".hhHHHHhhsw",
			".h.HHHH.ssw",
			".b.HHHH..sw",
			"...HHHH...w",
			"...HHHH...w",
			"...HH.HH..w",
			"...HH.HH...",
			"...bb.bb...",
		],
	},
	# Chapel Chorister — elite: robed singer whose hymn mends the dead, 12x16
	"chorister": {
		"colors": {
			"r": "3d3830", "R": "4a4438", # cassock
			"w": "cfc9b8", "W": "e0dac8", # surplice (once white)
			"f": "8a8474",                # dead grey face
			"e": "f0cd7a",                # gilt-lit hollow mouth/eyes
			"g": "8a6d3b",                # gold hymnal
		},
		"rows": [
			"....ffff....",
			"...ffffff...",
			"...fefefe...",
			"...ffeeff...",
			"....ffff....",
			"...wWWWWw...",
			"..wwWWWWww..",
			".ww.WWWW.ww.",
			".w..WWWW..w.",
			"..g.WWWW.g..",
			"..ggWWWWgg..",
			"...rRRRRr...",
			"...RRRRRR...",
			"...RRRRRR...",
			"...RRR.RRR..",
			"...rrr.rrr..",
		],
	},
	# The Thing in the Chapel — final boss: what answered the bell, 16x20
	"chapel_thing": {
		"colors": {
			"v": "1c1526", "V": "2a1f38", # a shape of chapel-dark
			"e": "f0cd7a",                # too many gilt eyes
			"b": "8a6d3b", "B": "a8894f", # the bell it carries, half-melted
			"w": "9a94a6",                # pale grasping hands
			"r": "8c2f2f",                # vestment scraps
		},
		"rows": [
			"....vvvvvvvv....",
			"..vvVVVVVVVVvv..",
			".vVVeVVeVVeVVv..",
			".vVVVVVVVVVVVv..",
			"vVVeVVVeVVVeVVv.",
			"vVVVVVVVVVVVVVv.",
			"vVVVVrVVVrVVVVv.",
			"vVVVVVVVVVVVVVv.",
			".vVVVVbbbVVVVv..",
			".vVVVbBBBbVVVv..",
			"wVVVVbBBBbVVVVw.",
			"wwVVVbbbbbVVVww.",
			"w.vVVVVVVVVv..w.",
			"...vVVVVVVv.....",
			"...vVVVVVVv.....",
			"..vVVVVVVVVv....",
			"..vVVv..vVVv....",
			"..vVv....vVv....",
			"...v......v.....",
			"................",
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

## QuadMesh UVs are 3D Y-up, so MultiMesh-rendered textures draw upside down
## in the 2D canvas. Every texture bound to a MultiMeshInstance2D must pass
## through this flip (regular Sprite2D/TextureRect must NOT).
static func flipped_for_multimesh(tex: Texture2D) -> ImageTexture:
	var img := tex.get_image()
	img.flip_y()
	return ImageTexture.create_from_image(img)
