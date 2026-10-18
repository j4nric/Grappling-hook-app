extends "res://tests/test_case.gd"
## The cave editor (TUNE, tab Cave): picks a hall, changes it, rebuilds the
## cave with the player at that hall; open ceiling with floating stones;
## edits are kept per level with their own records; Copy layout; Reset cave.


func run() -> void:
	DirAccess.remove_absolute(CaveEditor.SAVE_PATH)
	levels = Levels.LIST
	level_index = level_named("level_07")
	await load_main()
	var t := main.get_node("Tuning")
	var editor: CaveEditor = main.get_node("CaveEditor")
	var path: String = Levels.LIST[level_index]
	var original: Array = main.level.segments.duplicate(true)
	var real_id := Records.id(path, main.level)
	await wait_frames(2)
	check(editor.segments == original, "the editor holds the level's halls")
	check(t._sliders["CaveEditor/hall"].max_value == original.size() - 1, "the hall slider spans the halls")

	t._set_open(true)
	t._sliders["CaveEditor/hall"].value = 2
	check(editor.selected_hall == 2, "picking a hall")
	check(is_equal_approx(t._sliders["CaveEditor/width"].value, float(original[2].width)), "the sliders show the picked hall (%s vs %s)" % [t._sliders["CaveEditor/width"].value, original[2].width])
	check(t._labels["CaveEditor/hall"].text.contains("3 of %d" % original.size()), "the hall reads as 3 of %d" % original.size())

	# Changing a value rebuilds the cave a moment later.
	t._sliders["CaveEditor/width"].value = 100
	check(main.level.segments[2].width == original[2].width, "not rebuilt at once (slider still moving)")
	await _real_seconds(0.6)
	check(int(main.level.segments[2].width) == 100, "the cave is rebuilt with the new width")
	var starts := editor.hall_starts()
	var z: float = player().global_position.z
	check(z < starts[2] and z > starts[2] - float(main.level.segments[2].length), "the player waits in the edited hall (z %.0f)" % z)
	check(main._edited and main._record_id.begins_with("edit_"), "an edited cave keeps its own records")
	check(main.level_label.text.contains("(edit)"), "the HUD shows it is an edit")

	# Open ceiling with floating stones.
	t._sliders["CaveEditor/open"].value = 1
	t._sliders["CaveEditor/floater_spacing"].value = 12
	await _real_seconds(0.6)
	check(main.level.segments[2].open == true, "the hall is open")
	check(get_tree().get_nodes_in_group("floater").size() >= 5, "floating stones line the open hall")
	check(t._sliders["CaveEditor/open"].value == 1.0, "the sliders keep the hall after the rebuild")

	# Copy layout: the halls in the level file format.
	var text: String = editor.layout_text()
	check(text.contains("segments = [") and text.contains("\"open\": true") and text.contains("layout_seed ="), "Copy layout gives the halls as text")

	# The edit stays when the level loads again; records stay apart.
	main.load_level(level_index)
	await wait_frames(2)
	check(int(main.level.segments[2].width) == 100, "the edit is kept")
	check(Records.id(path, main.level) != real_id, "the edited cave is another version")
	check(not t.is_tuned() and not t.values_text().contains("CaveEditor"), "cave edits are no tuning")

	# Reset: back to the level as it was made.
	editor.reset_cave()
	await wait_frames(2)
	check(main.level.segments == original and not main._edited, "Reset cave restores the level")
	check(not CaveEditor.is_edited(path), "the saved edit is gone")
	t._set_open(false)
	DirAccess.remove_absolute(CaveEditor.SAVE_PATH)


## The panel pauses the game: wait in real (process) frames.
func _real_seconds(seconds: float) -> void:
	for i in roundi(seconds * 60.0):
		await get_tree().process_frame
