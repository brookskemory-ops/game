class_name UITheme
extends RefCounted
## Shared UI construction helpers so every screen speaks the same visual language.
## Fonts: Jacquard 12 (medieval display) + Pixelify Sans (readable body), both OFL.

const TITLE_FONT_PATH := "res://assets/fonts/Jacquard12-Regular.ttf"
const BODY_FONT_PATH := "res://assets/fonts/PixelifySans.ttf"

static var _title_font: Font
static var _body_font: Font

## Panels/columns designed for the 640-wide desktop canvas must shrink on the
## mobile profile (480-wide minimum). Pass any node for viewport access.
static func fit_width(node: Node, desired: float, margin := 40.0) -> float:
	var viewport := node.get_viewport()
	if viewport == null:
		return desired
	return minf(desired, viewport.get_visible_rect().size.x - margin)

## Overlay body height that leaves room for a title above and a button below.
static func fit_height(node: Node, desired: float, reserved := 110.0) -> float:
	var viewport := node.get_viewport()
	if viewport == null:
		return desired
	return minf(desired, viewport.get_visible_rect().size.y - reserved)

static func title_font() -> Font:
	if _title_font == null and ResourceLoader.exists(TITLE_FONT_PATH):
		_title_font = load(TITLE_FONT_PATH)
	return _title_font

static func body_font() -> Font:
	if _body_font == null and ResourceLoader.exists(BODY_FONT_PATH):
		# Pixelify Sans has a broken 'fi' ligature glyph ("fire" renders as
		# "Are") — wrap it in a FontVariation with ligatures disabled.
		var variation := FontVariation.new()
		variation.base_font = load(BODY_FONT_PATH)
		var liga_tag := TextServerManager.get_primary_interface().name_to_tag("liga")
		variation.opentype_features = {liga_tag: 0}
		_body_font = variation
	return _body_font

## A Label with our styling. `display=true` uses the medieval display font.
static func make_label(text: String, size: int, color: Color, display := false, shadow := true) -> Label:
	var label := Label.new()
	label.text = text
	var settings := LabelSettings.new()
	var font := title_font() if display else body_font()
	if font != null:
		settings.font = font
	settings.font_size = size
	settings.font_color = color
	if shadow:
		settings.shadow_color = Color(0, 0, 0, 0.55)
		settings.shadow_offset = Vector2(0, 2)
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

## Iron-and-parchment panel style.
static func panel_style(bg := Palette.INK, border := Palette.IRON) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(bg.r, bg.g, bg.b, 0.92)
	style.border_color = border
	style.set_border_width_all(2)
	style.set_content_margin_all(14)
	return style

## A themed button (flat, iron border, parchment text; torch highlight on press).
static func make_button(text: String, size := 15) -> Button:
	var button := Button.new()
	button.text = text
	# Touch game: no keyboard nav, and focus rings misleadingly highlight
	# disabled cards (found by the QA sweep).
	button.focus_mode = Control.FOCUS_NONE
	var font := body_font()
	if font != null:
		button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", Palette.PARCHMENT)
	button.add_theme_color_override("font_hover_color", Palette.TORCH)
	button.add_theme_color_override("font_pressed_color", Palette.TORCH)
	button.add_theme_color_override("font_focus_color", Palette.PARCHMENT)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(Palette.IRON.r, Palette.IRON.g, Palette.IRON.b, 0.6)
	normal.border_color = Palette.STONE
	normal.set_border_width_all(1)
	normal.set_content_margin_all(8)
	normal.content_margin_left = 18
	normal.content_margin_right = 18

	var hover := normal.duplicate()
	hover.border_color = Palette.TORCH

	var pressed := normal.duplicate()
	pressed.bg_color = Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, 0.18)
	pressed.border_color = Palette.TORCH

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover.duplicate())
	return button

## Controller support (v2.0): make every enabled Button under `root` focusable
## and drop initial focus on the first, so a joypad's ui_up/down/left/right/
## accept can drive the menu — Godot resolves neighbours geometrically. Gated
## on a pad actually being present, so mouse/touch/keyboard UX is untouched
## (no stray focus rings after a click). The focus box is styled like hover.
static func enable_focus(root: Node) -> void:
	if Input.get_connected_joypads().is_empty():
		return
	var buttons: Array = []
	_collect_focusable(root, buttons)
	for b in buttons:
		(b as Button).focus_mode = Control.FOCUS_ALL
	if not buttons.is_empty():
		(buttons[0] as Button).call_deferred("grab_focus")

static func _collect_focusable(n: Node, out: Array) -> void:
	for child in n.get_children():
		if child is Button and not (child as Button).disabled and (child as Button).visible:
			out.append(child)
		_collect_focusable(child, out)
