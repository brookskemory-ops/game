extends Node
## Global game state singleton, autoloaded as `Game`.
## Scene routing, JSON data loading, the save file, shop, and unlock logic.

signal run_started
signal run_ended(victory: bool)
signal gold_changed(total: int)
signal orientation_changed  # mobile canvas swapped landscape <-> portrait

const VERSION := "2.0 — the last grave"
const SAVE_PATH := "user://save.json"

## Player-facing settings (persisted inside the save file).
var settings := {
	"sfx_volume": 1.0,
	"music_volume": 1.0,
	"haptics": true,
	"damage_numbers": true,
	"difficulty": "normal",
}

## Difficulty tiers, multiplied into each night's own mods at run start.
## Normal is the baseline (all 1.0); Story eases the night, Hard sharpens it.
const DIFFICULTIES := ["story", "normal", "hard"]
const DIFFICULTY := {
	"story": {
		"name": "Story",
		"blurb": "a gentler watch",
		"enemy_hp": 0.7, "enemy_speed": 0.9, "enemy_damage": 0.7,
		"spawn": 0.8, "xp": 1.15, "gold": 1.0, "player_incoming": 0.7,
	},
	"normal": {
		"name": "Normal",
		"blurb": "the vigil as meant",
		"enemy_hp": 1.0, "enemy_speed": 1.0, "enemy_damage": 1.0,
		"spawn": 1.0, "xp": 1.0, "gold": 1.0, "player_incoming": 1.0,
	},
	"hard": {
		"name": "Hard",
		"blurb": "the night in full",
		"enemy_hp": 1.3, "enemy_speed": 1.1, "enemy_damage": 1.25,
		"spawn": 1.2, "xp": 1.0, "gold": 1.2, "player_incoming": 1.15,
	},
}

## The current tier id (always valid), its display record, and its multipliers.
func difficulty_id() -> String:
	var id := String(settings.get("difficulty", "normal"))
	return id if DIFFICULTY.has(id) else "normal"

func difficulty_def() -> Dictionary:
	return DIFFICULTY[difficulty_id()]

func difficulty_name() -> String:
	return String(difficulty_def().get("name", "Normal"))

func cycle_difficulty() -> void:
	var i := DIFFICULTIES.find(difficulty_id())
	settings["difficulty"] = DIFFICULTIES[(i + 1) % DIFFICULTIES.size()]
	write_save()

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
	"achievements": {},
	"save_version": 1,
}

## Achievement ids earned by the last run, awaiting their toast at the camp.
var newly_earned_achievements: Array = []

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
	# Web QA: ?difficulty=<tier> forces the tier for this session (not saved),
	# so probes can exercise each without clicking through the menu.
	if OS.has_feature("web"):
		var search := String(JavaScriptBridge.eval("window.location.search", true))
		for tier in DIFFICULTIES:
			if search.contains("difficulty=" + tier):
				settings["difficulty"] = tier
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
	var stage_def: Variant = load_json(stage_path())
	var theme := String(stage_def.get("theme", "")) if stage_def is Dictionary else ""
	Music.play_night(theme)
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
	lifetime["elite_kills"] = int(lifetime.get("elite_kills", 0)) + int(stats.get("elite_kills", 0))
	lifetime["evolutions_total"] = int(lifetime.get("evolutions_total", 0)) + int(stats.get("evolutions", 0))
	# Distinct heroes played, for the "whole watch" medal.
	var played: Dictionary = lifetime.get("heroes_played", {})
	played[selected_character] = true
	lifetime["heroes_played"] = played
	# The Bestiary: union of everything seen, sum of everything killed.
	var book: Dictionary = lifetime.get("bestiary", {})
	for eid in stats.get("bestiary", {}):
		var night_kills := int(stats["bestiary"][eid])
		book[eid] = int(book.get(eid, 0)) + night_kills
	lifetime["bestiary"] = book
	if victory:
		lifetime["nights_survived"] = int(lifetime.get("nights_survived", 0)) + 1
		var stage_id := String(stats.get("stage", ""))
		if not stage_id.is_empty():
			save_data["stages"][stage_id] = true
		# Per-hero mastery: another night held with this hero.
		var mastery: Dictionary = save_data.get("mastery", {})
		mastery[selected_character] = int(mastery.get(selected_character, 0)) + 1
		save_data["mastery"] = mastery
		# Deepening prestige: the deepest Deepening ever cleared.
		if ascension_level() > int(save_data.get("ascension_best", 0)):
			save_data["ascension_best"] = ascension_level()
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
	_check_achievements(stats)
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

## Wipe every scrap of saved progress back to a first-night state — unlocks,
## gold, the bestiary, relics, endings, seen hints, all of it. Audio/display
## settings are deliberately kept. Reachable from the camp settings overlay.
func reset_progress() -> void:
	save_data = {
		"gold": 0,
		"unlocks": {"wren": true},
		"best_run": {},
		"shop": {},
		"stats": {"deaths": 0, "total_kills": 0, "nights_survived": 0},
		"stages": {},
		"settings": settings,
		"ending": "",
		"weapon_unlocks": {},
		"relics": {},
		"relic_equipped": "",
		"relics_equipped": [],
		"seen_hints": {},
		"save_version": 1,
	}
	# Session-scoped queues, so the camp doesn't replay old unlock vignettes.
	newly_unlocked.clear()
	newly_unlocked_weapons.clear()
	newly_unlocked_relics.clear()
	selected_character = "wren"
	selected_stage = "stage1"
	last_run = {"victory": false, "time": 0.0, "kills": 0, "level": 1, "stage": "", "character": ""}
	write_save()

func write_save() -> void:
	save_data["settings"] = settings
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file")
		return
	file.store_string(JSON.stringify(save_data))
	file.close()

## True when an automated-QA URL override (?stage=/?hero=/?weapon=) is active.
## Story cards (prologue, stage intros) are skipped in this mode so probes get
## a clean camp; real players never have these params.
func qa_web_override() -> bool:
	if not OS.has_feature("web"):
		return false
	var search := String(JavaScriptBridge.eval("window.location.search", true))
	return search.contains("stage=") or search.contains("hero=") or search.contains("weapon=")

## True when `?debug=1` is on the URL (web only). Gates the HUD's live telemetry
## push to `window.__vigil` so automated balance probes can read exact numbers
## (enemies alive, kills, level, HP) instead of scraping pixels. Cached — never
## present for real players.
var _debug_telemetry := -1  # -1 unresolved, 0 off, 1 on
func debug_telemetry() -> bool:
	if _debug_telemetry < 0:
		if OS.has_feature("web"):
			var search := String(JavaScriptBridge.eval("window.location.search", true))
			_debug_telemetry = 1 if search.contains("debug=1") else 0
		else:
			_debug_telemetry = 0
	return _debug_telemetry == 1

## Which stage the arena loads. On web builds a `?stage=qa` URL parameter
## swaps in the 45-second QA stage so automated tests can play full runs
## (docs/NIGHT_SHIFT.md WP2). Ignored everywhere else.
func stage_cleared(id: String) -> bool:
	return bool(save_data.get("stages", {}).get(id, false))

# --- First-run hints (each shown once, then remembered forever) ---

## True when a joypad is present — UI copy swaps to controller prompts.
func using_controller() -> bool:
	return not Input.get_connected_joypads().is_empty()

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

# --- Achievements (data-driven; data/achievements.json) ---

## The full list, or [] if the data is missing (fail-soft — the camp panel
## simply shows nothing rather than crashing).
func all_achievements() -> Array:
	var data: Variant = load_json("res://data/achievements.json")
	if data is Dictionary and data.get("achievements") is Array:
		return data["achievements"]
	return []

func achievement_earned(id: String) -> bool:
	return bool(save_data.get("achievements", {}).get(id, false))

## Evaluate one achievement's condition against lifetime + this run's stats.
func _achievement_met(a: Dictionary, run_stats: Dictionary) -> bool:
	var lifetime: Dictionary = save_data.get("stats", {})
	var need: Variant = a.get("value", 0)
	match String(a.get("type", "")):
		"nights_survived":
			return int(lifetime.get("nights_survived", 0)) >= int(need)
		"total_kills":
			return int(lifetime.get("total_kills", 0)) >= int(need)
		"elite_kills":
			return int(lifetime.get("elite_kills", 0)) >= int(need)
		"evolutions_total":
			return int(lifetime.get("evolutions_total", 0)) >= int(need)
		"deaths":
			return int(lifetime.get("deaths", 0)) >= int(need)
		"heroes_count":
			return (lifetime.get("heroes_played", {}) as Dictionary).size() >= int(need)
		"run_kills":
			return int(run_stats.get("kills", 0)) >= int(need)
		"no_hit_win":
			return bool(run_stats.get("victory_flag", false)) and int(run_stats.get("hits", -1)) == 0
		"stage_cleared":
			return stage_cleared(String(need))
		"ending":
			return ending() == String(need)
	return false

## Award any newly-met achievements. Called after each run (with its stats) and
## when an ending is set. Newly-earned ids queue for the camp toast.
func _check_achievements(run_stats: Dictionary) -> void:
	if not save_data.has("achievements"):
		save_data["achievements"] = {}
	# no_hit_win needs to know THIS run was a victory (lifetime can't tell us).
	if run_stats.has("hits"):
		run_stats["victory_flag"] = bool(last_run.get("victory", false))
	var earned: Dictionary = save_data["achievements"]
	for a in all_achievements():
		if not (a is Dictionary):
			continue
		var id := String(a.get("id", ""))
		if id.is_empty() or bool(earned.get(id, false)):
			continue
		if _achievement_met(a, run_stats):
			earned[id] = true
			newly_earned_achievements.append(id)

# --- Ascension: "The Deepening" (unlocked by the true end) + hero mastery ---

const ASCENSION_MAX := 10
const MASTERY_MAX := 5  # tiers that grant a bonus; wins beyond still tally

## The Deepening is offered once the night has been taken to its root (Act IV).
func ascension_unlocked() -> bool:
	return stage_cleared("stage4") or ending() == "unburied"

func ascension_level() -> int:
	return clampi(int(save_data.get("ascension", 0)), 0, ASCENSION_MAX)

func set_ascension(n: int) -> void:
	save_data["ascension"] = clampi(n, 0, ASCENSION_MAX)
	write_save()

## Deepening multipliers, folded into the arena's enemy mods. Each level makes
## the dead harder but more generous. Level 0 is the identity (no change).
func ascension_mods() -> Dictionary:
	var n := float(ascension_level())
	return {
		"hp_mul": 1.0 + 0.18 * n,
		"damage_mul": 1.0 + 0.08 * n,
		"speed_mul": 1.0 + 0.03 * n,
		"gold_mul": 1.0 + 0.15 * n,
		"xp_mul": 1.0 + 0.10 * n,
	}

## Raw nights won with a hero (uncapped — the mastery panel shows the tally).
func hero_mastery(hero_id: String) -> int:
	return int(save_data.get("mastery", {}).get(hero_id, 0))

## +2% damage and +2 max HP per mastery tier (capped at MASTERY_MAX), applied
## once at hero setup. A small, permanent edge for a well-walked hero.
func hero_mastery_bonus(hero_id: String) -> Dictionary:
	var m := float(mini(hero_mastery(hero_id), MASTERY_MAX))
	return {"damage_mul": 1.0 + 0.02 * m, "max_hp": 2.0 * m}

# --- The ending (Block B): chosen once, at the camp, by the Hollow King ---

func ending() -> String:
	return String(save_data.get("ending", ""))

func set_ending(id: String) -> void:
	save_data["ending"] = id
	_check_achievements({})  # ending-gated medals can land now
	write_save()

## The final choice is offered when the Hollow King himself has just
## put down the Thing in the Chapel — and no ending is chosen yet.
func ending_pending() -> bool:
	return ending().is_empty() \
		and bool(last_run.get("victory", false)) \
		and String(last_run.get("stage", "")) == "stage3" \
		and String(last_run.get("character", "")) == "hollow_king"

## The true ending: shown once, the first time ANY hero puts down the Unburied
## at the root of the night (Act IV). Independent of the Hollow King's bargain —
## a deeper resolution beneath it.
func true_ending_pending() -> bool:
	return not hint_seen("true_ending") \
		and bool(last_run.get("victory", false)) \
		and String(last_run.get("stage", "")) == "stage4"

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
