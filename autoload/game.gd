extends Node
## Global game state singleton, autoloaded as `Game`.
## Scene routing, JSON data loading, and last-run stats.
## Later phases hang meta-progression and saves off this node.

signal run_started
signal run_ended(victory: bool)

const VERSION := "0.2.0 — phase 1 preview"

## Player-facing settings (persisted in a later phase).
var settings := {
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"haptics": true,
}

## Stats from the most recent run, for results/title screens.
var last_run := {
	"victory": false,
	"time": 0.0,
	"kills": 0,
	"level": 1,
}

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
	get_tree().paused = false
	run_ended.emit(victory)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

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
