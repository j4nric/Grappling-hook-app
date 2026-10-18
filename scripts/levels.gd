class_name Levels
## All levels in play order: the authored caves, then the procedural ones.
## A procedural level is a path "cave://<kind>/<seed>" (kind: daily, random).

const LIST: Array[String] = [
	# The design level: first in the list while we work on the cave design.
	"res://scenes/levels/level_07.tscn",
	"res://scenes/levels/level_00.tscn",
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn",
	"res://scenes/levels/level_04.tscn",
	"res://scenes/levels/level_05.tscn",
	"res://scenes/levels/level_06.tscn",
]
const CAVE_PREFIX := "cave://"


## Authored levels plus today's cave and a random one.
static func with_procedural() -> Array[String]:
	var list := LIST.duplicate()
	list.append(cave_path("daily", CaveGenerator.daily_seed()))
	list.append(random_cave_path())
	return list


static func cave_path(kind: String, seed_value: int) -> String:
	return "%s%s/%d" % [CAVE_PREFIX, kind, seed_value]


static func random_cave_path() -> String:
	return cave_path("random", randi_range(10000, 99999))


static func is_random_cave(path: String) -> bool:
	return path.begins_with(CAVE_PREFIX + "random/")


## The level for a path (not built yet).
static func instantiate(path: String) -> Level:
	if path.begins_with(CAVE_PREFIX):
		var parts := path.trim_prefix(CAVE_PREFIX).split("/")
		return CaveGenerator.make(parts[0], int(parts[1]))
	return load(path).instantiate()
