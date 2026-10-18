extends CanvasLayer
## Pause: a small button in the HUD and an overlay with Continue / Restart /
## Levels. Opens on its own when the app loses focus (tab switch, home
## screen), so the run timer never counts time the player was away.

signal restart_pressed
signal levels_pressed

const FONT_SIZE := 34

var _button: Button
var _panel: PanelContainer
## Pause state found when opening (the level menu may already pause).
var _was_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 6
	_button = Button.new()
	_button.text = "II"
	_button.add_theme_font_size_override("font_size", 28)
	_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_button.offset_left = -232.0
	_button.offset_right = -152.0
	_button.offset_top = 44.0
	_button.offset_bottom = 104.0
	_button.pressed.connect(open)
	_button.add_to_group(InputRouter.BLOCKING_GUI_GROUP)
	add_child(_button)

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.02, 0.04, 0.8)
	bg.set_content_margin_all(60.0)
	_panel.add_theme_stylebox_override("panel", bg)
	_panel.add_to_group(InputRouter.BLOCKING_GUI_GROUP)
	_panel.visible = false
	add_child(_panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	_panel.add_child(box)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	box.add_child(title)
	for entry in [["Continue", close], ["Restart", _on_restart], ["Levels", _on_levels]]:
		var b := Button.new()
		b.text = entry[0]
		b.custom_minimum_size = Vector2(0, 100)
		b.add_theme_font_size_override("font_size", FONT_SIZE)
		b.pressed.connect(entry[1])
		box.add_child(b)


func is_open() -> bool:
	return _panel.visible


func open() -> void:
	if _panel.visible:
		return
	_was_paused = get_tree().paused
	_panel.visible = true
	_button.visible = false
	get_tree().paused = true


func close() -> void:
	if not _panel.visible:
		return
	_panel.visible = false
	_button.visible = true
	get_tree().paused = _was_paused


func set_button_visible(shown: bool) -> void:
	_button.visible = shown and not _panel.visible


func _on_restart() -> void:
	close()
	restart_pressed.emit()


func _on_levels() -> void:
	close()
	levels_pressed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if not get_tree().paused:
			open()
