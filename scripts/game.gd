extends Node3D
## Level flow: level loading, timer, finish, checkpoints, lava and falls,
## restart, HUD.

## The first throw of a run: the timer starts.
signal run_started
signal level_loaded(level: Level)

## Longest frame the run timer counts (s). A hitch or a return from the
## background must not add a jump to the time.
@export var max_timer_step := 0.1
## Level to start directly (index into level_list); -1 opens the level menu.
@export var start_level := -1

@onready var player := $Player
@onready var menu := $LevelMenu
@onready var pause_menu := $PauseMenu
@onready var safe: Control = $HUD/Safe
@onready var time_label: Label = $HUD/Safe/TimeLabel
@onready var best_label: Label = $HUD/Safe/BestLabel
@onready var hint_label: Label = $HUD/Safe/HintLabel
@onready var level_label: Label = $HUD/Safe/LevelLabel
@onready var version_label: Label = $HUD/Safe/VersionLabel
@onready var finish_panel: PanelContainer = $HUD/Safe/FinishPanel
@onready var go_label: Label = $HUD/Safe/GoLabel
@onready var flow_label: Label = $HUD/Safe/FlowLabel
@onready var split_label: Label = $HUD/Safe/SplitLabel
@onready var ghost_label: Label = $HUD/Safe/GhostLabel
@onready var tuning := $Tuning
@onready var environment: Environment = $WorldEnvironment.environment
@onready var ghost := $Ghost

## Ambient light in dark halls, as a share of the normal ambient light.
const DARK_AMBIENT := 0.25
## How fast the light changes when entering or leaving a dark hall (1/s).
const DARK_FADE := 2.0

## Split time shows this long after a checkpoint (s).
const SPLIT_SHOW_TIME := 2.5
## The ghost delta shows once the player is this far into the level (m).
const GHOST_DELTA_FROM := 5.0

## The levels in play order (tests swap in their own).
var level_list: Array[String] = Levels.with_procedural()
var level: Level
var level_index := 0
var _respawn := Vector3.ZERO
var _elapsed := 0.0
var _running := false
var _finished := false
var _best := INF
## 0 = normal light, 1 = in a dark hall (head lamp on).
var darkness := 0.0
var _base_ambient := 1.0
## Record id of the loaded level version (Records.id()).
var _record_id := ""
## Times at the checkpoints of this run and of the best run.
var _splits: Array = []
var _best_splits: Array = []
## Checkpoints reached in this run (respawn positions).
var _reached: Array[Vector3] = []
var _touch := DisplayServer.is_touchscreen_available()
var _landscape := false
## The controls hint disappears after the first hook that sticks.
var _hint_dismissed := false
## Flow: hooks that bit in a row without landing, missing or bumping into
## rock in between.
var flow := 0
var best_flow := 0
## The flow counter shows from this many hooks in a row.
const FLOW_MIN_SHOWN := 2


func _ready() -> void:
	# The world is drawn by the pixel viewport (World/PixelView); the root
	# viewport only draws the HUD.
	get_viewport().disable_3d = true
	Settings.load_settings()
	_base_ambient = environment.ambient_light_energy
	player.hook_attached.connect(_on_hook_attached)
	player.crushed.connect(_on_killed)
	# The flow breaks on landing, a miss, or bumping into rock with the rope on.
	player.landed.connect(func(_speed: float) -> void: _set_flow(0))
	player.hook_missed.connect(func() -> void: _set_flow(0))
	player.rope_released.connect(func(reason: String) -> void:
		if reason in ["contact", "blocked"]:
			_set_flow(0))
	InputRouter.restart_requested.connect(restart)
	InputRouter.throw_requested.connect(_on_throw)
	InputRouter.release_requested.connect(_on_tap)
	# From the menu, the random cave is a new one every time.
	menu.level_chosen.connect(func(index: int) -> void: load_level(index, true))
	pause_menu.restart_pressed.connect(restart)
	pause_menu.levels_pressed.connect(open_menu)
	version_label.text = "build %s" % ProjectSettings.get_setting("application/config/version", "dev")
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.03, 0.05, 0.85)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(24.0)
	finish_panel.add_theme_stylebox_override("panel", panel_style)
	for button_name in ["Next", "Levels"]:
		finish_panel.get_node("Lines/Buttons/" + button_name).add_to_group(InputRouter.BLOCKING_GUI_GROUP)
	finish_panel.get_node("Lines/Buttons/Next").pressed.connect(_on_next)
	finish_panel.get_node("Lines/Buttons/Levels").pressed.connect(open_menu)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	load_level(maxi(start_level, 0))
	if start_level < 0:
		open_menu()


## new_cave: a random cave gets a fresh seed (else the same cave again).
func load_level(index: int, new_cave := false) -> void:
	if index < 0 or index >= level_list.size():
		open_menu()
		return
	if new_cave and Levels.is_random_cave(level_list[index]):
		level_list[index] = Levels.random_cave_path()
	if level:
		remove_child(level)
		level.queue_free()
	level_index = index
	pause_menu.set_button_visible(true)
	level = Levels.instantiate(level_list[index])
	level.name = "Level"
	level.build()
	# Move the player before the level exists, so it never overlaps the new
	# finish line (levels may share its position).
	player.reset_to(level.get_node("Start").position)
	add_child(level)
	level.finished.connect(_on_finished)
	level.checkpoint_reached.connect(_on_checkpoint)
	level.killed.connect(_on_killed)
	level.ring_passed.connect(func() -> void: $CameraRig.kick_fov())
	_record_id = Records.id(level_list[index], level)
	_best = Records.best_time(_record_id)
	restart()
	$LightLod.track(level)
	level_loaded.emit(level)


func open_menu() -> void:
	pause_menu.set_button_visible(false)
	var entries := []
	for path in level_list:
		var scene: Level = Levels.instantiate(path)
		var record_id := Records.id(path, scene)
		var best := Records.best_time(record_id)
		var detail := ""
		var level_title := scene.level_name
		if Levels.is_random_cave(path):
			level_title = "Random Cave"
			detail = "new every time"
		elif best < INF:
			detail = "%.2f s%s  %s" % [best, _tuned_mark(record_id), Records.medal_name(Records.medal(scene, best))]
		entries.append({"name": level_title, "detail": detail})
		scene.free()
	menu.open(entries)


func _process(delta: float) -> void:
	if _running:
		# Real time while aiming (slow motion must not shorten the run), game
		# time during a hit-stop (juice must not cost time).
		_elapsed += minf(TimeScale.timer_delta(delta), max_timer_step)
		ghost.update_run(_elapsed, player.global_position)
		_update_ghost_delta()
	TimeScale.update(delta)
	if player.global_position.y < level.kill_y:
		_on_killed()
	_update_darkness(delta)
	time_label.text = "%.2f" % _elapsed
	if not level.hints.is_empty() and not _finished and hint_label.text != level.hint_at(player.global_position.z):
		_update_hud()
	var size := get_viewport().get_visible_rect().size
	var landscape := size.x > size.y
	if landscape != _landscape:
		_landscape = landscape
		_update_hud()


## Back to the start of the level, timer reset.
func restart() -> void:
	_respawn = level.start_position()
	player.reset_to(_respawn)
	_elapsed = 0.0
	_running = false
	_finished = false
	best_flow = 0
	_set_flow(0)
	ghost.reset(Records.load_ghost(_record_id))
	level.reset_dynamic()
	_splits.clear()
	_best_splits = Records.best_splits(_record_id)
	_reached.clear()
	split_label.visible = false
	ghost_label.visible = false
	go_label.visible = false
	_update_hud()


## Lava or a fall: back to the last checkpoint, the timer keeps running.
func _on_killed() -> void:
	player.reset_to(_respawn)
	_set_flow(0)


## Only a throw starts the run; after the finish it plays again.
func _on_throw(_swipe: Vector2, _flick: Vector2) -> void:
	if _finished:
		restart()
	elif not _running:
		_running = true
		_flash_go()
		run_started.emit()


## A tap lets go of the rope (player.gd); after the finish it plays again.
func _on_tap() -> void:
	if _finished:
		restart()


## Start signal: the run (and the timer) starts with the first throw.
func _flash_go() -> void:
	go_label.visible = true
	go_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(go_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void: go_label.visible = false)


func _on_hook_attached(_point: Vector3, _normal: Vector3) -> void:
	# A hook from the floor starts a new chain.
	_set_flow(1 if player.is_on_floor() else flow + 1)
	if not _hint_dismissed:
		_hint_dismissed = true
		_update_hud()


func _on_finished() -> void:
	if _finished or not _running:
		return
	_finished = true
	_running = false
	var tuned: bool = tuning.is_tuned()
	var previous_best := _best
	var new_best := Records.submit(_record_id, _elapsed, _splits, tuned)
	if new_best:
		Records.save_ghost(_record_id, ghost.recording())
	_best = minf(_best, _elapsed)
	ghost_label.visible = false
	var medal := Records.medal(level, _elapsed)
	var medal_label: Label = finish_panel.get_node("Lines/Medal")
	medal_label.text = Records.medal_name(medal).to_upper() if medal != Records.Medal.NONE else "No medal"
	medal_label.add_theme_color_override("font_color", Records.medal_color(medal))
	finish_panel.get_node("Lines/Time").text = "%.2f s" % _elapsed
	var best_line := "Best: %.2f s" % _best
	if new_best:
		best_line = "New best!"
	if previous_best < INF:
		best_line += "  %s" % _signed(_elapsed - previous_best)
	if tuned:
		best_line += "  (TUNE*)"
	finish_panel.get_node("Lines/Best").text = best_line
	finish_panel.get_node("Lines/Flow").text = "Longest flow x%d" % best_flow if best_flow >= FLOW_MIN_SHOWN else ""
	finish_panel.get_node("Lines/Target").text = _next_target(medal)
	finish_panel.get_node("Lines/Again").text = "Tap to play again" if _touch else "Click to play again"
	var next: Button = finish_panel.get_node("Lines/Buttons/Next")
	var random := Levels.is_random_cave(level_list[level_index])
	next.text = "New cave" if random else "Next"
	next.visible = random or level_index + 1 < level_list.size()
	_update_hud()


## Checkpoint: new respawn point; the first time in a run also a split
## time against the best run.
func _on_checkpoint(point: Vector3) -> void:
	_respawn = point
	if not _running or point in _reached:
		return
	_reached.append(point)
	var index := _splits.size()
	_splits.append(_elapsed)
	if index < _best_splits.size():
		var delta: float = _elapsed - float(_best_splits[index])
		_show_split(delta)


func _show_split(delta: float) -> void:
	split_label.text = _signed(delta)
	split_label.add_theme_color_override("font_color", _delta_color(delta))
	split_label.visible = true
	split_label.modulate.a = 1.0
	var tween := split_label.create_tween()
	tween.tween_interval(SPLIT_SHOW_TIME)
	tween.tween_property(split_label, "modulate:a", 0.0, 0.5)


## Seconds ahead (-) or behind (+) the ghost at the same point of the level.
## Dark halls: the ambient light dims and the head lamp comes on.
func _update_darkness(delta: float) -> void:
	var target := 1.0 if level.is_dark_at(player.global_position.z) else 0.0
	darkness = move_toward(darkness, target, DARK_FADE * delta)
	environment.ambient_light_energy = _base_ambient * lerpf(1.0, DARK_AMBIENT, darkness)
	var lamp: SpotLight3D = player.figure.lamp
	lamp.visible = darkness > 0.01
	lamp.light_energy = 3.0 * darkness


func _update_ghost_delta() -> void:
	var z: float = player.global_position.z
	if not Settings.ghost_enabled or z > level.start_position().z - GHOST_DELTA_FROM:
		ghost_label.visible = false
		return
	var ghost_time: float = ghost.time_at_z(z)
	if ghost_time < 0.0:
		ghost_label.visible = false
		return
	var delta := _elapsed - ghost_time
	ghost_label.text = "ghost %s" % _signed(delta)
	ghost_label.add_theme_color_override("font_color", _delta_color(delta))
	ghost_label.visible = true


static func _signed(seconds: float) -> String:
	return ("+%.2f" if seconds >= 0.0 else "-%.2f") % absf(seconds)


static func _delta_color(seconds: float) -> Color:
	return Color(1.0, 0.4, 0.35) if seconds > 0.0 else Color(0.4, 1.0, 0.5)


static func _tuned_mark(record_id: String) -> String:
	return "*" if Records.is_tuned(record_id) else ""


## Finish screen "Next": the next level, or a new random cave.
func _on_next() -> void:
	if Levels.is_random_cave(level_list[level_index]):
		load_level(level_index, true)
	else:
		load_level(level_index + 1)


func _set_flow(value: int) -> void:
	var grew := value > flow
	flow = value
	if _running:
		best_flow = maxi(best_flow, flow)
	flow_label.visible = flow >= FLOW_MIN_SHOWN and not _finished
	if flow_label.visible and grew:
		flow_label.text = "x%d" % flow
		# Pop: bigger and brighter with every hook in the chain.
		var pop := 1.0 + minf(flow, 10) * 0.06
		flow_label.scale = Vector2.ONE * pop * 1.4
		var tween := flow_label.create_tween()
		tween.tween_property(flow_label, "scale", Vector2.ONE * pop, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _next_target(medal: Records.Medal) -> String:
	match medal:
		Records.Medal.NONE:
			return "Bronze: %.2f s" % level.bronze_time
		Records.Medal.BRONZE:
			return "Silver: %.2f s" % level.silver_time
		Records.Medal.SILVER:
			return "Gold: %.2f s" % level.gold_time
	return ""


func _apply_safe_area() -> void:
	var m := SafeArea.margins(get_viewport())
	safe.offset_left = m.x
	safe.offset_top = m.y
	safe.offset_right = -m.z
	safe.offset_bottom = -m.w


func _update_hud() -> void:
	finish_panel.visible = _finished
	var best_text := "%.2f s%s" % [_best, _tuned_mark(_record_id)] if _best < INF else "-"
	pause_menu.set_info("%s\nBest %s\nGold %.2f   Silver %.2f   Bronze %.2f" % [
			level.level_name, best_text, level.gold_time, level.silver_time, level.bronze_time])
	if _finished:
		flow_label.visible = false
	level_label.text = "%d  %s" % [level_index + 1, level.level_name]
	if _best == INF:
		best_label.text = "Gold %.2f" % level.gold_time
	else:
		var medal := Records.medal(level, _best)
		best_label.text = "Best %.2f%s  %s" % [_best, _tuned_mark(_record_id), Records.medal_name(medal)]
	if _finished:
		hint_label.text = ""
	elif _landscape and _touch:
		hint_label.text = "Hold your phone upright (portrait)"
	elif not level.hints.is_empty():
		hint_label.text = level.hint_at(player.global_position.z)
	elif _hint_dismissed:
		hint_label.text = ""
	elif _touch:
		hint_label.text = "Swipe up and let go: throw hook\nTap: let go   Hold two fingers: restart"
	else:
		hint_label.text = "Drag and release: throw hook   Right click: let go   R: restart"
