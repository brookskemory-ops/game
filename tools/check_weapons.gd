extends SceneTree
## CI smoke test: load and instantiate every weapon script.
##
## `gdparse`/`--check-only` do NOT run full type inference, so a weapon can
## parse clean yet fail to LOAD at runtime (e.g. `var x := a[2] / k` where the
## Array element is an untyped Variant). Booting the arena scene only exercises
## the default loadout, so a broken draftable weapon ships silently — its script
## fails to load, `.new()` returns null, and the weapon simply never fires.
##
## This walks data/weapons/*.json, loads each `script`, instantiates it, and
## fails the run on any that error.
## Run: godot --headless --quit-after 20 --script res://tools/check_weapons.gd
##
## The work runs once on the first frame and then returns true to stop the main
## loop (quit() alone, called from _init, is not honoured reliably in headless
## --script runs and can hang the process — hence the _process guard plus the
## --quit-after safety net on the command line).

var _done := false

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run()
	return true

func _run() -> void:
	var dir := DirAccess.open("res://data/weapons")
	var failures: Array = []
	var checked := 0
	if dir == null:
		printerr("check_weapons: cannot open res://data/weapons")
		quit(1)
		return
	for file in dir.get_files():
		if not file.ends_with(".json") or file == "_pool.json":
			continue
		var text := FileAccess.get_file_as_string("res://data/weapons/" + file)
		var def: Variant = JSON.parse_string(text)
		if not (def is Dictionary):
			failures.append("%s: not a JSON object" % file)
			continue
		var script_path := String(def.get("script", ""))
		if script_path.is_empty():
			failures.append("%s: missing 'script' field" % file)
			continue
		if not ResourceLoader.exists(script_path):
			failures.append("%s: script not found: %s" % [file, script_path])
			continue
		var scr: Variant = load(script_path)
		if scr == null:
			failures.append("%s: FAILED TO LOAD %s (parse/type error)" % [file, script_path])
			continue
		var inst: Variant = scr.new()
		if inst == null:
			failures.append("%s: .new() returned null for %s" % [file, script_path])
			continue
		if not (inst is Weapon):
			failures.append("%s: %s is not a Weapon" % [file, script_path])
		if inst is Node:
			inst.free()
		checked += 1
	if failures.is_empty():
		print("check_weapons: OK — %d weapon scripts load and instantiate" % checked)
		quit(0)
	else:
		for f in failures:
			printerr("check_weapons: " + f)
		quit(1)
