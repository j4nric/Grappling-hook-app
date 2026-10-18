class_name AmbientSound
extends AudioStreamPlayer3D
## A sound placed in the cave: a loop (lava, updraft, crystal hum) or a
## one-shot repeated at random intervals (water drips). Only plays while the
## listener is within max_distance, so a long cave does not keep dozens of
## voices running (each one is a Web Audio node in the browser).

## Seconds between one-shots; 0 = the stream loops.
@export var interval_min := 0.0
@export var interval_max := 0.0
## Seconds between distance checks.
@export var check_interval := 0.25

var _wait := 0.0
var _check := 0.0
var _near := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Drips next to each other must not fall in sync.
	_rng.seed = hash(global_position.snapped(Vector3.ONE * 0.1))
	_wait = _rng.randf_range(0.0, interval_max)
	_check = _rng.randf_range(0.0, check_interval)


## True while the listener is close enough to hear this sound.
func in_range() -> bool:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return false
	return camera.global_position.distance_to(global_position) < max_distance


func is_loop() -> bool:
	return interval_max <= 0.0


func _process(delta: float) -> void:
	_check -= delta
	if _check <= 0.0:
		_check = check_interval
		_near = in_range()
		if is_loop():
			# Browsers block audio until the first touch: retry until it runs.
			if _near and not playing:
				play(_rng.randf() * _loop_length())
			elif not _near and playing:
				stop()
	if is_loop() or not _near:
		return
	_wait -= delta
	if _wait <= 0.0:
		_wait = _rng.randf_range(interval_min, interval_max)
		pitch_scale = _rng.randf_range(0.85, 1.2)
		play()


func _loop_length() -> float:
	return stream.get_length() * 0.9 if stream else 0.0
