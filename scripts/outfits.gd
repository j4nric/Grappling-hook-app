class_name Outfits
## Colors for the climber (jacket, scarf, helmet), unlocked by medals: the
## pause menu offers the unlocked ones ("Outfit"). The choice is kept in
## Settings.

## needs: [medal, count] - that many levels with at least that medal
## ("all" = every level).
const LIST := [
	{"name": "Classic", "jacket": Color(0.72, 0.22, 0.16), "scarf": Color(0.95, 0.85, 0.3), "helmet": Color(0.9, 0.7, 0.15), "needs": ["bronze", 0]},
	{"name": "Moss", "jacket": Color(0.24, 0.48, 0.24), "scarf": Color(0.8, 0.95, 0.45), "helmet": Color(0.45, 0.32, 0.2), "needs": ["bronze", 3]},
	{"name": "Glacier", "jacket": Color(0.32, 0.58, 0.85), "scarf": Color(0.92, 0.97, 1.0), "helmet": Color(0.85, 0.9, 0.95), "needs": ["silver", 3]},
	{"name": "Ember", "jacket": Color(0.16, 0.12, 0.12), "scarf": Color(1.0, 0.45, 0.1), "helmet": Color(0.9, 0.3, 0.1), "needs": ["gold", 2]},
	{"name": "Firefly", "jacket": Color(0.18, 0.2, 0.32), "scarf": Color(0.75, 1.0, 0.35), "helmet": Color(0.3, 0.35, 0.48), "needs": ["gold", 5]},
	{"name": "Golden", "jacket": Color(0.95, 0.75, 0.2), "scarf": Color(1.0, 1.0, 1.0), "helmet": Color(1.0, 0.86, 0.35), "needs": ["gold", "all"]},
]
const MEDALS := {"bronze": Records.Medal.BRONZE, "silver": Records.Medal.SILVER, "gold": Records.Medal.GOLD}


static func find(outfit_name: String) -> Dictionary:
	for outfit: Dictionary in LIST:
		if outfit.name == outfit_name:
			return outfit
	return LIST[0]


## Best medal per level of Levels.LIST (Records.Medal values).
static func best_medals() -> Array[int]:
	var medals: Array[int] = []
	for path in Levels.LIST:
		var level: Level = Levels.instantiate(path)
		var best := Records.best_time(Records.id(path, level))
		medals.append(Records.medal(level, best) if best < INF else Records.Medal.NONE)
		level.free()
	return medals


static func is_unlocked(outfit: Dictionary, medals: Array[int]) -> bool:
	var need: Array = outfit.needs
	var count := medals.filter(func(m: int) -> bool: return m >= MEDALS[need[0]]).size()
	var wanted: int = medals.size() if str(need[1]) == "all" else int(need[1])
	return count >= wanted


## What an outfit needs, e.g. "3 silver medals".
static func requirement(outfit: Dictionary) -> String:
	var need: Array = outfit.needs
	if str(need[1]) == "all":
		return "%s in every level" % need[0]
	return "%d %s medal%s" % [need[1], need[0], "" if int(need[1]) == 1 else "s"]


static func unlocked_names(medals: Array[int]) -> Array[String]:
	var names: Array[String] = []
	for outfit: Dictionary in LIST:
		if is_unlocked(outfit, medals):
			names.append(outfit.name)
	return names
