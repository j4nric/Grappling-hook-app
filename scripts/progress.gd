class_name Progress
extends Node
## The level menu's progress: the medal summary with the daily streak above
## the levels, the stats screen (totals, each level with the curve of its
## finish times) and Backup / Restore of all progress (Backup).

@export var game: Node


func _ready() -> void:
	# (The game's own @onready references are not set yet.)
	var menu := game.get_node("LevelMenu")
	menu.stats_requested.connect(func() -> void: menu.show_stats(stats_sections()))
	menu.backup_requested.connect(func() -> void:
		game._flush_stats()
		Clipboard.copy(Backup.code())
		menu.show_backup_status("Backup copied: paste it with Restore on the other device."))
	menu.backup_pasted.connect(func(text: String) -> void: menu.show_backup_status(restore_backup(text)))


## The line above the level list: medals over the fixed levels and the
## daily streak. counts: levels per best medal (Records.Medal).
func summary(counts: Array) -> String:
	var parts: PackedStringArray = ["Gold %d" % counts[Records.Medal.GOLD], "Silver %d" % counts[Records.Medal.SILVER],
			"Bronze %d" % counts[Records.Medal.BRONZE]]
	var text := "%s   of %d levels" % ["  ".join(parts), Levels.LIST.size()]
	var streak := Stats.daily_streak(CaveGenerator.daily_seed())
	if streak > 0:
		text += "\nDaily streak: %d day%s" % [streak, "" if streak == 1 else "s"]
	return text


## The statistics screen of the level menu: total, then each level with
## the curve of its finish times. Sections {"title", "text", "times"}.
func stats_sections() -> Array:
	game._flush_stats()
	var sections := [{"title": "TOTAL", "text": Stats.describe(Stats.of(Stats.TOTAL))}]
	var seen := {}
	for path in game.level_list:
		var level_group := Stats.group(path)
		if seen.has(level_group):
			continue
		seen[level_group] = true
		var values := Stats.of(level_group)
		if values.runs == 0:
			continue
		var title: String = {"daily": "Daily Caves", "random": "Random Caves"}.get(level_group, "")
		var times := []
		if title == "":
			var scene: Level = Levels.instantiate(path)
			title = scene.level_name
			times = Stats.history(Records.id(path, scene))
			scene.free()
		sections.append({"title": title.to_upper(), "text": Stats.describe(values), "times": times})
	if sections.size() == 1:
		sections.append({"title": "", "text": "Play a level to start counting."})
	return sections


## Progress from a backup code: files written, settings and tuning loaded
## again, the screens refreshed. Returns the message to show.
func restore_backup(text: String) -> String:
	var restored := Backup.restore(text)
	if restored < 0:
		return "No backup code found in the pasted text."
	Settings.load_settings()
	game.player.figure.set_outfit(Outfits.find(Settings.outfit))
	game.tuning.reload_saved()
	game._best = Records.best_time(game._record_id)
	game._update_hud()
	game.menu.show_stats(stats_sections())
	return "Restored %d saved file%s." % [restored, "" if restored == 1 else "s"]
