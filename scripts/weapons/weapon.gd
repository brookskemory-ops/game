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

var damage_mul := 1.0
var extra_projectiles := 0

var _cooldown_left := 0.0

func init(p_def: Dictionary, p_wielder: Player, p_enemies: EnemyManager, p_projectiles: ProjectileManager) -> void:
	def = p_def
	wielder = p_wielder
	enemies = p_enemies
	projectiles = p_projectiles

func _physics_process(delta: float) -> void:
	if wielder == null or wielder.dead:
		return
	_cooldown_left -= delta
	if _cooldown_left <= 0.0 and _try_fire():
		_cooldown_left = float(def.get("cooldown", 1.0))

## Override per weapon. Return true only if the weapon actually fired
## (so weapons hold their shot when no target is in range).
func _try_fire() -> bool:
	return false

## Phase 1 auto-growth on level up (Phase 2 replaces this with upgrade choices).
## Returns a flavor message for the HUD toast.
func on_level(_level: int) -> String:
	damage_mul *= 1.08
	return "Resolve hardens  (+8% damage)"
