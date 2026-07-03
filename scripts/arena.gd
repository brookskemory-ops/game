extends Node2D
## Run orchestrator: wires the managers together, drives wave spawning from
## data/waves/stage1.json, and decides victory/defeat. Also draws the ground
## scatter (graves, crosses, rubble) so movement reads against the dark.

const SPAWN_DISTANCE := 300.0  # just past the zoom-2 camera's visible edge
const SCATTER_COUNT := 380
const SCATTER_RANGE := 1500.0

@onready var player: Player = $Player
@onready var enemies: EnemyManager = $EnemyManager
@onready var projectiles: ProjectileManager = $ProjectileManager
@onready var gems: GemManager = $GemManager
@onready var hazards: HazardManager = $HazardManager
@onready var hud: HUD = $UILayer/HUD

var stage := {}
var time_elapsed := 0.0
var run_over := false
var upgrades: UpgradeSystem
var _wave_acc := PackedFloat32Array()
var _events_fired := PackedByteArray()
var _draft_open := false
var _boss_summoned := false
var _trickle_acc := 0.0

func _ready() -> void:
	var data: Variant = Game.load_json(Game.stage_path())
	if data is Dictionary:
		stage = data
	_wave_acc.resize(waves().size())
	_events_fired.resize(events().size())
	player.setup({"enemies": enemies, "projectiles": projectiles, "hazards": hazards})
	enemies.setup(player, player.body_radius, gems)
	projectiles.setup(enemies)
	hazards.setup(enemies)
	gems.setup(player, player.pickup_radius)
	hud.setup(self, player, enemies)
	upgrades = UpgradeSystem.new(player)
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_on_player_leveled)
	enemies.boss_spawned.connect(_on_boss_spawned)
	enemies.boss_died.connect(_on_boss_died)

# --- Upgrade draft flow (queues if several levels land at once) ---

func _on_player_leveled(_level: int) -> void:
	if not _draft_open and not run_over:
		_open_draft()

func _open_draft() -> void:
	if player.pending_levels <= 0 or run_over:
		return
	player.pending_levels -= 1
	_draft_open = true
	hud.show_draft(upgrades.roll(), _on_draft_pick)

func _on_draft_pick(option: Dictionary) -> String:
	var message := upgrades.apply(option)
	_draft_open = false
	if player.pending_levels > 0 and not run_over:
		_open_draft()
	elif not run_over:
		get_tree().paused = false
	return message

func waves() -> Array:
	return stage.get("waves", [])

func events() -> Array:
	return stage.get("events", [])

func run_length() -> float:
	return float(stage.get("run_length", 300))

func _physics_process(delta: float) -> void:
	if run_over:
		return
	time_elapsed += delta
	# The timer running out doesn't end the night — it summons what rings the bell.
	if not _boss_summoned and time_elapsed >= run_length():
		_summon_boss()
	if _boss_summoned:
		_trickle_acc += delta
		var interval := float(stage.get("boss_trickle_interval", 2.0))
		if _trickle_acc >= interval:
			_trickle_acc -= interval
			enemies.spawn(String(stage.get("boss_trickle", "shambler")), _spawn_point())
	# Timed one-shot events (mini-bosses etc.).
	var event_list := events()
	for e in event_list.size():
		if _events_fired[e] == 1:
			continue
		var event: Dictionary = event_list[e]
		if time_elapsed >= float(event.get("t", 0)):
			_events_fired[e] = 1
			for c in int(event.get("count", 1)):
				enemies.spawn(String(event.get("spawn", "shambler")), _spawn_point())
			var announce := String(event.get("announce", ""))
			if not announce.is_empty():
				hud.toast(announce)
	var wave_list := waves()
	for w in wave_list.size():
		var wave: Dictionary = wave_list[w]
		if time_elapsed < float(wave.get("from", 0)) or time_elapsed >= float(wave.get("to", 0)):
			continue
		_wave_acc[w] += delta
		var interval := maxf(0.05, float(wave.get("interval", 1.0)))
		while _wave_acc[w] >= interval:
			_wave_acc[w] -= interval
			for c in int(wave.get("count", 1)):
				enemies.spawn(String(wave.get("type", "shambler")), _spawn_point())

func _spawn_point() -> Vector2:
	# Just past the edge of a landscape phone view, in a random direction.
	return player.global_position + Vector2.from_angle(randf() * TAU) * SPAWN_DISTANCE

func _summon_boss() -> void:
	_boss_summoned = true
	var boss_id := String(stage.get("boss", ""))
	if boss_id.is_empty():
		_finish(true)  # a stage without a boss simply ends at dawn
		return
	enemies.spawn(boss_id, _spawn_point())

func _on_boss_spawned(display_name: String) -> void:
	hud.set_boss_name(display_name)
	hud.banner("THE BELL TOLLS", "%s rises from the churchyard" % display_name)
	Sfx.play("bell")

func _on_boss_died() -> void:
	Sfx.play("boss_death")
	var unlock_id := String(stage.get("victory_unlock", ""))
	if not unlock_id.is_empty():
		Game.unlock(unlock_id)
	_finish(true)

func _on_player_died() -> void:
	_finish(false)

func _finish(victory: bool) -> void:
	if run_over:
		return
	run_over = true
	var stats := {
		"time": time_elapsed,
		"kills": enemies.kills,
		"level": player.level,
	}
	hud.show_results(victory, stats)
	# Freeze the night behind the overlay (HUD runs in PROCESS_MODE_ALWAYS).
	get_tree().paused = true

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1349
	for i in SCATTER_COUNT:
		var pos := Vector2(
			rng.randf_range(-SCATTER_RANGE, SCATTER_RANGE),
			rng.randf_range(-SCATTER_RANGE, SCATTER_RANGE)
		)
		var roll := rng.randf()
		var shade := rng.randf_range(0.10, 0.16)
		if roll < 0.18:
			# A tombstone with a base.
			var stone := Color(shade + 0.07, shade + 0.06, shade + 0.10)
			draw_rect(Rect2(pos, Vector2(8.0, 10.0)), stone)
			draw_rect(Rect2(pos + Vector2(-1.0, 8.0), Vector2(10.0, 2.0)), stone.darkened(0.25))
		elif roll < 0.26:
			# A grave cross.
			var cross := Color(shade + 0.05, shade + 0.05, shade + 0.07)
			draw_rect(Rect2(pos + Vector2(3.0, 0.0), Vector2(2.0, 12.0)), cross)
			draw_rect(Rect2(pos + Vector2(0.0, 3.0), Vector2(8.0, 2.0)), cross)
		else:
			# Rubble / dead grass.
			draw_rect(Rect2(pos, Vector2(3.0, 2.0)), Color(shade, shade + 0.02, shade))
