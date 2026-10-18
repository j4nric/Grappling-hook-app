extends CanvasLayer
## Level selection. Shown at the start and from the finish screen; pauses the
## game while open. Emits level_chosen with the index into Levels.LIST.
## The "Stats" button switches to the statistics (sections from the game:
## a title, a line of numbers and the curve of finish times).

signal level_chosen(index: int)
signal stats_requested

const FONT_SIZE := 34

var _list: VBoxContainer
var _scroll: ScrollContainer
var _panel: PanelContainer
var _stats_scroll: ScrollContainer
var _stats_list: VBoxContainer
var _stats_button: Button


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


## entries: one Dictionary per level with "name" and optional "detail".
func open(entries: Array) -> void:
	for child in _list.get_children():
		child.queue_free()
	for i in entries.size():
		var button := Button.new()
		var detail: String = entries[i].get("detail", "")
		button.text = "%d  %s%s" % [i + 1, entries[i].name, ("   " + detail) if detail != "" else ""]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
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


func _show_list(on: bool) -> void:
	_scroll.visible = on
	_stats_scroll.visible = not on
	_stats_button.text = "Stats" if on else "Back"


func _choose(index: int) -> void:
	close()
	level_chosen.emit(index)
