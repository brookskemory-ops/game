class_name AmbientMotes
extends Node2D
## Drifting ambient particles that follow the view — graveyard fireflies, forest
## spores, castle embers. A fixed, bounded pool (one cheap redraw per frame on
## its own node, so the heavy one-time prop draw is left alone). Purely
## cosmetic; sits just above the ground.

const COUNT := 46

var _player: Node2D
var _color := Color(0.8, 0.92, 0.6)
var _motes: Array = []
var _win := Vector2(780.0, 480.0)  # a little larger than the view, so wrap is unseen

func setup(player: Node2D, theme: String) -> void:
	_player = player
	match theme:
		"forest":
			_color = Color(0.72, 0.95, 0.7)   # pale spores
		"castle":
			_color = Color(1.0, 0.62, 0.32)   # warm embers
		"crypt":
			_color = Color(0.6, 0.72, 0.85)   # cold pale grave-dust
		_:
			_color = Color(0.82, 0.93, 0.62)  # graveyard fireflies
	var h := _win * 0.5
	for i in COUNT:
		_motes.append({
			"p": Vector2(randf_range(-h.x, h.x), randf_range(-h.y, h.y)),
			"v": Vector2(randf_range(-9.0, 9.0), randf_range(-16.0, -3.0)),
			"ph": randf() * TAU,
			"sz": randf_range(1.0, 2.4),
			"sp": randf_range(0.8, 2.0),
		})
	z_index = 1  # above the ground/props, subtle over the field

func _process(delta: float) -> void:
	if _player == null:
		return
	global_position = _player.global_position
	var h := _win * 0.5
	for m in _motes:
		m["p"] += Vector2(m["v"]) * delta + Vector2(sin(m["ph"]) * 7.0 * delta, 0.0)
		m["ph"] = float(m["ph"]) + delta * float(m["sp"])
		var p: Vector2 = m["p"]
		if p.x < -h.x: p.x += _win.x
		elif p.x > h.x: p.x -= _win.x
		if p.y < -h.y: p.y += _win.y
		elif p.y > h.y: p.y -= _win.y
		m["p"] = p
	queue_redraw()

func _draw() -> void:
	for m in _motes:
		var tw: float = 0.25 + 0.4 * (0.5 + 0.5 * sin(float(m["ph"]) * 2.0))
		var pos: Vector2 = m["p"]
		var sz: float = m["sz"]
		draw_circle(pos, sz, Color(_color.r, _color.g, _color.b, tw))
		draw_circle(pos, sz * 0.5, Color(1.0, 1.0, 1.0, tw * 0.7))
