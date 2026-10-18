class_name CaveGenerator
extends RefCounted
## Procedural caves: from a seed, a random but fair run of halls for the
## CavernBuilder. Always a ground hall at the start and the end, 4-6 halls in
## between (open abyss, islands, pillars, lava, ice, gate, movers, updrafts,
## brittle stalactites, speed rings, dark - never the same kind twice in a
## row), a checkpoint every second hall. Medal times
## come from an estimate of the run time (calibrated against the test bot).

## Average speed of a good run (m/s) and extra seconds per kind of hall.
const RUN_SPEED := 25.0
const EXTRA_SECONDS := {"gate": 6.0, "ice": 2.0, "movers": 1.0, "brittle": 1.5, "dark": 1.0, "updraft": 3.0}
## Medal times as multiples of the estimate. The test bot needs about 0.82
## of the estimate; like the authored levels, gold is 0.85, silver 1.2 and
## bronze 2 times the bot's time.
const GOLD := 0.7
const SILVER := 1.0
const BRONZE := 1.65
## Kind of hall -> chance weight.
const KINDS := {"open": 1.0, "islands": 1.0, "pillars": 1.0, "lava": 1.0, "ice": 0.7, "gate": 0.6,
		"movers": 0.6, "updraft": 0.7, "brittle": 0.6, "rings": 0.7, "dark": 0.5}


## A Level for "daily" or "random" with this seed (not built yet).
static func make(kind: String, seed_value: int) -> Level:
	var level := Level.new()
	level.level_name = "Daily Cave" if kind == "daily" else "Cave #%d" % seed_value
	level.layout_seed = seed_value
	level.segments = segments(seed_value)
	var estimate := estimate_time(level.segments)
	level.gold_time = snappedf(estimate * GOLD, 0.1)
	level.silver_time = snappedf(estimate * SILVER, 0.1)
	level.bronze_time = snappedf(estimate * BRONZE, 0.1)
	return level


## Today's seed: the UTC date as a number (20261018), the same for everyone
## at the same moment, whatever their time zone.
static func daily_seed() -> int:
	var date := Time.get_date_dict_from_system(true)
	return int(date.year) * 10000 + int(date.month) * 100 + int(date.day)


static func segments(seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var halls: Array = [_ground_hall(rng)]
	var count := rng.randi_range(4, 6)
	var last := ""
	for i in count:
		var kind := _pick(rng, last, i)
		last = kind
		var hall := {
			"kind": kind,
			"length": snappedf(rng.randf_range(50.0, 75.0), 1.0),
			"width": snappedf(rng.randf_range(34.0, 46.0), 1.0),
			"ceiling": snappedf(rng.randf_range(24.0, 32.0), 1.0),
			"stalactites": snappedf(rng.randf_range(0.25, 0.45), 0.05),
			"outcrops": snappedf(rng.randf_range(0.1, 0.25), 0.05),
			"crystals": rng.randi_range(2, 3),
			"shafts": rng.randi_range(0, 2),
			"checkpoint": i % 2 == 1,
		}
		match kind:
			"islands":
				hall.islands = rng.randi_range(1, 2)
			"pillars":
				hall.pillars = rng.randi_range(2, 2)
			"lava":
				hall.floor = "lava"
				hall.islands = 1
			"ice":
				hall.ice = snappedf(rng.randf_range(0.7, 1.0), 0.05)
				hall.outcrops = 0.3
				hall.pillars = 1
			"gate":
				hall.gate = [snappedf(rng.randf_range(-10.0, 10.0), 0.5), snappedf(rng.randf_range(14.0, 16.0), 0.5)]
			"movers":
				var length: float = hall.length
				var y: float = float(hall.ceiling) - 10.0
				hall.movers = [
					[-8.0, y, snappedf(length * 0.3, 1.0), 6.0, 4.0, 4.0, Vector3(16, 0, 0), 3.0, rng.randf()],
					[8.0, y + 2.0, snappedf(length * 0.7, 1.0), 6.0, 4.0, 4.0, Vector3(-16, 0, 0), 3.5, rng.randf()],
				]
			"updraft":
				hall.updrafts = rng.randi_range(2, 3)
				hall.ceiling = maxf(float(hall.ceiling), 30.0)
			"brittle":
				hall.brittle = snappedf(rng.randf_range(0.5, 0.7), 0.05)
				hall.stalactites = snappedf(rng.randf_range(0.6, 0.8), 0.05)
			"rings":
				hall.rings = rng.randi_range(3, 4)
				hall.islands = 1
			"dark":
				hall.dark = true
				hall.crystals = 4
				hall.stalactites = 0.5
		halls.append(hall)
	halls.append(_ground_hall(rng))
	return halls


## Seconds a good run needs: length at RUN_SPEED plus extras per hall kind.
static func estimate_time(halls: Array) -> float:
	var total := 0.0
	for hall: Dictionary in halls:
		total += float(hall.get("length", 60.0)) / RUN_SPEED
		total += EXTRA_SECONDS.get(hall.get("kind", ""), 0.0)
	return total


static func _ground_hall(rng: RandomNumberGenerator) -> Dictionary:
	return {"kind": "ground", "length": 40.0, "width": 34.0, "ceiling": 26.0, "floor": "ground",
			"stalactites": 0.3, "crystals": 2, "shafts": rng.randi_range(0, 1)}


## Weighted pick; not the same kind twice in a row, no gate right at the start.
static func _pick(rng: RandomNumberGenerator, last: String, index: int) -> String:
	var total := 0.0
	for kind: String in KINDS:
		if _allowed(kind, last, index):
			total += KINDS[kind]
	var roll := rng.randf() * total
	for kind: String in KINDS:
		if not _allowed(kind, last, index):
			continue
		roll -= KINDS[kind]
		if roll <= 0.0:
			return kind
	return "open"


static func _allowed(kind: String, last: String, index: int) -> bool:
	return kind != last and not (kind == "gate" and index == 0)
