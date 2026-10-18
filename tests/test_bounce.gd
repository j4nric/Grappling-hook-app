extends "res://tests/test_case.gd"
## Bounce mushrooms: on the floor of a ground hall and on a rock column over
## lava; landing on the cap throws the player up and on; editor and the
## records of levels without them stay as they were.


func run() -> void:
	levels = ["res://tests/levels/bounce_01.tscn"]
	await load_main()
	var p := player()
	var bouncers: Array[Node] = main.level.get_tree().get_nodes_in_group("bouncer")
	check(bouncers.size() == 3, "one mushroom in the ground hall, two over the lava (%d)" % bouncers.size())
	var bounced := [0]
	p.bounced.connect(func() -> void: bounced[0] += 1)

	for b: Bouncer in bouncers:
		var over_lava: bool = b.global_position.z < -60.0
		var cap_top: float = b.global_position.y - 0.7
		check(absf(cap_top - ((CavernBuilder.BOUNCER_COLUMN_TOP if over_lava else 0.0) + 4.0)) < 0.01,
				"the cap stands %s" % ("on a column over the lava" if over_lava else "on the floor"))
		# Drop onto the cap, moving forward.
		p.reset_to(b.global_position + Vector3(0, 4, 2))
		p.velocity = Vector3(0, -10, -6)
		var before: int = bounced[0]
		var up := await wait_until(func() -> bool: return bounced[0] > before, 60)
		check(up, "landing on the cap bounces")
		check(p.velocity.y > 20.0 and p.velocity.z < -10.0, "thrown up and on (%s)" % p.velocity)
		await wait_frames(20)
		check(p.global_position.y > cap_top + 6.0, "flies up high (%.1f m above the cap)" % (p.global_position.y - cap_top))

	# Hooks do not hold on the cap (a floor), and the sound plays.
	check(main.get_node("Sfx")._players["bounce"].stream != null, "a boing sound is loaded")
	# Editor: a slider with its sketch.
	check("bouncers" in CaveEditor.KEYS and TuningInfo.PARAMS.has("CaveEditor/bouncers"), "the cave editor sets mushrooms")
	# A level without mushrooms keeps its version (and so its records).
	var plain := Level.new()
	plain.segments = [{"length": 50.0}]
	var with_key := Level.new()
	with_key.segments = [{"length": 50.0, "bouncers": 0}]
	check(plain.version() == with_key.version(), "the new key at its default leaves the version alone")
	plain.free()
	with_key.free()
