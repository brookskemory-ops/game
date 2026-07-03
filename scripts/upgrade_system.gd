class_name UpgradeSystem
extends RefCounted
## Builds and applies the level-up draft (pick 1 of 3). All content comes from
## data: the weapon pool from data/weapons/_pool.json, passives from
## data/passives.json. Quality rule from docs/ABILITIES.md §5: a draft never
## offers the same option twice, and there is always at least one option
## (falling back to a bandage heal).

const DRAFT_SIZE := 3

var player: Player
var weapon_pool: Array = []   # weapon defs eligible to appear as new weapons
var passives := {}            # id -> passive def

func _init(p_player: Player) -> void:
	player = p_player
	var pool: Variant = Game.load_json("res://data/weapons/_pool.json")
	if pool is Array:
		for weapon_id in pool:
			var def: Variant = Game.load_json("res://data/weapons/%s.json" % String(weapon_id))
			if def is Dictionary:
				weapon_pool.append(def)
	var passive_data: Variant = Game.load_json("res://data/passives.json")
	if passive_data is Dictionary:
		passives = passive_data

## Roll up to DRAFT_SIZE distinct options for one level-up.
func roll() -> Array:
	var candidates: Array = []
	# Upgrade an owned weapon.
	for weapon in player.weapons:
		if weapon.level < weapon.max_level():
			candidates.append({
				"type": "weapon_up",
				"weapon": weapon,
				"title": weapon.display_name(),
				"desc": weapon.upgrade_preview(),
				"tag": "improve · LV %d" % (weapon.level + 1),
			})
	# Take a new weapon (if a slot is free).
	if player.weapons.size() < Player.MAX_WEAPONS:
		for def in weapon_pool:
			var weapon_id := String(def.get("id", ""))
			if player.has_weapon(weapon_id):
				continue
			candidates.append({
				"type": "weapon_new",
				"id": weapon_id,
				"family": String(def.get("family", "")),
				"title": String(def.get("name", weapon_id)),
				"desc": String(def.get("draft_desc", "A new weapon")),
				"tag": "new weapon",
			})
	# Take a passive.
	# 3+3 rule: once three distinct keepsakes are held, only those three may
	# deepen — no new ones appear (docs/ABILITIES.md).
	var at_passive_cap: bool = player.passive_stacks.size() >= Player.MAX_PASSIVES
	for passive_id in passives:
		var def: Dictionary = passives[passive_id]
		var stacks := int(player.passive_stacks.get(passive_id, 0))
		if stacks >= int(def.get("max_stacks", 5)):
			continue
		if at_passive_cap and stacks == 0:
			continue
		var tag := "keepsake"
		if stacks > 0:
			tag = "keepsake · %d/%d" % [stacks + 1, int(def.get("max_stacks", 5))]
		candidates.append({
			"type": "passive",
			"id": passive_id,
			"title": String(def.get("name", passive_id)),
			"desc": String(def.get("desc", "")),
			"tag": tag,
		})
	candidates.shuffle()
	# Quality rule (docs/ABILITIES.md §5): a draft never offers two new weapons
	# from the same delivery family.
	var options: Array = []
	var families := {}
	for candidate in candidates:
		if options.size() >= DRAFT_SIZE:
			break
		if String(candidate.get("type", "")) == "weapon_new":
			var family := String(candidate.get("family", ""))
			if not family.is_empty() and families.has(family):
				continue
			families[family] = true
		options.append(candidate)
	if options.is_empty():
		options.append({
			"type": "heal",
			"title": "Bandages",
			"desc": "Bind your wounds (+25 HP)",
			"tag": "respite",
		})
	return options

## Apply the chosen option. Returns the toast message.
func apply(option: Dictionary) -> String:
	match String(option.get("type", "")):
		"weapon_up":
			var weapon: Weapon = option.get("weapon")
			return weapon.upgrade()
		"weapon_new":
			var weapon := player.equip(String(option.get("id", "")))
			if weapon != null:
				return "%s taken up" % weapon.display_name()
			return "The weapon slips away..."
		"passive":
			var passive_id := String(option.get("id", ""))
			player.apply_passive(passive_id, passives.get(passive_id, {}))
			return "%s (%s)" % [String(option.get("title", "")), String(option.get("desc", ""))]
		"heal":
			player.heal(25.0)
			return "Wounds bound (+25 HP)"
	return ""
