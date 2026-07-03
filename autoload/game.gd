extends Node
## Global game state singleton, autoloaded as `Game`.
## Scene routing, JSON data loading, the save file, shop, and unlock logic.

signal run_started
signal run_ended(victory: bool)
signal gold_changed(total: int)

const VERSION := "0.5.0 — the survivors gather"
const SAVE_PATH := "user://save.json"

## Player-facing settings (persisted inside the save file).
var settings := {
	"sfx_volume": 1.0,
	"music_volume": 1.0,
	"haptics": true,
}

## Which hero the next run uses (picked at the camp).
var selected_character := "wren"

## Hero ids unlocked this session, awaiting their campfire vignette.
var newly_unlocked: Array = []

## Persistent progress. Written to user://save.json (IndexedDB on web).
var save_data := {
	"gold": 0,
	"unlocks": {"wren": true},
	"best_run": {},
	"shop": {},
	"stats": {"deaths": 0, "total_kills": 0, "nights_survived": 0},
	"settings": {},
}

## Stats from the most recent run, for camp/results screens.
var last_run := {
	"victory": false,
	"time": 0.0,
	"kills": 0,
	"level": 1,
}

func _ready() -> void:
	load_save()

# --- Scene routing ---

func go_camp() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/camp.tscn")

func start_run() -> void:
	get_tree().paused = false
	run_started.emit()
	get_tree().change_scene_to_file("res://scenes/arena.tscn")

func end_run(victory: bool, stats := {}) -> void:
	last_run = {
		"victory": victory,
		"time": stats.get("time", 0.0),
		"kills": stats.get("kills", 0),
		"level": stats.get("level", 1),
	}
	var lifetime: Dictionary = save_data["stats"]
	lifetime["total_kills"] = int(lifetime.get("total_kills", 0)) + int(stats.get("kills", 0))
	if victory:
		lifetime["nights_survived"] = int(lifetime.get("nights_survived", 0)) + 1
	else:
		lifetime["deaths"] = int(lifetime.get("deaths", 0)) + 1
	var best: Dictionary = save_data.get("best_run", {})
	if float(stats.get("time", 0.0)) > float(best.get("time", 0.0)):
		save_data["best_run"] = last_run.duplicate()
	_check_unlocks(stats)
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
	gold_changed.emit(gold())

func shop_level(id: String) -> int:
	return int(save_data.get("shop", {}).get(id, 0))

## Cost scales: base * growth^current_level, rounded to a clean number.
func shop_cost(id: String, def: Dictionary) -> int:
	var base := float(def.get("base_cost", 20))
	var growth := float(def.get("cost_growth", 1.6))
	return int(round(base * pow(growth, float(shop_level(id)))))

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
func stage_path() -> String:
	if OS.has_feature("web"):
		var search := String(JavaScriptBridge.eval("window.location.search", true))
		if search.contains("stage=qa"):
			return "res://data/waves/qa.json"
	return "res://data/waves/stage1.json"

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
