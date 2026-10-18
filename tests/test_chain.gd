extends "res://tests/test_case.gd"
## Chain throws: the rope holds until the new hook bites, swipes during a
## flight are buffered, double swipes are dropped, rethrowing costs no
## momentum. Swing phase keeps the rope length.

const STRONG := Vector2(0, -3000)

var _reasons: Array[String] = []


func run() -> void:
	await load_main()
	var p := player()
	p.rope_released.connect(func(reason: String) -> void: _reasons.append(reason))
	await wait_frames(20)

	# Hand-over: a throw while attached keeps the rope until the new hook bites.
	_throw(p, Vector2(0, -300))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	await wait_frames(5)
	var first_anchor: Vector3 = p.anchor
	_throw(p, Vector2(200, -300))
	await get_tree().physics_frame
	check(p.hook_state == p.HookState.ATTACHED and p.is_hook_flying(), "rope still pulls while the new hook flies")
	check(p.anchor == first_anchor, "anchor unchanged until the new hook bites")
	await wait_until(func() -> bool: return not p.is_hook_flying(), 60)
	check(p.anchor != first_anchor and _reasons.back() == "chain", "new hook takes over (%s)" % str(_reasons))

	# Buffer: a swipe during a flight is thrown when that hook bites.
	main.restart()
	await wait_frames(20)
	var thrown := [0]
	p.hook_thrown.connect(func() -> void: thrown[0] += 1)
	_throw(p, Vector2(0, -300))
	await wait_frames(int(p.throw_cooldown * 60) + 2)
	_throw(p, Vector2(150, -300))
	check(thrown[0] == 1, "swipe during the flight is buffered, not thrown")
	await wait_until(func() -> bool: return thrown[0] == 2, 60)
	check(thrown[0] == 2 and p.is_hook_flying(), "buffered swipe is thrown when the first hook bites")

	# Double swipe: a second swipe right after the throw is dropped.
	main.restart()
	await wait_frames(20)
	thrown[0] = 0
	_throw(p, Vector2(0, -300))
	await get_tree().physics_frame
	_throw(p, Vector2(0, -300))
	await wait_frames(80)
	check(thrown[0] == 1, "accidental double swipe throws once (%d)" % thrown[0])

	# Rethrowing as fast as possible no longer costs momentum.
	var single := await _run_for(p, false)
	var spam := await _run_for(p, true)
	print("    2 s single: %.1f m, max %.1f m/s | spam: %.1f m, max %.1f m/s" % [single.x, single.y, spam.x, spam.y])
	# Spamming may cost a little (each new hook is placed for a fresh pull),
	# but never a large part of the way, as it once did.
	check(spam.x >= single.x * 0.85, "rethrowing keeps the distance (%.1f vs %.1f m)" % [spam.x, single.x])

	# Swing phase: the rope keeps its length, then reels.
	main.restart()
	await wait_frames(20)
	p.swing_time = 0.3
	_throw(p, Vector2(0, -300))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	var length: float = p.rope_length
	await wait_frames(10)
	check(absf(p.rope_length - length) < 0.01, "rope keeps its length while swinging")
	await wait_frames(20)
	check(p.rope_length < length - 0.5, "reel starts after the swing")
	p.swing_time = 0.0


func _throw(p: CharacterBody3D, swipe: Vector2) -> void:
	InputRouter.throw_requested.emit(swipe, swipe.normalized() * STRONG.length())


## Distance (x) and top speed (y) after 2 s: one throw, or rethrow whenever
## no hook is in the air (spam).
func _run_for(p: CharacterBody3D, spam: bool) -> Vector2:
	main.restart()
	await wait_frames(20)
	_throw(p, Vector2(0, -300))
	var top := 0.0
	for i in 120:
		if spam and not p.is_hook_flying() and p.hook_state == p.HookState.ATTACHED and p._attached_time > 0.05:
			_throw(p, Vector2(0, -300))
		top = maxf(top, p.velocity.length())
		await get_tree().physics_frame
	return Vector2(-p.global_position.z, top)
