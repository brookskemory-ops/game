extends Node
## Global game state singleton, autoloaded as `Game`.
## Scene routing, JSON data loading, the save file, and run-to-run state.

signal run_started
signal run_ended(victory: bool)
signal gold_changed(total: int)

const VERSION := "0.4.0 — the sexton rises"
const SAVE_PATH := "user://save.json"

## Player-facing settings (persisted with the save in a later phase).
var settings := {
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"haptics": true,
}

## Which hero the next run uses (picked at the camp).
var selected_character := "wren"

## Persistent progress. Written to user://save.json (IndexedDB on web).
var save_data := {
	"gold": 0,
	"unlocks": {"wren": true},
	"best_run": {},
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
	var best: Dictionary = save_data.get("best_run", {})
	if float(stats.get("time", 0.0)) > float(best.get("time", 0.0)):
		save_data["best_run"] = last_run.duplicate()
	write_save()
	get_tree().paused = false
	run_ended.emit(victory)
	go_camp()

# --- Gold & unlocks ---

func gold() -> int:
	return int(save_data.get("gold", 0))

func add_gold(amount: int) -> void:
	save_data["gold"] = gold() + maxi(0, amount)
	gold_changed.emit(gold())

func is_unlocked(id: String) -> bool:
	return bool(save_data.get("unlocks", {}).get(id, false))

func unlock(id: String) -> bool:
	if is_unlocked(id):
		return false
	save_data["unlocks"][id] = true
	write_save()
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

func write_save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file")
		return
	file.store_string(JSON.stringify(save_data))
	file.close()

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
