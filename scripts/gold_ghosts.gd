class_name GoldGhosts
## Gold ghosts: a bot run per level, shipped with the game as a run code
## (RunCode) in assets/ghosts/<level key>.txt and played at the pace of the
## gold time, so it shows a line that gets gold. Recorded by the level test
## (RECORD_GHOSTS=1 BOT_FULL=1 TEST_FILTER=test_levels); a ghost of another
## level version is not shown (re-record after changing a level).

const DIR := "res://assets/ghosts/"


static func file_of(level_path: String) -> String:
	return DIR + Records.key(level_path) + ".txt"


## {"run", "time"} for this level version, or {} (none, or an old version).
static func load_for(level_path: String, level: Level) -> Dictionary:
	var file := file_of(level_path)
	if not FileAccess.file_exists(file):
		return {}
	var code := RunCode.decode(FileAccess.get_file_as_string(file))
	if code.is_empty() or code.id != Records.id(level_path, level):
		return {}
	return {"run": code.run, "time": code.time}


## Writes a bot run as the level's gold ghost (from the level test).
static func save(level_path: String, level: Level, time: float, run: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open(file_of(level_path), FileAccess.WRITE)
	if file:
		file.store_string(RunCode.encode(Records.id(level_path, level), time, run) + "\n")
