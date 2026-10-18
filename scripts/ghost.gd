extends MeshInstance3D
## Ghost of the best run: records the player during a run and replays the
## best recording next to the live run.

const SAMPLE_TIME := 0.05

var _recording := PackedVector3Array()
var _replay := PackedVector3Array()
var _record_clock := 0.0


func _ready() -> void:
	top_level = true
	# Placed by hand every rendered frame.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	visible = false


## New level or restart: drop the recording, load the replay.
func reset(replay: PackedVector3Array) -> void:
	_replay = replay
	_recording.clear()
	_record_clock = 0.0
	visible = false


func recording() -> PackedVector3Array:
	return _recording


## Called every frame while the run timer runs, with the run time (s).
func update_run(time: float, player_position: Vector3) -> void:
	while _record_clock <= time:
		_recording.append(player_position)
		_record_clock += SAMPLE_TIME
	if _replay.size() < 2:
		visible = false
		return
	var f := time / SAMPLE_TIME
	var i := int(f)
	if i >= _replay.size() - 1:
		global_position = _replay[-1]
	else:
		global_position = _replay[i].lerp(_replay[i + 1], f - i)
	visible = true
