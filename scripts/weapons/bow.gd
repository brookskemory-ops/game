class_name HuntingBow
extends Weapon
## Wren's Hunting Bow — niche: nearest-target piercing projectile
## (see docs/ABILITIES.md, weapon #1).

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
			float(def.get("damage", 10)) * damage_mul,
			float(def.get("proj_speed", 420)),
			float(def.get("proj_ttl", 0.9)),
			int(def.get("pierce", 1))
		)
	return true

func on_level(level: int) -> String:
	if level % 3 == 0:
		extra_projectiles += 1
		return "Another arrow nocked  (+1 arrow)"
	damage_mul *= 1.08
	return "The bow grows keener  (+8% damage)"
