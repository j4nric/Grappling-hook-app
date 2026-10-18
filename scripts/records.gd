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

## Records of procedural caves kept (newest first); older ones are deleted
## with their ghosts, so the save file does not grow forever.
const KEEP_RANDOM := 20
const KEEP_DAILY := 14
const SECTIONS := ["best", "splits", "tuned", "played"]


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
	cfg.set_value("played", record_id, Time.get_unix_time_from_system())
	_prune(cfg, record_id)
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


## Drops records of older versions of this level, and all but the newest
## random and daily caves.
static func _prune(cfg: ConfigFile, record_id: String) -> void:
	if not cfg.has_section("best"):
		return
	var key := record_id.get_slice("@", 0)
	var ids := cfg.get_section_keys("best")
	for other in ids:
		if other != record_id and other.get_slice("@", 0) == key:
			_erase(cfg, other)
	var limits := {"random_": KEEP_RANDOM, "daily_": KEEP_DAILY}
	for prefix: String in limits:
		var keep: int = limits[prefix]
		var caves: Array[String] = []
		for other in cfg.get_section_keys("best"):
			if other.begins_with(prefix):
				caves.append(other)
		caves.sort_custom(func(a: String, b: String) -> bool:
			return float(cfg.get_value("played", a, 0.0)) > float(cfg.get_value("played", b, 0.0)))
		for i in range(keep, caves.size()):
			_erase(cfg, caves[i])


static func _erase(cfg: ConfigFile, record_id: String) -> void:
	for section: String in SECTIONS:
		if cfg.has_section_key(section, record_id):
			cfg.erase_section_key(section, record_id)
	if FileAccess.file_exists(_ghost_path(record_id)):
		DirAccess.remove_absolute(_ghost_path(record_id))


static func _value(section: String, record_id: String, default: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return default
	return cfg.get_value(section, record_id, default)
