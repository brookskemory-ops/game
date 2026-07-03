class_name Reliquary
extends Node2D
## The Sexton's reliquary chest — the evolution moment (docs/ABILITIES.md §3,
## RESEARCH_NOTES: "the bell is our chest"). Sits where the boss fell, glowing;
## after a moment it drifts to the hero. Touching it opens it.

signal opened

const OPEN_DIST := 15.0
const DRIFT_DELAY := 2.2
const DRIFT_SPEED := 130.0

var _player: Node2D
var _age := 0.0
var _tex: Texture2D

func setup(player: Node2D) -> void:
	_player = player
	_tex = PixelSprites.get_tex("chest")

func _physics_process(delta: float) -> void:
	if _player == null:
		return
	_age += delta
	var to_player: Vector2 = _player.global_position - global_position
	if _age > DRIFT_DELAY and to_player.length() > OPEN_DIST:
		global_position += to_player.normalized() * DRIFT_SPEED * delta
	if to_player.length() <= OPEN_DIST:
		Sfx.play("buy")
		opened.emit()
		queue_free()
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_age * 4.0)
	# Halo.
	draw_circle(Vector2.ZERO, 14.0 + pulse * 3.0,
		Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, 0.10 + pulse * 0.06))
	draw_arc(Vector2.ZERO, 11.0 + pulse * 2.0, 0.0, TAU, 20,
		Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, 0.35), 1.5)
	if _tex != null:
		var bob := sin(_age * 3.0) * 1.5
		draw_texture(_tex, Vector2(-_tex.get_width() * 0.5, -_tex.get_height() * 0.5 + bob))
