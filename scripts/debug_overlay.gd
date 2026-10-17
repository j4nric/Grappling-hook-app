extends CanvasLayer
## Debug overlay (FPS, speed, hook state, last throw) and automatic quality:
## if the frame rate stays low, the pixel view renders at a lower resolution.
## Both are switched in the tuning panel (tab Misc).

@export var player: CharacterBody3D
@export var pixel_view: SubViewportContainer
## 1 = show the overlay. A float so it works as a tuning slider.
@export var shown := 0.0:
	set(value):
		shown = value
		if _label:
			_label.visible = value >= 0.5
## 1 = lower the resolution when the frame rate stays below min_fps.
@export var auto_quality := 1.0
@export var min_fps := 45.0
## Coarsest pixel size auto quality may switch to (stretch_shrink).
@export var max_shrink := 4
## Seconds below min_fps before the resolution drops.
@export var low_fps_time := 3.0

var _label: Label
var _low_time := 0.0


func _ready() -> void:
	layer = 8
	_label = Label.new()
	_label.position = Vector2(16, 150)
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.visible = shown >= 0.5
	add_child(_label)
	# Headless runs (tests) have no meaningful frame rate.
	if DisplayServer.get_name() == "headless":
		auto_quality = 0.0


func _process(delta: float) -> void:
	var fps := Engine.get_frames_per_second()
	if auto_quality >= 0.5:
		_low_time = _low_time + delta if fps < min_fps else 0.0
		if _low_time > low_fps_time and pixel_view.stretch_shrink < max_shrink:
			pixel_view.stretch_shrink += 1
			_low_time = 0.0
	if _label.visible:
		var state: String = player.HookState.keys()[player.hook_state]
		_label.text = "FPS %d   pixel x%d\nspeed %.1f m/s   hook %s\nlast throw %d px/s -> %.0f m/s" % [
			fps, pixel_view.stretch_shrink, player.velocity.length(), state,
			player.last_throw_flick, player.last_throw_speed]
