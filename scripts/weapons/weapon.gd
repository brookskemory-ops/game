class_name Weapon
extends Node2D
## Base class for all weapons. A weapon is DATA (data/weapons/*.json) driving a
## small script that implements one firing behavior. Every weapon must occupy a
## distinct mechanical niche — docs/ABILITIES.md is the registry that keeps the
## roster from overlapping. Check it before adding a weapon.

var def := {}
var wielder: Player
var enemies: EnemyManager
var projectiles: ProjectileManager
var hazards: HazardManager

var level := 1
var damage_mul := 1.0
var extra_projectiles := 0

var _cooldown_left := 0.0

func init(p_def: Dictionary, p_wielder: Player, ctx: Dictionary) -> void:
	def = p_def
	wielder = p_wielder
	enemies = ctx.get("enemies")
	projectiles = ctx.get("projectiles")
	hazards = ctx.get("hazards")

func _physics_process(delta: float) -> void:
	if wielder == null or wielder.dead:
		return
	_cooldown_left -= delta
	if _cooldown_left <= 0.0 and _try_fire():
		_cooldown_left = cooldown()

## Override per weapon. Return true only if the weapon actually fired
## (so weapons hold their shot when no target is in range).
func _try_fire() -> bool:
	return false

# --- Stats (always routed through the wielder's passive modifiers) ---

func display_name() -> String:
	return String(def.get("name", "Weapon"))

func weapon_id() -> String:
	return String(def.get("id", ""))

func damage() -> float:
	return float(def.get("damage", 10)) * damage_mul * wielder.damage_multiplier()

func cooldown() -> float:
	return float(def.get("cooldown", 1.0)) * clampf(wielder.mods["cooldown"], 0.5, 2.0)

func max_level() -> int:
	return int(def.get("max_level", 8))

func attack_range() -> float:
	return float(def.get("range", 220)) * float(wielder.mods["range"])

func area_mul() -> float:
	return float(wielder.mods["area"])

## The reliquary transforms this weapon (docs/ABILITIES.md §3). The evolved
## def replaces the base def; earned damage/projectile multipliers carry over.
func evolve(evolved_def: Dictionary) -> void:
	def = evolved_def
	queue_redraw()

# --- Leveling (chosen in the upgrade draft) ---

func upgrade() -> String:
	level += 1
	return _on_upgrade(level)

## Override for weapon-specific growth. Returns the toast message.
func _on_upgrade(_new_level: int) -> String:
	damage_mul *= 1.12
	return "%s: +12%% damage" % display_name()

## Short line shown on the draft card for an upgrade of this weapon.
func upgrade_preview() -> String:
	return String(def.get("up_desc", "Grows stronger"))
