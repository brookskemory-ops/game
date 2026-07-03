class_name GroundLayer
extends Node2D
## Textured ground for the unbounded world: one seamless base tile repeated
## across the camera view (world-anchored so it scrolls naturally), driven by
## stage data. Falls back to nothing (the flat Background ColorRect beneath)
## when the texture is missing. Cost: a single textured quad per frame.

const TILE := 64.0
const MARGIN := 128.0

var _base_tex: Texture2D
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
