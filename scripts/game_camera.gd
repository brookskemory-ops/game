class_name GameCamera
extends Camera2D
## Camera with trauma-based shake (juice checklist, DEVELOPMENT_PLAN.md Phase 5 —
## wired early because it's foundational feel).

const SHAKE_MAX := 6.0
const DECAY := 1.8

var _trauma := 0.0

func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - DECAY * delta)
		var strength := _trauma * _trauma * SHAKE_MAX
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO
