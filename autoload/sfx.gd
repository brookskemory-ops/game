extends Node
## Procedurally synthesized sound effects, autoloaded as `Sfx`.
## Zero external assets: every sound is an AudioStreamWAV built at boot from
## simple oscillators + decay envelopes (the audio equivalent of our
## procedural pixel sprites — placeholder character, quiet and dry).
## Usage: Sfx.play("hit"). Per-sound rate limiting is built in.

const MIX_RATE := 22050
const POOL_SIZE := 10
const DEFAULT_COOLDOWN_MS := 45

var _streams := {}
var _players: Array = []
var _next_player := 0
var _last_played := {}  # id -> ticks_msec

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # UI sounds must work while paused
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)
	_build_streams()

func play(id: String, volume := 1.0) -> void:
	var master := float(Game.settings.get("sfx_volume", 1.0))
	if master <= 0.01 or not _streams.has(id):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(id, -1000)) < DEFAULT_COOLDOWN_MS:
		return
	_last_played[id] = now
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	player.stream = _streams[id]
	player.volume_db = linear_to_db(clampf(volume * master, 0.0, 1.0))
	player.play()

# --- Synthesis ---

func _build_streams() -> void:
	_streams = {
		"ui": _wav(_tone(0.035, 900.0, 650.0, "square", 60.0, 0.0, 0.22)),
		"shoot": _wav(_tone(0.05, 480.0, 300.0, "tri", 50.0, 0.25, 0.3)),
		"swing": _wav(_tone(0.09, 300.0, 90.0, "tri", 28.0, 0.75, 0.4)),
		"lob": _wav(_tone(0.12, 220.0, 420.0, "sine", 20.0, 0.1, 0.28)),
		"hit": _wav(_tone(0.06, 600.0, 210.0, "square", 45.0, 0.5, 0.35)),
		"kill": _wav(_tone(0.13, 340.0, 55.0, "tri", 24.0, 0.35, 0.5)),
		"gem": _wav(_tone(0.09, 850.0, 1500.0, "sine", 32.0, 0.0, 0.28)),
		"coin": _wav(_tone(0.08, 1050.0, 1400.0, "square", 38.0, 0.0, 0.22)),
		"hurt": _wav(_tone(0.16, 135.0, 65.0, "tri", 17.0, 0.4, 0.6)),
		"level": _wav(_concat([
			_tone(0.09, 440.0, 440.0, "square", 22.0, 0.0, 0.3),
			_tone(0.09, 554.0, 554.0, "square", 22.0, 0.0, 0.3),
			_tone(0.16, 659.0, 659.0, "square", 14.0, 0.0, 0.32),
		])),
		"bell": _wav(_mix([
			_tone(1.5, 196.0, 196.0, "sine", 2.2, 0.0, 0.5),
			_tone(1.2, 297.0, 297.0, "sine", 3.2, 0.0, 0.3),
			_tone(0.8, 449.0, 449.0, "sine", 5.0, 0.0, 0.18),
		])),
		"boss_death": _wav(_mix([
			_tone(1.8, 147.0, 147.0, "sine", 1.8, 0.0, 0.55),
			_tone(1.4, 221.0, 221.0, "sine", 2.6, 0.0, 0.3),
			_tone(0.3, 200.0, 60.0, "tri", 10.0, 0.7, 0.4),
		])),
		"buy": _wav(_concat([
			_tone(0.06, 1000.0, 1000.0, "square", 40.0, 0.0, 0.22),
			_tone(0.1, 1330.0, 1330.0, "square", 28.0, 0.0, 0.24),
		])),
	}

func _tone(dur: float, f0: float, f1: float, kind: String, decay: float, noise_mix: float, vol: float) -> PackedFloat32Array:
	var count := int(dur * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var freq := lerpf(f0, f1, t / dur)
		phase += freq / MIX_RATE
		var cycle := fmod(phase, 1.0)
		var sample := 0.0
		match kind:
			"sine":
				sample = sin(TAU * phase)
			"square":
				sample = 1.0 if cycle < 0.5 else -1.0
			"tri":
				sample = 4.0 * absf(cycle - 0.5) - 1.0
		if noise_mix > 0.0:
			sample = lerpf(sample, randf() * 2.0 - 1.0, noise_mix)
		out[i] = sample * exp(-decay * t) * vol
	return out

func _concat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for part in parts:
		out.append_array(part)
	return out

func _mix(parts: Array) -> PackedFloat32Array:
	var length := 0
	for part in parts:
		length = maxi(length, part.size())
	var out := PackedFloat32Array()
	out.resize(length)
	for part in parts:
		for i in part.size():
			out[i] += part[i]
	return out

func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	return wav
