class_name RunCode
## A run as a short text code, to send to a friend without a server:
## "GC1:<level key>@<version>:<time in ms>:<data>". The data is the ghost
## recording (positions and rope anchors every Ghost.SAMPLE_TIME seconds) on
## a 5 cm grid, positions as steps from sample to sample, deflated and in
## base64. About 2 KB for a 20 s run.

const PREFIX := "GC1"
## Grid of the stored positions (m).
const GRID := 0.05
## Anchor x of a sample without a rope.
const NO_ANCHOR_MARK := 0x7fffffff
const MAX_DATA := 4 * 1024 * 1024


static func encode(record_id: String, time: float, run: Dictionary) -> String:
	var positions: PackedVector3Array = run.get("positions", PackedVector3Array())
	var anchors: PackedVector3Array = run.get("anchors", PackedVector3Array())
	var out := StreamPeerBuffer.new()
	out.put_u32(positions.size())
	var last := Vector3i.ZERO
	for p in positions:
		var cell := _cell(p)
		var step := cell - last
		# Steps fit 16 bits up to 1.6 km per sample; a longer one (never in a
		# level) is written whole after a marker.
		if maxi(maxi(absi(step.x), absi(step.y)), absi(step.z)) < 32767:
			for v in [step.x, step.y, step.z]:
				out.put_16(v)
		else:
			out.put_16(-32768)
			for v in [cell.x, cell.y, cell.z]:
				out.put_32(v)
		last = cell
	for i in positions.size():
		var anchor: Vector3 = anchors[i] if i < anchors.size() else Ghost.NO_ANCHOR
		if not anchor.is_finite():
			out.put_32(NO_ANCHOR_MARK)
			continue
		var cell := _cell(anchor)
		for v in [cell.x, cell.y, cell.z]:
			out.put_32(v)
	var packed := out.data_array.compress(FileAccess.COMPRESSION_DEFLATE)
	return "%s:%s:%d:%s" % [PREFIX, record_id, roundi(time * 1000.0), Marshalls.raw_to_base64(packed)]


## The run in a text (the code may sit inside a message): {"id", "key",
## "version", "time", "run"}, or {} if there is no valid code.
static func decode(text: String) -> Dictionary:
	var found := RegEx.create_from_string(PREFIX + ":([A-Za-z0-9_]+)@([0-9a-f]+):(\\d+):([A-Za-z0-9+/=]+)").search(text)
	if found == null:
		return {}
	var packed := Marshalls.base64_to_raw(found.get_string(4))
	if packed.is_empty():
		return {}
	var data := packed.decompress_dynamic(MAX_DATA, FileAccess.COMPRESSION_DEFLATE)
	if data.size() < 4:
		return {}
	var input := StreamPeerBuffer.new()
	input.data_array = data
	var count := input.get_u32()
	if count < 2 or count * 10 > data.size():
		return {}
	var positions := PackedVector3Array()
	var cell := Vector3i.ZERO
	for i in count:
		var x := input.get_16()
		if x == -32768:
			cell = Vector3i(input.get_32(), input.get_32(), input.get_32())
		else:
			cell += Vector3i(x, input.get_16(), input.get_16())
		positions.append(Vector3(cell) * GRID)
	var anchors := PackedVector3Array()
	for i in count:
		var x := input.get_32()
		if x == NO_ANCHOR_MARK:
			anchors.append(Ghost.NO_ANCHOR)
		else:
			anchors.append(Vector3(Vector3i(x, input.get_32(), input.get_32())) * GRID)
	if input.get_position() != data.size():
		return {}
	return {
		"id": "%s@%s" % [found.get_string(1), found.get_string(2)],
		"key": found.get_string(1),
		"version": found.get_string(2),
		"time": found.get_string(3).to_int() / 1000.0,
		"run": {"positions": positions, "anchors": anchors},
	}


static func _cell(p: Vector3) -> Vector3i:
	return Vector3i((p / GRID).round())
