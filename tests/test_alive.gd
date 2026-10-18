extends "res://tests/test_case.gd"
## A living cave: waterfalls down some walls (with mist and sound, no
## collision), lava as a swelling plane with embers, daylight behind the
## finish, motes in the air that follow the hall.


func run() -> void:
	levels = Levels.LIST
	await load_main()
	var falls := 0
	var lava_planes := 0
	for i in Levels.LIST.size():
		main.load_level(i)
		await wait_frames(1)
		var level: Level = main.level
		falls += level.get_node("Props").find_children("Waterfall*", "MeshInstance3D", false, false).size()
		for lava in level.get_node("Geometry").find_children("Lava*", "MeshInstance3D", false, false):
			if lava.mesh is PlaneMesh and (lava.mesh as PlaneMesh).subdivide_width > 4:
				lava_planes += 1
		check(level.get_node("Props").has_node("Daylight") and level.get_node("Lights").has_node("Daylight"),
				"%s: daylight shines in behind the finish" % level.level_name)
	check(falls >= 3, "waterfalls pour down some walls (%d)" % falls)
	check(lava_planes >= 2, "lava is a swelling plane (%d)" % lava_planes)

	# Waterfalls are only for the eye: a ray through one meets no rock.
	main.load_level(0)
	await wait_frames(1)
	var level: Level = main.level
	var fall: MeshInstance3D = null
	for i in Levels.LIST.size():
		main.load_level(i)
		await wait_frames(1)
		var found: Array = main.level.get_node("Props").find_children("Waterfall*", "MeshInstance3D", false, false)
		if not found.is_empty():
			fall = found[0]
			level = main.level
			break
	if fall:
		var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
		var through := PhysicsRayQueryParameters3D.create(fall.global_position + Vector3(0, 0, 3), fall.global_position + Vector3(0, 0, -3))
		through.exclude = [player().get_rid()]
		check(space.intersect_ray(through).is_empty(), "a waterfall has no collision")
		check(level.get_node("Sounds").find_children("Water*", "", false, false).size() > 0, "a waterfall rushes")

	# Motes follow the hall.
	var effects := main.get_node("Effects")
	check(effects.air_for(CavernBuilder.full_segment({"template": "lava_lake"})) == "embers", "embers over lava")
	check(effects.air_for(CavernBuilder.full_segment({"template": "ice_vault"})) == "snow", "snow in an ice hall")
	check(effects.air_for(CavernBuilder.full_segment({"dark": true})) == "fireflies", "fireflies in the dark")
	check(effects.air_for(CavernBuilder.full_segment({"template": "skyway"})) == "pollen", "pollen under an open sky")
	main.load_level(level_named("level_02"))
	await wait_frames(2)
	var lava_hall_z := 0.0
	for raw: Dictionary in main.level.segments:
		var hall := CavernBuilder.full_segment(raw)
		if hall.floor == "lava":
			lava_hall_z -= float(hall.length) / 2.0
			break
		lava_hall_z -= float(hall.length)
	player().reset_to(Vector3(0, 10, lava_hall_z))
	await wait_frames(40)
	check(effects.air == "embers", "over the lava the air glows with embers (%s)" % effects.air)
