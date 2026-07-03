class_name VirtualJoystick
extends Control
## Floating one-thumb joystick (design pillar #3: "One thumb").
## Touch anywhere → stick appears under the thumb; drag to move; release to hide.
##
## Listens in _input (NOT _unhandled_input): GUI controls like full-screen
## ColorRects can consume events before the unhandled phase — on the web build
## that ate every touch and the joystick never appeared. _input runs first.
## While the tree is paused (drafts, pause menu, results) touches are ignored
## so overlay buttons behave normally.

const MAX_RADIUS := 48.0
const KNOB_RADIUS := 18.0

## Normalized input direction, length 0..1. Read by player.gd.
var output := Vector2.ZERO

var _touch_index := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	# If a pause/draft/results overlay opened mid-touch, drop the stick.
	if _touch_index != -1 and get_tree().paused:
		_release()

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_origin = _to_ui(event.position)
			_knob = _origin
			output = Vector2.ZERO
			queue_redraw()
		elif not event.pressed and event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		var delta := _to_ui(event.position) - _origin
		delta = delta.limit_length(MAX_RADIUS)
		_knob = _origin + delta
		output = delta / MAX_RADIUS
		queue_redraw()

## Map a raw event position into this control's local space, robust to
## content-scale/DPI differences between the input and canvas coordinates.
func _to_ui(event_position: Vector2) -> Vector2:
	var vp_size := get_viewport().get_visible_rect().size
	if size.x > 0.0 and vp_size.x > 0.0 and absf(size.x - vp_size.x) > 0.5:
		return event_position * (size / vp_size)
	return event_position

func _release() -> void:
	_touch_index = -1
	output = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if _touch_index == -1:
		return
	draw_circle(_origin, MAX_RADIUS, Color(1.0, 1.0, 1.0, 0.06))
	draw_arc(_origin, MAX_RADIUS, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.22), 2.0)
	draw_circle(_knob, KNOB_RADIUS, Color(1.0, 1.0, 1.0, 0.30))
