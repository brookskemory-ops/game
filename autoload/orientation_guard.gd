extends CanvasLayer
## Web/mobile: the vigil is kept in landscape. When a phone is held portrait
## the layout stretches unplayably, so dim everything and ask for a turn of
## the wrist. Pure overlay — nothing about the game state changes.

var _panel: Control
var _icon: Control
var _time := 0.0

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		set_process(false)
		return
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.045, 0.08, 0.96)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(dim)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 14)
	_icon = Control.new()
	_icon.custom_minimum_size = Vector2(0, 64)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.draw.connect(_draw_phone)
	column.add_child(_icon)
	column.add_child(UITheme.make_label("TURN YOUR PHONE", 26, Palette.PARCHMENT, true))
	column.add_child(UITheme.make_label("the vigil is kept in landscape", 12, Palette.ASH))
	_panel.add_child(column)
	add_child(_panel)

func _process(delta: float) -> void:
	_time += delta
	var window := DisplayServer.window_get_size()
	var portrait := window.y > window.x
	if _panel.visible != portrait:
		_panel.visible = portrait
	if portrait:
		_icon.queue_redraw()

## A little phone rocking toward landscape.
func _draw_phone() -> void:
	var center := Vector2(_icon.size.x * 0.5, 32.0)
	var sway := sin(_time * 2.2)
	var angle := -PI / 4.0 - sway * PI / 4.0  # rocks between portrait and landscape
	var xform := Transform2D(angle, center)
	_icon.draw_set_transform_matrix(xform)
	_icon.draw_rect(Rect2(-12, -20, 24, 40), Palette.STONE)
	_icon.draw_rect(Rect2(-9, -16, 18, 29), Palette.INK)
	_icon.draw_circle(Vector2(0, 16.5), 1.8, Palette.INK)
	_icon.draw_set_transform_matrix(Transform2D())
