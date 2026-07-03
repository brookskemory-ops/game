class_name VirtualJoystick
extends Control
## Floating one-thumb joystick (design pillar #3: "One thumb").
## Touch anywhere → stick appears under the thumb; drag to move; release to hide.
## Desktop testing works too: `emulate_touch_from_mouse` is enabled in project settings,
## and arrow keys are a fallback (see player.gd).

const MAX_RADIUS := 48.0
const KNOB_RADIUS := 18.0

## Normalized input direction, length 0..1. Read by player.gd.
var output := Vector2.ZERO

var _touch_index := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_origin = event.position
			_knob = event.position
			output = Vector2.ZERO
			queue_redraw()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			output = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		var delta: Vector2 = event.position - _origin
		delta = delta.limit_length(MAX_RADIUS)
		_knob = _origin + delta
		output = delta / MAX_RADIUS
		queue_redraw()

func _draw() -> void:
	if _touch_index == -1:
		return
	draw_circle(_origin, MAX_RADIUS, Color(1.0, 1.0, 1.0, 0.06))
	draw_arc(_origin, MAX_RADIUS, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.22), 2.0)
	draw_circle(_knob, KNOB_RADIUS, Color(1.0, 1.0, 1.0, 0.30))
