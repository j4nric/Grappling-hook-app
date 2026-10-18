class_name Level
extends Node3D
## One level: a cave built from `segments` by CavernBuilder, with the nodes
## game.gd looks for:
##   Start (Marker3D)          where a run begins
##   Finish (Area3D)           finish line
##   Checkpoints/* (Area3D)    each with a Respawn (Marker3D) child
##   KillZones/* (Area3D)      lava and pits: back to the last checkpoint
## Surfaces in the group "no_hook" do not hold the hook.

signal finished
signal checkpoint_reached(respawn: Vector3)
signal killed

@export var level_name := "Level"
## Medal times (s).
@export var gold_time := 20.0
@export var silver_time := 30.0
@export var bronze_time := 45.0
## The cave: one dictionary per hall, keys see CavernBuilder.SEGMENT_DEFAULTS.
@export var segments: Array = []
## Same seed, same cave.
@export var layout_seed := 1
## Falling below this height: back to the last checkpoint.
@export var kill_y := -30.0

var _built := false


## Builds the cave (once). Call before reading Start; _ready calls it too.
func build() -> void:
	if _built:
		return
	_built = true
	if not segments.is_empty():
		CavernBuilder.new().build(self, segments, layout_seed)


func _ready() -> void:
	build()
	$Finish.body_entered.connect(_on_finish)
	for area in _children_of("Checkpoints"):
		var respawn: Vector3 = area.get_node("Respawn").global_position
		area.body_entered.connect(func(body: Node3D) -> void:
			if body.is_in_group("player"):
				checkpoint_reached.emit(respawn))
	for area in _children_of("KillZones"):
		area.body_entered.connect(func(body: Node3D) -> void:
			if body.is_in_group("player"):
				killed.emit())


func start_position() -> Vector3:
	return $Start.global_position


func finish_z() -> float:
	return $Finish.global_position.z


func _on_finish(body: Node3D) -> void:
	if body.is_in_group("player"):
		finished.emit()


func _children_of(path: String) -> Array[Node]:
	if not has_node(path):
		return []
	return get_node(path).get_children()
