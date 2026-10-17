extends Node3D
## Level flow: timer, finish detection, fall-out reset, restart, HUD.

## Falling below this Y resets the run.
@export var kill_y := -30.0

@onready var player := $Player
@onready var finish: Area3D = $TestTunnel/Finish
@onready var safe: Control = $HUD/Safe
@onready var time_label: Label = $HUD/Safe/TimeLabel
@onready var best_label: Label = $HUD/Safe/BestLabel
@onready var hint_label: Label = $HUD/Safe/HintLabel
@onready var version_label: Label = $HUD/Safe/VersionLabel
@onready var finish_panel: PanelContainer = $HUD/Safe/FinishPanel

var _start_position := Vector3.ZERO
var _elapsed := 0.0
var _running := false
var _finished := false
var _best := INF
var _touch := DisplayServer.is_touchscreen_available()
var _landscape := false
## The controls hint disappears after the first hook that sticks.
var _hint_dismissed := false


func _ready() -> void:
	_start_position = player.global_position
	finish.body_entered.connect(_on_finish_body_entered)
	player.hook_attached.connect(_on_hook_attached)
	InputRouter.restart_requested.connect(restart)
	InputRouter.throw_requested.connect(_on_any_input)
	InputRouter.release_requested.connect(_on_any_input)
	version_label.text = "build %s" % ProjectSettings.get_setting("application/config/version", "dev")
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.03, 0.05, 0.85)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(24.0)
	finish_panel.add_theme_stylebox_override("panel", panel_style)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	_update_hud()


func _process(delta: float) -> void:
	if _running:
		# Real time: slow motion while aiming must not shorten the run.
		_elapsed += delta / maxf(Engine.time_scale, 0.001)
	if player.global_position.y < kill_y:
		restart()
	time_label.text = "%.2f" % _elapsed
	var size := get_viewport().get_visible_rect().size
	var landscape := size.x > size.y
	if landscape != _landscape:
		_landscape = landscape
		_update_hud()


func restart() -> void:
	player.reset_to(_start_position)
	_elapsed = 0.0
	_running = false
	_finished = false
	_update_hud()


func _on_any_input(_a = null, _b = null, _c = null) -> void:
	if _finished:
		restart()
	elif not _running:
		_running = true


func _on_hook_attached(_point: Vector3, _normal: Vector3) -> void:
	if not _hint_dismissed:
		_hint_dismissed = true
		_update_hud()


func _on_finish_body_entered(body: Node3D) -> void:
	if body != player or _finished:
		return
	_finished = true
	_running = false
	var new_best := _elapsed < _best
	_best = minf(_best, _elapsed)
	finish_panel.get_node("Lines/Time").text = "%.2f s" % _elapsed
	finish_panel.get_node("Lines/Best").text = "New best!" if new_best else "Best: %.2f s" % _best
	finish_panel.get_node("Lines/Again").text = "Tap to play again" if _touch else "Click to play again"
	_update_hud()


func _apply_safe_area() -> void:
	var m := SafeArea.margins(get_viewport())
	safe.offset_left = m.x
	safe.offset_top = m.y
	safe.offset_right = -m.z
	safe.offset_bottom = -m.w


func _update_hud() -> void:
	finish_panel.visible = _finished
	best_label.text = "" if _best == INF else "Best %.2f" % _best
	if _finished:
		hint_label.text = ""
	elif _landscape and _touch:
		hint_label.text = "Hold your phone upright (portrait)"
	elif _hint_dismissed:
		hint_label.text = ""
	elif _touch:
		hint_label.text = "Swipe up and let go: throw hook\nTap: let go   Two-finger tap: restart"
	else:
		hint_label.text = "Drag and release: throw hook   Right click: let go   R: restart"
