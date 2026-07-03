extends Control
## Title screen: any tap, click, or key starts a run.

var _started := false

@onready var tap_prompt: Label = $TapPrompt

func _ready() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(tap_prompt, "modulate:a", 0.15, 0.8)
	tween.tween_property(tap_prompt, "modulate:a", 1.0, 0.8)

func _input(event: InputEvent) -> void:
	if _started:
		return
	var pressed := false
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
	elif event is InputEventMouseButton and event.pressed:
		pressed = true
	elif event is InputEventKey and event.pressed and not event.echo:
		pressed = true
	if pressed:
		_started = true
		Game.start_run()
