extends Node
## Global game state singleton, autoloaded as `Game`.
## Phase 0: scene routing + settings stub.
## Later phases hang run state, meta-progression, and saves off this node.

signal run_started
signal run_ended(victory: bool)

## Player-facing settings (persisted in a later phase).
var settings := {
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"haptics": true,
}

func start_run() -> void:
	run_started.emit()
	get_tree().change_scene_to_file("res://scenes/arena.tscn")

func end_run(victory: bool) -> void:
	run_ended.emit(victory)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
