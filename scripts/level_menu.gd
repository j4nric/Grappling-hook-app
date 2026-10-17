extends CanvasLayer
## Level selection. Shown at the start and from the finish screen; pauses the
## game while open. Emits level_chosen with the index into Levels.LIST.

signal level_chosen(index: int)

const FONT_SIZE := 34

var _list: VBoxContainer
var _panel: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.03, 0.05, 0.92)
	bg.set_content_margin_all(40.0)
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
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 16)
	root.add_child(_list)
	visible = false


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
		_list.add_child(button)
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


func _choose(index: int) -> void:
	close()
	level_chosen.emit(index)
