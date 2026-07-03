class_name FalconCompanion
extends Weapon
## Falcon Companion — niche: a seeker that hunts on its own, preferring elites
## (docs/ABILITIES.md #10). One target at a time.

var _falcon_pos := Vector2.ZERO
var _target := -1
var _hit_at := {}

func _physics_process(delta: float) -> void:
	if wielder == null or wielder.dead:
		return
	if _falcon_pos == Vector2.ZERO:
		_falcon_pos = wielder.global_position
	if _target < 0 or enemies.enemy_radius(_target) <= 0.0:
		_target = _pick_target()
	if _target >= 0:
		var goal := enemies.enemy_pos(_target)
		var dir := (goal - _falcon_pos)
		var dist := dir.length()
		if dist > 4.0:
			_falcon_pos += dir / dist * float(def.get("speed", 260)) * delta
		var now := float(Time.get_ticks_msec()) / 1000.0
		if dist < 14.0 and now - float(_hit_at.get(_target, -9.9)) >= float(def.get("hit_interval", 0.5)):
			_hit_at[_target] = now
			enemies.damage_slot(_target, damage())
	else:
		# Circle home lazily when there is nothing to hunt.
		var home: Vector2 = wielder.global_position + Vector2(30, -24)
		_falcon_pos = _falcon_pos.lerp(home, minf(1.0, delta * 2.0))
	queue_redraw()

## Elites first (big bodies), else the farthest prey in the hunting ground.
func _pick_target() -> int:
	var best := -1
	var best_score := -1.0
	for slot in enemies.query_circle(wielder.global_position, float(def.get("hunt_range", 340))):
		var score := (enemies.enemy_pos(slot) - wielder.global_position).length()
		if float(enemies.slot_def(slot).get("radius", 6)) >= 10.0:
			score += 10000.0  # elites always win
		if score > best_score:
			best_score = score
			best = slot
	return best

func _draw() -> void:
	var local := to_local(_falcon_pos)
	var flap := sin(float(Time.get_ticks_msec()) / 1000.0 * 16.0) * 3.0
	# A small chevron bird with beating wings.
	draw_line(local + Vector2(-5, -2 + flap), local, Palette.BONE, 1.5)
	draw_line(local, local + Vector2(5, -2 + flap), Palette.BONE, 1.5)
	draw_circle(local, 1.5, Palette.EMBER)

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		def["hit_interval"] = maxf(0.2, float(def.get("hit_interval", 0.5)) - 0.07)
		return "Falcon: faster strikes (-strike delay)"
	damage_mul *= 1.14
	return "Falcon: sharper talons (+14% damage)"
