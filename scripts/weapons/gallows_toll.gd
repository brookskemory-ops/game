class_name GallowsToll
extends Weapon
## Gallows Toll — iron weights dropped from the gallows onto the gathered dead
## (docs/ABILITIES.md weapon #15). Niche: a telegraphed strike from above — a
## shadow grows where the weight will land, then an instant AoE crush (no
## lingering pool; not a self-radial nova; not a frontal cleave).

var _strikes: Array = []  # {pos, telegraph, flash, struck}

func _try_fire() -> bool:
	var target := _densest(attack_range())
	if target == Vector2.INF:
		return false
	var count := int(def.get("weights", 1)) + extra_projectiles
	for k in count:
		var at := target
		if k > 0:
			at += Vector2.from_angle(randf() * TAU) * randf_range(20.0, 60.0)
		_strikes.append({
			"pos": at,
			"telegraph": float(def.get("telegraph", 0.5)),
			"flash": 0.22,
			"struck": false,
		})
	Sfx.play("swing", 0.5)
	return true

## Aim at the densest cluster in range (a rough sample), or hold if none.
func _densest(rng: float) -> Vector2:
	var slots := enemies.query_circle(wielder.global_position, rng)
	if slots.is_empty():
		return Vector2.INF
	var best := -1
	var best_n := -1
	for i in mini(slots.size(), 10):
		var slot: int = slots[randi() % slots.size()]
		var n := enemies.count_in_circle(enemies.enemy_pos(slot), 40.0)
		if n > best_n:
			best_n = n
			best = slot
	return enemies.enemy_pos(best)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _strikes.is_empty():
		return
	var radius := float(def.get("radius", 34)) * area_mul()
	var knockback := float(def.get("knockback", 80))
	for s in _strikes:
		if not bool(s["struck"]):
			s["telegraph"] = float(s["telegraph"]) - delta
			if float(s["telegraph"]) <= 0.0:
				s["struck"] = true
				var at: Vector2 = s["pos"]
				for slot in enemies.query_circle(at, radius):
					enemies.damage_slot(slot, damage())
					var away: Vector2 = enemies.enemy_pos(slot) - at
					enemies.push_slot(slot, away.normalized() * knockback)
				Sfx.play("swing", 0.9)
				var camera := wielder.get_node_or_null("Camera2D")
				if camera != null:
					camera.add_trauma(0.12)
		else:
			s["flash"] = float(s["flash"]) - delta
	_strikes = _strikes.filter(func(s): return not bool(s["struck"]) or float(s["flash"]) > 0.0)
	queue_redraw()

func _draw() -> void:
	var radius := float(def.get("radius", 34)) * area_mul()
	var telegraph := float(def.get("telegraph", 0.5))
	for s in _strikes:
		var local := to_local(Vector2(s["pos"]))
		if not bool(s["struck"]):
			# The shadow swells as the weight falls.
			var t := 1.0 - float(s["telegraph"]) / maxf(0.01, telegraph)
			draw_circle(local, radius * (0.4 + 0.6 * t), Color(0.0, 0.0, 0.0, 0.35))
			draw_arc(local, radius, 0.0, TAU, 24,
				Color(Palette.IRON.r, Palette.IRON.g, Palette.IRON.b, 0.55), 1.5)
		else:
			# Impact: a bright ring snapping outward.
			var a := float(s["flash"]) / 0.22
			draw_circle(local, radius, Color(Palette.PARCHMENT.r, Palette.PARCHMENT.g, Palette.PARCHMENT.b, a * 0.35))
			draw_arc(local, radius * (1.0 + (1.0 - a) * 0.25), 0.0, TAU, 28,
				Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, a * 0.8), 2.5)

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		extra_projectiles += 1
		return "Gallows Toll: another weight cut loose (+1 drop)"
	damage_mul *= 1.15
	return "Gallows Toll: heavier iron (+15% damage)"
