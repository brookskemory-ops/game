class_name WardingBell
extends Weapon
## Warding Bell — niche: radial nova that shoves the horde back
## (docs/ABILITIES.md #9). Crowd control, not a killer.

var _ring_time := 0.0

func _try_fire() -> bool:
	var radius := float(def.get("nova_radius", 90)) * area_mul()
	var slots := enemies.query_circle(wielder.global_position, radius)
	if slots.is_empty():
		return false
	var knockback := float(def.get("knockback", 320))
	for slot in slots:
		enemies.damage_slot(slot, damage())
		var away: Vector2 = enemies.enemy_pos(slot) - wielder.global_position
		enemies.push_slot(slot, away.normalized() * knockback)
	_ring_time = 0.35
	Sfx.play("bell", 0.5)
	queue_redraw()
	return true

func _process(delta: float) -> void:
	if _ring_time > 0.0:
		_ring_time -= delta
		queue_redraw()

func _draw() -> void:
	if _ring_time <= 0.0:
		return
	var alpha := _ring_time / 0.35
	var radius := float(def.get("nova_radius", 90)) * area_mul() * (1.2 - alpha * 0.5)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40,
		Color(Palette.MOON.r, Palette.MOON.g, Palette.MOON.b, alpha * 0.6), 2.5)
	draw_arc(Vector2.ZERO, radius * 0.8, 0.0, TAU, 32,
		Color(Palette.MOON.r, Palette.MOON.g, Palette.MOON.b, alpha * 0.3), 1.5)

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		def["nova_radius"] = float(def.get("nova_radius", 90)) + 18.0
		return "Warding Bell: the toll carries further (+ring size)"
	damage_mul *= 1.12
	def["knockback"] = float(def.get("knockback", 320)) + 25.0
	return "Warding Bell: a deeper voice (+damage, +push)"
