extends Control
## The camp between nights: campfire, character select, the WARES shop, and
## the story vignettes (each survivor's tale, told when they join the fire).

var _time := 0.0
var _coin_tex: Texture2D
var _treasury: Label
var _shop_overlay: Control
var _vignette_overlay: Control
var _vignettes := {}
var _shop_defs := {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_coin_tex = PixelSprites.get_tex("coin")
	var vignette_data: Variant = Game.load_json("res://data/story/vignettes.json")
	if vignette_data is Dictionary:
		_vignettes = vignette_data
	var shop_data: Variant = Game.load_json("res://data/shop.json")
	if shop_data is Dictionary:
		_shop_defs = shop_data

	var title := UITheme.make_label("THE CAMP", 32, Palette.PARCHMENT, true)
	_place(title, 0.5, 0.0, 0.5, 0.0, Rect2(-250, 10, 500, 40))
	add_child(title)

	var subtitle := UITheme.make_label("who keeps the vigil tonight?", 11, Palette.ASH)
	_place(subtitle, 0.5, 0.0, 0.5, 0.0, Rect2(-250, 48, 500, 16))
	add_child(subtitle)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var roster: Variant = Game.load_json("res://data/characters/_roster.json")
	if roster is Array:
		for hero_id in roster:
			row.add_child(_make_hero_column(String(hero_id)))
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(center, 0.0, 0.0, 1.0, 1.0, Rect2(0, 26, 0, -44))
	center.add_child(row)
	add_child(center)

	var wares := UITheme.make_button("W A R E S", 12)
	_place(wares, 0.5, 1.0, 0.5, 1.0, Rect2(-62, -40, 124, 30))
	wares.pressed.connect(func() -> void:
		Sfx.play("ui")
		_open_shop()
	)
	add_child(wares)

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
		last_run.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_place(last_run, 1.0, 1.0, 1.0, 1.0, Rect2(-340, -24, 332, 16))
		add_child(last_run)

	# Newly unlocked survivors tell their tale as they join the fire.
	_show_next_unlock_vignette()

func _show_next_unlock_vignette() -> void:
	if Game.newly_unlocked.is_empty():
		return
	var hero_id := String(Game.newly_unlocked.pop_front())
	_show_vignette(hero_id, true)

# --- Stage select (the forest opens once the village is survived) ---

func _build_stage_row() -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	_place(row, 0.5, 1.0, 0.5, 1.0, Rect2(-220, -72, 440, 26))
	var stages := [
		["stage1", "Hollowmere Village", true],
		["stage2", "The Wailing Forest", Game.stage_cleared("stage1")],
	]
	for entry in stages:
		var stage_id: String = entry[0]
		var open: bool = entry[2]
		var text: String = entry[1] if open else "the path is dark yet"
		if Game.selected_stage == stage_id:
			text = "> %s <" % text
		var button := UITheme.make_button(text, 9)
		button.disabled = not open
		button.pressed.connect(func() -> void:
			Sfx.play("ui")
			Game.selected_stage = stage_id
			row.queue_free()
			_build_stage_row()
		)
		row.add_child(button)
	add_child(row)

# --- Hero cards ---

func _make_hero_column(hero_id: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	var data: Variant = Game.load_json("res://data/characters/%s.json" % hero_id)
	var def: Dictionary = data if data is Dictionary else {}
	var unlocked := Game.is_unlocked(hero_id)
	# 5 columns × 118 + 4 × 8 = 622: fits the 640-wide minimum viewport.
	var card := UITheme.make_button("", 11)
	card.custom_minimum_size = Vector2(118, 150)
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
	column.custom_minimum_size = Vector2(460, 0)
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
		text.custom_minimum_size = Vector2(440, 0)
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
	_vignette_overlay.gui_input.connect(func(event: InputEvent) -> void:
		if _is_press(event):
			Sfx.play("ui")
			_vignette_overlay.queue_free()
			_vignette_overlay = null
			_show_next_unlock_vignette()
	)

# --- The WARES shop ---

func _open_shop() -> void:
	if _shop_overlay != null:
		return
	_shop_overlay = _overlay()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.add_child(UITheme.make_label("WARES OF THE WAKING", 24, Palette.PARCHMENT, true))
	for item_id in _shop_defs:
		column.add_child(_make_shop_row(String(item_id)))
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
	var seats := [Vector2(-34.0, -3.0), Vector2(32.0, -2.0), Vector2(-52.0, 4.0), Vector2(50.0, 5.0)]
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
