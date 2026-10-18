extends "res://tests/test_case.gd"
## Material library and atmosphere: textured triplanar materials in every
## level, lava shader, flickering torches, vignette and dust motes.

const LIBRARY := "res://assets/materials/"


func run() -> void:
	var names := ["rock", "rock_dark", "rock_floor", "obstacle", "metal", "ice", "crystal"]
	for material_name in names:
		var mat := load(LIBRARY + material_name + ".tres") as StandardMaterial3D
		check(mat != null, "%s material loads" % material_name)
		if mat:
			check(mat.albedo_texture != null, "%s has a texture" % material_name)
			check(mat.uv1_triplanar and mat.uv1_world_triplanar, "%s is world triplanar (seamless)" % material_name)
	var lava := load(LIBRARY + "lava.tres") as ShaderMaterial
	check(lava != null and lava.get_shader_parameter("noise") != null, "lava shader has its noise")

	for i in Levels.LIST.size():
		var level: Node = load(Levels.LIST[i]).instantiate()
		var plain := 0
		for box: CSGBox3D in level.get_node("Geometry").find_children("*", "CSGBox3D", true, false):
			if not box.material or not box.material.resource_path.begins_with(LIBRARY):
				plain += 1
		check(plain == 0, "level %d: all geometry uses library materials (%d plain)" % [i + 1, plain])
		level.free()

	await load_main()
	await wait_frames(5)
	var torch: OmniLight3D = main.level.get_node("Lights/Torch0")
	var energies := {}
	for i in 20:
		energies[snappedf(torch.light_energy, 0.01)] = true
		await get_tree().process_frame
	check(energies.size() > 5, "torches flicker (%d values)" % energies.size())
	check(main.get_node("World/Vignette").visible, "vignette over the 3D view")
	check(main.get_node("Effects")._motes.emitting, "dust motes float in the air")

	var crystal: Node3D = load("res://scenes/props/crystal.tscn").instantiate()
	check(crystal.get_node("Glow") is OmniLight3D, "crystal prop glows")
	crystal.free()
	var shaft: MeshInstance3D = load("res://scenes/props/light_shaft.tscn").instantiate()
	check(shaft.mesh != null, "light shaft prop has its beam")
	shaft.free()
