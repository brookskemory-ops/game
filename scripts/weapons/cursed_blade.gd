extends Weapon
## Cursed Blade — the Hollow King's bargain (docs/ABILITIES.md #6): slain foes
## rise again as spectral thralls that fight FOR the wielder. On-kill trigger,
## summon delivery — useless until the killing starts, unstoppable after.
##
## Evolution: Crownsorrow (persist: thralls serve until cut down, and detonate
## when they fall).

const SEEK_RANGE := 260.0
const THRALL_SPEED := 95.0
const HIT_COOLDOWN := 0.5
const CONTACT_PAD := 5.0
const SLASH_REACH := 38.0

var bonus_thralls := 0
var bonus_duration := 0.0

var _thralls: Array = []          # {pos, ttl, hp, hit_cd, face}
var _pending: Array = []          # kill positions waiting for a raise (gated by cooldown)
var _thralls_bursts: Array = []   # [position, age] Crownsorrow detonation rings
var _slashes: Array = []          # [from, to, age] direct blade strikes
var _tex: Texture2D
var _tex_scale := 1.0

func _ready() -> void:
	# Thralls live in world space, not on the wielder's shoulder.
	top_level = true
	global_position = Vector2.ZERO
	var gen_path := "res://assets/sprites/generated/thrall.png"
	if ResourceLoader.exists(gen_path):
		_tex = load(gen_path)
		_tex_scale = 0.28
	else:
		_tex = PixelSprites.get_tex("thrall")
	if enemies != null:
		enemies.enemy_killed.connect(_on_enemy_killed)

func _on_enemy_killed(at: Vector2) -> void:
	if _pending.size() < 4:
		_pending.append(at)

func max_thralls() -> int:
	return int(def.get("max_thralls", 3)) + bonus_thralls

func service_time() -> float:
	return (float(def.get("duration", 6.0)) + bonus_duration) \
		* (1.0 + float(wielder.mods.get("duration", 0.0)))

func _try_fire() -> bool:
	# The base cooldown gates the blade's rhythm: raising a thrall takes the
	# tick when a kill is waiting and the court has room; otherwise the blade
	# itself lashes out — a weak strike, but it's what starts the killing.
	if not _pending.is_empty() and _thralls.size() < max_thralls():
		var at: Vector2 = _pending.pop_front()
		_thralls.append({
			"pos": at,
			"ttl": service_time(),
			"hp": float(def.get("thrall_hp", 30.0)),
			"hit_cd": 0.0,
			"face": 1.0,
		})
		Sfx.play("bell", 0.35)
		return true
	_pending.clear()
	var target := enemies.nearest_enemy(wielder.global_position, SLASH_REACH * range_mul())
	if target < 0:
		return false
	var target_pos := enemies.enemy_pos(target)
	enemies.damage_slot(target, damage())
	enemies.push_slot(target, (target_pos - wielder.global_position).normalized() * 60.0)
	_slashes.append([wielder.global_position, target_pos, 0.0])
	Sfx.play("swing", 0.6)
	return true

func _physics_process(delta: float) -> void:
	super(delta)
	if wielder == null or enemies == null:
		return
	var persist := bool(def.get("persist", false))
	var fallen: Array = []
	for thrall in _thralls:
		if not persist:
			thrall["ttl"] -= delta
			if thrall["ttl"] <= 0.0:
				fallen.append(thrall)
				continue
		var pos: Vector2 = thrall["pos"]
		var target := enemies.nearest_enemy(pos, SEEK_RANGE)
		var goal: Vector2
		if target >= 0:
			goal = enemies.enemy_pos(target)
		else:
			# No prey in reach: drift back to the king's side.
			goal = wielder.global_position
			if pos.distance_to(goal) < 30.0:
				goal = pos
		var to_goal := goal - pos
		if to_goal.length() > 3.0:
			var dir := to_goal.normalized()
			thrall["pos"] = pos + dir * THRALL_SPEED * delta
			if absf(dir.x) > 0.1:
				thrall["face"] = -1.0 if dir.x < 0.0 else 1.0
		thrall["hit_cd"] = float(thrall["hit_cd"]) - delta
		if target >= 0 and float(thrall["hit_cd"]) <= 0.0:
			var reach := enemies.enemy_radius(target) + CONTACT_PAD
			if Vector2(thrall["pos"]).distance_to(enemies.enemy_pos(target)) <= reach:
				thrall["hit_cd"] = HIT_COOLDOWN
				enemies.damage_slot(target, damage())
				# Crownsorrow thralls are worn down by the fighting itself.
				if persist:
					thrall["hp"] = float(thrall["hp"]) - 6.0
					if float(thrall["hp"]) <= 0.0:
						fallen.append(thrall)
	for thrall in fallen:
		_thralls.erase(thrall)
		if bool(def.get("detonate", false)):
			_detonate(thrall["pos"])
	queue_redraw()

## Crownsorrow: a fallen thrall bursts into grave-light.
func _detonate(at: Vector2) -> void:
	var radius := 46.0 * area_mul()
	for slot in enemies.query_circle(at, radius):
		enemies.damage_slot(slot, damage() * 2.5)
	Sfx.play("boss_death", 0.4)
	_thralls_bursts.append([at, 0.0])

func _process(delta: float) -> void:
	if not _thralls_bursts.is_empty():
		for b in _thralls_bursts:
			b[1] += delta
		_thralls_bursts = _thralls_bursts.filter(func(b): return b[1] < 0.4)
		queue_redraw()
	if not _slashes.is_empty():
		for s in _slashes:
			s[2] += delta
		_slashes = _slashes.filter(func(s): return s[2] < 0.18)
		queue_redraw()

func _draw() -> void:
	if _tex == null:
		return
	var half := Vector2(_tex.get_width(), _tex.get_height()) * 0.5
	for thrall in _thralls:
		var pos: Vector2 = thrall["pos"]
		var face: float = thrall["face"]
		var fade := 1.0
		if not bool(def.get("persist", false)):
			fade = clampf(float(thrall["ttl"]) / 1.2, 0.35, 1.0)  # gutter out near the end
		draw_set_transform(pos, 0.0, Vector2(face * _tex_scale, _tex_scale))
		draw_texture(_tex, -half, Color(0.55, 0.85, 1.3, 0.85 * fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for b in _thralls_bursts:
		var frac: float = b[1] / 0.4
		draw_arc(b[0], 8.0 + frac * 40.0, 0.0, TAU, 20,
			Color(0.55, 0.85, 1.3, (1.0 - frac) * 0.6), 2.0)
	# The blade's own lash: a pale streak that dies fast.
	for s in _slashes:
		var slash_frac: float = s[2] / 0.18
		draw_line(s[0], s[1], Color(0.85, 0.9, 1.0, (1.0 - slash_frac) * 0.8), 2.0)

func _on_upgrade(new_level: int) -> String:
	match new_level:
		2, 5, 8:
			bonus_thralls += 1
			return "%s: the court grows (+1 thrall)" % display_name()
		3, 6:
			damage_mul *= 1.25
			return "%s: +25%% thrall damage" % display_name()
		_:
			bonus_duration += 2.0
			return "%s: +2s of service" % display_name()

func upgrade_preview() -> String:
	match level + 1:
		2, 5, 8:
			return "The court grows: +1 thrall"
		3, 6:
			return "+25% thrall damage"
		_:
			return "+2 seconds of service"
