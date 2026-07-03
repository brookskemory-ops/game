class_name SaintReliquary
extends Weapon
## Reliquary of the Unquiet Saint — niche: steady sanctified field around the
## wielder, very low ticks plus a slow (docs/ABILITIES.md #12). Pure attrition.

var _tick_acc := 0.0

func _physics_process(delta: float) -> void:
	if wielder == null or wielder.dead:
		return
	_tick_acc += delta
	var interval := float(def.get("tick_interval", 0.4))
	if _tick_acc >= interval:
		_tick_acc -= interval
		var radius := float(def.get("field_radius", 55)) * area_mul()
		for slot in enemies.query_circle(wielder.global_position, radius):
			enemies.damage_slot(slot, damage())
			enemies.slow_slot(slot, 0.5)
	queue_redraw()

func _draw() -> void:
	var radius := float(def.get("field_radius", 55)) * area_mul()
	var pulse := 0.08 + 0.03 * sin(float(Time.get_ticks_msec()) / 1000.0 * 2.2)
	draw_circle(Vector2.ZERO, radius, Color(Palette.MOON.r, Palette.MOON.g, Palette.MOON.b, pulse))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36,
		Color(Palette.BONE.r, Palette.BONE.g, Palette.BONE.b, 0.22), 1.5)
	# The reliquary cross glyph above the wielder.
	draw_rect(Rect2(Vector2(-1, -radius - 8), Vector2(2, 7)), Palette.BONE)
	draw_rect(Rect2(Vector2(-3, -radius - 6), Vector2(6, 2)), Palette.BONE)

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		def["field_radius"] = float(def.get("field_radius", 55)) + 10.0
		return "Reliquary: the sanctity spreads (+field size)"
	damage_mul *= 1.15
	return "Reliquary: the saint stirs (+15% damage)"
