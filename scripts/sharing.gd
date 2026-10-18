class_name Sharing
extends Node
## Runs as text codes (RunCode): "Share run" in the pause menu copies the
## best run, "Load run" loads a friend's run as the rival ghost (and its
## level, also a daily or random cave of another day).

@export var game: Node


func _ready() -> void:
	# (The game's own @onready references are not set yet.)
	var pause_menu := game.get_node("PauseMenu")
	pause_menu.share_requested.connect(func() -> void: pause_menu.show_status(share_run()))
	pause_menu.run_code_entered.connect(func(text: String) -> void: pause_menu.show_status(load_run_code(text)))


## Best run as a code for a friend (copied); returns the message to show.
func share_run() -> String:
	var run := Records.load_ghost(game._record_id)
	if game._edited:
		return "Edited caves cannot be shared (Reset cave in TUNE)."
	if game._best == INF or not Replay.can_play(run):
		return "Finish the level first: your best run is shared."
	Clipboard.copy(RunCode.encode(game._record_id, game._best, run))
	return "Run copied (%.2f s): send it to a friend." % game._best


## A friend's run code: loads its level and makes the run the rival ghost.
## Returns the message to show.
func load_run_code(text: String) -> String:
	var code := RunCode.decode(text)
	if code.is_empty():
		return "No run code found in the pasted text."
	var path := _level_path(code.key)
	var index: int = game.level_list.find(path)
	var replaced := false
	if index < 0 and path.begins_with(Levels.CAVE_PREFIX):
		# Another daily or random cave: it takes the place of that kind.
		for i in game.level_list.size():
			if game.level_list[i].get_base_dir() == path.get_base_dir():
				index = i
				game.level_list[i] = path
				replaced = true
	if index < 0:
		return "This run is from a level this game does not have."
	if index != game.level_index or replaced:
		game.load_level(index)
	if game._edited or Records.id(path, game.level) != code.id:
		return "This run is from another version of %s." % game.level.level_name
	Records.save_rival(game._record_id, code.time, code.run)
	game.restart()
	return "Rival loaded: %.2f s. Race the orange ghost!" % code.time


## Level path of a record key ("level_07", "daily_20261018").
func _level_path(level_key: String) -> String:
	for path in Levels.LIST:
		if Records.key(path) == level_key:
			return path
	for kind in ["daily", "random"]:
		var seed_text := level_key.trim_prefix(kind + "_")
		if level_key.begins_with(kind + "_") and seed_text.is_valid_int():
			return Levels.cave_path(kind, seed_text.to_int())
	return ""


func rival_time() -> float:
	if game._edited:
		return INF
	return float(Records.load_rival(game._record_id).get("time", INF))
