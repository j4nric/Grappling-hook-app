extends ColorRect
## Speed lines at the screen edges from start_speed on, densest at
## full_speed. Over the 3D view, below the HUD.

const SHADER := preload("res://shaders/speed_lines.gdshader")

@export var player: CharacterBody3D
## The pixel view, so the streaks use its coarse pixels.
@export var pixel_view: SubViewportContainer
## Speed (m/s) where the lines appear ...
@export var start_speed := 45.0
## ... and where they are strongest.
@export var full_speed := 48.0
## How fast the lines fade in and out (1/s).
@export var fade_speed := 6.0

var intensity := 0.0
var _material := ShaderMaterial.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	color = Color.WHITE
	_material.shader = SHADER
	material = _material


func _process(delta: float) -> void:
	var speed := player.velocity.length() if player else 0.0
	var target := clampf((speed - start_speed) / maxf(full_speed - start_speed, 0.001), 0.0, 1.0)
	intensity = lerpf(intensity, target, 1.0 - exp(-fade_speed * delta))
	visible = intensity > 0.01
	if visible:
		var shrink := float(pixel_view.stretch_shrink) if pixel_view else 1.0
		_material.set_shader_parameter("intensity", intensity)
		_material.set_shader_parameter("pixel_size", size / shrink)
