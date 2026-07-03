class_name HUD
extends Control
## All in-run UI: HP/XP bars, night timer, kill count, level-up toasts, damage
## vignette, pause menu, and the results overlay. Built entirely from UITheme
## so every screen shares one visual language.

const HP_BAR := Rect2(14, 12, 150, 10)
const XP_BAR_HEIGHT := 5.0
const RESULTS_INPUT_DELAY_MS := 600

var _arena  # untyped: arena exposes time_elapsed / run_length()
var _player: Player
var _enemies: EnemyManager

var _timer_label: Label
var _kills_label: Label
var _level_label: Label
var _toast_box: VBoxContainer
var _pause_button: Button
var _pause_panel: Control
var _results_panel: Control
var _skull_tex: Texture2D

var _vignette := 0.0
var _xp_flash := 0.0
var _hp_frac := 1.0        # smoothed toward _hp_target for a draining bar
var _hp_target := 1.0
var _draft_panel: Control
var _results_shown := false
var _results_victory := false
var _results_stats := {}
var _results_at_ms := 0

func setup(arena, player: Player, enemies: EnemyManager) -> void:
	_arena = arena
	_player = player
	_enemies = enemies
	player.hp_changed.connect(_on_hp_changed)
	player.hurt.connect(_on_hurt)
	player.leveled_up.connect(_on_leveled_up)

func _ready() -> void:
	# The pause menu and results overlay must keep working while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skull_tex = PixelSprites.get_tex("skull")

	_timer_label = UITheme.make_label("0:00", 30, Palette.PARCHMENT, true)
	_place(_timer_label, 0.5, 0.0, 0.5, 0.0, Rect2(-70, 2, 140, 34))
	add_child(_timer_label)

	_kills_label = UITheme.make_label("0", 13, Palette.ASH)
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_place(_kills_label, 1.0, 0.0, 1.0, 0.0, Rect2(-86, 10, 60, 18))
	add_child(_kills_label)

	_level_label = UITheme.make_label("LV 1", 12, Palette.TORCH)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_place(_level_label, 0.0, 1.0, 0.0, 1.0, Rect2(10, -26, 80, 16))
	add_child(_level_label)

	_toast_box = VBoxContainer.new()
	_toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_toast_box, 0.5, 0.0, 0.5, 0.0, Rect2(-160, 42, 320, 90))
	add_child(_toast_box)

	_pause_button = UITheme.make_button("II", 12)
	_place(_pause_button, 1.0, 0.0, 1.0, 0.0, Rect2(-42, 34, 32, 28))
	_pause_button.pressed.connect(toggle_pause)
	add_child(_pause_button)

## Anchor + offset helper for code-built controls.
func _place(control: Control, a_left: float, a_top: float, a_right: float, a_bottom: float, offsets: Rect2) -> void:
	control.anchor_left = a_left
	control.anchor_top = a_top
	control.anchor_right = a_right
	control.anchor_bottom = a_bottom
	control.offset_left = offsets.position.x
	control.offset_top = offsets.position.y
	control.offset_right = offsets.position.x + offsets.size.x
	control.offset_bottom = offsets.position.y + offsets.size.y

func _process(delta: float) -> void:
	if _results_shown or get_tree().paused:
		return
	if _arena != null:
		var remaining: float = maxf(0.0, _arena.run_length() - _arena.time_elapsed)
		_timer_label.text = "%d:%02d" % [int(remaining) / 60, int(remaining) % 60]
	if _enemies != null:
		_kills_label.text = str(_enemies.kills)
	if _player != null:
		_level_label.text = "LV %d" % _player.level
	_hp_frac = lerpf(_hp_frac, _hp_target, minf(1.0, delta * 10.0))
	_vignette = maxf(0.0, _vignette - delta * 1.6)
	_xp_flash = maxf(0.0, _xp_flash - delta * 2.2)
	queue_redraw()

func _draw() -> void:
	if _results_shown:
		return
	var w := size.x
	var h := size.y
	# --- HP bar (top left): iron frame, ink well, blood fill with a lit top edge ---
	draw_rect(Rect2(HP_BAR.position - Vector2.ONE, HP_BAR.size + Vector2.ONE * 2.0), Palette.IRON)
	draw_rect(HP_BAR, Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.9))
	var frac := clampf(_hp_frac, 0.0, 1.0)
	if frac > 0.0:
		var fill := Rect2(HP_BAR.position + Vector2.ONE, Vector2((HP_BAR.size.x - 2.0) * frac, HP_BAR.size.y - 2.0))
		draw_rect(fill, Palette.BLOOD)
		draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2.0)), Palette.BLOOD.lightened(0.25))
	for notch in range(1, 4):
		var nx := HP_BAR.position.x + HP_BAR.size.x * 0.25 * float(notch)
		draw_rect(Rect2(nx, HP_BAR.position.y, 1.0, HP_BAR.size.y), Color(0, 0, 0, 0.35))
	# --- Kill counter skull icon (next to the number, top right) ---
	if _skull_tex != null:
		draw_texture(_skull_tex, Vector2(w - 100.0, 12.0))
	# --- XP bar (bottom edge, full width) ---
	var y := h - XP_BAR_HEIGHT
	draw_rect(Rect2(0, y, w, XP_BAR_HEIGHT), Color(Palette.IRON.r, Palette.IRON.g, Palette.IRON.b, 0.7))
	if _player != null:
		var xp_frac := clampf(float(_player.xp) / float(_player.xp_needed(_player.level)), 0.0, 1.0)
		draw_rect(Rect2(0, y, w * xp_frac, XP_BAR_HEIGHT), Palette.TORCH)
	if _xp_flash > 0.0:
		draw_rect(Rect2(0, y, w, XP_BAR_HEIGHT), Color(1, 1, 1, _xp_flash * 0.6))
	# --- Damage vignette: blood-red frame that flares on hurt ---
	if _vignette > 0.0:
		var edge := 22.0
		for layer in 3:
			var t := edge * (1.0 - float(layer) / 3.0)
			var a := _vignette * 0.16
			var c := Color(Palette.BLOOD.r, Palette.BLOOD.g, Palette.BLOOD.b, a)
			draw_rect(Rect2(0, 0, w, t), c)
			draw_rect(Rect2(0, h - t, w, t), c)
			draw_rect(Rect2(0, 0, t, h), c)
			draw_rect(Rect2(w - t, 0, t, h), c)

# --- Signal handlers ---

func _on_hp_changed(current: float, max_value: float) -> void:
	_hp_target = 0.0 if max_value <= 0.0 else clampf(current / max_value, 0.0, 1.0)

func _on_hurt(_amount: float) -> void:
	_vignette = 1.0

func _on_leveled_up(_level: int) -> void:
	_xp_flash = 1.0

func toast(text: String) -> void:
	var label := UITheme.make_label(text, 12, Palette.TORCH)
	_toast_box.add_child(label)
	while _toast_box.get_child_count() > 3:
		_toast_box.get_child(0).queue_free()
	label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	tween.tween_interval(1.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

# --- Upgrade draft (pick 1 of 3 on level up) ---

## Shows the draft and pauses the night. `on_pick` receives the chosen option
## and must return the toast message. Unpausing is the caller's decision
## (it may chain straight into the next queued draft).
func show_draft(options: Array, on_pick: Callable) -> void:
	if _results_shown:
		return
	get_tree().paused = true
	_pause_button.visible = false
	_draft_panel = _build_overlay_base()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(UITheme.make_label("THE NIGHT PROVIDES", 26, Palette.PARCHMENT, true))
	column.add_child(UITheme.make_label("choose one", 11, Palette.ASH))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for option in options:
		row.add_child(_make_draft_card(option, on_pick))
	column.add_child(row)
	_center_in_overlay(_draft_panel, column)

func _make_draft_card(option: Dictionary, on_pick: Callable) -> Button:
	var card := UITheme.make_button("", 12)
	card.custom_minimum_size = Vector2(150, 132)
	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 6)
	_place(inner, 0.0, 0.0, 1.0, 1.0, Rect2(8, 8, -16, -16))
	var tag := UITheme.make_label(String(option.get("tag", "")), 9, Palette.ASH)
	inner.add_child(tag)
	var title := UITheme.make_label(String(option.get("title", "")), 14, Palette.TORCH)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(title)
	var desc := UITheme.make_label(String(option.get("desc", "")), 11, Palette.PARCHMENT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(desc)
	card.add_child(inner)
	card.pressed.connect(func() -> void:
		close_draft()
		var message: Variant = on_pick.call(option)
		if message is String and not String(message).is_empty():
			toast(String(message))
	)
	return card

func close_draft() -> void:
	if _draft_panel != null:
		_draft_panel.queue_free()
		_draft_panel = null
	_pause_button.visible = not _results_shown

func draft_open() -> bool:
	return _draft_panel != null

# --- Pause ---

func toggle_pause() -> void:
	if _results_shown or draft_open():
		return
	var tree := get_tree()
	tree.paused = not tree.paused
	_pause_button.visible = not tree.paused
	if tree.paused and _pause_panel == null:
		_build_pause_panel()
	if _pause_panel != null:
		_pause_panel.visible = tree.paused

func _build_pause_panel() -> void:
	_pause_panel = _build_overlay_base()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.add_child(UITheme.make_label("THE WATCH PAUSES", 30, Palette.PARCHMENT, true))
	var resume := UITheme.make_button("Resume the vigil")
	resume.pressed.connect(toggle_pause)
	column.add_child(resume)
	var abandon := UITheme.make_button("Abandon the night")
	abandon.pressed.connect(_abandon_run)
	column.add_child(abandon)
	panel.add_child(column)
	_center_in_overlay(_pause_panel, panel)

func _abandon_run() -> void:
	Game.end_run(false, _snapshot_stats())

# --- Results ---

func show_results(victory: bool, stats: Dictionary) -> void:
	if _results_shown:
		return
	close_draft()
	_results_shown = true
	_results_victory = victory
	_results_stats = stats
	_results_at_ms = Time.get_ticks_msec()
	_pause_button.visible = false
	queue_redraw()

	_results_panel = _build_overlay_base()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	if victory:
		column.add_child(UITheme.make_label("DAWN BREAKS", 46, Palette.TORCH, true))
		column.add_child(UITheme.make_label("the vigil holds.", 13, Palette.ASH))
	else:
		column.add_child(UITheme.make_label("THE NIGHT TAKES YOU", 46, Palette.BLOOD.lightened(0.25), true))
		column.add_child(UITheme.make_label("Hollowmere will remember.", 13, Palette.ASH))
	var seconds := int(stats.get("time", 0.0))
	column.add_child(UITheme.make_label("endured %d:%02d" % [seconds / 60, seconds % 60], 13, Palette.PARCHMENT))
	column.add_child(UITheme.make_label("%d dead put to rest" % int(stats.get("kills", 0)), 13, Palette.PARCHMENT))
	column.add_child(UITheme.make_label("reached level %d" % int(stats.get("level", 1)), 13, Palette.PARCHMENT))
	var prompt := UITheme.make_label("tap to return to camp", 12, Palette.BONE)
	column.add_child(prompt)
	_center_in_overlay(_results_panel, column)
	var tween := create_tween().set_loops()
	tween.tween_property(prompt, "modulate:a", 0.3, 0.7)
	tween.tween_property(prompt, "modulate:a", 1.0, 0.7)
	_results_panel.gui_input.connect(_on_results_input)

func _on_results_input(event: InputEvent) -> void:
	if _results_ready() and _is_press(event):
		_exit_to_title()

func _unhandled_input(event: InputEvent) -> void:
	if _results_shown:
		if _results_ready() and _is_press(event):
			_exit_to_title()
		return
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func _results_ready() -> bool:
	# Brief grace so a frantic last-moment tap doesn't skip the results.
	return Time.get_ticks_msec() - _results_at_ms > RESULTS_INPUT_DELAY_MS

func _is_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch and event.pressed:
		return true
	if event is InputEventMouseButton and event.pressed:
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return true
	return false

func _exit_to_title() -> void:
	Game.end_run(_results_victory, _results_stats)

# --- Overlay plumbing ---

func _build_overlay_base() -> Control:
	var overlay := Control.new()
	_place(overlay, 0.0, 0.0, 1.0, 1.0, Rect2(0, 0, 0, 0))
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	_place(dim, 0.0, 0.0, 1.0, 1.0, Rect2(0, 0, 0, 0))
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)
	add_child(overlay)
	return overlay

func _center_in_overlay(overlay: Control, content: Control) -> void:
	var center := CenterContainer.new()
	_place(center, 0.0, 0.0, 1.0, 1.0, Rect2(0, 0, 0, 0))
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(content)
	overlay.add_child(center)

func _snapshot_stats() -> Dictionary:
	var time_elapsed := 0.0
	if _arena != null:
		time_elapsed = _arena.time_elapsed
	return {
		"time": time_elapsed,
		"kills": _enemies.kills if _enemies != null else 0,
		"level": _player.level if _player != null else 1,
	}
