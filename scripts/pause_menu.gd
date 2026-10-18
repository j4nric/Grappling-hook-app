extends CanvasLayer
## Pause: a small button in the HUD and an overlay with the level's medal
## targets, Continue / Restart / Levels, the ghost and sound switches, and
## Share run / Load run (the best run as a code for a friend, a friend's run
## as the orange rival ghost).
## Opens on its own when the app loses focus (tab switch, home screen), so
## the run timer never counts time the player was away.

signal restart_pressed
signal levels_pressed
## Share run: the game copies the code (armed on button_down, see Clipboard).
signal share_requested
## Load run: the text the player pasted.
signal run_code_entered(text: String)
## Another outfit was picked (Settings.outfit holds its name).
signal outfit_changed

const FONT_SIZE := 34

var _button: Button
var _panel: PanelContainer
var _info: Label
var _ghost_toggle: Button
var _sound_toggle: Button
var _gold_toggle: Button
var _outfit_button: Button
## Unlocked outfit names, looked up when the menu opens.
var _outfits: Array[String] = ["Classic"]
var _status: Label
var _awaiting_paste := false
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
	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_font_size_override("font_size", 26)
	_info.modulate = Color(1, 1, 1, 0.8)
	box.add_child(_info)
	for entry in [["Continue", close], ["Restart", _on_restart], ["Levels", _on_levels]]:
		box.add_child(_make_button(entry[0], entry[1]))
	var switches := HBoxContainer.new()
	switches.add_theme_constant_override("separation", 16)
	box.add_child(switches)
	_ghost_toggle = _make_button("", _on_ghost_toggle)
	_sound_toggle = _make_button("", _on_sound_toggle)
	_gold_toggle = _make_button("", _on_gold_toggle)
	for toggle in [_ghost_toggle, _gold_toggle, _sound_toggle]:
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		switches.add_child(toggle)
	_outfit_button = _make_button("", next_outfit)
	box.add_child(_outfit_button)
	var sharing := HBoxContainer.new()
	sharing.add_theme_constant_override("separation", 16)
	box.add_child(sharing)
	var share := _make_button("Share run", func() -> void: pass)
	share.button_down.connect(func() -> void: share_requested.emit())
	var load_run := _make_button("Load run", func() -> void: pass)
	load_run.button_down.connect(func() -> void:
		Clipboard.request_paste("Paste a run code from a friend:")
		_awaiting_paste = true)
	for button in [share, load_run]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sharing.add_child(button)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 24)
	_status.add_theme_color_override("font_color", Color(1.0, 0.65, 0.35))
	box.add_child(_status)
	_update_toggles()


func _process(_delta: float) -> void:
	if not _awaiting_paste:
		return
	var text: Variant = Clipboard.take_paste()
	if text == null:
		return
	_awaiting_paste = false
	if text != "":
		run_code_entered.emit(text)


## A short message under the buttons (run copied, rival loaded, ...).
func show_status(text: String) -> void:
	_status.text = text


## Level name, best time and medal targets, shown above the buttons.
func set_info(text: String) -> void:
	_info.text = text


func is_open() -> bool:
	return _panel.visible


func open() -> void:
	if _panel.visible:
		return
	_was_paused = get_tree().paused
	_status.text = ""
	_outfits = Outfits.unlocked_names(Outfits.best_medals())
	_update_toggles()
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


func _make_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 100)
	b.add_theme_font_size_override("font_size", FONT_SIZE)
	b.pressed.connect(action)
	return b


func _on_ghost_toggle() -> void:
	Settings.ghost_enabled = not Settings.ghost_enabled
	Settings.save_settings()
	_update_toggles()


func _on_gold_toggle() -> void:
	Settings.gold_ghost_enabled = not Settings.gold_ghost_enabled
	Settings.save_settings()
	_update_toggles()


func _on_sound_toggle() -> void:
	Settings.sound_enabled = not Settings.sound_enabled
	Settings.save_settings()
	_update_toggles()


func _update_toggles() -> void:
	_ghost_toggle.text = "Ghost: %s" % ("on" if Settings.ghost_enabled else "off")
	_gold_toggle.text = "Gold: %s" % ("on" if Settings.gold_ghost_enabled else "off")
	_sound_toggle.text = "Sound: %s" % ("on" if Settings.sound_enabled else "off")
	_outfit_button.text = "Outfit: %s  (%d of %d)" % [Settings.outfit, _outfits.size(), Outfits.LIST.size()]


## Next unlocked outfit; shows what the next locked one needs.
func next_outfit() -> void:
	var at := _outfits.find(Settings.outfit)
	Settings.outfit = _outfits[(at + 1) % _outfits.size()]
	Settings.save_settings()
	_update_toggles()
	outfit_changed.emit()
	if _outfits.size() < Outfits.LIST.size():
		var locked: Dictionary = Outfits.LIST[_outfits.size()]
		for outfit: Dictionary in Outfits.LIST:
			if outfit.name not in _outfits:
				locked = outfit
				break
		show_status("Next outfit \"%s\": %s" % [locked.name, Outfits.requirement(locked)])


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
