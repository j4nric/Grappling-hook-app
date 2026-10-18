extends Node
## Music loop from tools/gen_music.py: three stems that play in sync. The
## base (pad, bass, drips) always plays; the pulse comes in with speed, the
## arpeggio at high speed or deep in a flow chain.

const STEMS := ["music_base", "music_pulse", "music_arp"]

@export var player: CharacterBody3D
@export var game: Node
## Music volume (0..1).
@export var volume := 0.5
## Pulse: from this speed (m/s) to full at the second value.
@export var pulse_speed := Vector2(6.0, 22.0)
## Arpeggio: from this speed to full ...
@export var arp_speed := Vector2(26.0, 42.0)
## ... or at full from this flow chain on.
@export var arp_flow := 4
## How fast the stems fade (1/s).
@export var fade_speed := 1.2

## Current level of each stem (0..1).
var levels := [1.0, 0.0, 0.0]
var _stream := AudioStreamSynchronized.new()
var _audio := AudioStreamPlayer.new()


func _ready() -> void:
	_stream.stream_count = STEMS.size()
	for i in STEMS.size():
		_stream.set_sync_stream(i, load("res://assets/music/%s.wav" % STEMS[i]))
	_audio.stream = _stream
	add_child(_audio)
	_apply()


func _process(delta: float) -> void:
	# Browsers only allow audio after the first touch; keep trying.
	if not _audio.playing:
		_audio.play()
	var speed := player.velocity.length() if player else 0.0
	var flow: int = game.flow if game and "flow" in game else 0
	var targets := [
		1.0,
		smoothstep(pulse_speed.x, pulse_speed.y, speed),
		maxf(smoothstep(arp_speed.x, arp_speed.y, speed), 1.0 if flow >= arp_flow else 0.0),
	]
	var k := 1.0 - exp(-fade_speed * delta)
	for i in levels.size():
		levels[i] = lerpf(levels[i], targets[i], k)
	_apply()


func is_playing() -> bool:
	return _audio.playing


func _apply() -> void:
	for i in levels.size():
		_stream.set_sync_stream_volume(i, linear_to_db(maxf(volume * levels[i], 0.0001)))
