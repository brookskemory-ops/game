class_name Player
extends CharacterBody2D
## The hero. Stats and weapon come from data (data/characters/*.json) —
## adding a hero must never require touching this script (design pillar #2).

signal hp_changed(current: float, max_value: float)
signal xp_changed(xp: int, needed: int, level: int)
signal leveled_up(level: int, message: String)
signal hurt(amount: float)
signal died

const LIGHTFOOT_RADIUS := 70.0
const LIGHTFOOT_BONUS := 1.15
const HURT_PULSE_THRESHOLD := 4.0

var stats := {}
var level := 1
var xp := 0
var max_hp := 80.0
var hp := 80.0
var move_speed := 130.0
var pickup_radius := 48.0
var body_radius := 6.0
var dead := false
var lightfoot_active := false

var _enemies: EnemyManager
var _projectiles: ProjectileManager
var _joystick: VirtualJoystick
var _sprite: Sprite2D
var _weapon: Weapon
var _camera: GameCamera
var _lightfoot_timer := 0.0
var _hurt_accum := 0.0  # aggregates contact DPS into discrete hurt pulses for feedback

func setup(enemies: EnemyManager, projectiles: ProjectileManager) -> void:
	_enemies = enemies
	_projectiles = projectiles
	var data: Variant = Game.load_json("res://data/characters/wren.json")
	if data is Dictionary:
		stats = data
	max_hp = float(stats.get("max_hp", 80))
	hp = max_hp
	move_speed = float(stats.get("move_speed", 130))
	pickup_radius = float(stats.get("pickup_radius", 48))
	body_radius = float(stats.get("radius", 6))
	_sprite = Sprite2D.new()
	_sprite.texture = PixelSprites.get_tex(String(stats.get("sprite", "wren")))
	add_child(_sprite)
	_equip(String(stats.get("weapon", "hunting_bow")))

func _equip(weapon_id: String) -> void:
	var def: Variant = Game.load_json("res://data/weapons/%s.json" % weapon_id)
	if not (def is Dictionary):
		return
	var weapon_script: Variant = load(String(def.get("script", "res://scripts/weapons/bow.gd")))
	_weapon = weapon_script.new()
	_weapon.init(def, self, _enemies, _projectiles)
	add_child(_weapon)

func _ready() -> void:
	_joystick = get_tree().get_first_node_in_group("virtual_joystick") as VirtualJoystick
	_camera = get_node_or_null("Camera2D") as GameCamera

func _physics_process(delta: float) -> void:
	if dead:
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if _joystick != null and _joystick.output.length() > 0.05:
		dir = _joystick.output
	# Light Foot (Wren's passive): faster while unthreatened. Checked at 5 Hz.
	_lightfoot_timer -= delta
	if _lightfoot_timer <= 0.0:
		_lightfoot_timer = 0.2
		lightfoot_active = _enemies != null \
			and _enemies.count_in_circle(global_position, LIGHTFOOT_RADIUS) == 0
	var speed := move_speed * (LIGHTFOOT_BONUS if lightfoot_active else 1.0)
	velocity = dir.limit_length(1.0) * speed
	move_and_slide()
	if _sprite != null:
		if absf(velocity.x) > 1.0:
			_sprite.flip_h = velocity.x < 0.0
		_sprite.modulate = _sprite.modulate.lerp(Color.WHITE, delta * 8.0)
	if _hurt_accum > 0.0:
		_hurt_accum = maxf(0.0, _hurt_accum - delta * 6.0)

func take_contact_damage(amount: float) -> void:
	if dead:
		return
	hp -= amount
	hp_changed.emit(hp, max_hp)
	_hurt_accum += amount
	if _hurt_accum >= HURT_PULSE_THRESHOLD:
		# A real bite, not a graze — pulse the red flash / vignette / shake once.
		_hurt_accum = 0.0
		if _sprite != null:
			_sprite.modulate = Color(1.0, 0.35, 0.35)
		hurt.emit(amount)
		if _camera != null:
			_camera.add_trauma(0.3)
	if hp <= 0.0:
		_die()

func gain_xp(amount: int) -> void:
	if dead:
		return
	xp += amount
	var needed := xp_needed(level)
	while xp >= needed:
		xp -= needed
		level += 1
		var message := ""
		if _weapon != null:
			message = _weapon.on_level(level)
		leveled_up.emit(level, message)
		if _camera != null:
			_camera.add_trauma(0.12)
		needed = xp_needed(level)
	xp_changed.emit(xp, needed, level)

func xp_needed(for_level: int) -> int:
	return 4 + for_level * 3

func _die() -> void:
	dead = true
	hp = 0.0
	hp_changed.emit(hp, max_hp)
	if _camera != null:
		_camera.add_trauma(0.7)
	died.emit()
