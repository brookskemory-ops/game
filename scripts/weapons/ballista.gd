class_name BallistaBolt
extends Weapon
## Ballista Bolt — niche: slow-charging shot that pierces everything down one
## lane (docs/ABILITIES.md #8). A single narrow line.

var _charge := 0.0
var _charge_dir := Vector2.RIGHT
var _beam_time := 0.0
var _beam_dir := Vector2.RIGHT

func _physics_process(delta: float) -> void:
	if wielder == null or wielder.dead:
		return
	if _beam_time > 0.0:
		_beam_time -= delta
		queue_redraw()
	if _charge > 0.0:
		_charge -= delta
		queue_redraw()
		if _charge <= 0.0:
			_loose()
		return
	_cooldown_left -= delta
	if _cooldown_left <= 0.0 and _try_fire():
		_cooldown_left = cooldown()

func _try_fire() -> bool:
	var target := enemies.nearest_enemy(wielder.global_position, attack_range())
	if target < 0:
		return false
	_charge_dir = (enemies.enemy_pos(target) - wielder.global_position).normalized()
	_charge = float(def.get("windup", 0.5))
	queue_redraw()
	return true

func _loose() -> void:
	_beam_dir = _charge_dir
	_beam_time = 0.18
	var reach := attack_range()
	var hit := {}
	var step := 14.0
	var travelled := 8.0
	while travelled < reach:
		for slot in enemies.query_circle(wielder.global_position + _beam_dir * travelled, 13.0):
			if hit.has(slot):
				continue
			hit[slot] = true
			enemies.damage_slot(slot, damage())
		travelled += step
	Sfx.play("shoot", 1.0)
	queue_redraw()

func _draw() -> void:
	if _charge > 0.0:
		var readiness := 1.0 - _charge / maxf(0.01, float(def.get("windup", 0.5)))
		draw_line(Vector2.ZERO, _charge_dir * 26.0,
			Color(Palette.BONE.r, Palette.BONE.g, Palette.BONE.b, 0.2 + readiness * 0.5), 2.0)
	if _beam_time > 0.0:
		var alpha := _beam_time / 0.18
		var tip := _beam_dir * attack_range()
		# Wide soft lane first — the bolt pierces everything within ~13px of the
		# line, so a width-26 wash shows the true catch — then the bright core.
		draw_line(Vector2.ZERO, tip,
			Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, alpha * 0.28), 26.0)
		draw_line(Vector2.ZERO, tip,
			Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, alpha * 0.4), 10.0)
		draw_line(Vector2.ZERO, tip,
			Color(Palette.PARCHMENT.r, Palette.PARCHMENT.g, Palette.PARCHMENT.b, alpha * 0.9), 3.0)

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		def["windup"] = maxf(0.15, float(def.get("windup", 0.5)) - 0.08)
		return "Ballista: faster crank (-wind-up)"
	damage_mul *= 1.16
	return "Ballista: heavier bolt (+16% damage)"
