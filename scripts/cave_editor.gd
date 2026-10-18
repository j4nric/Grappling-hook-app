class_name CaveEditor
extends Node
## Edits the halls of the loaded level from the TUNE panel (tab "Cave"):
## pick a hall, change its values, and the cave is rebuilt a moment later
## with the player at the start of that hall. Edits are kept per level in
## user:// and used whenever that level loads, until "Reset cave". Runs in an
## edited cave count as their own record ("edit_..."), so the real best
## times stay. "Copy layout" gives the halls as text for the level file.
## The panel reads and writes the values as properties (see _get/_set).

signal changed

const SAVE_PATH := "user://cave_edits.cfg"
## Hall values the panel edits (keys of CavernBuilder.SEGMENT_DEFAULTS).
const KEYS := ["length", "width", "ceiling", "floor", "stalactites", "pillars", "islands", "outcrops",
		"crystals", "shafts", "open", "floater_spacing", "floater_height", "floater_size", "slick_walls",
		"checkpoint", "ice", "rings", "updrafts", "bouncers", "dark", "shift", "shortcut"]
const FLOORS := ["abyss", "ground", "lava"]
const BOOLS := ["open", "slick_walls", "checkpoint", "dark"]
const INTS := ["pillars", "islands", "crystals", "shafts", "rings", "updrafts", "bouncers"]
## Seconds after the last change before the cave is rebuilt.
const REBUILD_DELAY := 0.35

@export var game: Node

## The halls being edited (a copy of the level's segments) and the seed.
var segments: Array = []
var layout_seed := 1
## Selected hall (index into segments); the panel sets it as "hall".
var selected_hall := 0
var _rebuild_in := -1.0
var _path := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if game:
		game.level_loaded.connect(_on_level_loaded)


## Before a level is built: use the saved edit for this level, if any.
## Returns true if the level is an edited one.
static func apply_saved(path: String, level: Level) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK or not cfg.has_section_key("segments", path):
		return false
	level.segments = cfg.get_value("segments", path)
	level.layout_seed = cfg.get_value("seed", path, level.layout_seed)
	return true


static func is_edited(path: String) -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(SAVE_PATH) == OK and cfg.has_section_key("segments", path)


func _on_level_loaded(level: Level) -> void:
	_path = game.level_list[game.level_index]
	segments = level.segments.duplicate(true)
	layout_seed = level.layout_seed
	selected_hall = clampi(selected_hall, 0, maxi(segments.size() - 1, 0))
	changed.emit()


## A value of the selected hall, as the panel shows it (numbers; floors and
## switches as 0, 1, 2).
func _get(property: StringName) -> Variant:
	match String(property):
		"hall":
			return float(selected_hall)
		"halls":
			return float(segments.size())
		"seed":
			return float(layout_seed)
	if String(property) not in KEYS:
		return null
	if segments.is_empty():
		return 0.0
	var seg: Dictionary = CavernBuilder.full_segment(segments[selected_hall])
	var value: Variant = seg[String(property)]
	if String(property) == "floor":
		return float(FLOORS.find(value))
	if value is bool:
		return 1.0 if value else 0.0
	return float(value)


func _set(property: StringName, value: Variant) -> bool:
	var key := String(property)
	# Hand-made levels (no halls) are not edited.
	if segments.is_empty():
		return false
	match key:
		"hall":
			selected_hall = clampi(int(value), 0, maxi(segments.size() - 1, 0))
			changed.emit()
			return true
		"halls":
			var count := clampi(int(value), 1, 12)
			while segments.size() < count:
				segments.append((segments[-1] as Dictionary).duplicate(true) if not segments.is_empty() else {})
			segments.resize(count)
			selected_hall = mini(selected_hall, count - 1)
			_schedule()
			return true
		"seed":
			layout_seed = int(value)
			_schedule()
			return true
	if key not in KEYS or segments.is_empty():
		return false
	var seg: Dictionary = segments[selected_hall]
	if key == "floor":
		seg[key] = FLOORS[clampi(int(value), 0, FLOORS.size() - 1)]
	elif key in BOOLS:
		seg[key] = float(value) >= 0.5
	elif key in INTS:
		seg[key] = int(value)
	else:
		seg[key] = float(value)
	_schedule()
	return true


func _schedule() -> void:
	_rebuild_in = REBUILD_DELAY


func _process(delta: float) -> void:
	if _rebuild_in < 0.0:
		return
	# Real time: the panel pauses the game.
	_rebuild_in -= delta / maxf(Engine.time_scale, 0.001)
	if _rebuild_in < 0.0:
		rebuild()


## Saves the edit and rebuilds the cave; the player waits at the start of
## the selected hall.
func rebuild() -> void:
	_rebuild_in = -1.0
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("segments", _path, segments.duplicate(true))
	cfg.set_value("seed", _path, layout_seed)
	cfg.save(SAVE_PATH)
	var keep := selected_hall
	game.load_level(game.level_index)
	selected_hall = mini(keep, segments.size() - 1)
	place_player()
	changed.emit()


## Back to the level as it was made (drops the saved edit).
func reset_cave() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK and cfg.has_section_key("segments", _path):
		cfg.erase_section_key("segments", _path)
		if cfg.has_section_key("seed", _path):
			cfg.erase_section_key("seed", _path)
		cfg.save(SAVE_PATH)
	game.load_level(game.level_index)


## The player at the start of the selected hall, a little below its middle.
func place_player() -> void:
	if selected_hall == 0 or segments.is_empty():
		return
	var z := 0.0
	for i in selected_hall:
		z -= float(CavernBuilder.full_segment(segments[i]).length)
	var seg: Dictionary = CavernBuilder.full_segment(segments[selected_hall])
	game.player.reset_to(Vector3(0, float(seg.ceiling) * 0.45, z - 6.0))


## Start of each hall along the cave (z, forward is -Z).
func hall_starts() -> Array[float]:
	var starts: Array[float] = []
	var z := 0.0
	for seg in segments:
		starts.append(z)
		z -= float(CavernBuilder.full_segment(seg).length)
	return starts


## The layout as text, in the format of the level files.
func layout_text() -> String:
	var title: String = game.level.level_name if game and game.level else "Cave"
	return "Grappling Cave layout (%s):\nlayout_seed = %d\nsegments = %s" % [title, layout_seed, var_to_str(segments)]
