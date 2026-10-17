extends Node3D
## Level flow: timer, finish detection, fall-out reset, restart.

## Falling below this Y resets the run.
@export var kill_y := -30.0

@onready var player := $Player
@onready var finish: Area3D = $TestTunnel/Finish
@onready var time_label: Label = $HUD/TimeLabel
@onready var hint_label: Label = $HUD/HintLabel
@onready var version_label: Label = $HUD/VersionLabel

var _start_position := Vector3.ZERO
var _elapsed := 0.0
var _running := false
var _finished := false
var _best := INF
var _touch := DisplayServer.is_touchscreen_available()
var _landscape := false


func _ready() -> void:
	_start_position = player.global_position
	finish.body_entered.connect(_on_finish_body_entered)
	InputRouter.restart_requested.connect(restart)
	InputRouter.throw_requested.connect(_on_any_input)
	InputRouter.release_requested.connect(_on_any_input)
	version_label.text = "build %s" % ProjectSettings.get_setting("application/config/version", "dev")
	_update_hint()


func _process(delta: float) -> void:
	if _running:
		_elapsed += delta
	if player.global_position.y < kill_y:
		restart()
	time_label.text = "%.2f" % _elapsed
	var size := get_viewport().get_visible_rect().size
	var landscape := size.x > size.y
	if landscape != _landscape:
		_landscape = landscape
		_update_hint()


func restart() -> void:
	player.reset_to(_start_position)
	_elapsed = 0.0
	_running = false
	_finished = false
	_update_hint()


func _on_any_input(_a = null, _b = null, _c = null) -> void:
	if _finished:
		restart()
	elif not _running:
		_running = true


func _on_finish_body_entered(body: Node3D) -> void:
	if body != player or _finished:
		return
	_finished = true
	_running = false
	_best = minf(_best, _elapsed)
	_update_hint()


func _update_hint() -> void:
	var restart_text := "two-finger tap" if _touch else "click"
	if _finished:
		hint_label.text = "Finished in %.2f s  |  Best: %.2f s  |  Tap/%s to restart" % [_elapsed, _best, restart_text]
		return
	var best_text := "" if _best == INF else "   Best: %.2f s" % _best
	if _landscape and _touch:
		hint_label.text = "Hold your phone upright (portrait)" + best_text
	elif _touch:
		hint_label.text = "Swipe up and let go: throw hook\nTap: let go   Two-finger tap: restart" + best_text
	else:
		hint_label.text = "Drag and release: throw hook   Right click: let go   R: restart" + best_text
