class_name ReapingHook
extends Weapon
## Reaping Hook — a sexton's curved blade thrown out and drawn back
## (docs/ABILITIES.md weapon #14). Niche: a returning projectile — it cuts on
## the way out AND the way home (bow is one-way; axes are one-way and random).

var _hooks: Array = []  # {pos, dir, dist, out, spin, age, hit_cd:{}}

func _try_fire() -> bool:
	var target := enemies.nearest_enemy(wielder.global_position, attack_range())
	if target < 0:
		return false
	var dir := (enemies.enemy_pos(target) - wielder.global_position).normalized()
	var count := int(def.get("hooks", 1)) + extra_projectiles
	var spread := deg_to_rad(float(def.get("spread_deg", 18.0)))
	for k in count:
		var a := 0.0
		if count > 1:
			a = lerpf(-spread, spread, float(k) / float(count - 1))
		_hooks.append({
			"pos": wielder.global_position,
			"dir": dir.rotated(a),
			"dist": 0.0,
			"out": true,
			"spin": randf() * TAU,
			"age": 0.0,
			"hit_cd": {},
		})
	Sfx.play("swing", 0.6)
	return true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _hooks.is_empty():
		return
	var reach := attack_range()
	var speed := float(def.get("speed", 300))
	var hit_radius := float(def.get("radius", 14)) * area_mul()
	var dmg := damage()
	var now := float(Time.get_ticks_msec()) / 1000.0
	for h in _hooks:
		h["age"] = float(h["age"]) + delta
		h["spin"] = float(h["spin"]) + 16.0 * delta
		var pos: Vector2 = h["pos"]
		if bool(h["out"]):
			h["dist"] = float(h["dist"]) + speed * delta
			pos += Vector2(h["dir"]) * speed * delta
			if float(h["dist"]) >= reach:
				h["out"] = false
		else:
			# Home to the (moving) wielder.
			var to_home := wielder.global_position - pos
			pos += to_home.normalized() * speed * delta
		h["pos"] = pos
		# Hit enemies near the blade; a per-enemy cooldown lets it strike twice.
		var cds: Dictionary = h["hit_cd"]
		for slot in enemies.query_circle(pos, hit_radius):
			if now < float(cds.get(slot, 0.0)):
				continue
			cds[slot] = now + 0.4
			enemies.damage_slot(slot, dmg)
	# Retire hooks that have returned, or that have flown too long (player outran it).
	_hooks = _hooks.filter(func(h):
		var returned := not bool(h["out"]) and wielder.global_position.distance_to(Vector2(h["pos"])) < 12.0
		return not returned and float(h["age"]) < 4.0)
	queue_redraw()

func _draw() -> void:
	for h in _hooks:
		var local := to_local(Vector2(h["pos"]))
		var s: float = h["spin"]
		# A curved sickle: an arc of blade plus a short haft to its heel.
		draw_arc(local, 6.0, s, s + PI * 1.15, 9, Palette.BONE, 2.0)
		draw_line(local, local + Vector2.from_angle(s) * 7.0, Palette.IRON, 2.0)

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		extra_projectiles += 1
		return "Reaping Hook: another blade on the cord (+1 hook)"
	damage_mul *= 1.13
	return "Reaping Hook: a keener edge (+13% damage)"
