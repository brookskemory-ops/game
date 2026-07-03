class_name PlagueVials
extends Weapon
## Corvus' Plague Vials — niche: lobbed zone at the densest cluster, lingering
## poison pools (docs/ABILITIES.md weapon #3). Slow kill; no burst, no knockback.

const FLIGHT_TIME := 0.45
const ARC_HEIGHT := 26.0

var _flights: Array = []  # [from: Vector2, to: Vector2, t: float]

func _try_fire() -> bool:
	var throw_range := attack_range()
	var target := _densest_target(throw_range)
	if target == Vector2.INF:
		return false
	_flights.append([wielder.global_position, target, 0.0])
	Sfx.play("lob", 0.7)
	return true

## Sample nearby enemies and pick the one with the most neighbors.
func _densest_target(throw_range: float) -> Vector2:
	var slots := enemies.query_circle(wielder.global_position, throw_range)
	if slots.is_empty():
		return Vector2.INF
	var best := -1
	var best_neighbors := -1
	for i in mini(slots.size(), 12):
		var slot: int = slots[randi() % slots.size()]
		var neighbors := enemies.count_in_circle(enemies.enemy_pos(slot), 42.0)
		if neighbors > best_neighbors:
			best_neighbors = neighbors
			best = slot
	return enemies.enemy_pos(best)

var _cloud_pos := Vector2.INF
var _cloud_tick := 0.0

func _physics_process(delta: float) -> void:
	# The Miasma evolution: the pools have merged into one roaming cloud.
	if bool(def.get("roaming", false)):
		_update_miasma(delta)
		return
	super._physics_process(delta)
	if _flights.is_empty():
		return
	for flight in _flights:
		flight[2] += delta / FLIGHT_TIME
	for flight in _flights:
		if flight[2] >= 1.0 and hazards != null:
			hazards.spawn(flight[1], float(def.get("pool_radius", 34)) * area_mul(),
				damage(),
				float(def.get("duration", 3.2)) * (1.0 + float(wielder.mods.get("duration", 0.0))))
	_flights = _flights.filter(func(f): return f[2] < 1.0)
	queue_redraw()

func _update_miasma(delta: float) -> void:
	if wielder == null or wielder.dead:
		return
	if _cloud_pos == Vector2.INF:
		_cloud_pos = wielder.global_position
	var goal := _densest_target(attack_range())
	if goal == Vector2.INF:
		goal = wielder.global_position
	_cloud_pos = _cloud_pos.move_toward(goal, 65.0 * delta)
	_cloud_tick += delta
	if _cloud_tick >= 0.35:
		_cloud_tick -= 0.35
		var radius := float(def.get("pool_radius", 44)) * area_mul()
		for slot in enemies.query_circle(_cloud_pos, radius):
			enemies.damage_slot(slot, damage() * 0.35)
	queue_redraw()

func _draw() -> void:
	if bool(def.get("roaming", false)) and _cloud_pos != Vector2.INF:
		var local := to_local(_cloud_pos)
		var radius := float(def.get("pool_radius", 44)) * area_mul()
		var t := float(Time.get_ticks_msec()) / 1000.0
		draw_circle(local, radius, Color(Palette.POISON.r, Palette.POISON.g, Palette.POISON.b,
			0.14 + 0.04 * sin(t * 2.4)))
		draw_circle(local, radius * 0.6, Color(Palette.POISON.r, Palette.POISON.g, Palette.POISON.b, 0.12))
		draw_arc(local, radius, 0.0, TAU, 24, Color(Palette.POISON.r, Palette.POISON.g, Palette.POISON.b, 0.3), 1.5)
		return
	for flight in _flights:
		var t: float = flight[2]
		var world: Vector2 = flight[0].lerp(flight[1], t) + Vector2(0.0, -ARC_HEIGHT * sin(PI * t))
		var local := to_local(world)
		draw_circle(local, 2.5, Palette.POISON)
		draw_circle(local, 1.0, Palette.POISON.lightened(0.3))

func _on_upgrade(new_level: int) -> String:
	if new_level % 3 == 0:
		def["pool_radius"] = float(def.get("pool_radius", 34)) + 8.0
		return "Plague Vials: fouler brew (+8 pool size)"
	def["duration"] = float(def.get("duration", 3.2)) + 0.5
	damage_mul *= 1.08
	return "Plague Vials: it lingers (+duration, +8% damage)"
