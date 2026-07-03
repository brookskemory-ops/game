class_name Player
extends CharacterBody2D
## The hero. Stats and starting weapon come from data (data/characters/*.json) —
## adding a hero must never require touching this script (design pillar #2).
## Leveling produces pending draft picks; the arena runs the upgrade drafts.

signal hp_changed(current: float, max_value: float)
signal xp_changed(xp: int, needed: int, level: int)
signal leveled_up(level: int)
signal hurt(amount: float)
signal died

const MAX_WEAPONS := 3
const LIGHTFOOT_RADIUS := 70.0
const LIGHTFOOT_BONUS := 1.15
const HURT_PULSE_THRESHOLD := 4.0

var stats := {}
var level := 1
var xp := 0
var pending_levels := 0  # unclaimed draft picks; consumed by the arena

# Base stats (from character data) and passive modifiers.
# mods: damage/cooldown/speed/pickup are multipliers (start 1.0);
#       armor is flat DPS blocked; max_hp is a flat bonus.
var mods := {
	"damage": 1.0, "cooldown": 1.0, "speed": 1.0, "pickup": 1.0,
	"range": 1.0, "area": 1.0, "armor": 0.0, "max_hp": 0.0,
}
var passive_stacks := {}  # passive id -> stacks taken
var base_max_hp := 80.0
var base_move_speed := 130.0
var base_pickup_radius := 48.0

var max_hp := 80.0
var hp := 80.0
var move_speed := 130.0
var pickup_radius := 48.0
var body_radius := 6.0
var gold_mul := 1.0  # Wages of Death (Maud) and Fortune raise this
var revives := 0     # Mercy (camp shop)
var dead := false
var lightfoot_active := false
var facing := Vector2.RIGHT
var _sig_light_foot := false
var _sig_malpractice := false
var _sig_mortification := false
var _sig_bulwark := false
var _invuln := 0.0
var _last_kill_at := -10.0

var weapons: Array = []  # of Weapon

var _ctx := {}  # enemies / projectiles / hazards, shared with weapons
var _enemies: EnemyManager
var _joystick: VirtualJoystick
var _sprite: Sprite2D
var _camera: GameCamera
var _lightfoot_timer := 0.0
var _hurt_accum := 0.0  # aggregates contact DPS into discrete hurt pulses

func setup(ctx: Dictionary) -> void:
	_ctx = ctx
	_enemies = ctx.get("enemies")
	var data: Variant = Game.load_json("res://data/characters/%s.json" % Game.selected_character)
	if data is Dictionary:
		stats = data
	# Signature passive: exclusive to the hero, resolved from data
	# (docs/ABILITIES.md §4). Each is one hook, never bespoke subsystems.
	match String(stats.get("signature", "")):
		"light_foot":
			_sig_light_foot = true
		"wages_of_death":
			gold_mul = 1.5
		"malpractice":
			_sig_malpractice = true
			if _enemies != null:
				_enemies.enemy_killed.connect(_on_enemy_killed)
		"mortification":
			_sig_mortification = true
		"bulwark":
			_sig_bulwark = true
	_apply_camp_shop()
	base_max_hp = float(stats.get("max_hp", 80))
	base_move_speed = float(stats.get("move_speed", 130))
	base_pickup_radius = float(stats.get("pickup_radius", 48))
	body_radius = float(stats.get("radius", 6))
	max_hp = base_max_hp
	hp = max_hp
	move_speed = base_move_speed
	pickup_radius = base_pickup_radius
	_sprite = Sprite2D.new()
	_sprite.texture = PixelSprites.get_tex(String(stats.get("sprite", "wren")))
	add_child(_sprite)
	equip(String(stats.get("weapon", "hunting_bow")))

## Add a weapon by id. Returns the Weapon node, or null if slots are full / data missing.
func equip(weapon_id: String) -> Weapon:
	if weapons.size() >= MAX_WEAPONS:
		return null
	var def: Variant = Game.load_json("res://data/weapons/%s.json" % weapon_id)
	if not (def is Dictionary):
		return null
	var weapon_script: Variant = load(String(def.get("script", "")))
	if weapon_script == null:
		return null
	var weapon: Weapon = weapon_script.new()
	weapon.init(def, self, _ctx)
	add_child(weapon)
	weapons.append(weapon)
	return weapon

func has_weapon(weapon_id: String) -> bool:
	for weapon in weapons:
		if weapon.weapon_id() == weapon_id:
			return true
	return false

## Permanent upgrades bought at the campfire (data/shop.json).
func _apply_camp_shop() -> void:
	var shop_defs: Variant = Game.load_json("res://data/shop.json")
	if not (shop_defs is Dictionary):
		return
	for item_id in shop_defs:
		var rank := Game.shop_level(String(item_id))
		if rank <= 0:
			continue
		var effects: Dictionary = shop_defs[item_id].get("effect", {})
		for key in effects:
			var amount := float(effects[key]) * float(rank)
			match String(key):
				"gold":
					gold_mul += amount
				"revive":
					revives += int(amount)
				_:
					if mods.has(key):
						mods[key] = float(mods[key]) + amount
	_recompute()

## Malpractice (Corvus): kills within a 3s streak each restore 1 HP.
func _on_enemy_killed() -> void:
	var now := float(Time.get_ticks_msec()) / 1000.0
	if now - _last_kill_at <= 3.0:
		heal(1.0)
	_last_kill_at = now

## All weapon damage routes through this (Mortification scales with missing HP).
func damage_multiplier() -> float:
	var multiplier := float(mods["damage"])
	if _sig_mortification and max_hp > 0.0:
		multiplier *= 1.0 + clampf(1.0 - hp / max_hp, 0.0, 1.0)
	return multiplier

func apply_passive(id: String, def: Dictionary) -> void:
	passive_stacks[id] = int(passive_stacks.get(id, 0)) + 1
	var effects: Dictionary = def.get("effects", {})
	for key in effects:
		mods[key] = float(mods.get(key, 0.0)) + float(effects[key])
	_recompute()

func _recompute() -> void:
	move_speed = base_move_speed * float(mods["speed"])
	pickup_radius = base_pickup_radius * float(mods["pickup"])
	var new_max := base_max_hp + float(mods["max_hp"])
	if new_max > max_hp:
		hp += new_max - max_hp  # raising the cap also heals the difference
	max_hp = new_max
	hp_changed.emit(hp, max_hp)

func heal(amount: float) -> void:
	if dead:
		return
	hp = minf(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)

func _ready() -> void:
	_joystick = get_tree().get_first_node_in_group("virtual_joystick") as VirtualJoystick
	_camera = get_node_or_null("Camera2D") as GameCamera

func _physics_process(delta: float) -> void:
	if dead:
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if _joystick != null and _joystick.output.length() > 0.05:
		dir = _joystick.output
	# Light Foot (Wren's signature): faster while unthreatened. Checked at 5 Hz.
	if _sig_light_foot:
		_lightfoot_timer -= delta
		if _lightfoot_timer <= 0.0:
			_lightfoot_timer = 0.2
			lightfoot_active = _enemies != null \
				and _enemies.count_in_circle(global_position, LIGHTFOOT_RADIUS) == 0
	var speed := move_speed * (LIGHTFOOT_BONUS if lightfoot_active else 1.0)
	velocity = dir.limit_length(1.0) * speed
	move_and_slide()
	if velocity.length_squared() > 1.0:
		facing = velocity.normalized()
	if _sprite != null:
		if absf(velocity.x) > 1.0:
			_sprite.flip_h = velocity.x < 0.0
		_sprite.modulate = _sprite.modulate.lerp(Color.WHITE, delta * 8.0)
	if _hurt_accum > 0.0:
		_hurt_accum = maxf(0.0, _hurt_accum - delta * 6.0)
	if _invuln > 0.0:
		_invuln -= delta
		if _sprite != null:  # flicker while invulnerable
			_sprite.visible = _invuln <= 0.0 or fmod(_invuln, 0.2) > 0.08

## Contact damage as DPS while touched, minus flat armor (Oaken Shield).
func take_contact_dps(dps: float, delta: float) -> void:
	if dead or _invuln > 0.0:
		return
	if _sig_bulwark:
		dps *= 0.75  # Ser Roland's wall of steel
	var amount := maxf(0.0, dps - float(mods["armor"])) * delta
	if amount <= 0.0:
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
		Sfx.play("hurt")
		if _camera != null:
			_camera.add_trauma(0.3)
	if hp <= 0.0:
		if revives > 0:
			_revive()
		else:
			_die()

## Mercy: rise once more — half HP, brief invulnerability.
func _revive() -> void:
	revives -= 1
	hp = max_hp * 0.5
	_invuln = 2.5
	hp_changed.emit(hp, max_hp)
	Sfx.play("bell", 0.7)
	if _camera != null:
		_camera.add_trauma(0.5)
	if _sprite != null:
		_sprite.visible = true

func gain_xp(amount: int) -> void:
	if dead:
		return
	xp += amount
	var needed := xp_needed(level)
	while xp >= needed:
		xp -= needed
		level += 1
		pending_levels += 1
		leveled_up.emit(level)
		Sfx.play("level")
		if _camera != null:
			_camera.add_trauma(0.12)
		needed = xp_needed(level)
	xp_changed.emit(xp, needed, level)

func xp_needed(for_level: int) -> int:
	return 5 + for_level * 4

func _die() -> void:
	dead = true
	hp = 0.0
	hp_changed.emit(hp, max_hp)
	if _camera != null:
		_camera.add_trauma(0.7)
	died.emit()
