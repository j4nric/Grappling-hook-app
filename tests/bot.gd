extends RefCounted
## Simple autopilot for tests: whenever no hook is out, it picks the throw
## (out of a fan of swipe directions) whose predicted arc sticks furthest
## ahead, and throws it with a strong flick.

const HOOK_SPEED := 45.0
const YAWS := [0.0, -20.0, 20.0, -40.0, 40.0, -60.0, 60.0, -80.0, 80.0]
## Ignore anchors less than this far ahead (m).
const MIN_PROGRESS := 2.0


## Call once per physics frame. Returns true if it threw.
static func step(p: CharacterBody3D) -> bool:
	if p.hook_state != p.HookState.IDLE:
		return false
	var best_score := -INF
	var best_swipe := Vector2.ZERO
	for yaw_deg: float in YAWS:
		var yaw := deg_to_rad(yaw_deg)
		var swipe := Vector2(sin(yaw), -cos(yaw)) * 300.0
		var path: Dictionary = p.predict_hook_path(p._throw_direction(swipe), HOOK_SPEED)
		if not path.hit:
			continue
		var end: Vector3 = path.points[-1]
		var progress: float = p.global_position.z - end.z
		if progress < MIN_PROGRESS:
			continue
		var score := progress - absf(yaw_deg) * 0.05
		if score > best_score:
			best_score = score
			best_swipe = swipe
	if best_score == -INF:
		return false
	InputRouter.throw_requested.emit(best_swipe, best_swipe.normalized() * HOOK_SPEED / p.throw_speed_per_px)
	return true
