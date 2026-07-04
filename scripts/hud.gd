class_name HUD
extends Control
## All in-run UI: HP/XP bars, night timer, kill count, level-up toasts, damage
## vignette, pause menu, and the results overlay. Built entirely from UITheme
## so every screen shares one visual language.

const XP_BAR_HEIGHT := 5.0
const RESULTS_INPUT_DELAY_MS := 600
const TRAY_POS := Vector2(14, 46)  # 3+3 build tray under the gold count
const TRAY_SLOT := 16.0
const TRAY_GAP := 4.0

var _arena  # untyped: arena exposes time_elapsed / run_length()
var _player: Player
var _enemies: EnemyManager

var _timer_label: Label
var _kills_label: Label
var _level_label: Label
var _gold_label: Label
var _boss_label: Label
var _coin_tex: Texture2D
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
var _move_hint: Label
var _results_shown := false
var _results_victory := false
var _results_stats := {}
var _results_at_ms := 0

# Orientation-aware statics: portrait's 270-wide canvas squeezes the top row,
# so the HP bar shortens and the timer shrinks. Recomputed on rotation.
var _narrow := false
var _hp_rect := Rect2(14, 12, 150, 10)

# The open draft's arguments, kept so rotation can rebuild it for the new
# canvas (the card row flips between horizontal and vertical).
var _draft_args: Array = []

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
	add_child(_timer_label)

	_kills_label = UITheme.make_label("0", 13, Palette.ASH)
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_kills_label)

	_coin_tex = PixelSprites.get_tex("coin")
	_gold_label = UITheme.make_label("0", 11, Color("f0cd7a"))
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_gold_label)

	_boss_label = UITheme.make_label("", 12, Palette.PARCHMENT, true)
	_boss_label.visible = false
	add_child(_boss_label)

	_level_label = UITheme.make_label("LV 1", 12, Palette.TORCH)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_level_label)

	_toast_box = VBoxContainer.new()
	_toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_box)

	_pause_button = UITheme.make_button("II", 12)
	_pause_button.pressed.connect(toggle_pause)
	add_child(_pause_button)

	# First night ever: one movement nudge, gone the moment they move.
	if not Game.hint_seen("move"):
		_move_hint = UITheme.make_label("touch and drag anywhere to move", 12, Palette.BONE)
		add_child(_move_hint)

	_layout_statics()
	Game.orientation_changed.connect(_on_orientation_changed)

## Anchors + sizes for the always-on HUD, chosen for the current canvas.
## Called at build and again whenever the phone rotates mid-run.
func _layout_statics() -> void:
	_narrow = get_viewport().get_visible_rect().size.x < 400.0
	_hp_rect = Rect2(14, 12, 80.0 if _narrow else 150.0, 10)
	_timer_label.label_settings.font_size = 22 if _narrow else 30
	_place(_timer_label, 0.5, 0.0, 0.5, 0.0,
		Rect2(-56, 4, 112, 28) if _narrow else Rect2(-70, 2, 140, 34))
	_place(_kills_label, 1.0, 0.0, 1.0, 0.0, Rect2(-86, 10, 60, 18))
	_place(_gold_label, 0.0, 0.0, 0.0, 0.0, Rect2(26, 26, 90, 14))
	var boss_w := UITheme.fit_width(self, 280.0, 12.0)
	_place(_boss_label, 0.5, 1.0, 0.5, 1.0, Rect2(-boss_w * 0.5, -42, boss_w, 16))
	_place(_level_label, 0.0, 1.0, 0.0, 1.0, Rect2(10, -26, 80, 16))
	var toast_w := UITheme.fit_width(self, 320.0, 36.0)
	_place(_toast_box, 0.5, 0.0, 0.5, 0.0, Rect2(-toast_w * 0.5, 42, toast_w, 90))
	_place(_pause_button, 1.0, 0.0, 1.0, 0.0, Rect2(-42, 34, 32, 28))
	if _move_hint != null:
		var hint_w := UITheme.fit_width(self, 400.0, 20.0)
		_place(_move_hint, 0.5, 0.5, 0.5, 0.5, Rect2(-hint_w * 0.5, 40, hint_w, 18))

func _on_orientation_changed() -> void:
	_layout_statics()
	# Overlays were sized for the old canvas: rebuild the ones that are open.
	if _pause_panel != null:
		var was_open := _pause_panel.visible
		_pause_panel.queue_free()
		_pause_panel = null
		if was_open:
			_build_pause_panel()
	if _draft_panel != null and _draft_args.size() == 4:
		show_draft(_draft_args[0], _draft_args[1], _draft_args[2], _draft_args[3])

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
		# Endless nights count up; every other night counts down to the bell.
		var shown: float = _arena.time_elapsed if _arena.is_endless() \
			else maxf(0.0, _arena.run_length() - _arena.time_elapsed)
		_timer_label.text = "%d:%02d" % [int(shown) / 60, int(shown) % 60]
	if _enemies != null:
		_kills_label.text = str(_enemies.kills)
		_boss_label.visible = _enemies.boss_active()
	if _player != null:
		_level_label.text = "LV %d" % _player.level
	_gold_label.text = str(Game.gold())
	_hp_frac = lerpf(_hp_frac, _hp_target, minf(1.0, delta * 10.0))
	_vignette = maxf(0.0, _vignette - delta * 1.6)
	_xp_flash = maxf(0.0, _xp_flash - delta * 2.2)
	if _move_hint != null:
		_move_hint.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 350.0)
		if _player != null and _player.velocity.length_squared() > 1.0:
			Game.mark_hint("move")
			_move_hint.queue_free()
			_move_hint = null
	queue_redraw()

func _draw() -> void:
	if _results_shown:
		return
	var w := size.x
	var h := size.y
	# --- HP bar (top left): iron frame, ink well, blood fill with a lit top edge ---
	draw_rect(Rect2(_hp_rect.position - Vector2.ONE, _hp_rect.size + Vector2.ONE * 2.0), Palette.IRON)
	draw_rect(_hp_rect, Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.9))
	var frac := clampf(_hp_frac, 0.0, 1.0)
	if frac > 0.0:
		var fill := Rect2(_hp_rect.position + Vector2.ONE, Vector2((_hp_rect.size.x - 2.0) * frac, _hp_rect.size.y - 2.0))
		draw_rect(fill, Palette.BLOOD)
		draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2.0)), Palette.BLOOD.lightened(0.25))
	for notch in range(1, 4):
		var nx := _hp_rect.position.x + _hp_rect.size.x * 0.25 * float(notch)
		draw_rect(Rect2(nx, _hp_rect.position.y, 1.0, _hp_rect.size.y), Color(0, 0, 0, 0.35))
	# --- Kill counter skull icon (next to the number, top right) ---
	if _skull_tex != null:
		draw_texture(_skull_tex, Vector2(w - 100.0, 12.0))
	# --- Gold coin icon (under the HP bar) ---
	if _coin_tex != null:
		draw_texture(_coin_tex, Vector2(15.0, 30.0))
	_draw_build_tray()
	# --- Boss HP bar (bottom center, above the XP bar) ---
	if _enemies != null and _enemies.boss_active():
		var bar_w := minf(w * 0.5, 280.0)
		var bar := Rect2((w - bar_w) * 0.5, h - 22.0, bar_w, 7.0)
		draw_rect(Rect2(bar.position - Vector2.ONE, bar.size + Vector2.ONE * 2.0), Palette.IRON)
		draw_rect(bar, Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.9))
		var boss_frac := _enemies.boss_hp_frac()
		if boss_frac > 0.0:
			var boss_fill := Rect2(bar.position + Vector2.ONE,
				Vector2((bar.size.x - 2.0) * boss_frac, bar.size.y - 2.0))
			draw_rect(boss_fill, Palette.EMBER)
			draw_rect(Rect2(boss_fill.position, Vector2(boss_fill.size.x, 1.0)), Palette.TORCH)
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

## The 3+3 build tray: a row of weapon slots over a row of keepsake slots.
## Icons from assets/icons/{weapons,passives}/<id>.png when present; a plain
## initial letter otherwise (procedural-fallback doctrine).
func _draw_build_tray() -> void:
	if _player == null:
		return
	var font := UITheme.body_font()
	for i in Player.MAX_WEAPONS:
		var slot := Rect2(TRAY_POS + Vector2(float(i) * (TRAY_SLOT + TRAY_GAP), 0.0),
			Vector2(TRAY_SLOT, TRAY_SLOT))
		_draw_tray_slot(slot, i < _player.weapons.size())
		if i < _player.weapons.size():
			var weapon: Weapon = _player.weapons[i]
			_draw_tray_content(slot, "weapons", weapon.weapon_id(),
				weapon.display_name(), font)
			if font != null:  # level, small, bottom-right corner
				draw_string(font, slot.position + Vector2(TRAY_SLOT - 5.0, TRAY_SLOT - 1.0),
					str(weapon.level), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Palette.TORCH)
	var passive_ids := _player.passive_stacks.keys()
	for i in Player.MAX_PASSIVES:
		var slot := Rect2(TRAY_POS + Vector2(float(i) * (TRAY_SLOT + TRAY_GAP), TRAY_SLOT + TRAY_GAP),
			Vector2(TRAY_SLOT, TRAY_SLOT))
		_draw_tray_slot(slot, i < passive_ids.size())
		if i < passive_ids.size():
			var pid := String(passive_ids[i])
			_draw_tray_content(slot, "passives", pid, pid, font)
			if font != null:
				draw_string(font, slot.position + Vector2(TRAY_SLOT - 5.0, TRAY_SLOT - 1.0),
					str(int(_player.passive_stacks[pid])), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Palette.BONE)

func _draw_tray_slot(slot: Rect2, filled: bool) -> void:
	draw_rect(Rect2(slot.position - Vector2.ONE, slot.size + Vector2.ONE * 2.0),
		Color(Palette.IRON.r, Palette.IRON.g, Palette.IRON.b, 0.8 if filled else 0.35))
	draw_rect(slot, Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.85 if filled else 0.5))

func _draw_tray_content(slot: Rect2, kind: String, id: String, display: String, font: Font) -> void:
	var tex := _icon(kind, id)
	if tex != null:
		draw_texture_rect(tex, slot.grow(-1.0), false)
	elif font != null and not display.is_empty():
		draw_string(font, slot.position + Vector2(4.0, TRAY_SLOT - 4.0),
			display.substr(0, 1).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.PARCHMENT)

var _icon_cache := {}

## Lazy icon lookup; a missing file caches as null so we only probe once.
func _icon(kind: String, id: String) -> Texture2D:
	var key := kind + "/" + id
	if _icon_cache.has(key):
		return _icon_cache[key]
	var path := "res://assets/icons/%s/%s.png" % [kind, id]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_icon_cache[key] = tex
	return tex

# --- Signal handlers ---

func _on_hp_changed(current: float, max_value: float) -> void:
	_hp_target = 0.0 if max_value <= 0.0 else clampf(current / max_value, 0.0, 1.0)

func _on_hurt(_amount: float) -> void:
	_vignette = 1.0

func _on_leveled_up(_level: int) -> void:
	_xp_flash = 1.0

## Names the boss above the boss HP bar.
func set_boss_name(display_name: String) -> void:
	_boss_label.text = display_name

## Full-screen announcement (boss arrivals): big title + subtitle, fades away.
func banner(title: String, subtitle: String) -> void:
	var holder := VBoxContainer.new()
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var banner_w := UITheme.fit_width(self, 520.0, 12.0)
	_place(holder, 0.5, 0.5, 0.5, 0.5, Rect2(-banner_w * 0.5, -90, banner_w, 80))
	var banner_title := UITheme.make_label(title, 26 if _narrow else 40, Palette.TORCH, true)
	banner_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	holder.add_child(banner_title)
	holder.add_child(UITheme.make_label(subtitle, 12, Palette.ASH))
	add_child(holder)
	holder.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(holder, "modulate:a", 1.0, 0.35)
	tween.tween_interval(1.8)
	tween.tween_property(holder, "modulate:a", 0.0, 0.7)
	tween.tween_callback(holder.queue_free)

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
## (it may chain straight into the next queued draft). Passing a valid
## `on_reroll` adds a gold-costing reroll button (Brotato lesson, WP8).
func show_draft(options: Array, on_pick: Callable, reroll_cost := 0, on_reroll := Callable()) -> void:
	if _results_shown:
		return
	get_tree().paused = true
	_pause_button.visible = false
	close_draft()  # rerolls replace the open panel
	_pause_button.visible = false
	_draft_args = [options, on_pick, reroll_cost, on_reroll]
	_draft_panel = _build_overlay_base()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8 if _narrow else 12)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(UITheme.make_label("THE NIGHT PROVIDES", 22 if _narrow else 26, Palette.PARCHMENT, true))
	column.add_child(UITheme.make_label("choose one", 11, Palette.ASH))
	if not Game.hint_seen("draft"):
		Game.mark_hint("draft")
		var build_hint := UITheme.make_label("a build is 3 weapons and 3 keepsakes — choose like it matters", 9, Palette.STONE)
		build_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		build_hint.custom_minimum_size = Vector2(UITheme.fit_width(self, 340.0, 30.0), 0)
		column.add_child(build_hint)
	# Portrait: the three cards stack vertically (wide and short) instead of
	# side by side (the 270-wide canvas can't fit three readable columns).
	var row: BoxContainer = VBoxContainer.new() if _narrow else HBoxContainer.new()
	row.add_theme_constant_override("separation", 8 if _narrow else 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for option in options:
		row.add_child(_make_draft_card(option, on_pick))
	column.add_child(row)
	if on_reroll.is_valid():
		var reroll := UITheme.make_button("Reroll  ·  %d gold" % reroll_cost, 10)
		reroll.disabled = Game.gold() < reroll_cost
		reroll.pressed.connect(func() -> void:
			Sfx.play("ui")
			on_reroll.call()
		)
		var reroll_center := HBoxContainer.new()
		reroll_center.alignment = BoxContainer.ALIGNMENT_CENTER
		reroll_center.add_child(reroll)
		column.add_child(reroll_center)
	_gold_label.text = str(Game.gold())
	_center_in_overlay(_draft_panel, column)

func _make_draft_card(option: Dictionary, on_pick: Callable) -> Button:
	var card := UITheme.make_button("", 12)
	var vw := get_viewport().get_visible_rect().size.x
	card.custom_minimum_size = Vector2(minf(240.0, vw - 30.0), 96) if _narrow \
		else Vector2(minf(150.0, (vw - 72.0) / 3.0), 132)
	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 6)
	_place(inner, 0.0, 0.0, 1.0, 1.0, Rect2(8, 8, -16, -16))
	var tag := UITheme.make_label(String(option.get("tag", "")), 9, Palette.ASH)
	inner.add_child(tag)
	# Icon (when the asset exists): weapon or keepsake, drawn above the title.
	var icon_tex := _draft_icon(option)
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(0, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(icon)
	var title := UITheme.make_label(String(option.get("title", "")), 14, Palette.TORCH)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(title)
	var desc := UITheme.make_label(String(option.get("desc", "")), 11, Palette.PARCHMENT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(desc)
	card.add_child(inner)
	card.pressed.connect(func() -> void:
		Sfx.play("ui")
		close_draft()
		var message: Variant = on_pick.call(option)
		if message is String and not String(message).is_empty():
			toast(String(message))
	)
	return card

func _draft_icon(option: Dictionary) -> Texture2D:
	match String(option.get("type", "")):
		"weapon_up":
			var weapon: Weapon = option.get("weapon")
			if weapon != null:
				return _icon("weapons", weapon.weapon_id())
		"weapon_new":
			return _icon("weapons", String(option.get("id", "")))
		"passive":
			return _icon("passives", String(option.get("id", "")))
	return null

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
	column.add_child(UITheme.make_label("THE WATCH PAUSES", 22 if _narrow else 30, Palette.PARCHMENT, true))
	var resume := UITheme.make_button("Resume the vigil")
	resume.pressed.connect(func() -> void:
		Sfx.play("ui")
		toggle_pause()
	)
	column.add_child(resume)
	var sound := UITheme.make_button(_sound_label())
	sound.pressed.connect(func() -> void:
		var muted := float(Game.settings.get("sfx_volume", 1.0)) <= 0.01
		Game.settings["sfx_volume"] = 1.0 if muted else 0.0
		Game.write_save()
		sound.text = _sound_label()
		Sfx.play("ui")
	)
	column.add_child(sound)
	var music := UITheme.make_button(_music_label())
	music.pressed.connect(func() -> void:
		var muted := float(Game.settings.get("music_volume", 1.0)) <= 0.01
		Game.settings["music_volume"] = 1.0 if muted else 0.0
		Game.write_save()
		music.text = _music_label()
		Sfx.play("ui")
	)
	column.add_child(music)
	var numbers := UITheme.make_button(_numbers_label())
	numbers.pressed.connect(func() -> void:
		Game.settings["damage_numbers"] = not bool(Game.settings.get("damage_numbers", true))
		Game.write_save()
		numbers.text = _numbers_label()
		Sfx.play("ui")
	)
	column.add_child(numbers)
	if OS.has_feature("web"):
		var full := UITheme.make_button("Fullscreen")
		full.pressed.connect(func() -> void:
			Sfx.play("ui")
			JavaScriptBridge.eval(
				"document.fullscreenElement ? document.exitFullscreen() : (document.documentElement.requestFullscreen && document.documentElement.requestFullscreen())",
				true)
		)
		column.add_child(full)
	var restart := UITheme.make_button("Restart the night")
	restart.pressed.connect(func() -> void:
		if restart.text == "Restart the night":
			restart.text = "tap again — the night restarts"
			Sfx.play("ui")
		else:
			Game.start_run()
	)
	column.add_child(restart)
	var abandon := UITheme.make_button("Abandon the night")
	abandon.pressed.connect(_abandon_run)
	column.add_child(abandon)
	panel.add_child(column)
	_center_in_overlay(_pause_panel, panel)

func _sound_label() -> String:
	return "Sound: off" if float(Game.settings.get("sfx_volume", 1.0)) <= 0.01 else "Sound: on"

func _music_label() -> String:
	return "Music: off" if float(Game.settings.get("music_volume", 1.0)) <= 0.01 else "Music: on"

func _numbers_label() -> String:
	return "Damage numbers: on" if bool(Game.settings.get("damage_numbers", true)) else "Damage numbers: off"

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
	# 22 on the 270-wide canvas: "THE NIGHT TAKES YOU" must fit edge to edge.
	var headline := 22 if _narrow else 46
	if victory:
		column.add_child(UITheme.make_label("DAWN BREAKS", headline, Palette.TORCH, true))
		column.add_child(UITheme.make_label("the vigil holds.", 13, Palette.ASH))
	else:
		column.add_child(UITheme.make_label("THE NIGHT TAKES YOU", headline, Palette.BLOOD.lightened(0.25), true))
		column.add_child(UITheme.make_label("Hollowmere will remember.", 13, Palette.ASH))
	var seconds := int(stats.get("time", 0.0))
	column.add_child(UITheme.make_label("endured %d:%02d" % [seconds / 60, seconds % 60], 13, Palette.PARCHMENT))
	column.add_child(UITheme.make_label("%d dead put to rest" % int(stats.get("kills", 0)), 13, Palette.PARCHMENT))
	column.add_child(UITheme.make_label("reached level %d" % int(stats.get("level", 1)), 13, Palette.PARCHMENT))
	var rite_line := String(stats.get("rite", ""))
	if not rite_line.is_empty():
		column.add_child(UITheme.make_label(rite_line, 11,
			Palette.TORCH if rite_line.contains("kept") and not rite_line.contains("unkept") else Palette.ASH))
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
		"elite_kills": _enemies.elite_kills if _enemies != null else 0,
		"level": _player.level if _player != null else 1,
	}
