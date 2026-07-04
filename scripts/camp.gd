extends Control
## The camp between nights: campfire, character select, the WARES shop, and
## the story vignettes (each survivor's tale, told when they join the fire).

var _time := 0.0
var _coin_tex: Texture2D
var _treasury: Label
var _shop_overlay: Control
var _vignette_overlay: Control
var _ending_overlay: Control
var _ledger_overlay: Control
var _vignettes := {}
var _shop_defs := {}
var _endings := {}

## True when the design viewport is portrait-narrow (the bottom controls
## stack in two rows instead of one). Fixed per camp visit: rotation reloads
## the scene, so the layout is always built for the current orientation.
var _narrow := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_narrow = get_viewport().get_visible_rect().size.x < 400.0
	Game.orientation_changed.connect(_on_orientation_changed)
	_coin_tex = PixelSprites.get_tex("coin")
	var vignette_data: Variant = Game.load_json("res://data/story/vignettes.json")
	if vignette_data is Dictionary:
		_vignettes = vignette_data
	var shop_data: Variant = Game.load_json("res://data/shop.json")
	if shop_data is Dictionary:
		_shop_defs = shop_data
	var endings_data: Variant = Game.load_json("res://data/story/endings.json")
	if endings_data is Dictionary:
		_endings = endings_data

	var title := UITheme.make_label("THE CAMP", 32, Palette.PARCHMENT, true)
	_place(title, 0.5, 0.0, 0.5, 0.0, Rect2(-250, 10, 500, 40))
	add_child(title)

	# Once the ending is chosen, its epitaph replaces the nightly question.
	var subtitle_text := "who keeps the vigil tonight?"
	if not Game.ending().is_empty():
		subtitle_text = String(_endings.get(Game.ending(), {}).get("epitaph", subtitle_text))
	var subtitle := UITheme.make_label(subtitle_text, 11, Palette.ASH)
	_place(subtitle, 0.5, 0.0, 0.5, 0.0, Rect2(-250, 48, 500, 16))
	add_child(subtitle)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	var roster: Variant = Game.load_json("res://data/characters/_roster.json")
	if roster is Array:
		for hero_id in roster:
			row.add_child(_make_hero_column(String(hero_id)))
	# The row (618px of cards) fits the desktop canvas whole; on the mobile
	# profile (480-wide minimum) it becomes a swipeable strip instead.
	var hero_scroll := ScrollContainer.new()
	hero_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	hero_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hero_scroll.custom_minimum_size = Vector2(UITheme.fit_width(self, 624.0, 12.0), 196)
	hero_scroll.add_child(row)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(center, 0.0, 0.0, 1.0, 1.0, Rect2(0, 26, 0, -44))
	center.add_child(hero_scroll)
	add_child(center)

	# Portrait stacks the bottom controls in two rows; landscape keeps one.
	var wares := UITheme.make_button("W A R E S", 12)
	_place(wares, 0.5, 1.0, 0.5, 1.0,
		Rect2(5, -110, 124, 30) if _narrow else Rect2(-62, -40, 124, 30))
	wares.pressed.connect(func() -> void:
		Sfx.play("ui")
		_open_shop()
	)
	add_child(wares)

	var ledger := UITheme.make_button("L E D G E R", 12)
	_place(ledger, 0.5, 1.0, 0.5, 1.0,
		Rect2(-129, -110, 124, 30) if _narrow else Rect2(-196, -40, 124, 30))
	ledger.pressed.connect(func() -> void:
		Sfx.play("ui")
		_open_ledger()
	)
	add_child(ledger)

	# What the last night earned for the book (weapons and relics alike).
	if not Game.newly_unlocked_weapons.is_empty() or not Game.newly_unlocked_relics.is_empty():
		var names: Array = []
		for wid in Game.newly_unlocked_weapons:
			var wdef: Variant = Game.load_json("res://data/weapons/%s.json" % String(wid))
			if wdef is Dictionary:
				names.append(String(wdef.get("name", wid)))
		var relic_defs: Variant = Game.load_json("res://data/relics.json")
		for rid in Game.newly_unlocked_relics:
			if relic_defs is Dictionary and relic_defs.has(rid):
				names.append(String(relic_defs[rid].get("name", rid)))
		Game.newly_unlocked_weapons.clear()
		Game.newly_unlocked_relics.clear()
		if not names.is_empty():
			var grows := UITheme.make_label("the ledger grows:  %s" % ", ".join(names), 11, Palette.TORCH)
			_place(grows, 0.5, 0.0, 0.5, 0.0, Rect2(-250, 66, 500, 16))
			add_child(grows)
			var pulse := create_tween().set_loops()
			pulse.tween_property(grows, "modulate:a", 0.45, 0.8)
			pulse.tween_property(grows, "modulate:a", 1.0, 0.8)

	_build_stage_row()

	_treasury = UITheme.make_label(str(Game.gold()), 12, Color("f0cd7a"))
	_treasury.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_place(_treasury, 0.0, 1.0, 0.0, 1.0, Rect2(26, -24, 100, 16))
	add_child(_treasury)
	Game.gold_changed.connect(func(total: int) -> void:
		_treasury.text = str(total)
	)

	if float(Game.last_run.get("time", 0.0)) > 0.0:
		var seconds := int(Game.last_run.get("time", 0.0))
		var verdict := "the vigil held" if bool(Game.last_run.get("victory", false)) else "the night won"
		var text := "last night:  %s  ·  %d:%02d  ·  %d dead" % [
			verdict, seconds / 60, seconds % 60, int(Game.last_run.get("kills", 0))]
		var last_run := UITheme.make_label(text, 10, Palette.ASH)
		if _narrow:
			_place(last_run, 0.5, 1.0, 0.5, 1.0, Rect2(-129, -76, 258, 16))
		else:
			last_run.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_place(last_run, 1.0, 1.0, 1.0, 1.0, Rect2(-340, -24, 332, 16))
		add_child(last_run)

	# The very first visitor gets one nudge toward the fire.
	if not Game.hint_seen("begin"):
		var nudge_text := "tap Wren — begin the vigil" if Game.is_mobile \
			else "click a survivor — begin the vigil"
		var nudge := UITheme.make_label(nudge_text, 11, Palette.TORCH)
		_place(nudge, 0.5, 0.0, 0.5, 0.0, Rect2(-250, 66, 500, 16))
		add_child(nudge)
		var pulse := create_tween().set_loops()
		pulse.tween_property(nudge, "modulate:a", 0.4, 0.7)
		pulse.tween_property(nudge, "modulate:a", 1.0, 0.7)

	# Settings by the fire (mirrors the pause menu's toggles).
	var gear := UITheme.make_button("sound", 9)
	_place(gear, 1.0, 1.0, 1.0, 1.0, Rect2(-92, -40, 84, 30))
	gear.pressed.connect(func() -> void:
		Sfx.play("ui")
		_open_settings()
	)
	add_child(gear)

	# The Hollow King's victory poses the final choice; otherwise the very
	# first visitor gets the prologue, and newly unlocked survivors tell their
	# tale as they join the fire.
	if Game.ending_pending():
		_show_ending_choice()
	elif not Game.hint_seen("prologue"):
		Game.mark_hint("prologue")
		var pro: Variant = Game.load_json("res://data/story/prologue.json")
		if pro is Dictionary:
			_show_story_card(String(pro.get("title", "")), pro.get("lines", []), _show_next_unlock_vignette)
		else:
			_show_next_unlock_vignette()
	else:
		_show_next_unlock_vignette()

## A generic tap-to-close story card (prologue, stage intros). Same overlay as
## the hero vignettes, with the same click-through rule so it never freezes.
var _story_overlay: Control

func _show_story_card(title: String, lines: Array, on_close := Callable()) -> void:
	if _story_overlay != null:
		return
	_story_overlay = _overlay()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(UITheme.fit_width(self, 470.0), 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(UITheme.make_label(title, 26, Palette.TORCH, true))
	for line in lines:
		var text := UITheme.make_label(String(line), 11, Palette.PARCHMENT)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(UITheme.fit_width(self, 450.0, 60.0), 0)
		column.add_child(text)
	var prompt := UITheme.make_label("tap to go on", 10, Palette.BONE)
	column.add_child(prompt)
	var tween := create_tween().set_loops()
	tween.tween_property(prompt, "modulate:a", 0.35, 0.7)
	tween.tween_property(prompt, "modulate:a", 1.0, 0.7)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style())
	panel.add_child(column)
	_center(_story_overlay, panel)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var close := func(event: InputEvent) -> void:
		if _is_press(event) and _story_overlay != null:
			Sfx.play("ui")
			_story_overlay.queue_free()
			_story_overlay = null
			if on_close.is_valid():
				on_close.call()
	_story_overlay.gui_input.connect(close)
	panel.gui_input.connect(close)

## First time a night is chosen, set its scene before the vigil begins.
func _maybe_show_stage_intro(stage_id: String) -> void:
	var key := "intro_" + stage_id
	if Game.hint_seen(key):
		return
	var intros: Variant = Game.load_json("res://data/story/stage_intros.json")
	if intros is Dictionary and intros.has(stage_id):
		Game.mark_hint(key)
		var it: Dictionary = intros[stage_id]
		_show_story_card(String(it.get("title", "")), it.get("lines", []))

## The camp is a menu — rebuilding it for the new orientation is cheap and
## closes any overlay sized for the old one.
func _on_orientation_changed() -> void:
	Game.go_camp()

func _show_next_unlock_vignette() -> void:
	if Game.newly_unlocked.is_empty():
		return
	var hero_id := String(Game.newly_unlocked.pop_front())
	_show_vignette(hero_id, true)

# --- Night select: one button showing tonight's pick, opening the full list ---

var _night_overlay: Control
var _stage_row: Control

func _build_stage_row() -> void:
	if _stage_row != null:
		_stage_row.queue_free()
	var selected: Variant = Game.load_json("res://data/waves/%s.json" % Game.selected_stage)
	var night_name := Game.selected_stage
	if selected is Dictionary:
		night_name = String(selected.get("name", night_name))
	var button := UITheme.make_button("night:  > %s <" % night_name, 10)
	if _narrow:
		var night_w := UITheme.fit_width(self, 320.0, 12.0)
		_place(button, 0.5, 1.0, 0.5, 1.0, Rect2(-night_w * 0.5, -146, night_w, 26))
	else:
		_place(button, 0.5, 1.0, 0.5, 1.0, Rect2(-160, -72, 320, 26))
	button.pressed.connect(func() -> void:
		Sfx.play("ui")
		_open_night_picker()
	)
	add_child(button)
	_stage_row = button

func _night_open(requires: Dictionary) -> bool:
	match String(requires.get("type", "")):
		"":
			return true
		"stage":
			return Game.stage_cleared(String(requires.get("id", "")))
		"relics":
			var owned := 0
			for rid in Game.save_data.get("relics", {}):
				if Game.relic_unlocked(String(rid)):
					owned += 1
			return owned >= int(requires.get("value", 99))
	return false

func _night_lock_hint(requires: Dictionary) -> String:
	match String(requires.get("type", "")):
		"stage":
			var gate: Variant = Game.load_json("res://data/waves/%s.json" % String(requires.get("id", "")))
			if gate is Dictionary:
				return "survive %s first" % String(gate.get("name", "an earlier night"))
			return "the path is dark yet"
		"relics":
			return "keep %d rites first" % int(requires.get("value", 3))
	return "the path is dark yet"

func _open_night_picker() -> void:
	if _night_overlay != null:
		return
	_night_overlay = _overlay()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.add_child(UITheme.make_label("CHOOSE THE NIGHT", 24, Palette.PARCHMENT, true))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(UITheme.fit_width(self, 500.0), UITheme.fit_height(self, 220.0))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var index: Variant = Game.load_json("res://data/waves/_nights.json")
	if index is Array:
		for entry in index:
			list.add_child(_make_night_row(entry))
	scroll.add_child(list)
	column.add_child(scroll)
	var leave := UITheme.make_button("Back to the fire", 11)
	leave.pressed.connect(func() -> void:
		Sfx.play("ui")
		_night_overlay.queue_free()
		_night_overlay = null
	)
	column.add_child(leave)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style())
	panel.add_child(column)
	_center(_night_overlay, panel)

func _make_night_row(entry: Dictionary) -> Control:
	var night_id := String(entry.get("id", ""))
	var requires: Dictionary = entry.get("requires", {})
	var open := _night_open(requires)
	var night: Variant = Game.load_json("res://data/waves/%s.json" % night_id)
	var def: Dictionary = night if night is Dictionary else {}
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var pick := UITheme.make_button("", 10)
	pick.custom_minimum_size = Vector2(190, 0)
	pick.disabled = not open
	var pick_name := String(def.get("name", night_id)) if open else "? ? ?"
	if open and Game.selected_stage == night_id:
		pick_name = "> %s <" % pick_name
	pick.text = pick_name
	pick.pressed.connect(func() -> void:
		Sfx.play("ui")
		Game.selected_stage = night_id
		_night_overlay.queue_free()
		_night_overlay = null
		_build_stage_row()
		_maybe_show_stage_intro(night_id)
	)
	row.add_child(pick)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line1 := _night_status_line(night_id, def) if open else _night_lock_hint(requires)
	var status := UITheme.make_label(line1, 9, Palette.ASH)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(status)
	if open:
		var tagline := UITheme.make_label(String(def.get("tagline", "")), 9, Palette.STONE)
		tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(tagline)
	row.add_child(info)
	return row

func _night_status_line(night_id: String, def: Dictionary) -> String:
	if bool(def.get("endless", false)):
		var record: Dictionary = Game.save_data["stats"].get("long_night_best", {})
		if record.is_empty():
			return "no count yet stands"
		var seconds := int(record.get("time", 0.0))
		return "deepest count:  %d:%02d  ·  %d dead" % [seconds / 60, seconds % 60, int(record.get("kills", 0))]
	var bits: Array = []
	bits.append("survived" if Game.stage_cleared(night_id) else "unsurvived")
	var rites: Array = def.get("rites", [])
	if not rites.is_empty():
		var kept := Game.relic_unlocked(String(rites[0].get("relic", "")))
		bits.append("rite kept" if kept else "a rite waits")
	return "  ·  ".join(bits)

# --- Hero cards ---

func _make_hero_column(hero_id: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	var data: Variant = Game.load_json("res://data/characters/%s.json" % hero_id)
	var def: Dictionary = data if data is Dictionary else {}
	var unlocked := Game.is_unlocked(hero_id)
	# 6 columns × 98 + 5 × 6 = 618: fits the 640-wide minimum viewport.
	var card := UITheme.make_button("", 11)
	card.custom_minimum_size = Vector2(98, 150)
	card.disabled = not unlocked
	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 4)
	_place(inner, 0.0, 0.0, 1.0, 1.0, Rect2(6, 6, -12, -12))
	var portrait := TextureRect.new()
	portrait.texture = _portrait_texture(hero_id, String(def.get("sprite", "wren")))
	portrait.custom_minimum_size = Vector2(0, 54)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not unlocked:
		portrait.modulate = Color(0.05, 0.04, 0.07, 0.9)  # silhouette
	inner.add_child(portrait)
	if unlocked:
		inner.add_child(UITheme.make_label(String(def.get("name", hero_id)).get_slice(",", 0), 12, Palette.TORCH))
		var weapon_def: Variant = Game.load_json("res://data/weapons/%s.json" % String(def.get("weapon", "")))
		if weapon_def is Dictionary:
			inner.add_child(UITheme.make_label(String(weapon_def.get("name", "")), 9, Palette.PARCHMENT))
		var sig := UITheme.make_label(String(def.get("signature_desc", "")).get_slice(" — ", 0), 8, Palette.ASH)
		sig.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(sig)
	else:
		inner.add_child(UITheme.make_label("? ? ?", 12, Palette.STONE))
		var hint := UITheme.make_label(String(def.get("unlock_hint", "")), 8, Palette.ASH)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(hint)
	card.add_child(inner)
	column.add_child(card)
	if unlocked:
		card.pressed.connect(func() -> void:
			Sfx.play("ui")
			Game.selected_character = hero_id
			Game.start_run()
		)
		if _vignettes.has(hero_id):
			var tale := UITheme.make_button("their tale", 8)
			tale.pressed.connect(func() -> void:
				Sfx.play("ui")
				_show_vignette(hero_id, false)
			)
			column.add_child(tale)
	return column

# --- Story vignettes ---

## Pixel Lab portrait if one exists (docs/ASSET_PIPELINE.md), else the
## procedural sprite.
func _portrait_texture(hero_id: String, sprite_id: String) -> Texture2D:
	var path := "res://assets/portraits/%s.png" % hero_id
	if ResourceLoader.exists(path):
		return load(path)
	return PixelSprites.get_tex(sprite_id)

func _show_vignette(hero_id: String, from_unlock: bool) -> void:
	if not _vignettes.has(hero_id) or _vignette_overlay != null:
		return
	var vignette: Dictionary = _vignettes[hero_id]
	_vignette_overlay = _overlay()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(UITheme.fit_width(self, 460.0), 0)
	# The whole card is tap-to-close: nothing inside may swallow the click, or
	# the tap never reaches the overlay's close handler and the game "freezes"
	# (VBoxContainer defaults to MOUSE_FILTER_STOP — the actual v0.13.4 gap).
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if from_unlock:
		column.add_child(UITheme.make_label("A NEW FACE AT THE FIRE", 13, Palette.ASH))
	var face := TextureRect.new()
	face.texture = _portrait_texture(hero_id, hero_id)
	face.custom_minimum_size = Vector2(0, 84)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(face)
	column.add_child(UITheme.make_label(String(vignette.get("title", "")), 28, Palette.TORCH, true))
	for line in vignette.get("lines", []):
		var text := UITheme.make_label(String(line), 11, Palette.PARCHMENT)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(UITheme.fit_width(self, 440.0, 60.0), 0)
		column.add_child(text)
	var prompt := UITheme.make_label("tap to return to the fire", 10, Palette.BONE)
	column.add_child(prompt)
	var tween := create_tween().set_loops()
	tween.tween_property(prompt, "modulate:a", 0.35, 0.7)
	tween.tween_property(prompt, "modulate:a", 1.0, 0.7)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style())
	panel.add_child(column)
	_center(_vignette_overlay, panel)
	# Tap ANYWHERE closes — including on the panel itself, which otherwise
	# swallows the tap (PanelContainer defaults to MOUSE_FILTER_STOP; on a
	# phone the panel is most of the screen, so the game read as frozen).
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var close := func(event: InputEvent) -> void:
		if _is_press(event) and _vignette_overlay != null:
			Sfx.play("ui")
			_vignette_overlay.queue_free()
			_vignette_overlay = null
			_show_next_unlock_vignette()
	_vignette_overlay.gui_input.connect(close)
	panel.gui_input.connect(close)

# --- The ending (Block B): the Hollow King's last bargain ---

func _show_ending_choice() -> void:
	if _ending_overlay != null or not _endings.has("prompt"):
		return
	var prompt: Dictionary = _endings["prompt"]
	_ending_overlay = _overlay()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size = Vector2(UITheme.fit_width(self, 470.0), 0)
	column.add_child(UITheme.make_label(String(prompt.get("title", "")), 28, Palette.TORCH, true))
	for line in prompt.get("lines", []):
		var text := UITheme.make_label(String(line), 11, Palette.PARCHMENT)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(UITheme.fit_width(self, 450.0, 60.0), 0)
		column.add_child(text)
	for choice in prompt.get("choices", []):
		var choice_id := String(choice.get("id", ""))
		var button := UITheme.make_button(String(choice.get("label", "")), 13)
		button.pressed.connect(func() -> void:
			Sfx.play("bell")
			Game.set_ending(choice_id)
			_ending_overlay.queue_free()
			_ending_overlay = null
			_show_ending_epilogue(choice_id)
		)
		column.add_child(button)
		var hint := UITheme.make_label(String(choice.get("hint", "")), 9, Palette.ASH)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.custom_minimum_size = Vector2(UITheme.fit_width(self, 450.0, 60.0), 0)
		column.add_child(hint)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style())
	panel.add_child(column)
	_center(_ending_overlay, panel)

func _show_ending_epilogue(ending_id: String) -> void:
	if _ending_overlay != null or not _endings.has(ending_id):
		return
	var epilogue: Dictionary = _endings[ending_id]
	_ending_overlay = _overlay()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(UITheme.fit_width(self, 470.0), 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE  # tap-to-close: don't eat it
	column.add_child(UITheme.make_label(String(epilogue.get("title", "")), 28, Palette.TORCH, true))
	for line in epilogue.get("lines", []):
		var text := UITheme.make_label(String(line), 11, Palette.PARCHMENT)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(UITheme.fit_width(self, 450.0, 60.0), 0)
		column.add_child(text)
	var prompt := UITheme.make_label("tap to return to the fire", 10, Palette.BONE)
	column.add_child(prompt)
	var tween := create_tween().set_loops()
	tween.tween_property(prompt, "modulate:a", 0.35, 0.7)
	tween.tween_property(prompt, "modulate:a", 1.0, 0.7)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style())
	panel.add_child(column)
	_center(_ending_overlay, panel)
	# Same tap-anywhere rule as vignettes (the panel must not eat the tap).
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var close := func(event: InputEvent) -> void:
		if _is_press(event) and _ending_overlay != null:
			Sfx.play("ui")
			_ending_overlay.queue_free()
			_ending_overlay = null
			_show_next_unlock_vignette()
	_ending_overlay.gui_input.connect(close)
	panel.gui_input.connect(close)

# --- Settings by the fire ---

var _settings_overlay: Control

func _open_settings() -> void:
	if _settings_overlay != null:
		return
	_settings_overlay = _overlay()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.add_child(UITheme.make_label("BY THE FIRE", 24, Palette.PARCHMENT, true))
	column.add_child(_settings_toggle("Sound", "sfx_volume"))
	column.add_child(_settings_toggle("Music", "music_volume"))
	var numbers := UITheme.make_button("")
	var refresh_numbers := func() -> void:
		numbers.text = "Damage numbers: %s" % ("on" if bool(Game.settings.get("damage_numbers", true)) else "off")
	refresh_numbers.call()
	numbers.pressed.connect(func() -> void:
		Game.settings["damage_numbers"] = not bool(Game.settings.get("damage_numbers", true))
		Game.write_save()
		refresh_numbers.call()
		Sfx.play("ui")
	)
	column.add_child(numbers)
	# Destructive: erases all progress, so it takes a second tap to confirm.
	var reset := UITheme.make_button("Forget every night", 11)
	reset.pressed.connect(func() -> void:
		if reset.text == "Forget every night":
			reset.text = "tap again — this erases all progress"
			reset.add_theme_color_override("font_color", Palette.BLOOD.lightened(0.35))
			Sfx.play("ui")
		else:
			Game.reset_progress()
			Sfx.play("ui")
			Game.go_camp()  # rebuild the camp fresh (heroes relock, tallies clear)
	)
	column.add_child(reset)
	var leave := UITheme.make_button("Back to the fire", 11)
	leave.pressed.connect(func() -> void:
		Sfx.play("ui")
		_settings_overlay.queue_free()
		_settings_overlay = null
	)
	column.add_child(leave)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style())
	panel.add_child(column)
	_center(_settings_overlay, panel)

func _settings_toggle(label: String, key: String) -> Button:
	var button := UITheme.make_button("")
	var refresh := func() -> void:
		var muted := float(Game.settings.get(key, 1.0)) <= 0.01
		button.text = "%s: %s" % [label, "off" if muted else "on"]
	refresh.call()
	button.pressed.connect(func() -> void:
		var muted := float(Game.settings.get(key, 1.0)) <= 0.01
		Game.settings[key] = 1.0 if muted else 0.0
		Game.write_save()
		refresh.call()
		Sfx.play("ui")
	)
	return button

# --- The Ledger: Maud's grave-book of every weapon the vale remembers ---

func _open_ledger() -> void:
	if _ledger_overlay != null:
		return
	_ledger_overlay = _overlay()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.add_child(UITheme.make_label("THE LEDGER", 24, Palette.PARCHMENT, true))
	column.add_child(UITheme.make_label("what the vale remembers", 10, Palette.ASH))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(UITheme.fit_width(self, 500.0), UITheme.fit_height(self, 220.0))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var passives: Variant = Game.load_json("res://data/passives.json")
	var pool: Variant = Game.load_json("res://data/weapons/_pool.json")
	list.add_child(UITheme.make_label("— THE ARMORY —", 11, Palette.BONE))
	var evolutions: Array = []
	if pool is Array:
		for wid in pool:
			var def: Variant = Game.load_json("res://data/weapons/%s.json" % String(wid))
			if not (def is Dictionary):
				continue
			list.add_child(_make_ledger_row(def, Game.is_weapon_unlocked(String(wid))))
			if not String(def.get("evolution", "")).is_empty():
				evolutions.append(def)
	list.add_child(UITheme.make_label("— OLD OATHS —", 11, Palette.BONE))
	for base_def in evolutions:
		var evo: Variant = Game.load_json("res://data/weapons/%s.json" % String(base_def.get("evolution", "")))
		if not (evo is Dictionary):
			continue
		var known := Game.is_weapon_unlocked(String(base_def.get("id", "")))
		var catalyst_name := String(base_def.get("catalyst", ""))
		if passives is Dictionary and passives.has(catalyst_name):
			catalyst_name = String(passives[catalyst_name].get("name", catalyst_name))
		var recipe := "%s, carried with %s" % [String(base_def.get("name", "")), catalyst_name]
		list.add_child(_make_ledger_evo_row(evo, known, recipe))
	# Relics: earned by keeping rites; the Reliquary Chain adds a second slot.
	list.add_child(UITheme.make_label("— RELICS (carry %d) —" % Game.relic_slots(), 11, Palette.BONE))
	var relic_defs: Variant = Game.load_json("res://data/relics.json")
	if relic_defs is Dictionary:
		for relic_id in relic_defs:
			list.add_child(_make_relic_row(String(relic_id), relic_defs[relic_id]))
	# The Bestiary: every dead thing the vale has shown you, and your tally.
	var book: Dictionary = Game.save_data.get("stats", {}).get("bestiary", {})
	var seen_count := book.size()
	var enemy_defs: Variant = Game.load_json("res://data/enemies.json")
	var enemy_total: int = enemy_defs.size() if enemy_defs is Dictionary else 0
	list.add_child(UITheme.make_label("— THE BESTIARY (%d / %d) —" % [seen_count, enemy_total], 11, Palette.BONE))
	if enemy_defs is Dictionary:
		for enemy_id in enemy_defs:
			list.add_child(_make_bestiary_row(String(enemy_id), enemy_defs[enemy_id], book))
	scroll.add_child(list)
	column.add_child(scroll)
	var leave := UITheme.make_button("Close the book", 11)
	leave.pressed.connect(func() -> void:
		Sfx.play("ui")
		_ledger_overlay.queue_free()
		_ledger_overlay = null
	)
	column.add_child(leave)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style())
	panel.add_child(column)
	_center(_ledger_overlay, panel)

func _make_ledger_row(def: Dictionary, unlocked: bool) -> HBoxContainer:
	var name_text := String(def.get("name", "?")) if unlocked else "? ? ?"
	var desc_text := String(def.get("draft_desc", "")) if unlocked \
		else String(def.get("unlock_hint", "its page is still blank"))
	return _ledger_line("weapons/" + String(def.get("id", "")), name_text, desc_text, unlocked)

func _make_ledger_evo_row(evo: Dictionary, known: bool, recipe: String) -> HBoxContainer:
	var name_text := String(evo.get("name", "?")) if known else "? ? ?"
	var desc_text := recipe if known else "a weapon's final form, unproven"
	return _ledger_line("weapons/" + String(evo.get("id", "")), name_text, desc_text, known)

func _make_relic_row(relic_id: String, def: Dictionary) -> HBoxContainer:
	var unlocked := Game.relic_unlocked(relic_id)
	var name_text := String(def.get("name", "?")) if unlocked else "? ? ?"
	var desc_text := String(def.get("desc", "")) if unlocked else String(def.get("hint", ""))
	var row := _ledger_line("relics/" + relic_id, name_text, desc_text, unlocked)
	if unlocked:
		var equip := UITheme.make_button("", 9)
		equip.custom_minimum_size = Vector2(84, 0)
		var refresh := func() -> void:
			equip.text = "CARRIED" if Game.relic_active(relic_id) else "carry"
		refresh.call()
		equip.pressed.connect(func() -> void:
			Sfx.play("buy")
			Game.equip_relic(relic_id)
			# Rebuild the book so every row's button reflects the single slot.
			_ledger_overlay.queue_free()
			_ledger_overlay = null
			_open_ledger()
		)
		row.add_child(equip)
	return row

func _ledger_line(icon_id: String, name_text: String, desc_text: String, unlocked: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_path := "res://assets/icons/%s.png" % icon_id
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
		if not unlocked:
			icon.modulate = Color(0.12, 0.11, 0.16)  # silhouette, like locked heroes
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := UITheme.make_label(name_text, 12, Palette.TORCH if unlocked else Palette.STONE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(name_label)
	var desc := UITheme.make_label(desc_text, 9, Palette.PARCHMENT if unlocked else Palette.ASH)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc)
	row.add_child(info)
	return row

## A bestiary entry: the enemy's own sprite (silhouetted until first seen),
## its name and lore, and how many you have put down. `book` is the lifetime
## {id: kills} tally — a present key means you have met this one.
func _make_bestiary_row(enemy_id: String, def: Dictionary, book: Dictionary) -> HBoxContainer:
	var seen := book.has(enemy_id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sprite_path := "res://assets/sprites/generated/%s.png" % String(def.get("sprite", enemy_id))
	if ResourceLoader.exists(sprite_path):
		icon.texture = load(sprite_path)
		if not seen:
			icon.modulate = Color(0.1, 0.09, 0.14)  # a shape in the dark
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tier := ""
	if bool(def.get("boss", false)):
		tier = "  ·  a lord of the night"
	elif bool(def.get("elite", false)):
		tier = "  ·  a greater dead"
	var name_text := (String(def.get("name", "?")) + tier) if seen else "? ? ?"
	var name_label := UITheme.make_label(name_text, 12, Palette.TORCH if seen else Palette.STONE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(name_label)
	var desc_text := String(def.get("lore", "")) if seen else "not yet met — walk the nights and it will find you"
	var desc := UITheme.make_label(desc_text, 9, Palette.PARCHMENT if seen else Palette.ASH)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc)
	if seen:
		var count := int(book.get(enemy_id, 0))
		var tally := "put to rest:  %d" % count if count > 0 else "seen, but never felled"
		var tally_label := UITheme.make_label(tally, 9, Palette.ASH)
		tally_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(tally_label)
	row.add_child(info)
	return row

# --- The WARES shop ---

func _open_shop() -> void:
	if _shop_overlay != null:
		return
	_shop_overlay = _overlay()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.add_child(UITheme.make_label("WARES OF THE WAKING", 24, Palette.PARCHMENT, true))
	# The rows scroll so the leave button always stays on screen (the mobile
	# profile's shorter viewport can't fit all wares at once).
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(UITheme.fit_width(self, 420.0),
		UITheme.fit_height(self, 240.0))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item_id in _shop_defs:
		rows.add_child(_make_shop_row(String(item_id)))
	scroll.add_child(rows)
	column.add_child(scroll)
	var leave := UITheme.make_button("Back to the fire", 11)
	leave.pressed.connect(func() -> void:
		Sfx.play("ui")
		_shop_overlay.queue_free()
		_shop_overlay = null
	)
	column.add_child(leave)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style())
	panel.add_child(column)
	_center(_shop_overlay, panel)

func _make_shop_row(item_id: String) -> HBoxContainer:
	var def: Dictionary = _shop_defs[item_id]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(280, 0)
	var name_label := UITheme.make_label("", 12, Palette.TORCH)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(name_label)
	var desc := UITheme.make_label(String(def.get("desc", "")), 9, Palette.ASH)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(desc)
	row.add_child(info)
	var buy := UITheme.make_button("", 10)
	buy.custom_minimum_size = Vector2(92, 0)
	row.add_child(buy)
	var refresh := func() -> void:
		var rank := Game.shop_level(item_id)
		var maxed := rank >= int(def.get("max", 1))
		name_label.text = "%s  %s" % [String(def.get("name", item_id)), _pips(rank, int(def.get("max", 1)))]
		buy.text = "OWNED" if maxed else "%d gold" % Game.shop_cost(item_id, def)
		buy.disabled = maxed or Game.gold() < Game.shop_cost(item_id, def)
	refresh.call()
	buy.pressed.connect(func() -> void:
		if Game.shop_buy(item_id, def):
			Sfx.play("buy")
			refresh.call()
			_refresh_shop_rows()
		else:
			Sfx.play("ui", 0.5)
	)
	row.set_meta("refresh", refresh)
	return row

## Re-evaluate every row's affordability after any purchase.
func _refresh_shop_rows() -> void:
	if _shop_overlay == null:
		return
	for row in _find_shop_rows(_shop_overlay):
		var refresh: Variant = row.get_meta("refresh")
		if refresh is Callable:
			refresh.call()

func _find_shop_rows(node: Node) -> Array:
	var found: Array = []
	for child in node.get_children():
		if child is HBoxContainer and child.has_meta("refresh"):
			found.append(child)
		found.append_array(_find_shop_rows(child))
	return found

func _pips(rank: int, max_rank: int) -> String:
	# Plain digits: the pixel font lacks the ●/○ glyphs (QA sweep finding).
	return "%d/%d" % [rank, max_rank]

# --- Overlay plumbing ---

func _overlay() -> Control:
	var overlay := Control.new()
	_place(overlay, 0.0, 0.0, 1.0, 1.0, Rect2(0, 0, 0, 0))
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(dim, 0.0, 0.0, 1.0, 1.0, Rect2(0, 0, 0, 0))
	overlay.add_child(dim)
	add_child(overlay)
	return overlay

func _center(overlay: Control, content: Control) -> void:
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(center, 0.0, 0.0, 1.0, 1.0, Rect2(0, 0, 0, 0))
	center.add_child(content)
	overlay.add_child(center)

func _is_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch and event.pressed:
		return true
	if event is InputEventMouseButton and event.pressed:
		return true
	return false

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
	_time += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	# Night sky.
	var bands := 10
	for band in bands:
		var f := float(band) / float(bands)
		draw_rect(Rect2(0, f * h * 0.75, w, h * 0.75 / float(bands) + 1.0),
			Palette.INK.lerp(Palette.NIGHT_HIGH, f * 0.6))
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in 40:
		var star := Vector2(rng.randf() * w, rng.randf() * h * 0.5)
		var twinkle := 0.5 + 0.5 * sin(_time * rng.randf_range(0.5, 1.8) + float(i))
		draw_rect(Rect2(star, Vector2(1.5, 1.5)),
			Color(Palette.MOON.r, Palette.MOON.g, Palette.MOON.b, 0.1 + 0.22 * twinkle))
	# Ground.
	draw_rect(Rect2(0, h * 0.75, w, h * 0.25), Color(0.08, 0.07, 0.1))
	# The campfire, low center — glow, logs, flames.
	var fire := Vector2(w * 0.5, h * 0.87)
	var flicker := 0.8 + 0.2 * sin(_time * 9.0) * sin(_time * 5.3)
	for glow in 4:
		draw_circle(fire, 14.0 + float(glow) * 16.0,
			Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, 0.035 * flicker))
	draw_rect(Rect2(fire + Vector2(-14, 2), Vector2(28, 4)), Color(0.22, 0.15, 0.1))
	draw_rect(Rect2(fire + Vector2(-9, 5), Vector2(18, 3)), Color(0.18, 0.12, 0.08))
	for flame in 3:
		var sway := sin(_time * (6.0 + float(flame) * 1.7) + float(flame) * 2.1) * 2.5
		var flame_h := 10.0 + 4.0 * sin(_time * 7.0 + float(flame) * 1.3)
		var base := fire + Vector2(float(flame - 1) * 5.0, 0.0)
		draw_circle(base + Vector2(sway * 0.4, -flame_h * 0.4), 4.5 - float(flame), Palette.EMBER)
		draw_circle(base + Vector2(sway, -flame_h * 0.75), 3.0 - float(flame) * 0.6, Palette.TORCH)
	# Sparks.
	for spark in 4:
		var phase := fmod(_time * 0.6 + float(spark) * 0.27, 1.0)
		var spark_pos := fire + Vector2(sin(_time * 2.0 + float(spark) * 3.0) * 6.0, -6.0 - phase * 34.0)
		draw_rect(Rect2(spark_pos, Vector2(1.5, 1.5)),
			Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, (1.0 - phase) * 0.7))
	# Survivors' silhouettes by the fire (one per unlocked hero).
	var seats := [Vector2(-34.0, -3.0), Vector2(32.0, -2.0), Vector2(-52.0, 4.0),
		Vector2(50.0, 5.0), Vector2(-18.0, 7.0), Vector2(16.0, 8.0)]
	var roster: Variant = Game.load_json("res://data/characters/_roster.json")
	var seat := 0
	if roster is Array:
		for hero_id in roster:
			if not Game.is_unlocked(String(hero_id)) or seat >= seats.size():
				continue
			var at: Vector2 = fire + seats[seat]
			seat += 1
			var shade := Color(0.07, 0.06, 0.1)
			draw_circle(at + Vector2(0, -9), 3.5, shade)
			draw_rect(Rect2(at + Vector2(-4, -6), Vector2(8, 8)), shade)
