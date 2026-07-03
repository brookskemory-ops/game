class_name FogLayer
extends Node2D
## The Deep Mist: a drifting translucent fog over the field (stage json
## "mods": {"fog": true}). A handful of large soft blobs orbiting the player
## slowly — one canvas item, no per-frame allocations, no perf cost.

const BLOBS := 7

var _player: Node2D
var _time := 0.0

func setup(player: Node2D) -> void:
	_player = player
	z_index = 4  # above actors, below the UI layer

func _process(delta: float) -> void:
	_time += delta
	if _player != null:
		queue_redraw()

func _draw() -> void:
	if _player == null:
		return
	var center: Vector2 = _player.global_position
	for i in BLOBS:
		var phase := float(i) * 1.9
		var drift := Vector2(
			sin(_time * 0.11 + phase) * 260.0 + cos(_time * 0.07 + phase * 2.2) * 120.0,
			cos(_time * 0.09 + phase) * 150.0 + sin(_time * 0.13 + phase * 1.4) * 90.0
		)
		var radius := 130.0 + 60.0 * sin(phase * 3.1 + _time * 0.05)
		draw_circle(center + drift, radius, Color(0.72, 0.76, 0.82, 0.10))
	# A thin even haze so the mist never fully parts.
	draw_rect(Rect2(center - Vector2(700, 400), Vector2(1400, 800)), Color(0.72, 0.76, 0.82, 0.06))
