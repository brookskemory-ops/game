class_name FenFire
extends Weapon
## Fen-Fire — a mere-wisp that leaps from the nearest dead to the next
## (docs/ABILITIES.md weapon #13). Niche: a bouncing chain — instant, arcs
## from enemy to enemy, weaker with each leap. No other weapon chains.

var _arcs: Array = []  # [from: Vector2, to: Vector2, age: float]

func _try_fire() -> bool:
	var first := enemies.nearest_enemy(wielder.global_position, attack_range())
	if first < 0:
		return false
	var jumps := int(def.get("jumps", 3)) + extra_projectiles
	var jump_range := float(def.get("jump_range", 95)) * range_mul()
	var falloff := float(def.get("falloff", 0.8))
	var hit := {}
	var dmg := damage()
	var prev_pos := wielder.global_position
	var cur := first
	for j in jumps:
		if cur < 0 or hit.has(cur):
			break
		hit[cur] = true
		var cpos := enemies.enemy_pos(cur)
		enemies.damage_slot(cur, dmg)
		_arcs.append([prev_pos, cpos, 0.0])
		prev_pos = cpos
		dmg *= falloff
		cur = _nearest_unhit(cpos, jump_range, hit)
	Sfx.play("shoot", 0.5)
	queue_redraw()
	return true

## Closest enemy to `from` within `radius` that the chain hasn't touched yet.
func _nearest_unhit(from: Vector2, radius: float, hit: Dictionary) -> int:
	var best := -1
	var best_d := radius * radius
	for slot in enemies.query_circle(from, radius):
		if hit.has(slot):
			continue
		var d := from.distance_squared_to(enemies.enemy_pos(slot))
		if d < best_d:
			best_d = d
			best = slot
	return best

func _process(delta: float) -> void:
	if _arcs.is_empty():
		return
	for a in _arcs:
		a[2] += delta
	_arcs = _arcs.filter(func(a): return a[2] < 0.18)
	queue_redraw()

func _draw() -> void:
	for a in _arcs:
		var alpha := 1.0 - float(a[2]) / 0.18
		_draw_bolt(to_local(a[0]), to_local(a[1]), alpha)

## A jagged bolt: midpoints jittered perpendicular to the line (re-jittered each
## frame, so the light crackles).
func _draw_bolt(from: Vector2, to: Vector2, alpha: float) -> void:
	var dir := to - from
	var perp := Vector2(-dir.y, dir.x).normalized()
	var pts: PackedVector2Array = [from]
	for s in range(1, 4):
		var t := float(s) / 4.0
		pts.append(from.lerp(to, t) + perp * randf_range(-5.0, 5.0))
	pts.append(to)
	var glow := Color(0.55, 0.9, 1.0, alpha * 0.35)
	var core := Color(0.85, 0.98, 1.0, alpha * 0.95)
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1], glow, 4.0)
		draw_line(pts[i], pts[i + 1], core, 1.5)

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		extra_projectiles += 1
		return "Fen-Fire: the wisp leaps once more (+1 arc)"
	damage_mul *= 1.12
	return "Fen-Fire: colder light (+12% damage)"
