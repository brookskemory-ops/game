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
	var m := Palette.MOON
	# A filled shockwave flash fading as the ring expands, then a bright ring.
	draw_circle(Vector2.ZERO, radius, Color(m.r, m.g, m.b, alpha * alpha * 0.12))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(m.r, m.g, m.b, alpha * 0.7), 3.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, alpha * 0.35), 1.0)
	draw_arc(Vector2.ZERO, radius * 0.8, 0.0, TAU, 32,
		Color(m.r, m.g, m.b, alpha * 0.3), 1.5)

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		def["nova_radius"] = float(def.get("nova_radius", 90)) + 18.0
		return "Warding Bell: the toll carries further (+ring size)"
	damage_mul *= 1.12
	def["knockback"] = float(def.get("knockback", 320)) + 25.0
	return "Warding Bell: a deeper voice (+damage, +push)"
