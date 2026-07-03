class_name EnemyManager
extends Node2D
## The horde. This is the performance-critical heart of the game
## (ENGINE_RECOMMENDATION.md §5): NO physics bodies — enemies are rows in flat
## packed arrays, moved with position math, hit-tested through a spatial hash
## grid, and rendered via one MultiMesh per enemy type.
##
## Packed arrays are direct members (never nested in Dictionaries/Arrays) so
## in-place writes like `_pos[i] = v` actually stick — nesting them in a
## container would silently mutate a copy.

const MAX_ENEMIES := 700
const CELL_SIZE := 48.0
const FLASH_TIME := 0.12
const PUFF_TIME := 0.35
const MAX_BOLTS := 48
const BOLT_LIFE := 2.6
const PULSE_TIME := 0.5
const HIDDEN := Transform2D(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)

signal boss_spawned(display_name: String)
signal boss_died(at: Vector2)
signal enemy_killed(at: Vector2)
signal elite_spawned(type_name: String)   # elites + bosses (rite windows)
signal elite_killed(type_name: String)

var kills := 0
var elite_kills := 0  # elites + bosses felled (weapon unlock conditions)
var player_radius := 6.0
var _boss_slot := -1
var _boss_max_hp := 1.0

var _player: Node2D
var _gems: GemManager

# Night modifiers (v0.15 variant nights): stage json "mods" block.
var _hp_mul := 1.0
var _speed_mul := 1.0
var _gold_mul := 1.0
var _xp_mul := 1.0

func set_mods(mods: Dictionary) -> void:
	_hp_mul = float(mods.get("hp_mul", 1.0))
	_speed_mul = float(mods.get("speed_mul", 1.0))
	_gold_mul = float(mods.get("gold_mul", 1.0))
	_xp_mul = float(mods.get("xp_mul", 1.0))

## Endless escalation: each tier deepens the night (The Long Night).
func escalate(hp_factor: float) -> void:
	_hp_mul *= hp_factor

# Type registry, from data/enemies.json.
var _type_defs: Array = []      # Dictionary per type id
var _type_mm: Array = []        # MultiMesh per type id
var _name_to_type := {}         # String -> int

# Flat per-enemy state. One slot per enemy, shared across types.
var _alive := PackedByteArray()
var _type := PackedInt32Array()
var _pos := PackedVector2Array()
var _hp := PackedFloat32Array()
var _flash := PackedFloat32Array()
var _wobble := PackedVector2Array()  # fixed per-enemy offset so the horde doesn't stack into one point
var _phase := PackedFloat32Array()   # per-enemy animation phase
var _facing := PackedFloat32Array()
var _push := PackedVector2Array()    # knockback impulse, decays fast
var _slow := PackedFloat32Array()    # remaining slow time (0.6x speed while > 0)
var _shot_cd := PackedFloat32Array() # per-enemy ability timer (archer shots, choir hymns)
var _free := PackedInt32Array()
var _alive_count := 0

# Enemy bolts (crypt archers, the Thing's volleys): tiny flat pool, canvas-drawn.
var _bolt_pos := PackedVector2Array()
var _bolt_vel := PackedVector2Array()
var _bolt_age := PackedFloat32Array()
var _bolt_damage := PackedFloat32Array()
var _bolt_live := PackedByteArray()

var _grid := {}                 # Vector2i cell -> Array of slots (rebuilt every physics tick)
var _puffs: Array = []          # death puffs: [position: Vector2, age: float]
var _pulses: Array = []         # choir hymn rings: [position, age, radius, color]
var _dmg_numbers: Array = []    # floating damage numbers: [position, value, age]
var _time := 0.0

func setup(player: Node2D, p_player_radius: float, gems: GemManager) -> void:
	_player = player
	player_radius = p_player_radius
	_gems = gems
	_alive.resize(MAX_ENEMIES)
	_type.resize(MAX_ENEMIES)
	_pos.resize(MAX_ENEMIES)
	_hp.resize(MAX_ENEMIES)
	_flash.resize(MAX_ENEMIES)
	_wobble.resize(MAX_ENEMIES)
	_phase.resize(MAX_ENEMIES)
	_facing.resize(MAX_ENEMIES)
	_push.resize(MAX_ENEMIES)
	_slow.resize(MAX_ENEMIES)
	_shot_cd.resize(MAX_ENEMIES)
	_free.resize(MAX_ENEMIES)
	for i in MAX_ENEMIES:
		_alive[i] = 0
		_free[i] = MAX_ENEMIES - 1 - i
	_bolt_pos.resize(MAX_BOLTS)
	_bolt_vel.resize(MAX_BOLTS)
	_bolt_age.resize(MAX_BOLTS)
	_bolt_damage.resize(MAX_BOLTS)
	_bolt_live.resize(MAX_BOLTS)
	var defs: Variant = Game.load_json("res://data/enemies.json")
	if defs is Dictionary:
		for type_name in defs:
			_register_type(String(type_name), defs[type_name])

func _register_type(type_name: String, def: Dictionary) -> void:
	# Pixel Lab art when it exists (64x64 canvases, scaled down to world size
	# by gen_scale); procedural ASCII sprites as the fallback.
	var sprite_id := String(def.get("sprite", type_name))
	var tex: Texture2D
	var quad := QuadMesh.new()
	var gen_path := "res://assets/sprites/generated/%s.png" % sprite_id
	if ResourceLoader.exists(gen_path):
		tex = load(gen_path)
		quad.size = Vector2(tex.get_width(), tex.get_height()) * float(def.get("gen_scale", 0.3))
	else:
		tex = PixelSprites.get_tex(sprite_id)
		quad.size = Vector2(tex.get_width(), tex.get_height())
	tex = PixelSprites.flipped_for_multimesh(tex)
	# Art that natively faces left gets mirrored at load, so ALL textures face
	# right and the runtime velocity-flip logic stays uniform.
	if bool(def.get("flip_x", false)):
		var img := tex.get_image()
		img.flip_x()
		tex = ImageTexture.create_from_image(img)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.mesh = quad
	mm.instance_count = MAX_ENEMIES
	for i in MAX_ENEMIES:
		mm.set_instance_transform_2d(i, HIDDEN)
		mm.set_instance_color(i, Color.WHITE)
	var mmi := MultiMeshInstance2D.new()
	mmi.name = "Horde_" + type_name
	mmi.multimesh = mm
	mmi.texture = tex
	add_child(mmi)
	def["_id"] = type_name  # so kill/spawn signals can name the type
	_name_to_type[type_name] = _type_defs.size()
	_type_defs.append(def)
	_type_mm.append(mm)

func spawn(type_name: String, at: Vector2) -> void:
	if not _name_to_type.has(type_name):
		push_warning("Unknown enemy type: " + type_name)
		return
	if _free.is_empty():
		return  # horde is at capacity — the night is full
	var slot := _free[_free.size() - 1]
	_free.resize(_free.size() - 1)
	var type_id: int = _name_to_type[type_name]
	_alive[slot] = 1
	_type[slot] = type_id
	_pos[slot] = at
	_hp[slot] = float(_type_defs[type_id].get("hp", 10)) * _hp_mul
	_flash[slot] = 0.0
	_wobble[slot] = Vector2.from_angle(randf() * TAU) * randf_range(2.0, 26.0)
	_phase[slot] = randf() * TAU
	_facing[slot] = 1.0
	_push[slot] = Vector2.ZERO
	_slow[slot] = 0.0
	_shot_cd[slot] = randf_range(0.5, 1.5)  # desync abilities across a squad
	_alive_count += 1
	if bool(_type_defs[type_id].get("boss", false)):
		_boss_slot = slot
		_boss_max_hp = float(_type_defs[type_id].get("hp", 1))
		boss_spawned.emit(String(_type_defs[type_id].get("name", type_name)))
	if bool(_type_defs[type_id].get("elite", false)) or bool(_type_defs[type_id].get("boss", false)):
		elite_spawned.emit(type_name)

func _physics_process(delta: float) -> void:
	if _player == null:
		return
	_time += delta
	var ppos: Vector2 = _player.global_position
	_grid.clear()
	var contact_dps := 0.0
	# Briar Crown relic: whatever gnaws the wearer is gnawed back.
	var thorns := 0.0
	var thorns_v: Variant = _player.get("thorns")
	if thorns_v != null:
		thorns = float(thorns_v)

	for i in MAX_ENEMIES:
		if _alive[i] == 0:
			continue
		var def: Dictionary = _type_defs[_type[i]]
		# Move: plain position math toward the player (plus a fixed wobble
		# offset so the horde spreads into a mob instead of a single point).
		# Ranged types (crypt archers) hold at their preferred distance instead
		# of closing to melee; bosses with volleys keep advancing regardless.
		var target: Vector2 = ppos + _wobble[i]
		var to_target := target - _pos[i]
		var dist := to_target.length()
		var ranged: Dictionary = def.get("ranged", {})
		var move_sign := 1.0
		if not ranged.is_empty() and bool(ranged.get("hold_distance", true)):
			var preferred := float(ranged.get("range", 150)) * 0.7
			if dist < preferred * 0.65:
				move_sign = -1.0  # too close: back away, bow drawn
			elif dist < preferred:
				move_sign = 0.0   # in the pocket: hold and loose
		if dist > 2.0:
			var dir := to_target / dist
			var speed_mul := 1.0
			if _slow[i] > 0.0:
				_slow[i] -= delta
				speed_mul = 0.6
			_pos[i] += dir * float(def.get("speed", 40)) * speed_mul * _speed_mul * move_sign * delta
			if absf(dir.x) > 0.1:
				_facing[i] = -1.0 if dir.x < 0.0 else 1.0
		# Per-type abilities on the shared per-slot timer.
		if not ranged.is_empty():
			_shot_cd[i] -= delta
			if _shot_cd[i] <= 0.0 and dist <= float(ranged.get("range", 150)):
				_shot_cd[i] = float(ranged.get("cooldown", 2.5))
				_fire_bolts(_pos[i], ppos, ranged)
		var choir: Dictionary = def.get("heals_allies", {})
		if not choir.is_empty():
			_shot_cd[i] -= delta
			if _shot_cd[i] <= 0.0:
				_shot_cd[i] = float(choir.get("interval", 2.0))
				_sing_hymn(i, choir)
		# Knockback impulse (from shovel swings etc.), decays fast.
		if _push[i] != Vector2.ZERO:
			_pos[i] += _push[i] * delta
			_push[i] *= maxf(0.0, 1.0 - 7.0 * delta)
			if _push[i].length_squared() < 4.0:
				_push[i] = Vector2.ZERO
		# Spatial hash insert.
		var cell := Vector2i(int(floorf(_pos[i].x / CELL_SIZE)), int(floorf(_pos[i].y / CELL_SIZE)))
		if _grid.has(cell):
			_grid[cell].append(i)
		else:
			_grid[cell] = [i]
		# Contact damage accumulates as DPS while touching the player.
		if _pos[i].distance_to(ppos) < float(def.get("radius", 6)) + player_radius:
			contact_dps += float(def.get("damage", 5))
			# Thorns tick roughly twice a second, probabilistically (cheap).
			if thorns > 0.0 and randf() < delta * 2.0:
				damage_slot(i, thorns)
		# Hit flash decay.
		if _flash[i] > 0.0:
			_flash[i] -= delta
			if _flash[i] <= 0.0:
				_type_mm[_type[i]].set_instance_color(i, Color.WHITE)
		# Render transform: flip toward movement, shamble-bob rotation
		# (big bodies — elites/bosses — lumber slower and heavier).
		# Fresh hits scale-pop the body (juice, WP9).
		var heavy := float(def.get("radius", 6)) >= 10.0
		var bob := sin(_time * (3.5 if heavy else 7.0) + _phase[i]) * (0.04 if heavy else 0.07)
		var pop := 1.0 + maxf(0.0, _flash[i]) * 1.6
		var xform := Transform2D(bob, Vector2(_facing[i] * pop, pop), 0.0, _pos[i])
		_type_mm[_type[i]].set_instance_transform_2d(i, xform)

	if contact_dps > 0.0 and _player.has_method("take_contact_dps"):
		_player.take_contact_dps(contact_dps, delta)

	_update_bolts(delta, ppos)

	if not _pulses.is_empty():
		for p in _pulses:
			p[1] += delta
		_pulses = _pulses.filter(func(p): return p[1] < PULSE_TIME)
		queue_redraw()
	if not _puffs.is_empty():
		for p in _puffs:
			p[1] += delta
		_puffs = _puffs.filter(func(p): return p[1] < PUFF_TIME)
		queue_redraw()
	if not _dmg_numbers.is_empty():
		for n in _dmg_numbers:
			n[2] += delta
		_dmg_numbers = _dmg_numbers.filter(func(n): return n[2] < 0.6)
		queue_redraw()

## Crypt archers loose a bolt (or a fan of them, for the Thing's volleys).
func _fire_bolts(from: Vector2, at: Vector2, ranged: Dictionary) -> void:
	var count := int(ranged.get("volley", 1))
	var spread := deg_to_rad(float(ranged.get("spread_deg", 0.0)))
	var speed := float(ranged.get("proj_speed", 140))
	var aim := (at - from).angle()
	for b in count:
		var slot := _free_bolt()
		if slot < 0:
			return
		var angle := aim
		if count > 1:
			angle += spread * (float(b) / float(count - 1) - 0.5)
		_bolt_live[slot] = 1
		_bolt_pos[slot] = from
		_bolt_vel[slot] = Vector2.from_angle(angle) * speed
		_bolt_age[slot] = 0.0
		_bolt_damage[slot] = float(ranged.get("proj_damage", 8))
	Sfx.play("shoot", 0.4)

func _free_bolt() -> int:
	for i in MAX_BOLTS:
		if _bolt_live[i] == 0:
			return i
	return -1

func _update_bolts(delta: float, ppos: Vector2) -> void:
	var any := false
	for i in MAX_BOLTS:
		if _bolt_live[i] == 0:
			continue
		any = true
		_bolt_age[i] += delta
		_bolt_pos[i] += _bolt_vel[i] * delta
		if _bolt_age[i] >= BOLT_LIFE:
			_bolt_live[i] = 0
			continue
		if _bolt_pos[i].distance_to(ppos) < player_radius + 3.0:
			_bolt_live[i] = 0
			if _player.has_method("take_hit"):
				_player.take_hit(_bolt_damage[i])
	if any:
		queue_redraw()

## The chapel choir's hymn: mends every risen thing within earshot.
func _sing_hymn(singer: int, choir: Dictionary) -> void:
	var radius := float(choir.get("radius", 90))
	var amount := float(choir.get("amount", 6))
	var healed := false
	for slot in query_circle(_pos[singer], radius):
		if slot == singer:
			continue
		var cap := float(_type_defs[_type[slot]].get("hp", 10))
		if _hp[slot] < cap:
			_hp[slot] = minf(cap, _hp[slot] + amount)
			healed = true
	if healed:
		_pulses.append([_pos[singer], 0.0, radius, Color(0.85, 0.75, 0.4)])
		queue_redraw()

## Apply damage to one enemy. White hit-flash; death drops an XP gem + puff.
## Risen knights carry grave-plate: flat armor shaves each hit (never below 1).
func damage_slot(slot: int, amount: float) -> void:
	if slot < 0 or slot >= MAX_ENEMIES or _alive[slot] == 0:
		return
	var plate := float(_type_defs[_type[slot]].get("armor", 0.0))
	if plate > 0.0:
		amount = maxf(1.0, amount - plate)
	_hp[slot] -= amount
	_flash[slot] = FLASH_TIME
	# HDR-ish color: texture * (4,4,4) clamps to white for a clean damage flash.
	_type_mm[_type[slot]].set_instance_color(slot, Color(4.0, 4.0, 4.0, 1.0))
	Sfx.play("hit", 0.7)
	if bool(Game.settings.get("damage_numbers", true)) and _dmg_numbers.size() < 48:
		_dmg_numbers.append([_pos[slot] + Vector2(randf_range(-4, 4), -8.0), amount, 0.0])
	if _hp[slot] <= 0.0:
		_kill(slot)

func _kill(slot: int) -> void:
	var def: Dictionary = _type_defs[_type[slot]]
	_alive[slot] = 0
	_alive_count -= 1
	kills += 1
	if bool(def.get("elite", false)) or bool(def.get("boss", false)):
		elite_kills += 1
		elite_killed.emit(String(def.get("_id", "")))
	_free.append(slot)
	_type_mm[_type[slot]].set_instance_transform_2d(slot, HIDDEN)
	_type_mm[_type[slot]].set_instance_color(slot, Color.WHITE)
	_drop_pickups(slot, def)
	_puffs.append([_pos[slot], 0.0])
	Sfx.play("kill", 0.8)
	enemy_killed.emit(_pos[slot])
	queue_redraw()
	if slot == _boss_slot:
		_boss_slot = -1
		boss_died.emit(_pos[slot])

## XP gems always; gold from elites/bosses (and a rare trickle from normals).
func _drop_pickups(slot: int, def: Dictionary) -> void:
	if _gems == null:
		return
	var xp := maxi(1, int(round(float(def.get("xp", 1)) * _xp_mul)))
	var gem_count := clampi(xp, 1, 8)
	for g in gem_count:
		var value := xp / gem_count + (1 if g < xp % gem_count else 0)
		_gems.spawn(_scatter(_pos[slot], gem_count), value, GemManager.KIND_GEM)
	var gold := int(round(float(def.get("gold", 0)) * _gold_mul))
	if gold == 0 and randf() < float(def.get("gold_chance", 0.0)) * _gold_mul:
		gold = 1
	if gold > 0:
		var coin_count := clampi(gold, 1, 8)
		for c in coin_count:
			var value := gold / coin_count + (1 if c < gold % coin_count else 0)
			_gems.spawn(_scatter(_pos[slot], coin_count), value, GemManager.KIND_COIN)
	# Elites carry scrolls: a bonus draft for whoever puts them down.
	if bool(def.get("drops_scroll", false)):
		_gems.spawn(_pos[slot], 1, GemManager.KIND_SCROLL)

func _scatter(at: Vector2, count: int) -> Vector2:
	if count <= 1:
		return at
	return at + Vector2.from_angle(randf() * TAU) * randf_range(4.0, 16.0)

# --- Boss state (polled by the HUD) ---

func boss_active() -> bool:
	return _boss_slot >= 0

func boss_hp_frac() -> float:
	if _boss_slot < 0:
		return 0.0
	return clampf(_hp[_boss_slot] / _boss_max_hp, 0.0, 1.0)

func _draw() -> void:
	# Enemy bolts: a short bone-pale streak along the flight path.
	for i in MAX_BOLTS:
		if _bolt_live[i] == 0:
			continue
		var tail: Vector2 = _bolt_pos[i] - _bolt_vel[i].normalized() * 6.0
		draw_line(tail, _bolt_pos[i], Color(0.81, 0.79, 0.72), 1.5)
		draw_rect(Rect2(_bolt_pos[i] - Vector2.ONE, Vector2(2, 2)), Color(0.55, 0.52, 0.58))
	# Choir hymns: an expanding ring in sickly gold over whoever it mended.
	for p in _pulses:
		var pulse_age: float = p[1]
		var frac := pulse_age / PULSE_TIME
		var tint: Color = p[3]
		draw_arc(p[0], 8.0 + frac * float(p[2]), 0.0, TAU, 20,
			Color(tint.r, tint.g, tint.b, (1.0 - frac) * 0.45), 1.5)
	# Death puffs: an expanding, fading ring. Cheap, batched into this node's canvas item.
	for p in _puffs:
		var age: float = p[1]
		var alpha := (1.0 - age / PUFF_TIME) * 0.5
		var radius := 3.0 + age * 26.0
		draw_arc(p[0], radius, 0.0, TAU, 12, Color(Palette.ASH.r, Palette.ASH.g, Palette.ASH.b, alpha), 2.0)
	# Floating damage numbers (toggleable in the pause menu).
	if not _dmg_numbers.is_empty():
		var font := UITheme.body_font()
		if font != null:
			for n in _dmg_numbers:
				var age: float = n[2]
				var alpha := clampf(1.2 - age * 2.0, 0.0, 1.0)
				var at: Vector2 = n[0] + Vector2(0.0, -age * 22.0)
				draw_string(font, at, str(int(round(n[1]))), HORIZONTAL_ALIGNMENT_CENTER,
					40.0, 8, Color(Palette.BONE.r, Palette.BONE.g, Palette.BONE.b, alpha))

# --- Spatial queries (used by weapons, projectiles, and player passives) ---

func query_circle(center: Vector2, radius: float) -> PackedInt32Array:
	var result := PackedInt32Array()
	var min_cx := int(floorf((center.x - radius) / CELL_SIZE))
	var max_cx := int(floorf((center.x + radius) / CELL_SIZE))
	var min_cy := int(floorf((center.y - radius) / CELL_SIZE))
	var max_cy := int(floorf((center.y + radius) / CELL_SIZE))
	for cy in range(min_cy, max_cy + 1):
		for cx in range(min_cx, max_cx + 1):
			var key := Vector2i(cx, cy)
			if not _grid.has(key):
				continue
			for slot in _grid[key]:
				if _pos[slot].distance_to(center) <= radius:
					result.append(slot)
	return result

func count_in_circle(center: Vector2, radius: float) -> int:
	return query_circle(center, radius).size()

func nearest_enemy(from: Vector2, max_range: float) -> int:
	var best := -1
	var best_dist := max_range
	var min_cx := int(floorf((from.x - max_range) / CELL_SIZE))
	var max_cx := int(floorf((from.x + max_range) / CELL_SIZE))
	var min_cy := int(floorf((from.y - max_range) / CELL_SIZE))
	var max_cy := int(floorf((from.y + max_range) / CELL_SIZE))
	for cy in range(min_cy, max_cy + 1):
		for cx in range(min_cx, max_cx + 1):
			var key := Vector2i(cx, cy)
			if not _grid.has(key):
				continue
			for slot in _grid[key]:
				var d: float = _pos[slot].distance_to(from)
				if d < best_dist:
					best_dist = d
					best = slot
	return best

func push_slot(slot: int, impulse: Vector2) -> void:
	if slot < 0 or slot >= MAX_ENEMIES or _alive[slot] == 0:
		return
	_push[slot] = (_push[slot] + impulse).limit_length(280.0)

func slow_slot(slot: int, duration: float) -> void:
	if slot < 0 or slot >= MAX_ENEMIES or _alive[slot] == 0:
		return
	_slow[slot] = maxf(_slow[slot], duration)

func slot_def(slot: int) -> Dictionary:
	if slot < 0 or slot >= MAX_ENEMIES or _alive[slot] == 0:
		return {}
	return _type_defs[_type[slot]]

func enemy_pos(slot: int) -> Vector2:
	return _pos[slot]

func enemy_radius(slot: int) -> float:
	if slot < 0 or slot >= MAX_ENEMIES or _alive[slot] == 0:
		return 0.0
	return float(_type_defs[_type[slot]].get("radius", 6))

func alive_count() -> int:
	return _alive_count
