class_name ThrowingAxes
extends Weapon
## Throwing Axes — niche: high-damage tumbling throws in random directions
## (docs/ABILITIES.md #7). Unreliable by design; rewards repositioning.

var _axes: Array = []  # [position, velocity, spin_angle, time_left, hit_set]

func _try_fire() -> bool:
	if enemies.nearest_enemy(wielder.global_position, 300.0) < 0:
		return false  # hold when nothing is anywhere near
	var count := int(def.get("count", 2)) + extra_projectiles
	for i in count:
		var dir := Vector2.from_angle(randf() * TAU)
		_axes.append([wielder.global_position, dir * float(def.get("throw_speed", 240)),
			randf() * TAU, float(def.get("flight_time", 0.7)), {}])
	Sfx.play("swing", 0.6)
	return true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _axes.is_empty():
		return
	for axe in _axes:
		axe[3] -= delta
		axe[1] *= maxf(0.0, 1.0 - 1.6 * delta)  # decelerating tumble
		axe[0] += axe[1] * delta
		axe[2] += 12.0 * delta
		var hits: Dictionary = axe[4]
		for slot in enemies.query_circle(axe[0], 12.0):
			if hits.has(slot):
				continue
			hits[slot] = true
			enemies.damage_slot(slot, damage())
	_axes = _axes.filter(func(a): return a[3] > 0.0)
	queue_redraw()

func _draw() -> void:
	for axe in _axes:
		var local := to_local(axe[0])
		var spin: float = axe[2]
		# Tumbling axe: haft line + wedge head.
		var haft := Vector2.from_angle(spin) * 5.0
		draw_line(local - haft, local + haft, Palette.EMBER.darkened(0.3), 2.0)
		draw_circle(local + haft, 2.5, Palette.BONE)

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		extra_projectiles += 1
		return "Throwing Axes: another axe on the belt (+1 axe)"
	damage_mul *= 1.13
	return "Throwing Axes: heavier heads (+13% damage)"
