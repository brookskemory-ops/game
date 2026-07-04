extends Node
## Layered synthesized music, autoloaded as `Music`. Four loops play forever
## and are volume-blended: camp (the fire), night (the vigil), danger (rises
## with the horde), boss (the bell will not stop). All synthesized offline —
## same doctrine as Sfx. Missing files fail silent (procedural-fallback rule:
## the game runs without them).

const TRACKS := {
	"camp": "res://assets/music/camp.wav",
	"night": "res://assets/music/night.wav",
	"danger": "res://assets/music/danger.wav",
	"boss": "res://assets/music/boss.wav",
}
## Per-layer mix ceiling (the blend targets scale inside these).
const LEVEL := {"camp": 0.85, "night": 0.75, "danger": 0.6, "boss": 0.9}
const FADE_SPEED := 1.6

var _players := {}
var _targets := {"camp": 0.0, "night": 0.0, "danger": 0.0, "boss": 0.0}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in TRACKS:
		if not ResourceLoader.exists(String(TRACKS[id])):
			continue
		var stream: AudioStreamWAV = load(String(TRACKS[id]))
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2  # 16-bit mono: bytes -> frames
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.volume_db = -60.0
		add_child(player)
		player.play()
		_players[id] = player

func _process(delta: float) -> void:
	if _players.is_empty():
		return
	var master := clampf(float(Game.settings.get("music_volume", 1.0)), 0.0, 1.0)
	for id in _players:
		var player: AudioStreamPlayer = _players[id]
		var current := db_to_linear(player.volume_db)
		var goal: float = float(_targets[id]) * float(LEVEL[id]) * master
		var next := lerpf(current, goal, minf(1.0, delta * FADE_SPEED))
		player.volume_db = linear_to_db(maxf(next, 0.0001))

## The fire: camp and title screens.
func play_camp() -> void:
	_targets = {"camp": 1.0, "night": 0.0, "danger": 0.0, "boss": 0.0}

## The vigil: a run begins. Danger and boss layers blend in on top.
func play_night() -> void:
	_targets = {"camp": 0.0, "night": 1.0, "danger": 0.0, "boss": 0.0}

## 0..1 — how hard the horde is pressing (arena feeds alive_count).
func set_danger(fraction: float) -> void:
	if _targets["night"] > 0.0 or _targets["boss"] > 0.0:
		_targets["danger"] = clampf(fraction, 0.0, 1.0)

func set_boss(active: bool) -> void:
	_targets["boss"] = 1.0 if active else 0.0
	_targets["night"] = 0.35 if active else 1.0  # duck the vigil under the bell
