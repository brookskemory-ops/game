class_name GameCamera
extends Camera2D
## Camera with trauma-based shake (juice checklist, DEVELOPMENT_PLAN.md Phase 5 —
## wired early because it's foundational feel) and brief hitstop for impact weight.

const SHAKE_MAX := 6.0
const DECAY := 1.8

var _trauma := 0.0
var _hitstop_until_ms := 0

func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

## A brief global freeze-frame for impact weight — the classic hitstop. `secs` is
## measured in REAL time (deadline in ticks_msec) so it is immune to the very
## time-scale it sets. `scale` is the time factor during the freeze (0.0 = hard
## stop). Non-stacking: a new call only ever extends the current freeze, never
## shortens it, so a flurry of hits doesn't cut the stop short.
##
## Reserved for genuinely heavy beats (cleave, gallows crush, ballista, boss
## death, a hard hit taken). Never per-basic-hit — constant stutter feels awful
## in a horde game.
func hitstop(secs: float, scale := 0.0) -> void:
	var until := Time.get_ticks_msec() + int(secs * 1000.0)
	if until > _hitstop_until_ms:
		_hitstop_until_ms = until
		Engine.time_scale = scale

## Force time back to normal. Called from the pause/results paths so a freeze can
## never leak across a draft or the end of a night.
static func clear_hitstop() -> void:
	Engine.time_scale = 1.0

func _process(delta: float) -> void:
	if _hitstop_until_ms > 0 and Time.get_ticks_msec() >= _hitstop_until_ms:
		_hitstop_until_ms = 0
		Engine.time_scale = 1.0
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - DECAY * delta)
		var strength := _trauma * _trauma * SHAKE_MAX
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO
