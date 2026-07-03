extends Node2D
## Phase 0 test arena: proves rendering, camera follow, and touch input on device.
## Draws a deterministic scatter of graves and rubble so player movement is visible.
## Esc (desktop) returns to the title screen.

const SCATTER_COUNT := 140
const SCATTER_RANGE := 1600.0

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1349
	for i in SCATTER_COUNT:
		var pos := Vector2(
			rng.randf_range(-SCATTER_RANGE, SCATTER_RANGE),
			rng.randf_range(-SCATTER_RANGE, SCATTER_RANGE)
		)
		var shade := rng.randf_range(0.10, 0.16)
		if rng.randf() < 0.25:
			# A tombstone.
			draw_rect(Rect2(pos, Vector2(8.0, 10.0)), Color(shade + 0.07, shade + 0.06, shade + 0.10))
		else:
			# Rubble / dead grass specks.
			draw_rect(Rect2(pos, Vector2(3.0, 2.0)), Color(shade, shade + 0.02, shade))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Game.end_run(false)
