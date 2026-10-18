extends CanvasLayer
## Level selection. Shown at the start and from the finish screen; pauses the
## game while open. Emits level_chosen with the index into Levels.LIST.
## The "Stats" button switches to the statistics (sections from the game:
## a title, a line of numbers and the curve of finish times).

signal level_chosen(index: int)
signal stats_requested
## Stats screen "Backup": the game copies the code (armed on button_down).
signal backup_requested
## Stats screen "Restore": the text the player pasted.
signal backup_pasted(text: String)

const FONT_SIZE := 34

var _list: VBoxContainer
var _scroll: ScrollContainer
var _panel: PanelContainer
var _stats_scroll: ScrollContainer
var _stats_list: VBoxContainer
var _stats_button: Button
var _summary: Label
var _backup_row: VBoxContainer
var _backup_status: Label
var _awaiting_paste := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.03, 0.05, 0.98)
	bg.set_content_margin_all(40.0)
	# Room for the TUNE and pause buttons above the title.
	bg.content_margin_top = 90.0
	_panel.add_theme_stylebox_override("panel", bg)
	_panel.add_to_group(InputRouter.BLOCKING_GUI_GROUP)
	add_child(_panel)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 24)
	_panel.add_child(root)
	var title := Label.new()
	title.text = "GRAPPLING CAVE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	root.add_child(title)
	var hint := install_hint()
	if hint != "":
		var install := Label.new()
		install.text = hint
		install.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		install.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		install.add_theme_font_size_override("font_size", 24)
		install.modulate = Color(1, 1, 1, 0.7)
		root.add_child(install)
	# Medals so far and the daily streak.
	_summary = Label.new()
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.add_theme_font_size_override("font_size", 26)
	_summary.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	root.add_child(_summary)
	# Scrolls when the levels do not fit (small phones, landscape).
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_scroll = scroll
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 16)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_stats_scroll = ScrollContainer.new()
	_stats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_stats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stats_scroll.visible = false
	root.add_child(_stats_scroll)
	_stats_list = VBoxContainer.new()
	_stats_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_list.add_theme_constant_override("separation", 8)
	_stats_scroll.add_child(_stats_list)
	# Backup / Restore on the stats screen: all progress as a code.
	_backup_row = VBoxContainer.new()
	var backup_buttons := HBoxContainer.new()
	backup_buttons.add_theme_constant_override("separation", 16)
	_backup_row.add_child(backup_buttons)
	var backup := Button.new()
	backup.text = "Backup"
	backup.button_down.connect(func() -> void: backup_requested.emit())
	var restore := Button.new()
	restore.text = "Restore"
	restore.button_down.connect(func() -> void:
		Clipboard.request_paste("Paste a backup code:")
		_awaiting_paste = true)
	for button: Button in [backup, restore]:
		button.custom_minimum_size = Vector2(0, 80)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 30)
		backup_buttons.add_child(button)
	_backup_status = Label.new()
	_backup_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_backup_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_backup_status.add_theme_font_size_override("font_size", 22)
	_backup_status.add_theme_color_override("font_color", Color(1.0, 0.65, 0.35))
	_backup_status.text = "Backup copies best times, stats and tuning as a code: paste it into the game on another device or in the home screen app."
	_backup_row.add_child(_backup_status)
	_backup_row.visible = false
	root.add_child(_backup_row)
	_stats_button = Button.new()
	_stats_button.custom_minimum_size = Vector2(0, 80)
	_stats_button.add_theme_font_size_override("font_size", 30)
	_stats_button.pressed.connect(_toggle_stats)
	root.add_child(_stats_button)
	visible = false


## In Safari on iPhone/iPad, until the game runs from the home screen: how
## to install it (fullscreen, offline). Empty everywhere else.
static func install_hint() -> String:
	if not OS.has_feature("web"):
		return ""
	var installed = JavaScriptBridge.eval("navigator.standalone === true || matchMedia('(display-mode: standalone), (display-mode: fullscreen)').matches", true)
	var ios = JavaScriptBridge.eval("/iPhone|iPad|iPod/.test(navigator.userAgent) || (navigator.maxTouchPoints > 1 && /Macintosh/.test(navigator.userAgent))", true)
	if installed or not ios:
		return ""
	return "Tip: Share  >  Add to Home Screen\nplays fullscreen and offline"


## The line above the levels (medals, daily streak).
func set_summary(text: String) -> void:
	_summary.text = text


## entries: one Dictionary per level with "name" and optional "detail" and
## "medal" (Records.Medal: a colored mark in front, an empty ring without).
func open(entries: Array) -> void:
	for child in _list.get_children():
		child.queue_free()
	for i in entries.size():
		var button := Button.new()
		var detail: String = entries[i].get("detail", "")
		button.text = "%d  %s%s" % [i + 1, entries[i].name, ("   " + detail) if detail != "" else ""]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.icon = medal_icon(int(entries[i].get("medal", Records.Medal.NONE)))
		button.add_theme_constant_override("h_separation", 16)
		button.custom_minimum_size = Vector2(0, 96)
		button.add_theme_font_size_override("font_size", FONT_SIZE)
		button.pressed.connect(_choose.bind(i))
		# A drag on a button scrolls the list instead of being swallowed.
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		_list.add_child(button)
	_scroll.scroll_vertical = 0
	_show_list(true)
	visible = true
	get_tree().paused = true


## A round mark in the medal's color (an empty ring for none).
static func medal_icon(medal: int) -> ImageTexture:
	var size := 36
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var color: Color = Records.medal_color(medal)
	var r := size / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var a := clampf(r - 1.0 - d, 0.0, 1.0)
			if medal == Records.Medal.NONE:
				# A thin ring.
				a *= clampf(d - (r - 4.0), 0.0, 1.0) * 0.4
			img.set_pixel(x, y, Color(color, a))
	return ImageTexture.create_from_image(img)


func close() -> void:
	visible = false
	get_tree().paused = false


## Shows the statistics instead of the levels: sections {"title", "text",
## "times" (finish times, oldest first; a curve from two on)}.
func show_stats(sections: Array) -> void:
	for child in _stats_list.get_children():
		child.queue_free()
	for section: Dictionary in sections:
		var label := Label.new()
		label.text = ("%s\n%s" % [section.title, section.text]).strip_edges()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 28)
		_stats_list.add_child(label)
		var times: Array = section.get("times", [])
		if times.size() >= 2:
			var curve := Sparkline.new()
			curve.times = times
			_stats_list.add_child(curve)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 16)
		_stats_list.add_child(gap)
	_stats_scroll.scroll_vertical = 0
	_show_list(false)


## The statistics as text (all labels), for tests.
func stats_text() -> String:
	var lines: PackedStringArray = []
	for child in _stats_list.get_children():
		if child is Label and not child.is_queued_for_deletion():
			lines.append(child.text)
	return "\n\n".join(lines)


## Curves shown in the statistics.
func stats_curves() -> Array[Sparkline]:
	var curves: Array[Sparkline] = []
	for child in _stats_list.get_children():
		if child is Sparkline and not child.is_queued_for_deletion():
			curves.append(child)
	return curves


func is_showing_stats() -> bool:
	return _stats_scroll.visible


func _toggle_stats() -> void:
	if is_showing_stats():
		_show_list(true)
	else:
		stats_requested.emit()


func _process(_delta: float) -> void:
	if not _awaiting_paste:
		return
	var text: Variant = Clipboard.take_paste()
	if text == null:
		return
	_awaiting_paste = false
	if text != "":
		backup_pasted.emit(text)


func show_backup_status(text: String) -> void:
	_backup_status.text = text


func _show_list(on: bool) -> void:
	_scroll.visible = on
	_stats_scroll.visible = not on
	_backup_row.visible = not on
	_stats_button.text = "Stats" if on else "Back"


func _choose(index: int) -> void:
	close()
	level_chosen.emit(index)
