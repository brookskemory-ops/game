class_name DevouringGrief
extends Weapon
## Thessaly's signature — a tether of grief to the nearest of the dead: a
## continuous drain that wounds it and feeds her. Niche: a SUSTAINED single-
## target beam with lifesteal (no other weapon channels — the lash hits a line,
## the falcon strikes in bursts, the aura is a radial field). Hero-locked.

var _target := -1
var _sway := 0.0

func _physics_process(delta: float) -> void:
	if wielder == null or wielder.dead:
		return
	_sway += delta * 9.0
	# Re-acquire the nearest each frame (cheap; also keeps the target valid).
	_target = enemies.nearest_enemy(wielder.global_position, attack_range())
	if _target >= 0:
		# damage() is treated as damage-per-second here; it still routes through
		# the wielder's mods (so Communion feeds the beam).
		enemies.damage_slot(_target, damage() * delta)
		wielder.heal(float(def.get("leech", 2.5)) * delta)
	queue_redraw()

func _draw() -> void:
	if _target < 0:
		return
	var to := to_local(enemies.enemy_pos(_target))
	# A wavering violet tether: perpendicular jitter so it writhes.
	var perp := Vector2(-to.y, to.x).normalized()
	var pts: PackedVector2Array = [Vector2.ZERO]
	for s in range(1, 5):
		var t := float(s) / 5.0
		pts.append(Vector2.ZERO.lerp(to, t) + perp * sin(_sway + s) * 3.0)
	pts.append(to)
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1], Color(0.55, 0.35, 0.65, 0.35), 4.0)
		draw_line(pts[i], pts[i + 1], Color(0.9, 0.75, 1.0, 0.85), 1.5)
	draw_circle(to, 4.0, Color(0.8, 0.6, 0.9, 0.4))

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		def["leech"] = float(def.get("leech", 2.5)) + 1.0
		return "Devouring Grief: it feeds you deeper (+lifesteal)"
	if new_level % 3 == 1:
		def["range"] = float(def.get("range", 150)) + 25.0
		return "Devouring Grief: the tether reaches further (+range)"
	damage_mul *= 1.15
	return "Devouring Grief: a hungrier grief (+15% drain)"
