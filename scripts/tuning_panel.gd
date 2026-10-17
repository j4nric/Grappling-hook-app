extends CanvasLayer
## Debug overlay with sliders for the feel-relevant @export values, so the
## swing can be tuned on the phone without a new build. Opening it pauses the
## game. Values persist in user:// (IndexedDB in the browser).
## The GUI handles its own input; gameplay input still only runs through
## InputRouter.

## Bump the file name when the meaning of values changes, old values are ignored.
const SAVE_PATH := "user://tuning_v2.cfg"
const SECTION := "tuning"

## [node path relative to the parent, property path, min, max, step]
const PARAMS := [
	["Player", "gravity", 5.0, 60.0, 0.5],
	["Player", "max_speed", 10.0, 120.0, 1.0],
	["Player", "throw_speed_per_px", 0.002, 0.03, 0.001],
	["Player", "hook_min_speed", 0.0, 40.0, 1.0],
	["Player", "hook_max_speed", 10.0, 150.0, 1.0],
	["Player", "hook_gravity", 0.0, 80.0, 1.0],
	["Player", "throw_pitch", 0.0, 90.0, 1.0],
	["Player", "throw_yaw_gain", 0.0, 2.0, 0.05],
	["Player", "max_rope_length", 10.0, 100.0, 1.0],
	["Player", "reel_speed", 0.0, 40.0, 0.5],
	["Player", "min_rope_length", 0.5, 15.0, 0.25],
	["Player", "tension_boost", 0.0, 40.0, 0.5],
	["CameraRig", "follow_speed", 1.0, 20.0, 0.25],
	["CameraRig", "base_fov", 40.0, 120.0, 1.0],
	["CameraRig", "fov_per_speed", 0.0, 2.0, 0.05],
	["CameraRig", "max_fov", 60.0, 140.0, 1.0],
	["CameraRig", "offset:y", 0.0, 8.0, 0.25],
	["CameraRig", "offset:z", 2.0, 15.0, 0.25],
]

const FONT_SIZE := 26
const ROW_HEIGHT := 52.0
const LABEL_WIDTH := 340.0

var _defaults := {}
var _sliders := {}
var _labels := {}
var _panel: PanelContainer
var _toggle: Button


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

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 4)
	scroll.add_child(rows)

	for p in PARAMS:
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
	_panel.visible = open
	_toggle.visible = not open
	get_tree().paused = open
	if not open:
		_save()


func _reset() -> void:
	for p in PARAMS:
		_sliders[_key(p)].value = _defaults[_key(p)]
	_save()


# --- Persistence --------------------------------------------------------------

func _save() -> void:
	var cfg := ConfigFile.new()
	for p in PARAMS:
		cfg.set_value(SECTION, _key(p), _sliders[_key(p)].value)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for p in PARAMS:
		var value = cfg.get_value(SECTION, _key(p), null)
		if value != null:
			_sliders[_key(p)].value = value
