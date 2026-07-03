extends Node2D
## Run orchestrator: wires the managers together, drives wave spawning from
## data/waves/stage1.json, and decides victory/defeat. Also draws the ground
## scatter (graves, crosses, rubble) so movement reads against the dark.

const SPAWN_DISTANCE := 400.0
const SCATTER_COUNT := 170
const SCATTER_RANGE := 1700.0

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
var _draft_open := false

func _ready() -> void:
	var data: Variant = Game.load_json("res://data/waves/stage1.json")
	if data is Dictionary:
		stage = data
	_wave_acc.resize(waves().size())
	player.setup({"enemies": enemies, "projectiles": projectiles, "hazards": hazards})
	enemies.setup(player, player.body_radius, gems)
	projectiles.setup(enemies)
	hazards.setup(enemies)
	gems.setup(player, player.pickup_radius)
	hud.setup(self, player, enemies)
	upgrades = UpgradeSystem.new(player)
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_on_player_leveled)

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

func run_length() -> float:
	return float(stage.get("run_length", 300))

func _physics_process(delta: float) -> void:
	if run_over:
		return
	time_elapsed += delta
	if time_elapsed >= run_length():
		_finish(true)
		return
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
