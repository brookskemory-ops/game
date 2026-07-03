class_name GemManager
extends Node2D
## Pooled XP gems with magnet pickup. Flat arrays + MultiMesh, like the horde.

const CAP := 900
const COLLECT_DIST := 10.0
const ATTRACT_ACCEL := 1400.0

var _player: Node2D
var _pickup_radius := 48.0
var _mm: MultiMesh
var _time := 0.0

var _alive := PackedByteArray()
var _pos := PackedVector2Array()
var _value := PackedInt32Array()
var _attract := PackedByteArray()
var _pull_speed := PackedFloat32Array()
var _free := PackedInt32Array()

func setup(player: Node2D, pickup_radius: float) -> void:
	_player = player
	_pickup_radius = pickup_radius
	_alive.resize(CAP)
	_pos.resize(CAP)
	_value.resize(CAP)
	_attract.resize(CAP)
	_pull_speed.resize(CAP)
	_free.resize(CAP)
	for i in CAP:
		_alive[i] = 0
		_free[i] = CAP - 1 - i
	var tex := PixelSprites.get_tex("gem")
	var quad := QuadMesh.new()
	quad.size = Vector2(tex.get_width(), tex.get_height())
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_2D
	_mm.mesh = quad
	_mm.instance_count = CAP
	for i in CAP:
		_mm.set_instance_transform_2d(i, Transform2D(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO))
	var mmi := MultiMeshInstance2D.new()
	mmi.name = "Gems"
	mmi.multimesh = _mm
	mmi.texture = tex
	add_child(mmi)

func spawn(at: Vector2, value: int) -> void:
	if _free.is_empty():
		return  # cap reached; the ground is already paved with souls
	var slot := _free[_free.size() - 1]
	_free.resize(_free.size() - 1)
	_alive[slot] = 1
	_pos[slot] = at + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
	_value[slot] = maxi(1, value)
	_attract[slot] = 0
	_pull_speed[slot] = 0.0

func _physics_process(delta: float) -> void:
	if _player == null:
		return
	_time += delta
	var ppos: Vector2 = _player.global_position
	# Read live so pickup-range passives (Lodestone) take effect immediately.
	var live_radius: Variant = _player.get("pickup_radius")
	if live_radius != null:
		_pickup_radius = float(live_radius)
	for i in CAP:
		if _alive[i] == 0:
			continue
		var dist := _pos[i].distance_to(ppos)
		if _attract[i] == 0:
			if dist <= _pickup_radius:
				_attract[i] = 1
		else:
			_pull_speed[i] += ATTRACT_ACCEL * delta
			var step := _pull_speed[i] * delta
			if step >= dist or dist <= COLLECT_DIST:
				_collect(i)
				continue
			_pos[i] += (ppos - _pos[i]) / dist * step
		var bob := sin(_time * 3.0 + float(i) * 0.7) * 1.5
		_mm.set_instance_transform_2d(i, Transform2D(0.0, _pos[i] + Vector2(0.0, bob)))

func _collect(slot: int) -> void:
	if _player.has_method("gain_xp"):
		_player.gain_xp(_value[slot])
	_alive[slot] = 0
	_free.append(slot)
	_mm.set_instance_transform_2d(slot, Transform2D(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO))
