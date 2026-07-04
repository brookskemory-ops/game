extends Node
## Global game state singleton, autoloaded as `Game`.
## Scene routing, JSON data loading, the save file, shop, and unlock logic.

signal run_started
signal run_ended(victory: bool)
signal gold_changed(total: int)
signal orientation_changed  # mobile canvas swapped landscape <-> portrait

const VERSION := "1.1-pc — at the desk"
const SAVE_PATH := "user://save.json"

## Player-facing settings (persisted inside the save file).
var settings := {
	"sfx_volume": 1.0,
	"music_volume": 1.0,
	"haptics": true,
	"damage_numbers": true,
}

## Which hero and stage the next run uses (picked at the camp).
var selected_character := "wren"
var selected_stage := "stage1"

## Hero ids unlocked this session, awaiting their campfire vignette.
var newly_unlocked: Array = []

## Weapon ids that unlocked after the last run ("THE LEDGER GROWS" notice).
var newly_unlocked_weapons: Array = []

## Relic ids earned by rites in the last run.
var newly_unlocked_relics: Array = []

## Gold earned during the current night (Ferryman's Coin doubles it on death).
var run_gold := 0

## Persistent progress. Written to user://save.json (IndexedDB on web).
var save_data := {
	"gold": 0,
	"unlocks": {"wren": true},
	"best_run": {},
	"shop": {},
	"stats": {"deaths": 0, "total_kills": 0, "nights_survived": 0},
	"stages": {},
	"settings": {},
	"ending": "",
	"weapon_unlocks": {},
	"relics": {},
	"relic_equipped": "",
	"relics_equipped": [],
	"seen_hints": {},
	"save_version": 1,
}

## Stats from the most recent run, for camp/results screens.
var last_run := {
	"victory": false,
	"time": 0.0,
	"kills": 0,
	"level": 1,
	"stage": "",
	"character": "",
}

## True on touch devices: the mobile profile renders everything ~33% larger.
var is_mobile := false

func _ready() -> void:
	_apply_device_profile()
	load_save()
	Music.play_camp.call_deferred()  # the title shares the fire's theme

## F11 toggles fullscreen anywhere in the game (desktop and web).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()

func toggle_fullscreen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
			"document.fullscreenElement ? document.exitFullscreen() : (document.documentElement.requestFullscreen && document.documentElement.requestFullscreen())",
			true)
		return
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

const MOBILE_LANDSCAPE := Vector2i(480, 270)
const MOBILE_PORTRAIT := Vector2i(270, 480)

## One build, two profiles: phones get a smaller design canvas so the world
## and UI render larger; desktop keeps the original 640x360. Runtime-detected,
## no separate branches. The vigil is kept in either orientation: the canvas
## follows the phone whenever it rotates.
func _apply_device_profile() -> void:
	if not OS.has_feature("web"):
		return
	# Ask the browser directly: DisplayServer.is_touchscreen_available() is
	# always true here because emulate_touch_from_mouse is on project-wide.
	is_mobile = bool(JavaScriptBridge.eval(
		"('ontouchstart' in window) || navigator.maxTouchPoints > 0", true))
	if is_mobile:
		_update_mobile_scale()
		get_window().size_changed.connect(_update_mobile_scale)

func _update_mobile_scale() -> void:
	var win := get_window()
	var target := MOBILE_PORTRAIT if win.size.y > win.size.x else MOBILE_LANDSCAPE
	if win.content_scale_size != target:
		win.content_scale_size = target
		orientation_changed.emit()

# --- Scene routing ---

func go_camp() -> void:
	get_tree().paused = false
	Music.play_camp()
	get_tree().change_scene_to_file("res://scenes/camp.tscn")

func start_run() -> void:
	# Web QA override: ?hero=<id> forces the hero for automated runs
	# (bypasses unlocks — test builds only reachable by URL, like ?stage=).
	if OS.has_feature("web"):
		var search := String(JavaScriptBridge.eval("window.location.search", true))
		var roster: Variant = load_json("res://data/characters/_roster.json")
		if roster is Array:
			for hero_id in roster:
				if search.contains("hero=" + String(hero_id)):
					selected_character = String(hero_id)
					break
	run_gold = 0
	if not hint_seen("begin"):
		mark_hint("begin")
	get_tree().paused = false
	Music.play_night()
	run_started.emit()
	get_tree().change_scene_to_file("res://scenes/arena.tscn")

func end_run(victory: bool, stats := {}) -> void:
	# Snapshot weapon availability first, so post-run stat changes can be
	# diffed into "THE LEDGER GROWS" notices.
	var weapons_before := _weapon_unlock_snapshot()
	last_run = {
		"victory": victory,
		"time": stats.get("time", 0.0),
		"kills": stats.get("kills", 0),
		"level": stats.get("level", 1),
		"stage": String(stats.get("stage", "")),
		"character": selected_character,
	}
	var lifetime: Dictionary = save_data["stats"]
	lifetime["total_kills"] = int(lifetime.get("total_kills", 0)) + int(stats.get("kills", 0))
	if victory:
		lifetime["nights_survived"] = int(lifetime.get("nights_survived", 0)) + 1
		var stage_id := String(stats.get("stage", ""))
		if not stage_id.is_empty():
			save_data["stages"][stage_id] = true
	else:
		lifetime["deaths"] = int(lifetime.get("deaths", 0)) + 1
	var best: Dictionary = save_data.get("best_run", {})
	if float(stats.get("time", 0.0)) > float(best.get("time", 0.0)):
		save_data["best_run"] = last_run.duplicate()
	# The Long Night keeps its own tally: how deep did the count go?
	if String(stats.get("stage", "")) == "long_night":
		var record: Dictionary = save_data["stats"].get("long_night_best", {})
		if float(stats.get("time", 0.0)) > float(record.get("time", 0.0)):
			save_data["stats"]["long_night_best"] = {
				"time": float(stats.get("time", 0.0)),
				"kills": int(stats.get("kills", 0)),
			}
	_check_unlocks(stats)
	_check_weapon_unlocks(stats, weapons_before)
	write_save()
	get_tree().paused = false
	run_ended.emit(victory)
	go_camp()

# --- Unlocks (conditions live in character data, docs/ABILITIES.md §4) ---

func _check_unlocks(stats: Dictionary) -> void:
	var roster: Variant = load_json("res://data/characters/_roster.json")
	if not (roster is Array):
		return
	for hero_id in roster:
		var id := String(hero_id)
		if is_unlocked(id):
			continue
		var def: Variant = load_json("res://data/characters/%s.json" % id)
		if not (def is Dictionary):
			continue
		var cond: Dictionary = def.get("unlock", {})
		var met := false
		match String(cond.get("type", "")):
			"kills_in_night":
				met = int(stats.get("kills", 0)) >= int(cond.get("value", 999999))
			"lifetime_deaths":
				met = int(save_data["stats"].get("deaths", 0)) >= int(cond.get("value", 999999))
		if met:
			unlock(id)

func is_unlocked(id: String) -> bool:
	return bool(save_data.get("unlocks", {}).get(id, false))

# --- Weapon unlocks (the Ledger, docs/ABILITIES.md; conditions in weapon data) ---

## A weapon may enter drafts when its unlock condition holds. Hero-tied and
## lifetime-stat conditions evaluate live (past progress always counts);
## single-run feats (elite_kill, level_in_night) persist as flags set below.
func is_weapon_unlocked(id: String) -> bool:
	if bool(save_data.get("weapon_unlocks", {}).get(id, false)):
		return true
	var def: Variant = load_json("res://data/weapons/%s.json" % id)
	if not (def is Dictionary):
		return false
	return _weapon_cond_met(def.get("unlock", {}))

func _weapon_cond_met(cond: Dictionary) -> bool:
	match String(cond.get("type", "")):
		"":
			return true
		"hero":
			return is_unlocked(String(cond.get("id", "")))
		"lifetime_kills":
			return int(save_data["stats"].get("total_kills", 0)) >= int(cond.get("value", 999999))
		"victory":
			return int(save_data["stats"].get("nights_survived", 0)) >= 1
		"stage_cleared":
			return stage_cleared(String(cond.get("id", "")))
	return false

func _weapon_unlock_snapshot() -> Dictionary:
	var snapshot := {}
	var pool: Variant = load_json("res://data/weapons/_pool.json")
	if pool is Array:
		for wid in pool:
			snapshot[String(wid)] = is_weapon_unlocked(String(wid))
	return snapshot

## Persist single-run feats as flags, then diff against the pre-run snapshot
## so the camp can announce what the run earned.
func _check_weapon_unlocks(stats: Dictionary, before: Dictionary) -> void:
	var pool: Variant = load_json("res://data/weapons/_pool.json")
	if not (pool is Array):
		return
	if not save_data.has("weapon_unlocks"):
		save_data["weapon_unlocks"] = {}
	for wid_v in pool:
		var wid := String(wid_v)
		var def: Variant = load_json("res://data/weapons/%s.json" % wid)
		if not (def is Dictionary):
			continue
		var cond: Dictionary = def.get("unlock", {})
		match String(cond.get("type", "")):
			"elite_kill":
				if int(stats.get("elite_kills", 0)) > 0:
					save_data["weapon_unlocks"][wid] = true
			"level_in_night":
				if int(stats.get("level", 1)) >= int(cond.get("value", 999)):
					save_data["weapon_unlocks"][wid] = true
	for wid_v in pool:
		var wid := String(wid_v)
		if not bool(before.get(wid, false)) and is_weapon_unlocked(wid):
			newly_unlocked_weapons.append(wid)

func unlock(id: String) -> bool:
	if is_unlocked(id):
		return false
	save_data["unlocks"][id] = true
	newly_unlocked.append(id)
	write_save()
	return true

# --- Gold & the camp shop ---

func gold() -> int:
	return int(save_data.get("gold", 0))

func add_gold(amount: int) -> void:
	save_data["gold"] = gold() + maxi(0, amount)
	run_gold += maxi(0, amount)
	gold_changed.emit(gold())

func spend_gold(amount: int) -> bool:
	if gold() < amount:
		return false
	save_data["gold"] = gold() - amount
	gold_changed.emit(gold())
	return true

func shop_level(id: String) -> int:
	return int(save_data.get("shop", {}).get(id, 0))

## Cost scales: base * growth^current_level, rounded to a clean number.
## The King's Coin relic talks the prices down 15%.
func shop_cost(id: String, def: Dictionary) -> int:
	var base := float(def.get("base_cost", 20))
	var growth := float(def.get("cost_growth", 1.6))
	var cost := base * pow(growth, float(shop_level(id)))
	if relic_active("kings_coin"):
		cost *= 0.85
	return int(round(cost))

func shop_buy(id: String, def: Dictionary) -> bool:
	if shop_level(id) >= int(def.get("max", 1)):
		return false
	var cost := shop_cost(id, def)
	if gold() < cost:
		return false
	save_data["gold"] = gold() - cost
	save_data["shop"][id] = shop_level(id) + 1
	write_save()
	gold_changed.emit(gold())
	return true

# --- Save file ---

func load_save() -> void:
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	if text.is_empty():
		return
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		for key in save_data:
			if parsed.has(key):
				save_data[key] = parsed[key]
	var saved_settings: Dictionary = save_data.get("settings", {})
	for key in settings:
		if saved_settings.has(key):
			settings[key] = saved_settings[key]
	_migrate_save()

## One place for schema migrations, keyed on save_version, so no future
## change ever eats a player's progress. Bump save_version when adding one.
func _migrate_save() -> void:
	# v0 -> v1: the single relic slot (v0.14) became a list (v0.16.1).
	var old_relic := String(save_data.get("relic_equipped", ""))
	if not old_relic.is_empty() and (save_data.get("relics_equipped", []) as Array).is_empty():
		save_data["relics_equipped"] = [old_relic]
		save_data["relic_equipped"] = ""
	save_data["save_version"] = 1

func write_save() -> void:
	save_data["settings"] = settings
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file")
		return
	file.store_string(JSON.stringify(save_data))
	file.close()

## Which stage the arena loads. On web builds a `?stage=qa` URL parameter
## swaps in the 45-second QA stage so automated tests can play full runs
## (docs/NIGHT_SHIFT.md WP2). Ignored everywhere else.
func stage_cleared(id: String) -> bool:
	return bool(save_data.get("stages", {}).get(id, false))

# --- First-run hints (each shown once, then remembered forever) ---

func hint_seen(id: String) -> bool:
	return bool(save_data.get("seen_hints", {}).get(id, false))

func mark_hint(id: String) -> void:
	if not save_data.has("seen_hints"):
		save_data["seen_hints"] = {}
	save_data["seen_hints"][id] = true
	write_save()

# --- Relics (earned by rites; one may be carried into the night) ---

func relic_unlocked(id: String) -> bool:
	return bool(save_data.get("relics", {}).get(id, false))

func unlock_relic(id: String) -> bool:
	if id.is_empty() or relic_unlocked(id):
		return false
	if not save_data.has("relics"):
		save_data["relics"] = {}
	save_data["relics"][id] = true
	newly_unlocked_relics.append(id)
	write_save()
	return true

## How many relics may be carried (the Reliquary Chain adds a second).
func relic_slots() -> int:
	return 1 + shop_level("reliquary_chain")

func equipped_relics() -> Array:
	return save_data.get("relics_equipped", [])

func relic_active(id: String) -> bool:
	return id in equipped_relics()

## Tap to carry; tap again to set down; at capacity the oldest is set down.
func equip_relic(id: String) -> void:
	var carried: Array = save_data.get("relics_equipped", [])
	if id in carried:
		carried.erase(id)
	else:
		while carried.size() >= relic_slots():
			carried.pop_front()
		carried.append(id)
	save_data["relics_equipped"] = carried
	write_save()

# --- The ending (Block B): chosen once, at the camp, by the Hollow King ---

func ending() -> String:
	return String(save_data.get("ending", ""))

func set_ending(id: String) -> void:
	save_data["ending"] = id
	write_save()

## The final choice is offered when the Hollow King himself has just
## put down the Thing in the Chapel — and no ending is chosen yet.
func ending_pending() -> bool:
	return ending().is_empty() \
		and bool(last_run.get("victory", false)) \
		and String(last_run.get("stage", "")) == "stage3" \
		and String(last_run.get("character", "")) == "hollow_king"

func stage_path() -> String:
	if OS.has_feature("web"):
		var search := String(JavaScriptBridge.eval("window.location.search", true))
		# NOTE: "qa3" must precede "qa" — the match is a substring check.
		for stage_id in ["qa3", "qa", "stress", "stage1", "stage2", "stage3",
				"blood_toll", "deep_mist", "cold_court", "bells_echo", "long_night"]:
			if search.contains("stage=" + stage_id):
				return "res://data/waves/%s.json" % stage_id
	return "res://data/waves/%s.json" % selected_stage

## Loads a JSON data file (all game content is data — see data/README.md).
func load_json(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Missing or empty JSON file: " + path)
		return null
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("Malformed JSON in: " + path)
	return parsed
