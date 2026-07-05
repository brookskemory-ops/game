extends Control
## Title screen — a fully code-drawn night over Hollowmere: gradient sky,
## twinkling stars, the moon, Castle Vane with one lit window, fog, and graves.
## Any tap / click / key begins the night.

var _started := false
var _time := 0.0
var _prompt: Label
var _moon_tex: Texture2D
var _hero_texs: Array = []  # unlocked survivors' side profiles, walking the road
var _full_btn: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var moon_path := "res://assets/sprites/generated/props/moon.png"
	if ResourceLoader.exists(moon_path):
		_moon_tex = load(moon_path)
	var roster: Variant = Game.load_json("res://data/characters/_roster.json")
	if roster is Array:
		for hero_id in roster:
			if not Game.is_unlocked(String(hero_id)):
				continue
			var side_path := "res://assets/sprites/generated/side/%s.png" % String(hero_id)
			if ResourceLoader.exists(side_path):
				_hero_texs.append(load(side_path))

	var title := UITheme.make_label("VIGIL", 78, Palette.PARCHMENT, true)
	_place(title, 0.5, 0.5, 0.5, 0.5, Rect2(-300, -118, 600, 92))
	add_child(title)

	var subtitle := UITheme.make_label("hold the night", 14, Palette.ASH)
	_place(subtitle, 0.5, 0.5, 0.5, 0.5, Rect2(-300, -24, 600, 22))
	add_child(subtitle)

	var begin_text := "TAP TO BEGIN" if Game.is_mobile else "CLICK OR PRESS ANY KEY"
	if Game.using_controller():
		begin_text = "PRESS ANY BUTTON"
	_prompt = UITheme.make_label(begin_text, 13, Palette.BONE)
	_place(_prompt, 0.5, 1.0, 0.5, 1.0, Rect2(-150, -64, 300, 22))
	add_child(_prompt)

	var version := UITheme.make_label(Game.VERSION, 9, Palette.STONE)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_place(version, 0.0, 1.0, 0.0, 1.0, Rect2(8, -20, 300, 14))
	add_child(version)

	# Web: offer fullscreen (a phone browser's chrome eats a lot of night).
	# The tap-to-begin handler ignores taps on this button (it consumes them).
	if OS.has_feature("web"):
		_full_btn = UITheme.make_button("fullscreen", 9)
		_place(_full_btn, 1.0, 0.0, 1.0, 0.0, Rect2(-104, 10, 96, 26))
		_full_btn.pressed.connect(func() -> void:
			Sfx.play("ui")
			JavaScriptBridge.eval(
				"document.documentElement.requestFullscreen && document.documentElement.requestFullscreen()",
				true)
		)
		add_child(_full_btn)

	if float(Game.last_run.get("time", 0.0)) > 0.0:
		var seconds := int(Game.last_run.get("time", 0.0))
		var text := "last vigil:  %d:%02d  ·  %d dead  ·  LV %d" % [
			seconds / 60, seconds % 60,
			int(Game.last_run.get("kills", 0)),
			int(Game.last_run.get("level", 1)),
		]
		var last_run := UITheme.make_label(text, 10, Palette.ASH)
		last_run.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_place(last_run, 1.0, 1.0, 1.0, 1.0, Rect2(-320, -20, 312, 14))
		add_child(last_run)

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
	if _prompt != null:
		_prompt.modulate.a = 0.55 + 0.45 * sin(_time * 2.6)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var horizon := h * 0.62

	# Sky: vertical gradient, ink to a faint moonlit band at the horizon.
	var bands := 12
	for band in bands:
		var f := float(band) / float(bands)
		var band_h := horizon / float(bands)
		draw_rect(Rect2(0, f * horizon, w, band_h + 1.0), Palette.INK.lerp(Palette.NIGHT_HIGH, f))

	# Stars (deterministic, twinkling).
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 60:
		var star := Vector2(rng.randf() * w, rng.randf() * horizon * 0.85)
		var rate := rng.randf_range(0.5, 2.0)
		var twinkle := 0.5 + 0.5 * sin(_time * rate + float(i))
		draw_rect(Rect2(star, Vector2(1.5, 1.5)),
			Color(Palette.MOON.r, Palette.MOON.g, Palette.MOON.b, 0.12 + 0.3 * twinkle))

	# The moon (generated art), with the code-drawn glow kept beneath it.
	var moon := Vector2(w * 0.78, h * 0.2)
	for glow in 3:
		draw_circle(moon, 24.0 + float(glow) * 9.0,
			Color(Palette.MOON.r, Palette.MOON.g, Palette.MOON.b, 0.05))
	if _moon_tex != null:
		var moon_size := Vector2(52, 52)
		draw_texture_rect(_moon_tex, Rect2(moon - moon_size * 0.5, moon_size), false)
	else:
		draw_circle(moon, 21.0, Palette.MOON)
		draw_circle(moon + Vector2(-6, -4), 3.5, Palette.MOON.darkened(0.14))
		draw_circle(moon + Vector2(4, 6), 2.5, Palette.MOON.darkened(0.1))

	# Castle Vane, far left: keep, wall, and the bell tower with one lit window.
	var castle := Color(0.09, 0.08, 0.12)
	var cx := w * 0.07
	draw_rect(Rect2(cx - 16.0, horizon - 44.0, 16.0, 44.0), castle)
	draw_rect(Rect2(cx, horizon - 72.0, 48.0, 72.0), castle)
	draw_rect(Rect2(cx + 48.0, horizon - 104.0, 22.0, 104.0), castle)
	for merlon in 4:
		draw_rect(Rect2(cx + float(merlon) * 13.0, horizon - 78.0, 7.0, 6.0), castle)
	draw_rect(Rect2(cx + 50.0, horizon - 110.0, 5.0, 6.0), castle)
	draw_rect(Rect2(cx + 65.0, horizon - 110.0, 5.0, 6.0), castle)
	var flicker := 0.7 + 0.3 * sin(_time * 7.0) * sin(_time * 3.1)
	draw_rect(Rect2(cx + 55.0, horizon - 88.0, 7.0, 10.0),
		Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, flicker))

	# Ground.
	draw_rect(Rect2(0, horizon, w, h - horizon), Color(0.075, 0.065, 0.095))

	# Graveyard silhouettes.
	rng.seed = 31
	for i in 16:
		var gx := rng.randf() * w
		var gy := horizon + rng.randf_range(6.0, h - horizon - 14.0)
		var gh := rng.randf_range(6.0, 13.0)
		var stone := Color(0.1, 0.09, 0.13)
		if rng.randf() < 0.3:
			draw_rect(Rect2(gx + 2.0, gy - gh, 2.0, gh), stone)
			draw_rect(Rect2(gx, gy - gh + 3.0, 6.0, 2.0), stone)
		else:
			draw_rect(Rect2(gx, gy - gh, rng.randf_range(5.0, 9.0), gh), stone)

	# The unlocked survivors walk the road, single file, toward the castle.
	if not _hero_texs.is_empty():
		var walk_y := h - 34.0
		for i in _hero_texs.size():
			var tex: Texture2D = _hero_texs[i]
			var walk_x := fmod(_time * 14.0 + float(i) * 44.0, w + 200.0) - 100.0
			var hero_scale := 30.0 / float(tex.get_height())
			var hero_size := Vector2(tex.get_width(), tex.get_height()) * hero_scale
			var bob := absf(sin(_time * 5.0 + float(i) * 1.7)) * 1.6
			# They walk right-to-left (art faces right; flip via negative width).
			draw_texture_rect(tex,
				Rect2(Vector2(w - walk_x + hero_size.x, walk_y - bob) - Vector2(0, hero_size.y),
					Vector2(-hero_size.x, hero_size.y)),
				false, Color(0.55, 0.55, 0.65))

	# Low fog: two translucent sheets drifting in opposite directions.
	var fog := Color(Palette.ASH.r, Palette.ASH.g, Palette.ASH.b, 0.045)
	var drift_a := fmod(_time * 7.0, w + 360.0) - 360.0
	var drift_b := w - fmod(_time * 4.0, w + 420.0)
	draw_rect(Rect2(drift_a, horizon - 7.0, 340.0, 16.0), fog)
	draw_rect(Rect2(drift_b, horizon + 14.0, 400.0, 13.0), fog)

func _input(event: InputEvent) -> void:
	if _started:
		return
	var pressed := false
	var at := Vector2(-1000, -1000)
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
		at = event.position
	elif event is InputEventMouseButton and event.pressed:
		pressed = true
		at = event.position
	elif event is InputEventKey and event.pressed and not event.echo:
		pressed = true
	elif event is InputEventJoypadButton and event.pressed:
		pressed = true  # any controller button begins (A/Start/etc.)
	# _input runs before button handlers: a tap on the fullscreen button
	# must not double as tap-to-begin.
	if pressed and _full_btn != null and _full_btn.get_global_rect().has_point(at):
		return
	if pressed:
		_started = true
		Game.go_camp()
