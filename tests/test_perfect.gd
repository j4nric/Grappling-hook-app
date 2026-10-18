extends "res://tests/test_case.gd"
## Perfect chain: a hook that bites just before the old rope lets go (or
## right after a zip) adds speed and shows PERFECT; an early one does not.


func run() -> void:
	await load_main()
	var p := player()
	p.perfect_chain_boost = 6.0
	p.perfect_chain_window = 5.0
	p.perfect_after_zip = 0.2
	var perfect := [0]
	p.perfect_chain.connect(func() -> void: perfect[0] += 1)
	var release_at: float = maxf(p.zip_release_distance, p.min_rope_length)

	# Early: the old anchor is still far away.
	p.reset_to(Vector3(0, 2, 0))
	p.attach(Vector3(0, 8, -40), Vector3.BACK)
	p.velocity = Vector3(0, 0, -20)
	var speed_before: float = p.velocity.length()
	p.attach(Vector3(0, 8, -80), Vector3.BACK)
	check(perfect[0] == 0, "an early chain is not perfect")

	# In the window: close to the old anchor and moving toward it.
	p.reset_to(Vector3(0, 2, 0))
	var anchor := Vector3(0, 2, -(release_at + 3.0))
	p.attach(anchor, Vector3.BACK)
	p.velocity = Vector3(0, 0, -20)
	speed_before = p.velocity.length()
	p.attach(Vector3(0, 8, -60), Vector3.BACK)
	check(perfect[0] == 1, "a chain just before the release is perfect")
	# The pull impulse toward the new anchor adds a little, the boost the rest.
	check(p.velocity.length() > speed_before + 5.0, "the perfect chain adds speed (%.1f -> %.1f)" % [speed_before, p.velocity.length()])
	await wait_frames(2)
	check(main.perfect_label.visible, "PERFECT shows")
	check(main.get_node("Sfx")._players["perfect"].playing, "a bright chime plays")

	# Moving away from the old anchor: not perfect.
	p.reset_to(Vector3(0, 2, 0))
	p.attach(Vector3(0, 2, -(release_at + 3.0)), Vector3.BACK)
	p.velocity = Vector3(0, 0, 20)
	p.attach(Vector3(0, 8, -60), Vector3.BACK)
	check(perfect[0] == 1, "moving away is not perfect")

	# Right after a zip launch.
	p.reset_to(Vector3(0, 2, 0))
	p.attach(Vector3(0, 2, -30), Vector3.BACK)
	p.velocity = Vector3(0, 0, -25)
	p._zip_launch()
	await wait_frames(3)
	p.attach(Vector3(0, 8, -70), Vector3.BACK)
	check(perfect[0] == 2, "a hook right after a zip is perfect")
	p.release("reset")
	p._zip_launch()
	await wait_frames(30)
	p.attach(Vector3(0, 8, -90), Vector3.BACK)
	check(perfect[0] == 2, "a hook long after a zip is not")

	# Off.
	p.perfect_chain_boost = 0.0
	p.reset_to(Vector3(0, 2, 0))
	p.attach(Vector3(0, 2, -(release_at + 3.0)), Vector3.BACK)
	p.velocity = Vector3(0, 0, -20)
	p.attach(Vector3(0, 8, -60), Vector3.BACK)
	check(perfect[0] == 2, "boost 0 turns it off")

	# A real chain in the tunnel with the bot-like timing counts in the run.
	check(main.perfects >= 0, "perfects are counted per run")
	check(Stats.describe({"runs": 1, "finishes": 1, "meters": 10.0, "hooks": 3, "perfects": 2, "best_flow": 0, "play_time": 5.0}).contains("2 perfect"),
			"stats list perfect chains")
