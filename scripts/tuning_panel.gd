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

## [node path relative to the parent, property path, min, max, step, tab]
const PARAMS := [
	["Player", "throw_speed_per_px", 0.002, 0.03, 0.001, "Throw"],
	["Player", "hook_min_speed", 0.0, 40.0, 1.0, "Throw"],
	["Player", "hook_max_speed", 10.0, 150.0, 1.0, "Throw"],
	["Player", "hook_gravity", 0.0, 80.0, 1.0, "Throw"],
	["Player", "throw_pitch", 0.0, 90.0, 1.0, "Throw"],
	["Player", "throw_yaw_gain", 0.0, 2.0, 0.05, "Throw"],
	["Player", "max_rope_length", 10.0, 100.0, 1.0, "Throw"],
	["Player", "min_hook_distance", 0.0, 10.0, 0.25, "Throw"],
	["Player", "throw_buffer_time", 0.0, 1.0, 0.05, "Throw"],
	["Player", "aim_preview_speed", 5.0, 100.0, 1.0, "Throw"],
	["Player", "aim_assist_angle", 0.0, 30.0, 1.0, "Throw"],
	["Player", "aim_time_scale", 0.1, 1.0, 0.05, "Throw"],
	["Player", "pull_impulse", 0.0, 30.0, 0.5, "Rope"],
	["Player", "reel_speed", 0.0, 40.0, 0.5, "Rope"],
	["Player", "reel_acceleration", 0.0, 150.0, 1.0, "Rope"],
	["Player", "reel_max_speed", 5.0, 80.0, 1.0, "Rope"],
	["Player", "tension_boost", 0.0, 40.0, 0.5, "Rope"],
	["Player", "min_rope_length", 0.0, 15.0, 0.25, "Rope"],
	["Player", "zip_release_distance", 0.0, 10.0, 0.25, "Rope"],
	["Player", "zip_boost", 0.0, 20.0, 0.5, "Rope"],
	["Player", "flyby_release_distance", 0.0, 15.0, 0.5, "Rope"],
	["Player", "swing_time", 0.0, 1.0, 0.05, "Rope"],
	["Player", "contact_release_grace", 0.0, 1.0, 0.05, "Rope"],
	["Player", "gravity", 5.0, 60.0, 0.5, "Move"],
	["Player", "max_speed", 10.0, 120.0, 1.0, "Move"],
	["Player", "floor_friction", 0.0, 100.0, 1.0, "Move"],
	["Player", "slide_friction", 0.0, 50.0, 0.5, "Move"],
	["Player", "landing_roll", 0.0, 1.0, 0.05, "Move"],
	["Player", "deflect_keep", 0.0, 1.0, 0.05, "Move"],
	["Player", "wall_bounce", 0.0, 1.0, 0.05, "Move"],
	["Player", "wall_kick_up", 0.0, 15.0, 0.5, "Move"],
	["CameraRig", "follow_speed", 1.0, 20.0, 0.25, "Camera"],
	["CameraRig", "base_fov", 40.0, 120.0, 1.0, "Camera"],
	["CameraRig", "fov_per_speed", 0.0, 2.0, 0.05, "Camera"],
	["CameraRig", "max_fov", 60.0, 140.0, 1.0, "Camera"],
	["CameraRig", "offset:y", 0.0, 8.0, 0.25, "Camera"],
	["CameraRig", "offset:z", 2.0, 15.0, 0.25, "Camera"],
	["CameraRig", "look_ahead:y", -5.0, 10.0, 0.25, "Camera"],
	["CameraRig", "anchor_look_weight", 0.0, 1.0, 0.05, "Camera"],
	["CameraRig", "roll_per_speed", 0.0, 5.0, 0.1, "Camera"],
	["CameraRig", "max_roll", 0.0, 45.0, 1.0, "Camera"],
	["CameraRig", "shake_strength", 0.0, 2.0, 0.05, "Camera"],
	["World/PixelView", "stretch_shrink", 1.0, 6.0, 1.0, "Camera"],
	["Sfx", "volume", 0.0, 1.0, 0.05, "Misc"],
	["Debug", "shown", 0.0, 1.0, 1.0, "Misc"],
	["Debug", "auto_quality", 0.0, 1.0, 1.0, "Misc"],
	["Debug", "min_fps", 20.0, 60.0, 1.0, "Misc"],
	["Effects", "haptics", 0.0, 1.0, 1.0, "Misc"],
]

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
## Pause state before the panel opened (the level menu may pause, too).
var _was_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	for p in PARAMS:
		_defaults[_key(p)] = _target(p).get_indexed(p[1])
	_build_ui()
	_load()


func _key(p: Array) -> String:
	return "%s/%s" % [p[0], p[1]]


func _target(p: Array) -> Node:
	return get_parent().get_node(p[0] as String)


func _set_value(p: Array, value: float) -> void:
	_target(p).set_indexed(p[1], value)
	var prefix := "cam " if p[0] == "CameraRig" else ""
	_labels[_key(p)].text = "%s%s  %s" % [prefix, p[1], str(snappedf(value, p[4]))]


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

	_last_throw = Label.new()
	_last_throw.add_theme_font_size_override("font_size", 22)
	root.add_child(_last_throw)

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


func _add_row(rows: VBoxContainer, p: Array) -> void:
	var row := HBoxContainer.new()
	rows.add_child(row)
	var label := Label.new()
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	label.add_theme_font_size_override("font_size", 22)
	label.clip_text = true
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
	row.add_child(slider)
	_sliders[_key(p)] = slider
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
	var tuned := false
	for p in PARAMS:
		if not _is_default(p):
			tuned = true
	_toggle.text = "TUNE*" if tuned else "TUNE"


func _is_default(p: Array) -> bool:
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
	var text := values_text()
	if OS.has_feature("web"):
		# Browsers (iOS Safari above all) only allow clipboard writes inside a
		# real input event handler. Godot handles input a frame later, so the
		# write is armed now and runs when the finger lifts.
		JavaScriptBridge.eval("""
			window.gcCopyText = %s;
			const gcCopy = () => navigator.clipboard.writeText(window.gcCopyText).catch(() => {});
			window.addEventListener('touchend', gcCopy, {once: true, capture: true});
			window.addEventListener('mouseup', gcCopy, {once: true, capture: true});
		""" % JSON.stringify(text))
	else:
		DisplayServer.clipboard_set(text)
	_copy.text = "Copied"
	get_tree().create_timer(1.5, true, false, true).timeout.connect(func() -> void: _copy.text = "Copy")


func _reset() -> void:
	for p in PARAMS:
		_sliders[_key(p)].value = _defaults[_key(p)]
	_save()
	_update_toggle_text()


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
	_update_toggle_text()
