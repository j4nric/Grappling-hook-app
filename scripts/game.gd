extends Node3D
## Level flow: timer, finish detection, fall-out reset, restart.

## Falling below this Y resets the run.
@export var kill_y := -30.0

@onready var player := $Player
@onready var finish: Area3D = $TestTunnel/Finish
@onready var time_label: Label = $HUD/TimeLabel
@onready var hint_label: Label = $HUD/HintLabel

var _start_position := Vector3.ZERO
var _elapsed := 0.0
var _running := false
var _finished := false
var _best := INF


func _ready() -> void:
	_start_position = player.global_position
	finish.body_entered.connect(_on_finish_body_entered)
	InputRouter.restart_requested.connect(restart)
	InputRouter.grapple_requested.connect(_on_any_input)
	InputRouter.release_requested.connect(_on_any_input)
	_update_hint()


func _process(delta: float) -> void:
	if _running:
		_elapsed += delta
	if player.global_position.y < kill_y:
		restart()
	time_label.text = "%.2f" % _elapsed


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
	if _finished:
		hint_label.text = "Finished in %.2f s  |  Best: %.2f s  |  Click/tap to restart" % [_elapsed, _best]
	else:
		var best_text := "" if _best == INF else "   Best: %.2f s" % _best
		hint_label.text = "Left click / swipe: grapple    Right click / tap: release    R: restart" + best_text
