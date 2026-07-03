class_name GemManager
extends Node2D
## Pooled ground pickups with magnet collection: XP gems and gold coins.
## Flat arrays + one MultiMesh per pickup kind, like the horde.

const CAP := 900
const COLLECT_DIST := 10.0
const ATTRACT_ACCEL := 1400.0
const HIDDEN := Transform2D(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)

const KIND_GEM := 0
const KIND_COIN := 1
const KIND_SCROLL := 2  # elite drop: grants a bonus draft

var _player: Node2D
var _pickup_radius := 48.0
var _time := 0.0
var _mm := []  # MultiMesh per kind

var _alive := PackedByteArray()
var _kind := PackedByteArray()
var _pos := PackedVector2Array()
var _value := PackedInt32Array()
var _attract := PackedByteArray()
var _pull_speed := PackedFloat32Array()
var _free := PackedInt32Array()

func setup(player: Node2D, pickup_radius: float) -> void:
	_player = player
	_pickup_radius = pickup_radius
	_alive.resize(CAP)
	_kind.resize(CAP)
	_pos.resize(CAP)
	_value.resize(CAP)
	_attract.resize(CAP)
	_pull_speed.resize(CAP)
	_free.resize(CAP)
	for i in CAP:
		_alive[i] = 0
		_free[i] = CAP - 1 - i
	for sprite_id in ["gem", "coin", "scroll"]:
		var tex: Texture2D = PixelSprites.flipped_for_multimesh(PixelSprites.get_tex(sprite_id))
		var quad := QuadMesh.new()
		quad.size = Vector2(tex.get_width(), tex.get_height())
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_2D
		mm.mesh = quad
		mm.instance_count = CAP
		for i in CAP:
			mm.set_instance_transform_2d(i, HIDDEN)
		var mmi := MultiMeshInstance2D.new()
		mmi.name = "Pickups_" + sprite_id
		mmi.multimesh = mm
		mmi.texture = tex
		add_child(mmi)
		_mm.append(mm)

## Level-up juice: every gem on the ground flies to the hero.
func vacuum_all() -> void:
	for i in CAP:
		if _alive[i] == 1 and _kind[i] == KIND_GEM:
			_attract[i] = 1

func spawn(at: Vector2, value: int, kind := KIND_GEM) -> void:
	if _free.is_empty():
		return  # cap reached; the ground is already paved with souls
	var slot := _free[_free.size() - 1]
	_free.resize(_free.size() - 1)
	_alive[slot] = 1
	_kind[slot] = kind
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
		_mm[_kind[i]].set_instance_transform_2d(i, Transform2D(0.0, _pos[i] + Vector2(0.0, bob)))

func _collect(slot: int) -> void:
	if _kind[slot] == KIND_SCROLL:
		if _player.has_method("grant_bonus_draft"):
			_player.grant_bonus_draft()
		Sfx.play("level", 0.7)
	elif _kind[slot] == KIND_COIN:
		var gold_mul := 1.0
		var live_mul: Variant = _player.get("gold_mul")
		if live_mul != null:
			gold_mul = float(live_mul)
		Game.add_gold(int(round(float(_value[slot]) * gold_mul)))
		Sfx.play("coin", 0.6)
	elif _player.has_method("gain_xp"):
		_player.gain_xp(_value[slot])
		Sfx.play("gem", 0.5)
	_alive[slot] = 0
	_free.append(slot)
	_mm[_kind[slot]].set_instance_transform_2d(slot, HIDDEN)
