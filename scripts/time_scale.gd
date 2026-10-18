class_name TimeScale
extends RefCounted
## Engine.time_scale has two users: slow motion while aiming and the hit-stop
## when a hook bites. Both go through here so neither undoes the other.
## The run timer counts game time without the hit-stop (a juice effect must
## not cost the player time) but with real time during aim slow motion.

static var _aim := 1.0
static var _stop := 1.0
## Real seconds the hit-stop still lasts.
static var _stop_left := 0.0
## Scales in effect for the current frame's delta. Godot computes a frame's
## delta before the frame runs, so a change made during a frame (a hook bites
## in the physics step) only shows in the next delta.
static var _frame_scale := 1.0
static var _frame_aim := 1.0


static func set_aim(scale: float) -> void:
	_aim = scale
	_apply()


## Nearly freezes the game for `seconds` of real time.
static func hit_stop(seconds: float, scale: float) -> void:
	if seconds <= 0.0:
		return
	_stop = scale
	_stop_left = seconds
	_apply()


## Call once per rendered frame with the (scaled) frame delta, after
## timer_delta(); ends the hit-stop on time. Counts frame deltas, not the wall
## clock, so it is deterministic in headless tests.
static func update(delta: float) -> void:
	if _stop_left > 0.0:
		_stop_left -= delta / maxf(_frame_scale, 0.001)
		if _stop_left <= 0.0:
			_stop = 1.0
			_apply()
	_frame_scale = Engine.time_scale
	_frame_aim = _aim


static func is_hit_stopped() -> bool:
	return _stop_left > 0.0


## Back to normal speed (restart, teleport).
static func reset() -> void:
	_aim = 1.0
	_stop = 1.0
	_stop_left = 0.0
	_apply()
	_frame_scale = Engine.time_scale
	_frame_aim = _aim


## Scaled frame delta → delta of the run timer: real time while aiming,
## game time while the hit-stop freezes.
static func timer_delta(delta: float) -> float:
	return delta / maxf(_frame_aim, 0.001)


static func _apply() -> void:
	Engine.time_scale = _aim * _stop
