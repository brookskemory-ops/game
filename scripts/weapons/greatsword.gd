class_name Greatsword
extends Weapon
## Ser Roland's Greatsword — niche: heavy frontal cleave behind a telegraphed
## wind-up, huge burst + heavy knockback (docs/ABILITIES.md #5). The Oathkeeper
## evolution swings the full circle with a shockwave ring.
## Overrides _physics_process entirely: wind-up state machine, not insta-fire.

const SWING_FLASH := 0.22

var _windup := 0.0
var _windup_dir := Vector2.RIGHT
var _swing_time := 0.0
var _swing_angle := 0.0

func _physics_process(delta: float) -> void:
	if wielder == null or wielder.dead:
		return
	if _swing_time > 0.0:
		_swing_time -= delta
		queue_redraw()
	if _windup > 0.0:
		_windup -= delta
		queue_redraw()
		if _windup <= 0.0:
			_release()
		return
	_cooldown_left -= delta
	if _cooldown_left <= 0.0 and _try_fire():
		_cooldown_left = cooldown()

func _try_fire() -> bool:
	if enemies.nearest_enemy(wielder.global_position, attack_range() + 10.0) < 0:
		return false
	_windup = float(def.get("windup", 0.25))
	_windup_dir = wielder.facing
	queue_redraw()
	return true

func _release() -> void:
	var reach := attack_range()
	var arc_half := deg_to_rad(float(def.get("arc_deg", 200)) * 0.5)
	var full_circle := float(def.get("arc_deg", 200)) >= 355.0
	_swing_angle = _windup_dir.angle()
	var knockback := float(def.get("knockback", 260))
	for slot in enemies.query_circle(wielder.global_position, reach):
		var to_enemy: Vector2 = enemies.enemy_pos(slot) - wielder.global_position
		if not full_circle and to_enemy.length() > 14.0 \
				and absf(_windup_dir.angle_to(to_enemy)) > arc_half:
			continue
		enemies.damage_slot(slot, damage())
		enemies.push_slot(slot, to_enemy.normalized() * knockback)
	_swing_time = SWING_FLASH
	Sfx.play("swing", 1.0)
	var camera := wielder.get_node_or_null("Camera2D")
	if camera != null:
		camera.add_trauma(0.15)
	queue_redraw()

func _draw() -> void:
	var reach := attack_range()
	if _windup > 0.0:
		# Telegraph: a glint brightening along the blade path.
		var charge := 1.0 - _windup / maxf(0.01, float(def.get("windup", 0.25)))
		draw_arc(Vector2.ZERO, reach * 0.9, _windup_dir.angle() - 0.4, _windup_dir.angle() + 0.4, 8,
			Color(Palette.MOON.r, Palette.MOON.g, Palette.MOON.b, 0.15 + charge * 0.35), 2.0)
	if _swing_time > 0.0:
		var alpha := _swing_time / SWING_FLASH
		var arc_half := deg_to_rad(float(def.get("arc_deg", 200)) * 0.5)
		draw_arc(Vector2.ZERO, reach * 0.9, _swing_angle - arc_half, _swing_angle + arc_half, 20,
			Color(Palette.MOON.r, Palette.MOON.g, Palette.MOON.b, alpha * 0.85), 3.5)
		if bool(def.get("shockwave", false)):
			draw_arc(Vector2.ZERO, reach * (1.15 - alpha * 0.25), 0.0, TAU, 28,
				Color(Palette.PARCHMENT.r, Palette.PARCHMENT.g, Palette.PARCHMENT.b, alpha * 0.4), 2.0)

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		def["arc_deg"] = minf(360.0, float(def.get("arc_deg", 200)) + 30.0)
		return "Greatsword: a wider oath (+30° arc)"
	damage_mul *= 1.14
	return "Greatsword: heavier steel (+14% damage)"
