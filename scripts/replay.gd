class_name Replay
extends Node
## Plays a recorded run (Ghost.recording(), Records.load_ghost()) back on the
## player: position, speed and rope, so camera, figure, rope, wind and speed
## lines behave as in the real run. Runs at the physics rate, so physics
## interpolation keeps it smooth.

signal finished

## The player this far between two samples (m) jumped: a respawn.
const JUMP_DISTANCE := 12.0
## The last picture stays this long before finished (s).
const HOLD_AT_END := 0.8

@export var player: CharacterBody3D

## Seconds into the recording.
var time := 0.0
var _positions := PackedVector3Array()
var _anchors := PackedVector3Array()
var _playing := false
var _sample := -1


func is_playing() -> bool:
	return _playing


## Seconds the recording lasts.
func length() -> float:
	return maxf(0.0, (_positions.size() - 1) * Ghost.SAMPLE_TIME)


static func can_play(run: Dictionary) -> bool:
	return (run.get("positions", PackedVector3Array()) as PackedVector3Array).size() >= 2


func start(run: Dictionary) -> void:
	if not can_play(run):
		return
	_positions = run.positions
	_anchors = run.get("anchors", PackedVector3Array())
	time = 0.0
	_sample = -1
	_playing = true
	player.replaying = true
	_step(true)


func stop() -> void:
	if not _playing:
		return
	_playing = false
	player.replaying = false
	finished.emit()


func _physics_process(delta: float) -> void:
	if not _playing:
		return
	time += delta
	if time >= length() + HOLD_AT_END:
		stop()
		return
	_step(false)


func _step(first: bool) -> void:
	var f := minf(time, length()) / Ghost.SAMPLE_TIME
	var i := mini(int(f), _positions.size() - 2)
	var t := clampf(f - i, 0.0, 1.0)
	var a := _positions[i]
	var b := _positions[i + 1]
	var pos := a.lerp(b, t)
	var vel := (b - a) / Ghost.SAMPLE_TIME
	var jump := first
	if a.distance_to(b) > JUMP_DISTANCE:
		# Respawn in the recording: no flight across the cave.
		pos = a if t < 1.0 else b
		vel = Vector3.ZERO
		jump = true
	elif i != _sample and _sample >= 0 and _positions[_sample].distance_to(a) > JUMP_DISTANCE:
		jump = true
	if time >= length():
		vel = Vector3.ZERO
	_sample = i
	var anchor := Ghost.NO_ANCHOR
	if i < _anchors.size():
		anchor = _anchors[i]
	player.replay_step(pos, vel, anchor, jump)
