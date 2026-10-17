extends Node3D
## Level flow: level loading, timer, finish, checkpoints, lava and falls,
## restart, HUD.

## Falling below this Y counts like lava.
@export var kill_y := -30.0
## Level to start directly (index into Levels.LIST); -1 opens the level menu.
@export var start_level := -1

@onready var player := $Player
@onready var menu := $LevelMenu
@onready var safe: Control = $HUD/Safe
@onready var time_label: Label = $HUD/Safe/TimeLabel
@onready var best_label: Label = $HUD/Safe/BestLabel
@onready var hint_label: Label = $HUD/Safe/HintLabel
@onready var level_label: Label = $HUD/Safe/LevelLabel
@onready var version_label: Label = $HUD/Safe/VersionLabel
@onready var finish_panel: PanelContainer = $HUD/Safe/FinishPanel
@onready var go_label: Label = $HUD/Safe/GoLabel
@onready var ghost := $Ghost

var level: Level
var level_index := 0
var _respawn := Vector3.ZERO
var _elapsed := 0.0
var _running := false
var _finished := false
var _best := INF
var _touch := DisplayServer.is_touchscreen_available()
var _landscape := false
## The controls hint disappears after the first hook that sticks.
var _hint_dismissed := false


func _ready() -> void:
	# The world is drawn by the pixel viewport (World/PixelView); the root
	# viewport only draws the HUD.
	get_viewport().disable_3d = true
	player.hook_attached.connect(_on_hook_attached)
	InputRouter.restart_requested.connect(restart)
	InputRouter.throw_requested.connect(_on_any_input)
	InputRouter.release_requested.connect(_on_any_input)
	menu.level_chosen.connect(load_level)
	version_label.text = "build %s" % ProjectSettings.get_setting("application/config/version", "dev")
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.03, 0.05, 0.85)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(24.0)
	finish_panel.add_theme_stylebox_override("panel", panel_style)
	for button_name in ["Next", "Levels"]:
		finish_panel.get_node("Lines/Buttons/" + button_name).add_to_group(InputRouter.BLOCKING_GUI_GROUP)
	finish_panel.get_node("Lines/Buttons/Next").pressed.connect(func() -> void: load_level(level_index + 1))
	finish_panel.get_node("Lines/Buttons/Levels").pressed.connect(open_menu)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	load_level(maxi(start_level, 0))
	if start_level < 0:
		open_menu()


func load_level(index: int) -> void:
	if index < 0 or index >= Levels.LIST.size():
		open_menu()
		return
	if level:
		remove_child(level)
		level.queue_free()
	level_index = index
	level = load(Levels.LIST[index]).instantiate()
	level.name = "Level"
	# Move the player before the level exists, so it never overlaps the new
	# finish line (levels may share its position).
	player.reset_to(level.get_node("Start").position)
	add_child(level)
	level.finished.connect(_on_finished)
	level.checkpoint_reached.connect(func(point: Vector3) -> void: _respawn = point)
	level.killed.connect(_on_killed)
	_best = Records.best_time(Levels.LIST[index])
	restart()


func open_menu() -> void:
	var entries := []
	for path in Levels.LIST:
		var scene: Level = load(path).instantiate()
		var best := Records.best_time(path)
		var detail := ""
		if best < INF:
			detail = "%.2f s  %s" % [best, Records.medal_name(Records.medal(scene, best))]
		entries.append({"name": scene.level_name, "detail": detail})
		scene.free()
	menu.open(entries)


func _process(delta: float) -> void:
	if _running:
		# Real time: slow motion while aiming must not shorten the run.
		_elapsed += delta / maxf(Engine.time_scale, 0.001)
		ghost.update_run(_elapsed, player.global_position)
	if player.global_position.y < kill_y:
		_on_killed()
	time_label.text = "%.2f" % _elapsed
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
	ghost.reset(Records.load_ghost(Levels.LIST[level_index]))
	go_label.visible = false
	_update_hud()


## Lava or a fall: back to the last checkpoint, the timer keeps running.
func _on_killed() -> void:
	player.reset_to(_respawn)


func _on_any_input(_a = null, _b = null, _c = null) -> void:
	if _finished:
		restart()
	elif not _running:
		_running = true
		_flash_go()


## Start signal: the run (and the timer) starts with the first throw.
func _flash_go() -> void:
	go_label.visible = true
	go_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(go_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void: go_label.visible = false)


func _on_hook_attached(_point: Vector3, _normal: Vector3) -> void:
	if not _hint_dismissed:
		_hint_dismissed = true
		_update_hud()


func _on_finished() -> void:
	if _finished or not _running:
		return
	_finished = true
	_running = false
	var path: String = Levels.LIST[level_index]
	var new_best := Records.submit(path, _elapsed)
	if new_best:
		Records.save_ghost(path, ghost.recording())
	_best = minf(_best, _elapsed)
	var medal := Records.medal(level, _elapsed)
	var medal_label: Label = finish_panel.get_node("Lines/Medal")
	medal_label.text = Records.medal_name(medal).to_upper() if medal != Records.Medal.NONE else "No medal"
	medal_label.add_theme_color_override("font_color", Records.medal_color(medal))
	finish_panel.get_node("Lines/Time").text = "%.2f s" % _elapsed
	finish_panel.get_node("Lines/Best").text = "New best!" if new_best else "Best: %.2f s" % _best
	finish_panel.get_node("Lines/Target").text = _next_target(medal)
	finish_panel.get_node("Lines/Again").text = "Tap to play again" if _touch else "Click to play again"
	finish_panel.get_node("Lines/Buttons/Next").visible = level_index + 1 < Levels.LIST.size()
	_update_hud()


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
	level_label.text = "%d  %s" % [level_index + 1, level.level_name]
	if _best == INF:
		best_label.text = "Gold %.2f" % level.gold_time
	else:
		var medal := Records.medal(level, _best)
		best_label.text = "Best %.2f  %s" % [_best, Records.medal_name(medal)]
	if _finished:
		hint_label.text = ""
	elif _landscape and _touch:
		hint_label.text = "Hold your phone upright (portrait)"
	elif _hint_dismissed:
		hint_label.text = ""
	elif _touch:
		hint_label.text = "Swipe up and let go: throw hook\nTap: let go   Two-finger tap: restart"
	else:
		hint_label.text = "Drag and release: throw hook   Right click: let go   R: restart"
