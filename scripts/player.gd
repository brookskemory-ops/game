extends CharacterBody2D
## Placeholder hero for Phase 0 — a movable shape that proves input + camera.
## Phase 1 replaces the polygon art with a real sprite and adds weapons.

const SPEED := 130.0

var _joystick: VirtualJoystick

func _ready() -> void:
	_joystick = get_tree().get_first_node_in_group("virtual_joystick") as VirtualJoystick

func _physics_process(_delta: float) -> void:
	# Keyboard fallback for desktop testing (arrow keys via built-in ui_ actions).
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if _joystick != null and _joystick.output.length() > 0.05:
		dir = _joystick.output
	velocity = dir.limit_length(1.0) * SPEED
	move_and_slide()
