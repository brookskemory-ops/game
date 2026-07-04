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
const MAX_PASSIVES := 3  # distinct keepsakes; stacks within each stay allowed
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
var thorns := 0.0    # Briar Crown relic: contact attackers take this much
var _flask_ready := false  # Pilgrim's Flask relic: one 25% revive
var dead := false
var lightfoot_active := false
var facing := Vector2.RIGHT
var _sig_light_foot := false
var _sig_malpractice := false
var _sig_mortification := false
var _sig_bulwark := false
var _sig_deathless := false
var _invuln := 0.0
var _last_kill_at := -10.0

var weapons: Array = []  # of Weapon

var _ctx := {}  # enemies / projectiles / hazards, shared with weapons
var _enemies: EnemyManager
var _joystick: VirtualJoystick
var _sprite: Sprite2D
var _camera: GameCamera
var _front_tex: Texture2D
var _side_tex: Texture2D
var _gait_t := 0.0
var _sprite_base_scale := 1.0
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
		"deathless":
			_sig_deathless = true
			if _enemies != null:
				_enemies.enemy_killed.connect(_on_enemy_killed)
	_apply_camp_shop()
	# Carried relics (one hook each, like signatures — docs/ABILITIES.md §7).
	if Game.relic_active("briar_crown"):
		thorns = 3.0
	if Game.relic_active("pilgrims_flask"):
		_flask_ready = true
	base_max_hp = float(stats.get("max_hp", 80))
	base_move_speed = float(stats.get("move_speed", 130))
	base_pickup_radius = float(stats.get("pickup_radius", 48))
	body_radius = float(stats.get("radius", 6))
	max_hp = base_max_hp
	hp = max_hp
	move_speed = base_move_speed
	pickup_radius = base_pickup_radius
	_sprite = Sprite2D.new()
	# Pixel Lab full-body art (same image as the camp portrait) scaled to
	# world size; procedural sprite as fallback.
	var hero_id := String(stats.get("id", "wren"))
	var portrait_path := "res://assets/portraits/%s.png" % hero_id
	if ResourceLoader.exists(portrait_path):
		_sprite.texture = load(portrait_path)
		var target_height := float(stats.get("world_height", 19.0))
		var sprite_scale := target_height / float(_sprite.texture.get_height())
		_sprite.scale = Vector2(sprite_scale, sprite_scale)
	else:
		_sprite.texture = PixelSprites.get_tex(String(stats.get("sprite", "wren")))
	_front_tex = _sprite.texture
	# Directional art: strict side profile used while moving horizontally.
	var side_path := "res://assets/sprites/generated/side/%s.png" % hero_id
	if ResourceLoader.exists(side_path):
		_side_tex = load(side_path)
	_sprite_base_scale = _sprite.scale.x
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
## Deathless (the Hollow King): EVERY kill leeches life — his only healing.
func _on_enemy_killed(_at: Vector2) -> void:
	if _sig_deathless:
		# 1.5/kill (was 1.0): bot runs showed Deathless as by far the
		# hardest opening — the leech is his only healing.
		hp = minf(max_hp, hp + 1.5)
		hp_changed.emit(hp, max_hp)
		return
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
	# 3+3 build rule (docs/ABILITIES.md): three keepsakes, no more. The draft
	# never offers a fourth; this guard is the belt to that suspender.
	if not passive_stacks.has(id) and passive_stacks.size() >= MAX_PASSIVES:
		return
	passive_stacks[id] = int(passive_stacks.get(id, 0)) + 1
	var effects: Dictionary = def.get("effects", {})
	for key in effects:
		if String(key) == "gold":
			gold_mul += float(effects[key])  # Gravedust routes to the coin pipeline
			continue
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
	if _sig_deathless:
		return  # no salve nor prayer works on him; only the leech (docs/ABILITIES.md §4)
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
	var moving := velocity.length_squared() > 1.0
	if moving:
		facing = velocity.normalized()
	if _sprite != null:
		if absf(velocity.x) > 1.0:
			_sprite.flip_h = velocity.x < 0.0
		_sprite.modulate = _sprite.modulate.lerp(Color.WHITE, delta * 8.0)
		# Directional still: side profile when horizontal movement dominates.
		if _side_tex != null:
			_sprite.texture = _side_tex if (moving and absf(velocity.x) >= absf(velocity.y)) else _front_tex
		# Procedural gait (genre-standard): footstep bob, sway, and a small
		# squash on each footfall. Settles smoothly when standing.
		if moving:
			_gait_t += delta * move_speed * 0.085
			var step := sin(_gait_t)
			_sprite.rotation = step * 0.07
			_sprite.position.y = -absf(step) * 1.4
			_sprite.scale.y = _sprite_base_scale * (1.0 - 0.04 * absf(step))
		else:
			_sprite.rotation = lerpf(_sprite.rotation, 0.0, minf(1.0, delta * 10.0))
			_sprite.position.y = lerpf(_sprite.position.y, 0.0, minf(1.0, delta * 10.0))
			_sprite.scale.y = lerpf(_sprite.scale.y, _sprite_base_scale, minf(1.0, delta * 10.0))
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

## Discrete hits (crypt archer bolts). Armor blocks its flat value once per hit.
func take_hit(amount: float) -> void:
	if dead or _invuln > 0.0:
		return
	if _sig_bulwark:
		amount *= 0.75
	amount = maxf(0.0, amount - float(mods["armor"]))
	if amount <= 0.0:
		return
	hp -= amount
	hp_changed.emit(hp, max_hp)
	if _sprite != null:
		_sprite.modulate = Color(1.0, 0.35, 0.35)
	hurt.emit(amount)
	Sfx.play("hurt")
	if _camera != null:
		_camera.add_trauma(0.25)
	if hp <= 0.0:
		if revives > 0:
			_revive()
		elif _flask_ready:
			_flask_revive()
		else:
			_die()

## Pilgrim's Flask: one desperate swallow — a quarter of life, once a night.
func _flask_revive() -> void:
	_flask_ready = false
	hp = max_hp * 0.25
	_invuln = 2.0
	hp_changed.emit(hp, max_hp)
	Sfx.play("bell", 0.6)
	if _sprite != null:
		_sprite.visible = true

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

## Elite scrolls: an extra draft without an extra level.
func grant_bonus_draft() -> void:
	if dead:
		return
	pending_levels += 1
	leveled_up.emit(level)

func _die() -> void:
	dead = true
	hp = 0.0
	hp_changed.emit(hp, max_hp)
	if _camera != null:
		_camera.add_trauma(0.7)
	died.emit()
