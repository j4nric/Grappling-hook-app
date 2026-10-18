extends "res://tests/test_case.gd"
## Shader warm-up: at the start every effect and level material is drawn
## once (hidden behind the black start), then everything is put away again;
## a real effect later shows as usual.


func run() -> void:
	await load_main()
	var effects := main.get_node("Effects")
	check(effects.is_warming_up(), "the start warms up the shaders")
	check(effects._warm_meshes.get_child_count() >= CavernBuilder.MATERIALS.size() + 2, "every level material and shader is drawn once")
	check(effects._sparks.visible and effects._gold.visible, "every effect fires once")
	check(main.fade.color.a > 0.5, "behind the black of the start")
	await wait_frames(CavernBuilder.MATERIALS.size() + 6)
	check(not effects.is_warming_up() and effects._warm_meshes == null, "then it is put away")
	check(not effects._sparks.visible and not effects._gold.visible, "the effects are hidden again")
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	var p := player()
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	check(effects._sparks.visible, "a real spark shows as usual")
