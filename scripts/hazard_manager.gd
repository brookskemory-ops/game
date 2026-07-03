class_name HazardManager
extends Node2D
## Pooled ground hazards (poison pools, later burning ground etc.).
## Same doctrine as the horde: flat packed arrays, no physics, no allocation
## mid-run. Damage ticks in discrete pulses through the enemy grid.

const CAP := 48
const TICK := 0.35

var _enemies: EnemyManager
var _time := 0.0

var _alive := PackedByteArray()
var _pos := PackedVector2Array()
var _radius := PackedFloat32Array()
var _dps := PackedFloat32Array()
var _ttl := PackedFloat32Array()
var _tick_acc := PackedFloat32Array()
var _free := PackedInt32Array()

func setup(enemies: EnemyManager) -> void:
	_enemies = enemies
	_alive.resize(CAP)
	_pos.resize(CAP)
	_radius.resize(CAP)
	_dps.resize(CAP)
	_ttl.resize(CAP)
	_tick_acc.resize(CAP)
	_free.resize(CAP)
	for i in CAP:
		_alive[i] = 0
		_free[i] = CAP - 1 - i

func spawn(at: Vector2, radius: float, dps: float, duration: float) -> void:
	if _free.is_empty():
		return
	var slot := _free[_free.size() - 1]
	_free.resize(_free.size() - 1)
	_alive[slot] = 1
	_pos[slot] = at
	_radius[slot] = radius
	_dps[slot] = dps
	_ttl[slot] = duration
	_tick_acc[slot] = 0.0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _enemies == null:
		return
	_time += delta
	var any_active := false
	for i in CAP:
		if _alive[i] == 0:
			continue
		any_active = true
		_ttl[i] -= delta
		if _ttl[i] <= 0.0:
			_alive[i] = 0
			_free.append(i)
			continue
		_tick_acc[i] += delta
		if _tick_acc[i] >= TICK:
			_tick_acc[i] -= TICK
			for slot in _enemies.query_circle(_pos[i], _radius[i]):
				_enemies.damage_slot(slot, _dps[i] * TICK)
	if any_active:
		queue_redraw()

func _draw() -> void:
	for i in CAP:
		if _alive[i] == 0:
			continue
		var pulse := 0.16 + 0.05 * sin(_time * 3.0 + float(i) * 1.7)
		var fade := clampf(_ttl[i] / 0.5, 0.0, 1.0)  # quick fade-out at the end
		draw_circle(_pos[i], _radius[i],
			Color(Palette.POISON.r, Palette.POISON.g, Palette.POISON.b, pulse * fade))
		draw_arc(_pos[i], _radius[i], 0.0, TAU, 20,
			Color(Palette.POISON.r, Palette.POISON.g, Palette.POISON.b, 0.35 * fade), 1.5)
		# A couple of rising bubbles for texture.
		for b in 3:
			var bubble_phase := fmod(_time * 0.7 + float(b) * 0.33 + float(i) * 0.21, 1.0)
			var bubble_pos := _pos[i] + Vector2(
				sin(float(b) * 2.1 + float(i)) * _radius[i] * 0.5,
				(0.5 - bubble_phase) * _radius[i] * 0.8
			)
			draw_circle(bubble_pos, 1.5,
				Color(Palette.POISON.r, Palette.POISON.g, Palette.POISON.b, (1.0 - bubble_phase) * 0.5 * fade))
