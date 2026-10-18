class_name Records
## Best times and ghost runs per level, kept in user:// (IndexedDB in the
## browser). Levels are keyed by their scene file name, procedural caves by
## kind and seed.

const PATH := "user://records.cfg"
const GHOST_DIR := "user://"

enum Medal { NONE, BRONZE, SILVER, GOLD }


static func key(level_path: String) -> String:
	# Procedural caves: one record per kind and seed ("daily_20261018").
	if level_path.begins_with(Levels.CAVE_PREFIX):
		return level_path.trim_prefix(Levels.CAVE_PREFIX).replace("/", "_")
	return level_path.get_file().get_basename()


static func best_time(level_path: String) -> float:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return INF
	return cfg.get_value("best", key(level_path), INF)


## Stores the time if it beats the best. Returns true for a new best.
static func submit(level_path: String, time: float) -> bool:
	if time >= best_time(level_path):
		return false
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("best", key(level_path), time)
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
static func save_ghost(level_path: String, samples: PackedVector3Array) -> void:
	var file := FileAccess.open(_ghost_path(level_path), FileAccess.WRITE)
	if file:
		file.store_var(samples)


static func load_ghost(level_path: String) -> PackedVector3Array:
	var file := FileAccess.open(_ghost_path(level_path), FileAccess.READ)
	if file == null:
		return PackedVector3Array()
	var data = file.get_var()
	return data if data is PackedVector3Array else PackedVector3Array()


static func _ghost_path(level_path: String) -> String:
	return GHOST_DIR + "ghost_%s.dat" % key(level_path)
