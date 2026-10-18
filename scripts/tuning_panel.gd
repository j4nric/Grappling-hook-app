extends CanvasLayer
## Debug overlay with sliders for the feel-relevant @export values, so the
## swing can be tuned on the phone without a new build. Opening it pauses the
## game. Values persist in user:// (IndexedDB in the browser).
## The GUI handles its own input; gameplay input still only runs through
## InputRouter.

## Only values that differ from the code defaults are saved, together with the
## default they were tuned against. If a default changes in the code, the saved
## value for it is dropped, so code changes always reach the phone.
const SAVE_PATH := "user://tuning_v3.cfg"
## Earlier format that stored every value; only real changes are taken over.
const LEGACY_SAVE_PATH := "user://tuning_v2.cfg"
## Code defaults at the time of the legacy format. Legacy values equal to these
## were never tuned and are ignored.
const LEGACY_DEFAULTS := {
	"Player/gravity": 22.0, "Player/max_speed": 50.0,
	"Player/throw_speed_per_px": 0.015, "Player/hook_min_speed": 8.0,
	"Player/hook_max_speed": 70.0, "Player/hook_gravity": 25.0,
	"Player/throw_pitch": 50.0, "Player/throw_yaw_gain": 1.0,
	"Player/max_rope_length": 45.0, "Player/reel_speed": 10.0,
	"Player/min_rope_length": 2.5, "Player/tension_boost": 6.0,
	"CameraRig/follow_speed": 6.0, "CameraRig/base_fov": 75.0,
	"CameraRig/fov_per_speed": 0.5, "CameraRig/max_fov": 105.0,
	"CameraRig/offset:y": 2.5, "CameraRig/offset:z": 7.0,
}
const SECTION := "tuning"
const DEFAULTS_SECTION := "defaults"
## Tuning sets A, B, C: switch with one tap to compare two feels. The live
## values are always the active set; the others wait in this file (in the
## same format: only changed values, with the default they were tuned against).
const PRESETS_PATH := "user://tuning_presets.cfg"
const SLOTS := ["A", "B", "C"]

## [node path relative to the parent, property path, min, max, step, tab]
const PARAMS := [
	["Player", "throw_speed_per_px", 0.002, 0.06, 0.001, "Throw"],
	["Player", "hook_min_speed", 0.0, 80.0, 1.0, "Throw"],
	["Player", "hook_max_speed", 10.0, 200.0, 1.0, "Throw"],
	["Player", "hook_gravity", 0.0, 80.0, 1.0, "Throw"],
	["Player", "throw_pitch", 0.0, 90.0, 1.0, "Throw"],
	["Player", "min_throw_reach", 0.0, 60.0, 1.0, "Throw"],
	["Player", "throw_yaw_gain", 0.0, 2.0, 0.05, "Throw"],
	["Player", "max_rope_length", 10.0, 100.0, 1.0, "Throw"],
	["Player", "min_hook_distance", 0.0, 10.0, 0.25, "Throw"],
	["Player", "throw_buffer_time", 0.0, 1.5, 0.05, "Throw"],
	["Player", "aim_preview_speed", 5.0, 200.0, 1.0, "Throw"],
	["Player", "aim_assist_angle", 0.0, 30.0, 1.0, "Throw"],
	["Player", "aim_time_scale", 0.1, 1.0, 0.05, "Throw"],
	["Player", "pull_impulse", 0.0, 30.0, 0.5, "Rope"],
	["Player", "reel_speed", 0.0, 80.0, 0.5, "Rope"],
	["Player", "reel_acceleration", 0.0, 150.0, 1.0, "Rope"],
	["Player", "reel_max_speed", 5.0, 80.0, 1.0, "Rope"],
	["Player", "tension_boost", 0.0, 80.0, 0.5, "Rope"],
	["Player", "min_rope_length", 0.0, 25.0, 0.25, "Rope"],
	["Player", "rope_end_release", 0.0, 1.0, 1.0, "Rope"],
	["Player", "zip_release_distance", 0.0, 20.0, 0.25, "Rope"],
	["Player", "zip_boost", 0.0, 20.0, 0.5, "Rope"],
	["Player", "flyby_release_distance", 0.0, 30.0, 0.5, "Rope"],
	["Player", "perfect_chain_boost", 0.0, 20.0, 0.5, "Rope"],
	["Player", "perfect_chain_window", 0.0, 20.0, 0.5, "Rope"],
	["Player", "perfect_after_zip", 0.0, 0.6, 0.05, "Rope"],
	["Player", "swing_time", 0.0, 1.0, 0.05, "Rope"],
	["Player", "contact_release_grace", 0.0, 1.0, 0.05, "Rope"],
	["Player", "rope_pluck", 0.0, 4.0, 0.05, "Rope"],
	["Player", "flight_rope_slack", 1.0, 1.6, 0.01, "Rope"],
	["Player", "gravity", 5.0, 100.0, 0.5, "Move"],
	["Player", "max_speed", 10.0, 120.0, 1.0, "Move"],
	["Player", "floor_friction", 0.0, 200.0, 1.0, "Move"],
	["Player", "slide_friction", 0.0, 100.0, 0.5, "Move"],
	["Player", "landing_roll", 0.0, 1.0, 0.05, "Move"],
	["Player", "deflect_keep", 0.0, 1.0, 0.05, "Move"],
	["Player", "wall_bounce", 0.0, 1.0, 0.05, "Move"],
	["Player", "wall_kick_up", 0.0, 25.0, 0.5, "Move"],
	["CameraRig", "follow_speed", 1.0, 20.0, 0.25, "Camera"],
	["CameraRig", "base_fov", 40.0, 120.0, 1.0, "Camera"],
	["CameraRig", "fov_per_speed", 0.0, 2.0, 0.05, "Camera"],
	["CameraRig", "max_fov", 60.0, 160.0, 1.0, "Camera"],
	["CameraRig", "offset:y", 0.0, 8.0, 0.25, "Camera"],
	["CameraRig", "offset:z", 2.0, 15.0, 0.25, "Camera"],
	["CameraRig", "look_ahead:y", -5.0, 10.0, 0.25, "Camera"],
	["CameraRig", "anchor_look_weight", 0.0, 1.0, 0.05, "Camera"],
	["CameraRig", "roll_per_speed", 0.0, 5.0, 0.1, "Camera"],
	["CameraRig", "max_roll", 0.0, 45.0, 1.0, "Camera"],
	["CameraRig", "shake_strength", 0.0, 3.0, 0.05, "Camera"],
	["CameraRig", "zip_fov_kick", 0.0, 30.0, 1.0, "Camera"],
	["CameraRig", "collision_margin", 0.0, 2.0, 0.1, "Camera"],
	["CameraRig", "ceiling_near", 0.0, 15.0, 0.5, "Camera"],
	["CameraRig", "ceiling_look_up", 0.0, 10.0, 0.5, "Camera"],
	["World/PixelView", "stretch_shrink", 1.0, 6.0, 1.0, "Camera"],
	["Sfx", "volume", 0.0, 1.0, 0.05, "Misc"],
	["Music", "volume", 0.0, 1.0, 0.05, "Misc"],
	["Debug", "shown", 0.0, 1.0, 1.0, "Misc"],
	["Debug", "auto_quality", 0.0, 1.0, 1.0, "Misc"],
	["Debug", "min_fps", 20.0, 60.0, 1.0, "Misc"],
	["Effects", "haptics", 0.0, 1.0, 1.0, "Misc"],
	["Effects", "hit_stop_time", 0.0, 0.2, 0.01, "Misc"],
	["Effects", "streak_speed", 5.0, 100.0, 1.0, "Misc"],
	["World/SpeedLines", "start_speed", 5.0, 100.0, 1.0, "Misc"],
	# Cave editor: the halls of the loaded level (not saved as tuning).
	["CaveEditor", "hall", 0.0, 11.0, 1.0, "Cave"],
	["CaveEditor", "length", 20.0, 200.0, 5.0, "Cave"],
	["CaveEditor", "width", 20.0, 120.0, 2.0, "Cave"],
	["CaveEditor", "shift", -40.0, 40.0, 2.0, "Cave"],
	["CaveEditor", "ceiling", 12.0, 60.0, 1.0, "Cave"],
	["CaveEditor", "open", 0.0, 1.0, 1.0, "Cave"],
	["CaveEditor", "floater_spacing", 0.0, 40.0, 1.0, "Cave"],
	["CaveEditor", "floater_height", -1.0, 60.0, 1.0, "Cave"],
	["CaveEditor", "floater_size", 1.0, 8.0, 0.25, "Cave"],
	["CaveEditor", "slick_walls", 0.0, 1.0, 1.0, "Cave"],
	["CaveEditor", "floor", 0.0, 2.0, 1.0, "Cave"],
	["CaveEditor", "stalactites", 0.0, 1.5, 0.05, "Cave"],
	["CaveEditor", "pillars", 0.0, 8.0, 1.0, "Cave"],
	["CaveEditor", "islands", 0.0, 8.0, 1.0, "Cave"],
	["CaveEditor", "outcrops", 0.0, 1.0, 0.05, "Cave"],
	["CaveEditor", "crystals", 0.0, 10.0, 1.0, "Cave"],
	["CaveEditor", "shafts", 0.0, 5.0, 1.0, "Cave"],
	["CaveEditor", "ice", 0.0, 1.0, 0.05, "Cave"],
	["CaveEditor", "rings", 0.0, 8.0, 1.0, "Cave"],
	["CaveEditor", "updrafts", 0.0, 5.0, 1.0, "Cave"],
	["CaveEditor", "bouncers", 0.0, 6.0, 1.0, "Cave"],
	["CaveEditor", "shortcut", 0.0, 12.0, 1.0, "Cave"],
	["CaveEditor", "dark", 0.0, 1.0, 1.0, "Cave"],
	["CaveEditor", "checkpoint", 0.0, 1.0, 1.0, "Cave"],
	["CaveEditor", "halls", 1.0, 12.0, 1.0, "Cave"],
	["CaveEditor", "seed", 1.0, 999.0, 1.0, "Cave"],
]
## The cave editor's tab: live values of the loaded level, never saved or
## reset as tuning.
const CAVE_TAB := "Cave"

## Tabs whose values change the play (and mark records with TUNE*).
const GAMEPLAY_TABS := ["Throw", "Rope", "Move"]

const FONT_SIZE := 26
const ROW_HEIGHT := 52.0
const LABEL_WIDTH := 340.0

var _defaults := {}
var _sliders := {}
var _labels := {}
var _panel: PanelContainer
var _toggle: Button
var _last_throw: Label
var _copy: Button
var _copy_layout: Button
var _illustration: TuningIllustration
var _info_title: Label
var _info_text: Label
## Key of the slider explained at the top.
var _selected := ""
## Pause state before the panel opened (the level menu may pause, too).
var _was_paused := false
## Active tuning set (SLOTS) and its buttons.
var _slot := "A"
var _slot_buttons := {}
var _paste: Button
var _awaiting_paste := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	for p in PARAMS:
		_defaults[_key(p)] = _target(p).get_indexed(p[1])
	_build_ui()
	_load()
	_select(PARAMS[0])
	var editor := get_parent().get_node_or_null("CaveEditor")
	if editor:
		editor.changed.connect(_refresh_cave)


func _key(p: Array) -> String:
	return "%s/%s" % [p[0], p[1]]


func _target(p: Array) -> Node:
	return get_parent().get_node(p[0] as String)


func _set_value(p: Array, value: float) -> void:
	_target(p).set_indexed(p[1], value)
	_show_value(p, value)


func _show_value(p: Array, value: float) -> void:
	_labels[_key(p)].text = "%s  %s" % [_title(p), _format(p, value)]
	if _key(p) == _selected:
		_explain(p)


## The cave editor changed (level loaded, hall picked, cave rebuilt): the
## Cave sliders show the selected hall.
func _refresh_cave() -> void:
	for p in PARAMS:
		if p[5] != CAVE_TAB:
			continue
		var slider: HSlider = _sliders[_key(p)]
		if p[1] == "hall":
			slider.max_value = maxf(float(_target(p).get("halls")) - 1.0, 0.0)
		slider.set_value_no_signal(float(_target(p).get(p[1])))
		_show_value(p, slider.value)

## Plain name of a slider (TuningInfo), the property name as a fallback.
func _title(p: Array) -> String:
	return TuningInfo.PARAMS.get(_key(p), [p[1]])[0]


func _format(p: Array, value: float) -> String:
	var unit: String = TuningInfo.PARAMS.get(_key(p), ["", ""])[1]
	match unit:
		"switch":
			return "on" if value >= 0.5 else "off"
		"floor":
			return CaveEditor.FLOORS[clampi(int(value), 0, 2)]
		"hall":
			return "%d of %d" % [int(value) + 1, int(_target(p).get("halls"))]
		"m auto":
			return "auto" if value < 0.0 else "%s m" % str(snappedf(value, p[4]))
	return ("%s %s" % [str(snappedf(value, p[4])), unit]).strip_edges()


## Shows what the slider does: name, explanation and the animated sketch.
func _select(p: Array) -> void:
	if _selected != "" and _labels.has(_selected):
		_labels[_selected].remove_theme_color_override("font_color")
	_selected = _key(p)
	_labels[_selected].add_theme_color_override("font_color", Color(0.91, 0.77, 0.28))
	_explain(p)


func _explain(p: Array) -> void:
	var info: Array = TuningInfo.PARAMS.get(_key(p), [p[1], "", "", ""])
	_info_title.text = "%s  %s" % [info[0], _format(p, _sliders[_key(p)].value)]
	_info_text.text = "%s\n%s" % [info[3], _key(p)]
	var current := {}
	for q in PARAMS:
		current[_key(q)] = _sliders[_key(q)].value
	var editor := get_parent().get_node_or_null("CaveEditor")
	if editor:
		current["cave_segments"] = editor.segments
		current["cave_hall"] = editor.selected_hall
	_illustration.show_param(_key(p), info[2], _sliders[_key(p)].value, current)


func selected_key() -> String:
	return _selected


# --- UI -------------------------------------------------------------------------

func _build_ui() -> void:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE
	theme.set_icon("grabber", "HSlider", _circle_texture(40, Color(0.91, 0.77, 0.28)))
	theme.set_icon("grabber_highlight", "HSlider", _circle_texture(40, Color(1.0, 0.88, 0.45)))
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.25)
	track.content_margin_top = 6.0
	track.content_margin_bottom = 6.0
	theme.set_stylebox("slider", "HSlider", track)

	_toggle = Button.new()
	_toggle.text = "TUNE"
	_toggle.theme = theme
	_toggle.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_toggle.offset_left = -136.0
	_toggle.offset_right = -16.0
	_toggle.offset_top = 44.0
	_toggle.offset_bottom = 104.0
	_toggle.pressed.connect(_set_open.bind(true))
	_toggle.add_to_group(InputRouter.BLOCKING_GUI_GROUP)
	add_child(_toggle)

	_panel = PanelContainer.new()
	_panel.theme = theme
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 12.0
	_panel.offset_right = -12.0
	_panel.offset_top = 120.0
	_panel.offset_bottom = -12.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.08, 0.88)
	bg.set_corner_radius_all(12)
	bg.set_content_margin_all(20.0)
	_panel.add_theme_stylebox_override("panel", bg)
	_panel.visible = false
	_panel.add_to_group(InputRouter.BLOCKING_GUI_GROUP)
	add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	_panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "Tuning"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_copy = Button.new()
	_copy.text = "Copy"
	_copy.custom_minimum_size = Vector2(120, ROW_HEIGHT)
	# Arm on press: the copy itself runs in the browser's touchend handler.
	_copy.button_down.connect(_copy_values)
	header.add_child(_copy)
	var reset := Button.new()
	reset.text = "Reset"
	reset.custom_minimum_size = Vector2(120, ROW_HEIGHT)
	reset.pressed.connect(_reset)
	header.add_child(reset)
	var close := Button.new()
	close.text = "Play"
	close.custom_minimum_size = Vector2(120, ROW_HEIGHT)
	close.pressed.connect(_set_open.bind(false))
	header.add_child(close)

	# Tuning sets: tap to switch; a set used for the first time starts as a
	# copy of the current values. "Paste" takes values copied with "Copy".
	var sets := HBoxContainer.new()
	root.add_child(sets)
	var sets_label := Label.new()
	sets_label.text = "Set"
	sets_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sets.add_child(sets_label)
	for slot: String in SLOTS:
		var button := Button.new()
		button.text = slot
		button.custom_minimum_size = Vector2(90, ROW_HEIGHT)
		button.pressed.connect(switch_slot.bind(slot))
		sets.add_child(button)
		_slot_buttons[slot] = button
	_paste = Button.new()
	_paste.text = "Paste"
	_paste.custom_minimum_size = Vector2(120, ROW_HEIGHT)
	_paste.button_down.connect(func() -> void:
		Clipboard.request_paste("Paste tuning values (from Copy):")
		_awaiting_paste = true)
	sets.add_child(_paste)

	_last_throw = Label.new()
	_last_throw.add_theme_font_size_override("font_size", 22)
	root.add_child(_last_throw)

	# What the selected slider does: sketch, name and explanation.
	_illustration = TuningIllustration.new()
	root.add_child(_illustration)
	_info_title = Label.new()
	_info_title.add_theme_color_override("font_color", Color(0.91, 0.77, 0.28))
	root.add_child(_info_title)
	_info_text = Label.new()
	_info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_text.add_theme_font_size_override("font_size", 20)
	# Fixed height: the rows below must not jump when the text changes.
	_info_text.custom_minimum_size = Vector2(0, 104)
	_info_text.max_lines_visible = 4
	_info_text.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_info_text.modulate = Color(1, 1, 1, 0.8)
	root.add_child(_info_text)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	var tab_rows := {}
	for p in PARAMS:
		var tab_name: String = p[5]
		if not tab_rows.has(tab_name):
			var scroll := ScrollContainer.new()
			scroll.name = tab_name
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			tabs.add_child(scroll)
			var rows := VBoxContainer.new()
			rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rows.add_theme_constant_override("separation", 4)
			scroll.add_child(rows)
			tab_rows[tab_name] = rows
		_add_row(tab_rows[tab_name], p)
	if tab_rows.has(CAVE_TAB):
		var buttons := HBoxContainer.new()
		_copy_layout = Button.new()
		_copy_layout.text = "Copy layout"
		_copy_layout.custom_minimum_size = Vector2(200, ROW_HEIGHT)
		_copy_layout.button_down.connect(func() -> void:
			_copy_text(get_parent().get_node("CaveEditor").layout_text(), _copy_layout, "Copy layout"))
		buttons.add_child(_copy_layout)
		var reset_cave := Button.new()
		reset_cave.text = "Reset cave"
		reset_cave.custom_minimum_size = Vector2(200, ROW_HEIGHT)
		reset_cave.pressed.connect(func() -> void: get_parent().get_node("CaveEditor").reset_cave())
		buttons.add_child(reset_cave)
		tab_rows[CAVE_TAB].add_child(buttons)
		tab_rows[CAVE_TAB].move_child(buttons, 0)
	# A new tab explains its first slider.
	tabs.tab_changed.connect(func(index: int) -> void:
		var tab_name := tabs.get_tab_control(index).name
		for p in PARAMS:
			if p[5] == tab_name:
				_select(p)
				return)


func _add_row(rows: VBoxContainer, p: Array) -> void:
	var row := HBoxContainer.new()
	rows.add_child(row)
	var label := Label.new()
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	label.add_theme_font_size_override("font_size", 22)
	label.clip_text = true
	# Tap the name to see what it does.
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
			_select(p))
	row.add_child(label)
	_labels[_key(p)] = label
	var slider := HSlider.new()
	slider.min_value = p[2]
	slider.max_value = p[3]
	slider.step = p[4]
	slider.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = _defaults[_key(p)]
	slider.value_changed.connect(func(v: float) -> void: _set_value(p, v))
	slider.drag_started.connect(_select.bind(p))
	slider.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed and _selected != _key(p):
			_select(p))
	row.add_child(slider)
	_sliders[_key(p)] = slider
	if p[5] == CAVE_TAB:
		_show_value(p, slider.value)
	else:
		_set_value(p, slider.value)


func _circle_texture(diameter: int, color: Color) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var r := diameter / 2.0
	for y in diameter:
		for x in diameter:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			img.set_pixel(x, y, Color(color, clampf(r - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


func _set_open(open: bool) -> void:
	if open:
		var p := get_parent().get_node("Player")
		_last_throw.text = "Last throw: finger %d px/s -> hook %.0f m/s" % [p.last_throw_flick, p.last_throw_speed]
	if open:
		_was_paused = get_tree().paused
	_panel.visible = open
	_toggle.visible = not open
	get_tree().paused = open or _was_paused
	if not open:
		_save()
	_update_toggle_text()


## "TUNE*" shows that saved values differ from the defaults in the code.
func _update_toggle_text() -> void:
	_toggle.text = "TUNE*" if is_tuned() else "TUNE"


## Some value that changes the play differs from its code default: records
## get marked (TUNE*). Camera, sound and debug settings do not count.
func is_tuned() -> bool:
	for p in PARAMS:
		if p[5] in GAMEPLAY_TABS and not _is_default(p):
			return true
	return false


func _is_default(p: Array) -> bool:
	if p[5] == CAVE_TAB:
		return true
	return is_equal_approx(_sliders[_key(p)].value, snappedf(_defaults[_key(p)], p[4]))


## Tuned values as text, to send them to Claude without a screenshot.
func values_text() -> String:
	var lines: PackedStringArray = []
	for p in PARAMS:
		if not _is_default(p):
			lines.append("%s = %s (default %s)" % [_key(p), str(snappedf(_sliders[_key(p)].value, p[4])), str(snappedf(_defaults[_key(p)], p[4]))])
	if lines.is_empty():
		return "Grappling Cave tuning: all values at default"
	return "Grappling Cave tuning:\n" + "\n".join(lines)


func _copy_values() -> void:
	_copy_text(values_text(), _copy, "Copy")


func _copy_text(text: String, button: Button, label: String) -> void:
	Clipboard.copy(text)
	_flash(button, "Copied", label)


## Shows a short message on a button, then its label again.
func _flash(button: Button, message: String, label: String) -> void:
	button.text = message
	get_tree().create_timer(1.5, true, false, true).timeout.connect(func() -> void: button.text = label)


func _reset() -> void:
	apply_values({})


func _process(_delta: float) -> void:
	if not _awaiting_paste:
		return
	var text: Variant = Clipboard.take_paste()
	if text == null:
		return
	_awaiting_paste = false
	var values := parse_values(text)
	if values.is_empty():
		_flash(_paste, "No values", "Paste")
		return
	apply_values(values)
	_flash(_paste, "%d set" % values.size(), "Paste")


## The saved values again (after a backup was restored): defaults, then the
## file, and the active tuning set.
func reload_saved() -> void:
	for p in PARAMS:
		if p[5] != CAVE_TAB:
			_sliders[_key(p)].value = _defaults[_key(p)]
	_load()


## Every tuning value at its default, except the given ones (key -> value).
func apply_values(values: Dictionary) -> void:
	for p in PARAMS:
		if p[5] != CAVE_TAB:
			_sliders[_key(p)].value = values.get(_key(p), _defaults[_key(p)])
	_save()
	_update_toggle_text()


## The values that differ from the defaults (key -> value).
func tuned_values() -> Dictionary:
	var values := {}
	for p in PARAMS:
		if not _is_default(p):
			values[_key(p)] = _sliders[_key(p)].value
	return values


## Tuning values in a text: the lines of "Copy" ("Player/gravity = 30 (default
## 43)") or a list like "Player gravity 30, floor_friction 76, CameraRig base_fov 61"
## (a node name holds for the values after it). Unknown names are skipped.
func parse_values(text: String) -> Dictionary:
	var nodes := {}
	for p in PARAMS:
		if p[5] != CAVE_TAB:
			nodes[p[0]] = p[0]
			nodes[(p[0] as String).get_file()] = p[0]
	var names: Array = nodes.keys()
	# Longest first: "World/SpeedLines" before "World".
	names.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	var entry := RegEx.create_from_string("^([a-z_]+(?::[a-z])?)\\s*[=:]?\\s*(-?\\d+(?:\\.\\d+)?)")
	var values := {}
	var node := ""
	for token in text.replace(";", "\n").replace(",", "\n").split("\n"):
		var rest := token.strip_edges()
		for node_name: String in names:
			if rest.begins_with(node_name + " ") or rest.begins_with(node_name + "/"):
				node = nodes[node_name]
				rest = rest.substr(node_name.length() + 1).strip_edges()
				break
		var found := entry.search(rest)
		if found == null or node == "":
			continue
		var key := "%s/%s" % [node, found.get_string(1)]
		if _sliders.has(key) and not key.begins_with("CaveEditor/"):
			values[key] = found.get_string(2).to_float()
	return values


## Switches to another tuning set: the current values are kept in their
## set, the other set's values come in (a new set copies the current ones).
func switch_slot(slot: String) -> void:
	if slot == _slot or slot not in SLOTS:
		return
	var cfg := ConfigFile.new()
	cfg.load(PRESETS_PATH)
	_store_slot(cfg, _slot)
	if cfg.has_section_key("used", slot):
		var values := {}
		for key: String in _slot_keys(cfg, slot):
			# A value tuned against an older default is dropped, as in _load().
			if _defaults.has(key) and is_equal_approx(cfg.get_value("defaults_" + slot, key, INF), _defaults[key]):
				values[key] = cfg.get_value("slot_" + slot, key)
		apply_values(values)
	_slot = slot
	_store_slot(cfg, slot)
	cfg.set_value("active", "slot", slot)
	cfg.save(PRESETS_PATH)
	_update_slots()


func active_slot() -> String:
	return _slot


func _store_slot(cfg: ConfigFile, slot: String) -> void:
	for section in ["slot_" + slot, "defaults_" + slot]:
		if cfg.has_section(section):
			cfg.erase_section(section)
	var values := tuned_values()
	for key: String in values:
		cfg.set_value("slot_" + slot, key, values[key])
		cfg.set_value("defaults_" + slot, key, _defaults[key])
	cfg.set_value("used", slot, true)


func _slot_keys(cfg: ConfigFile, slot: String) -> PackedStringArray:
	return cfg.get_section_keys("slot_" + slot) if cfg.has_section("slot_" + slot) else PackedStringArray()


func _update_slots() -> void:
	for slot: String in _slot_buttons:
		var button: Button = _slot_buttons[slot]
		if slot == _slot:
			button.add_theme_color_override("font_color", Color(0.91, 0.77, 0.28))
			button.add_theme_color_override("font_hover_color", Color(0.91, 0.77, 0.28))
		else:
			button.remove_theme_color_override("font_color")
			button.remove_theme_color_override("font_hover_color")


# --- Persistence --------------------------------------------------------------

func _save() -> void:
	var cfg := ConfigFile.new()
	for p in PARAMS:
		if not _is_default(p):
			cfg.set_value(SECTION, _key(p), _sliders[_key(p)].value)
			cfg.set_value(DEFAULTS_SECTION, _key(p), _defaults[_key(p)])
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		for p in PARAMS:
			var key := _key(p)
			if cfg.has_section_key(SECTION, key) and cfg.has_section_key(DEFAULTS_SECTION, key) \
					and is_equal_approx(cfg.get_value(DEFAULTS_SECTION, key), _defaults[key]):
				_sliders[key].value = cfg.get_value(SECTION, key)
	elif cfg.load(LEGACY_SAVE_PATH) == OK:
		for p in PARAMS:
			var key := _key(p)
			if not cfg.has_section_key(SECTION, key):
				continue
			var value: float = cfg.get_value(SECTION, key)
			if LEGACY_DEFAULTS.has(key) and is_equal_approx(value, LEGACY_DEFAULTS[key]):
				continue
			_sliders[key].value = value
	var presets := ConfigFile.new()
	if presets.load(PRESETS_PATH) == OK:
		_slot = presets.get_value("active", "slot", "A")
	_update_slots()
	_update_toggle_text()
