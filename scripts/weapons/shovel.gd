class_name IronShovel
extends Weapon
## Maud's Iron Shovel — niche: facing-direction melee arc with knockback
## (docs/ABILITIES.md weapon #2). No reach; must face the threat.

var _swing_time := 0.0
var _swing_angle := 0.0

func _try_fire() -> bool:
	var reach := float(def.get("range", 52))
	# Hold the swing until something is actually in reach.
	if enemies.nearest_enemy(wielder.global_position, reach + 8.0) < 0:
		return false
	var dir := wielder.facing
	_swing_angle = dir.angle()
	var center: Vector2 = wielder.global_position + dir * reach * 0.5
	var knockback := float(def.get("knockback", 150))
	var arc_half := deg_to_rad(float(def.get("arc_deg", 130)) * 0.5)
	for slot in enemies.query_circle(center, reach * 0.75):
		var to_enemy: Vector2 = enemies.enemy_pos(slot) - wielder.global_position
		if absf(dir.angle_to(to_enemy)) > arc_half and to_enemy.length() > 12.0:
			continue
		enemies.damage_slot(slot, damage())
		enemies.push_slot(slot, to_enemy.normalized() * knockback)
	_swing_time = 0.16
	queue_redraw()
	return true

func _process(delta: float) -> void:
	if _swing_time > 0.0:
		_swing_time -= delta
		queue_redraw()

func _draw() -> void:
	if _swing_time <= 0.0:
		return
	var alpha := _swing_time / 0.16
	var reach := float(def.get("range", 52))
	var arc_half := deg_to_rad(float(def.get("arc_deg", 130)) * 0.5)
	# A fading slash arc in front of the wielder (weapon node sits at player origin).
	draw_arc(Vector2.ZERO, reach * 0.85, _swing_angle - arc_half, _swing_angle + arc_half, 14,
		Color(Palette.BONE.r, Palette.BONE.g, Palette.BONE.b, alpha * 0.8), 3.0)
	draw_arc(Vector2.ZERO, reach * 0.6, _swing_angle - arc_half * 0.8, _swing_angle + arc_half * 0.8, 10,
		Color(Palette.ASH.r, Palette.ASH.g, Palette.ASH.b, alpha * 0.4), 2.0)

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		def["arc_deg"] = float(def.get("arc_deg", 130)) + 30.0
		return "Iron Shovel: wider swing (+30° arc)"
	damage_mul *= 1.14
	return "Iron Shovel: heavier blade (+14% damage)"
