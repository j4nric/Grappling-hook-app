class_name Stats
## Play statistics, kept in user:// (IndexedDB in the browser): runs,
## finishes, meters flown, hooks, longest flow and play time, in total and
## per level. Procedural caves count together per kind ("daily", "random").

const PATH := "user://stats.cfg"
const TOTAL := "total"
## Summed fields; "best_flow" keeps the maximum instead.
const SUMS := ["runs", "finishes", "meters", "hooks", "play_time"]
## Finish times per level for the curve in the stats screen: the newest
## HISTORY_SIZE of one level version (a changed level starts a new curve).
const HISTORY_PATH := "user://history.cfg"
const HISTORY_SIZE := 50


## Stats group of a level path: the level key, or the kind of cave.
static func group(level_path: String) -> String:
	if Levels.is_random_cave(level_path):
		return "random"
	if level_path.begins_with(Levels.CAVE_PREFIX):
		return "daily"
	return Records.key(level_path)


## Adds a piece of play (any of SUMS, plus "best_flow") to the level and
## to the total.
static func add(level_group: String, piece: Dictionary) -> void:
	if piece.is_empty():
		return
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	for section in [level_group, TOTAL]:
		for field: String in SUMS:
			if piece.has(field):
				cfg.set_value(section, field, cfg.get_value(section, field, 0) + piece[field])
		if piece.has("best_flow"):
			cfg.set_value(section, "best_flow", maxi(cfg.get_value(section, "best_flow", 0), piece.best_flow))
	cfg.save(PATH)


## The stats of a level group (or TOTAL), every field present.
static func of(level_group: String) -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	var result := {}
	for field: String in SUMS + ["best_flow"]:
		result[field] = cfg.get_value(level_group, field, 0)
	return result


## One line of stats, e.g. "12 runs (3 finished)  2.4 km  140 hooks  flow x9  14 min".
static func describe(values: Dictionary) -> String:
	var parts := ["%d runs (%d finished)" % [values.runs, values.finishes], distance(values.meters),
			"%d hooks" % values.hooks]
	if values.best_flow >= 2:
		parts.append("flow x%d" % values.best_flow)
	parts.append(duration(values.play_time))
	return "  ".join(parts)


static func distance(meters: float) -> String:
	return "%.1f km" % (meters / 1000.0) if meters >= 1000.0 else "%d m" % roundi(meters)


static func duration(seconds: float) -> String:
	var minutes := floori(seconds / 60.0)
	if minutes >= 60:
		return "%d h %d min" % [minutes / 60, minutes % 60]
	if minutes >= 1:
		return "%d min" % minutes
	return "%d s" % floori(seconds)


## Adds a finish time of a level version (Records.id()).
static func add_finish(record_id: String, time: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(HISTORY_PATH)
	var level_key := record_id.get_slice("@", 0)
	var finishes: Array = []
	if cfg.get_value("version", level_key, "") == record_id:
		finishes = cfg.get_value("finishes", level_key, [])
	finishes.append([Time.get_unix_time_from_system(), time])
	if finishes.size() > HISTORY_SIZE:
		finishes = finishes.slice(finishes.size() - HISTORY_SIZE)
	cfg.set_value("version", level_key, record_id)
	cfg.set_value("finishes", level_key, finishes)
	cfg.save(HISTORY_PATH)


## Finish times of a level version, oldest first.
static func history(record_id: String) -> Array:
	var cfg := ConfigFile.new()
	var level_key := record_id.get_slice("@", 0)
	if cfg.load(HISTORY_PATH) != OK or cfg.get_value("version", level_key, "") != record_id:
		return []
	return (cfg.get_value("finishes", level_key, []) as Array).map(func(entry: Array) -> float: return entry[1])
