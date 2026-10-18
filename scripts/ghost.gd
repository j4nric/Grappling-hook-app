extends MeshInstance3D
## Ghost of the best run: records the player during a run and replays the
## best recording next to the live run.

const SAMPLE_TIME := 0.05

var _recording := PackedVector3Array()
var _replay := PackedVector3Array()
var _record_clock := 0.0
## Where time_at_z() last found the ghost (the search goes on from there).
var _search := 0


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
	_search = 0
	visible = false


func has_replay() -> bool:
	return _replay.size() >= 2


## Run time (s) at which the ghost first got as far forward (-Z) as z;
## -1 if it never did (or there is no ghost). For the ghost delta in the HUD.
func time_at_z(z: float) -> float:
	if not has_replay():
		return -1.0
	# Forward progress is monotonic enough: search on from the last hit, and
	# step back if the player fell behind it (respawn at a checkpoint).
	_search = clampi(_search, 0, _replay.size() - 1)
	while _search > 0 and _replay[_search].z < z:
		_search -= 1
	while _search < _replay.size() - 1 and _replay[_search + 1].z > z:
		_search += 1
	if _search >= _replay.size() - 1:
		return -1.0
	var a := _replay[_search]
	var b := _replay[_search + 1]
	var t := clampf((a.z - z) / maxf(a.z - b.z, 0.001), 0.0, 1.0)
	return (_search + t) * SAMPLE_TIME


func recording() -> PackedVector3Array:
	return _recording


## Called every frame while the run timer runs, with the run time (s).
func update_run(time: float, player_position: Vector3) -> void:
	while _record_clock <= time:
		_recording.append(player_position)
		_record_clock += SAMPLE_TIME
	if _replay.size() < 2 or not Settings.ghost_enabled:
		visible = false
		return
	var f := time / SAMPLE_TIME
	var i := int(f)
	if i >= _replay.size() - 1:
		global_position = _replay[-1]
	else:
		global_position = _replay[i].lerp(_replay[i + 1], f - i)
	visible = true
