class_name PilgrimsChain
extends Weapon
## Pilgrim's Chain — niche: fast thin lash, alternating left and right
## (docs/ABILITIES.md #11). Only ever horizontal.

var _side := 1.0
var _lash_time := 0.0
var _lash_side := 1.0

func _try_fire() -> bool:
	var reach := float(def.get("reach", 95)) * range_mul()
	var center: Vector2 = wielder.global_position + Vector2(_side * reach * 0.5, 0)
	var any_hit := false
	for slot in enemies.query_circle(center, reach * 0.55):
		var offset: Vector2 = enemies.enemy_pos(slot) - wielder.global_position
		if absf(offset.y) > 16.0 or signf(offset.x) != _side:
			continue
		enemies.damage_slot(slot, damage())
		any_hit = true
	_lash_time = 0.12
	_lash_side = _side
	_side = -_side  # alternate regardless — the rhythm is the weapon
	if any_hit:
		Sfx.play("swing", 0.5)
	queue_redraw()
	return true

func _process(delta: float) -> void:
	if _lash_time > 0.0:
		_lash_time -= delta
		queue_redraw()

func _draw() -> void:
	if _lash_time <= 0.0:
		return
	var alpha := _lash_time / 0.12
	var reach := float(def.get("reach", 95)) * range_mul()
	var tip := Vector2(_lash_side * reach, sin(alpha * PI) * 5.0)
	draw_line(Vector2.ZERO, tip * 0.55, Color(Palette.BONE.r, Palette.BONE.g, Palette.BONE.b, alpha * 0.9), 2.0)
	draw_line(tip * 0.55, tip, Color(Palette.ASH.r, Palette.ASH.g, Palette.ASH.b, alpha * 0.7), 1.5)

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		def["reach"] = float(def.get("reach", 95)) + 16.0
		return "Pilgrim's Chain: another link (+reach)"
	damage_mul *= 1.12
	return "Pilgrim's Chain: penance weighs more (+12% damage)"
