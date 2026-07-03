extends Control
## The camp between nights: a code-drawn campfire on the hill above Hollowmere,
## and the character select. This is the hub where story scenes will live
## (DEVELOPMENT_PLAN.md Phase 4) — the roster around the fire grows as heroes
## are unlocked.

var _time := 0.0
var _coin_tex: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_coin_tex = PixelSprites.get_tex("coin")

	var title := UITheme.make_label("THE CAMP", 34, Palette.PARCHMENT, true)
	_place(title, 0.5, 0.0, 0.5, 0.0, Rect2(-250, 14, 500, 44))
	add_child(title)

	var subtitle := UITheme.make_label("who keeps the vigil tonight?", 11, Palette.ASH)
	_place(subtitle, 0.5, 0.0, 0.5, 0.0, Rect2(-250, 56, 500, 18))
	add_child(subtitle)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	var roster: Variant = Game.load_json("res://data/characters/_roster.json")
	if roster is Array:
		for hero_id in roster:
			row.add_child(_make_hero_card(String(hero_id)))
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(center, 0.0, 0.0, 1.0, 1.0, Rect2(0, 30, 0, -40))
	center.add_child(row)
	add_child(center)

	var treasury := UITheme.make_label(str(Game.gold()), 12, Color("f0cd7a"))
	treasury.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_place(treasury, 0.0, 1.0, 0.0, 1.0, Rect2(26, -24, 100, 16))
	add_child(treasury)

	if float(Game.last_run.get("time", 0.0)) > 0.0:
		var seconds := int(Game.last_run.get("time", 0.0))
		var verdict := "the vigil held" if bool(Game.last_run.get("victory", false)) else "the night won"
		var text := "last night:  %s  ·  %d:%02d  ·  %d dead" % [
			verdict, seconds / 60, seconds % 60, int(Game.last_run.get("kills", 0))]
		var last_run := UITheme.make_label(text, 10, Palette.ASH)
		last_run.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_place(last_run, 1.0, 1.0, 1.0, 1.0, Rect2(-340, -24, 332, 16))
		add_child(last_run)

func _make_hero_card(hero_id: String) -> Button:
	var data: Variant = Game.load_json("res://data/characters/%s.json" % hero_id)
	var def: Dictionary = data if data is Dictionary else {}
	var unlocked := Game.is_unlocked(hero_id)
	var card := UITheme.make_button("", 12)
	card.custom_minimum_size = Vector2(158, 172)
	card.disabled = not unlocked
	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 5)
	_place(inner, 0.0, 0.0, 1.0, 1.0, Rect2(8, 8, -16, -16))
	var portrait := TextureRect.new()
	portrait.texture = PixelSprites.get_tex(String(def.get("sprite", "wren")))
	portrait.custom_minimum_size = Vector2(0, 62)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not unlocked:
		portrait.modulate = Color(0.05, 0.04, 0.07, 0.9)  # silhouette
	inner.add_child(portrait)
	if unlocked:
		inner.add_child(UITheme.make_label(String(def.get("name", hero_id)), 13, Palette.TORCH))
		var weapon_def: Variant = Game.load_json("res://data/weapons/%s.json" % String(def.get("weapon", "")))
		if weapon_def is Dictionary:
			inner.add_child(UITheme.make_label(String(weapon_def.get("name", "")), 10, Palette.PARCHMENT))
		var sig := UITheme.make_label(String(def.get("signature_desc", "")), 9, Palette.ASH)
		sig.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(sig)
	else:
		inner.add_child(UITheme.make_label("? ? ?", 13, Palette.STONE))
		var hint := UITheme.make_label(String(def.get("unlock_hint", "")), 9, Palette.ASH)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(hint)
	card.add_child(inner)
	if unlocked:
		card.pressed.connect(func() -> void:
			Game.selected_character = hero_id
			Game.start_run()
		)
	return card

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
			draw_circle(at + Vector2(0, -9), 3.5, shade)              # head
			draw_rect(Rect2(at + Vector2(-4, -6), Vector2(8, 8)), shade)  # body
