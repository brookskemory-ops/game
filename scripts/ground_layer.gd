class_name GroundLayer
extends Node2D
## Textured ground for the unbounded world: one seamless base tile repeated
## across the camera view (world-anchored so it scrolls naturally), driven by
## stage data. Falls back to nothing (the flat Background ColorRect beneath)
## when the texture is missing. Cost: a single textured quad per frame.

const TILE := 64.0
const MARGIN := 128.0

const DECAL_COUNT := 160
const DECAL_RANGE := 1500.0

var _base_tex: Texture2D
var _decals: Array = []  # [Texture2D, scale] pairs
var _player: Node2D
var _view_half := Vector2(480, 270)  # zoom-2 view half-size + headroom

func setup(stage: Dictionary, player: Node2D) -> void:
	_player = player
	z_index = -2
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var ground: Dictionary = stage.get("ground", {})
	var base_path := String(ground.get("base", ""))
	if not base_path.is_empty() and ResourceLoader.exists(base_path):
		_base_tex = load(base_path)
	for entry in ground.get("decals", []):
		var decal_path := String(entry[0])
		if ResourceLoader.exists(decal_path):
			_decals.append([load(decal_path), float(entry[1])])

func _process(_delta: float) -> void:
	if _base_tex != null and _player != null:
		queue_redraw()

func _draw() -> void:
	if _base_tex == null or _player == null:
		return
	var center: Vector2 = _player.global_position
	# Snap the rect to the tile grid so the repeat pattern is world-anchored.
	var top_left := ((center - _view_half - Vector2.ONE * MARGIN) / TILE).floor() * TILE
	var size := _view_half * 2.0 + Vector2.ONE * MARGIN * 2.0 + Vector2.ONE * TILE
	draw_texture_rect(_base_tex, Rect2(top_left, size), true)
	# Ground decals: deterministic world-space scatter, dimmed into the night.
	if _decals.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for i in DECAL_COUNT:
		var pos := Vector2(
			rng.randf_range(-DECAL_RANGE, DECAL_RANGE),
			rng.randf_range(-DECAL_RANGE, DECAL_RANGE)
		)
		var pick: Array = _decals[rng.randi() % _decals.size()]
		var tex: Texture2D = pick[0]
		var decal_size := Vector2(tex.get_width(), tex.get_height()) * float(pick[1])
		draw_texture_rect(tex, Rect2(pos - decal_size * 0.5, decal_size), false,
			Color(0.62, 0.62, 0.7))
