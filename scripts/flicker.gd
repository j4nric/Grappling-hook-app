extends Light3D
## Fire light: the energy wanders around its base value (torches, lava glow).

## Share of the energy that flickers (0 = steady).
@export var amount := 0.25
## Flicker speed.
@export var speed := 9.0

## Set by LightLod: 0..1 while the light fades in or out with distance.
var fade := 1.0
var _base := 1.0
var _time := 0.0
var _seed := 0.0


func _ready() -> void:
	_base = light_energy
	# Lights next to each other must not pulse in sync.
	_seed = fmod(absf(global_position.x * 3.1 + global_position.z * 1.7), 100.0)


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta * speed
	var t := _time + _seed
	# Two incommensurate waves: irregular, but smooth.
	var wave := sin(t) * 0.6 + sin(t * 2.37 + 1.3) * 0.4
	light_energy = _base * fade * (1.0 + amount * wave)
