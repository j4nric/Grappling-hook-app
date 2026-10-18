class_name Records
## Best times, split times and ghost runs per level, kept in user://
## (IndexedDB in the browser). A record belongs to one version of a level:
## its id is the level key plus a hash of the level's layout, so a changed
## level starts fresh instead of keeping a time (and ghost) that no longer
## fits. Levels are keyed by their scene file name, procedural caves by kind
## and seed.

const PATH := "user://records.cfg"
const GHOST_DIR := "user://"

enum Medal { NONE, BRONZE, SILVER, GOLD }


static func key(level_path: String) -> String:
	# Procedural caves: one record per kind and seed ("daily_20261018").
	if level_path.begins_with(Levels.CAVE_PREFIX):
		return level_path.trim_prefix(Levels.CAVE_PREFIX).replace("/", "_")
	return level_path.get_file().get_basename()


## Record id of this level in this version ("level_01@3f2a9c1d").
static func id(level_path: String, level: Level) -> String:
	return "%s@%s" % [key(level_path), level.version()]


static func best_time(record_id: String) -> float:
	return _value("best", record_id, INF)


## Times at each checkpoint of the best run (s).
static func best_splits(record_id: String) -> Array:
	return _value("splits", record_id, [])


## The best run was made with changed tuning values (TUNE*).
static func is_tuned(record_id: String) -> bool:
	return _value("tuned", record_id, false)


## Stores the run if it beats the best. Returns true for a new best.
static func submit(record_id: String, time: float, splits: Array = [], tuned := false) -> bool:
	if time >= best_time(record_id):
		return false
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("best", record_id, time)
	cfg.set_value("splits", record_id, splits)
	cfg.set_value("tuned", record_id, tuned)
	cfg.save(PATH)
	return true


static func medal(level: Level, time: float) -> Medal:
	if time <= level.gold_time:
		return Medal.GOLD
	if time <= level.silver_time:
		return Medal.SILVER
	if time <= level.bronze_time:
		return Medal.BRONZE
	return Medal.NONE


static func medal_name(medal_value: Medal) -> String:
	return ["", "Bronze", "Silver", "Gold"][medal_value]


static func medal_color(medal_value: Medal) -> Color:
	return [Color.WHITE, Color(0.8, 0.5, 0.25), Color(0.8, 0.82, 0.88), Color(1.0, 0.82, 0.2)][medal_value]


## Ghost: player positions sampled every Ghost.SAMPLE_TIME seconds.
static func save_ghost(record_id: String, samples: PackedVector3Array) -> void:
	var file := FileAccess.open(_ghost_path(record_id), FileAccess.WRITE)
	if file:
		file.store_var(samples)


static func load_ghost(record_id: String) -> PackedVector3Array:
	var file := FileAccess.open(_ghost_path(record_id), FileAccess.READ)
	if file == null:
		return PackedVector3Array()
	var data = file.get_var()
	return data if data is PackedVector3Array else PackedVector3Array()


static func _ghost_path(record_id: String) -> String:
	return GHOST_DIR + "ghost_%s.dat" % record_id.replace("@", "_")


static func _value(section: String, record_id: String, default: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return default
	return cfg.get_value(section, record_id, default)
