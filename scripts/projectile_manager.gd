class_name ProjectileManager
extends Node2D
## Pooled projectiles, same doctrine as the horde: flat packed arrays,
## one MultiMesh, no physics bodies, never allocated mid-run.

const CAP := 320
const HIT_RADIUS := 10.0
const HIDDEN := Transform2D(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)

var _enemies: EnemyManager
var _mm: MultiMesh

var _alive := PackedByteArray()
var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _ttl := PackedFloat32Array()
var _dmg := PackedFloat32Array()
var _pierce := PackedInt32Array()
var _last_hit := PackedInt32Array()
var _free := PackedInt32Array()

func setup(enemies: EnemyManager) -> void:
	_enemies = enemies
	_alive.resize(CAP)
	_pos.resize(CAP)
	_vel.resize(CAP)
	_ttl.resize(CAP)
	_dmg.resize(CAP)
	_pierce.resize(CAP)
	_last_hit.resize(CAP)
	_free.resize(CAP)
	for i in CAP:
		_alive[i] = 0
		_free[i] = CAP - 1 - i
	var tex := PixelSprites.get_tex("arrow")
	var quad := QuadMesh.new()
	quad.size = Vector2(tex.get_width(), tex.get_height())
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_2D
	_mm.mesh = quad
	_mm.instance_count = CAP
	for i in CAP:
		_mm.set_instance_transform_2d(i, HIDDEN)
	var mmi := MultiMeshInstance2D.new()
	mmi.name = "Projectiles"
	mmi.multimesh = _mm
	mmi.texture = tex
	add_child(mmi)

func fire(from: Vector2, dir: Vector2, damage: float, speed: float, ttl: float, pierce: int) -> void:
	if _free.is_empty():
		return
	var slot := _free[_free.size() - 1]
	_free.resize(_free.size() - 1)
	_alive[slot] = 1
	_pos[slot] = from
	_vel[slot] = dir.normalized() * speed
	_ttl[slot] = ttl
	_dmg[slot] = damage
	_pierce[slot] = maxi(1, pierce)
	_last_hit[slot] = -1

func _physics_process(delta: float) -> void:
	if _enemies == null:
		return
	for i in CAP:
		if _alive[i] == 0:
			continue
		_ttl[i] -= delta
		if _ttl[i] <= 0.0:
			_despawn(i)
			continue
		_pos[i] += _vel[i] * delta
		var hits := _enemies.query_circle(_pos[i], HIT_RADIUS)
		for slot in hits:
			if slot == _last_hit[i]:
				continue
			_enemies.damage_slot(slot, _dmg[i])
			_last_hit[i] = slot
			_pierce[i] -= 1
			if _pierce[i] <= 0:
				_despawn(i)
				break
		if _alive[i] == 1:
			_mm.set_instance_transform_2d(i, Transform2D(_vel[i].angle(), _pos[i]))

func _despawn(slot: int) -> void:
	if _alive[slot] == 0:
		return
	_alive[slot] = 0
	_free.append(slot)
	_mm.set_instance_transform_2d(slot, HIDDEN)
