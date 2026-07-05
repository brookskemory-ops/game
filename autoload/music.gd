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
var _default_stream := {}   # id -> the base looping stream
var _variant := {}          # "<layer>_<theme>" -> looping stream (optional)

func _prep(path: String) -> AudioStreamWAV:
	if not ResourceLoader.exists(path):
		return null
	var s: AudioStreamWAV = load(path)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = s.data.size() / 2  # 16-bit mono: bytes -> frames
	return s

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in TRACKS:
		var stream := _prep(String(TRACKS[id]))
		if stream == null:
			continue
		_default_stream[id] = stream
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.volume_db = -60.0
		add_child(player)
		player.play()
		_players[id] = player
	# Optional per-theme beds (Act IV): night_crypt, boss_crypt, ...
	for key in ["night_crypt", "boss_crypt"]:
		var vs := _prep("res://assets/music/%s.wav" % key)
		if vs != null:
			_variant[key] = vs

## Swap a layer's stream to a themed variant (or back to the default). Restarts
## that layer's loop — fine, it fades in from silence anyway.
func _use_variant(layer: String, theme: String) -> void:
	if not _players.has(layer):
		return
	var want: AudioStreamWAV = _variant.get("%s_%s" % [layer, theme], _default_stream.get(layer))
	var player: AudioStreamPlayer = _players[layer]
	if player.stream != want and want != null:
		player.stream = want
		player.play()

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

## The vigil: a run begins. Danger and boss layers blend in on top. The stage
## theme picks the night/boss bed (Act IV's crypt gets its own colder loop).
func play_night(theme := "") -> void:
	_targets = {"camp": 0.0, "night": 1.0, "danger": 0.0, "boss": 0.0}
	_use_variant("night", theme)
	_use_variant("boss", theme)

## 0..1 — how hard the horde is pressing (arena feeds alive_count).
func set_danger(fraction: float) -> void:
	if _targets["night"] > 0.0 or _targets["boss"] > 0.0:
		_targets["danger"] = clampf(fraction, 0.0, 1.0)

func set_boss(active: bool) -> void:
	_targets["boss"] = 1.0 if active else 0.0
	_targets["night"] = 0.35 if active else 1.0  # duck the vigil under the bell
