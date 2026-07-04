class_name RiteTracker
extends Node2D
## Mid-run objectives — the Rites (docs/ABILITIES.md §6 relics are their
## reward). Data-driven from the stage json: "rites": [{id, name, type, ...,
## relic}]. Three archetypes, implemented once:
##  - slay_elite:    put the named elite down within `within` seconds of its
##                   spawn (windows open per spawn, first kill inside wins)
##  - light_candles: walk over `count` candle shrines set in a ring of
##                   `radius` around the night's start
##  - stand_ground:  at t=`t` a ring appears at `pos`; stay inside for
##                   `seconds` consecutive seconds
## First completion unlocks the rite's relic + a gold burst; repeats pay gold.

const CANDLE_LIGHT_RADIUS := 20.0
const GOLD_BURST := 10

var _player: Player
var _enemies: EnemyManager
var _hud: HUD
var _gems: GemManager
var _rites: Array = []
var _state: Array = []   # per rite: {status: waiting|active|kept|failed, ...}
var _time := 0.0
var _candle_tex: Texture2D

func setup(stage: Dictionary, player: Player, enemies: EnemyManager, hud: HUD, gems: GemManager) -> void:
	_player = player
	_enemies = enemies
	_hud = hud
	_gems = gems
	_rites = stage.get("rites", [])
	z_index = -1  # above the ground, below the actors
	for rite in _rites:
		var entry := {"status": "waiting"}
		match String(rite.get("type", "")):
			"light_candles":
				var candles: Array = []
				var count := int(rite.get("count", 4))
				var radius := float(rite.get("radius", 380))
				for c in count:
					var angle := TAU * float(c) / float(count) + 0.4  # off-axis: not straight up
					candles.append({"pos": Vector2.from_angle(angle) * radius, "lit": false})
				entry["candles"] = candles
			"stand_ground":
				entry["held"] = 0.0
		_state.append(entry)
	if not _rites.is_empty():
		var candle_path := "res://assets/sprites/generated/props/prop_candelabra.png"
		if ResourceLoader.exists(candle_path):
			_candle_tex = load(candle_path)
		if _enemies != null:
			_enemies.elite_spawned.connect(_on_elite_spawned)
			_enemies.elite_killed.connect(_on_elite_killed)

func _physics_process(delta: float) -> void:
	if _rites.is_empty() or _player == null:
		return
	_time += delta
	var dirty := false
	for i in _rites.size():
		var rite: Dictionary = _rites[i]
		var state: Dictionary = _state[i]
		match String(rite.get("type", "")):
			"light_candles":
				dirty = _tick_candles(rite, state, i) or dirty
			"stand_ground":
				dirty = _tick_ground(rite, state, i, delta) or dirty
			"slay_elite":
				if String(state.get("status", "")) == "active" \
						and _time > float(state.get("deadline", 0.0)):
					state["status"] = "waiting"  # window closed; the next spawn reopens it
					dirty = true
	if dirty or _any_visible():
		queue_redraw()

func _any_visible() -> bool:
	for i in _rites.size():
		var status := String(_state[i].get("status", ""))
		if status == "active" or (status == "waiting" and _state[i].has("candles")):
			return true
	return false

# --- light_candles ---

func _tick_candles(rite: Dictionary, state: Dictionary, index: int) -> bool:
	if String(state.get("status", "")) == "kept":
		return false
	# The rite announces itself once the night is underway.
	if String(state.get("status", "")) == "waiting":
		if _time >= float(rite.get("announce_t", 20)):
			state["status"] = "active"
			_announce(rite)
		return false
	var all_lit := true
	var changed := false
	for candle in state["candles"]:
		if bool(candle["lit"]):
			continue
		if _player.global_position.distance_to(candle["pos"]) <= CANDLE_LIGHT_RADIUS:
			candle["lit"] = true
			changed = true
			Sfx.play("gem", 0.9)
			_hud.toast("a wake-light burns  (%d/%d)" % [_lit_count(state), state["candles"].size()])
		if not bool(candle["lit"]):
			all_lit = false
	if all_lit:
		_keep(rite, state, index)
	return changed

func _lit_count(state: Dictionary) -> int:
	var lit := 0
	for candle in state["candles"]:
		if bool(candle["lit"]):
			lit += 1
	return lit

# --- stand_ground ---

func _tick_ground(rite: Dictionary, state: Dictionary, index: int, delta: float) -> bool:
	match String(state.get("status", "")):
		"kept", "failed":
			return false
		"waiting":
			if _time >= float(rite.get("t", 240)):
				state["status"] = "active"
				_announce(rite)
				return true
			return false
	var center := _ring_pos(rite)
	var inside := _player.global_position.distance_to(center) <= float(rite.get("radius", 80))
	if inside:
		state["held"] = float(state["held"]) + delta
		if float(state["held"]) >= float(rite.get("seconds", 18)):
			_keep(rite, state, index)
	else:
		state["held"] = 0.0
	return true

func _ring_pos(rite: Dictionary) -> Vector2:
	var pos: Array = rite.get("pos", [0, 0])
	return Vector2(float(pos[0]), float(pos[1]))

# --- slay_elite ---

func _on_elite_spawned(type_name: String) -> void:
	for i in _rites.size():
		var rite: Dictionary = _rites[i]
		if String(rite.get("type", "")) != "slay_elite":
			continue
		if String(rite.get("target", "")) != type_name:
			continue
		var state: Dictionary = _state[i]
		if String(state.get("status", "")) == "kept":
			continue
		state["status"] = "active"
		state["deadline"] = _time + float(rite.get("within", 60))
		_announce(rite)

func _on_elite_killed(type_name: String) -> void:
	for i in _rites.size():
		var rite: Dictionary = _rites[i]
		if String(rite.get("type", "")) != "slay_elite":
			continue
		if String(rite.get("target", "")) != type_name:
			continue
		var state: Dictionary = _state[i]
		if String(state.get("status", "")) == "active" and _time <= float(state.get("deadline", 0.0)):
			_keep(rite, state, i)

# --- shared ---

func _announce(rite: Dictionary) -> void:
	_hud.toast("A RITE IS ASKED:  %s" % String(rite.get("name", "")))
	if not Game.hint_seen("rite"):
		Game.mark_hint("rite")
		_hud.toast("(optional — keep it, and its relic waits at the fire)")
	Sfx.play("bell", 0.5)

## For the results screen: how did the night's rites go?
func summary() -> String:
	if _rites.is_empty():
		return ""
	for state in _state:
		if String(state.get("status", "")) == "kept":
			return "the rite was kept"
	return "the rite went unkept"

func _keep(rite: Dictionary, state: Dictionary, _index: int) -> void:
	state["status"] = "kept"
	_hud.banner("THE RITE IS KEPT", String(rite.get("name", "")))
	Sfx.play("level")
	var first := Game.unlock_relic(String(rite.get("relic", "")))
	if _gems != null:
		var burst := GOLD_BURST * (2 if first else 1)
		for c in burst:
			_gems.spawn(_player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(8, 26),
				2, GemManager.KIND_COIN)

func _draw() -> void:
	for i in _rites.size():
		var rite: Dictionary = _rites[i]
		var state: Dictionary = _state[i]
		match String(rite.get("type", "")):
			"light_candles":
				if not state.has("candles"):
					continue
				for candle in state["candles"]:
					var lit: bool = candle["lit"]
					var at: Vector2 = candle["pos"]
					if _candle_tex != null:
						var size := Vector2(_candle_tex.get_width(), _candle_tex.get_height()) * 0.6
						var tint := Color(1.05, 1.0, 0.9) if lit else Color(0.45, 0.45, 0.55)
						draw_texture_rect(_candle_tex, Rect2(at - size * 0.5, size), false, tint)
					else:
						draw_circle(at, 5.0, Color(0.9, 0.7, 0.3) if lit else Color(0.3, 0.3, 0.38))
					if lit:
						draw_circle(at, 11.0, Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, 0.12))
			"stand_ground":
				if String(state.get("status", "")) != "active":
					continue
				var center := _ring_pos(rite)
				var radius := float(rite.get("radius", 80))
				draw_arc(center, radius, 0.0, TAU, 40, Color(Palette.BONE.r, Palette.BONE.g, Palette.BONE.b, 0.5), 1.5)
				var frac: float = clampf(float(state.get("held", 0.0)) / float(rite.get("seconds", 18)), 0.0, 1.0)
				if frac > 0.0:
					draw_arc(center, radius - 4.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 40,
						Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, 0.85), 3.0)
