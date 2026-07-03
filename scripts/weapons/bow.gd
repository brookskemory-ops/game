class_name HuntingBow
extends Weapon
## Wren's Hunting Bow — niche: nearest-target piercing projectile
## (docs/ABILITIES.md weapon #1).

func _try_fire() -> bool:
	var target := enemies.nearest_enemy(wielder.global_position, float(def.get("range", 220)))
	if target < 0:
		return false
	var dir := (enemies.enemy_pos(target) - wielder.global_position).normalized()
	var count := int(def.get("projectiles", 1)) + extra_projectiles
	var spread := deg_to_rad(float(def.get("spread_deg", 6.0)))
	for k in count:
		var angle_off := randf_range(-0.02, 0.02)
		if count > 1:
			angle_off += lerpf(-spread, spread, float(k) / float(count - 1))
		projectiles.fire(
			wielder.global_position,
			dir.rotated(angle_off),
			damage(),
			float(def.get("proj_speed", 420)),
			float(def.get("proj_ttl", 0.9)),
			int(def.get("pierce", 1))
		)
	return true

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		extra_projectiles += 1
		return "Hunting Bow: another arrow nocked (+1 arrow)"
	damage_mul *= 1.10
	return "Hunting Bow: the string sings keener (+10% damage)"
