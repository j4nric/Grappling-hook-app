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
## A speed ring was passed (for sound and effects).
signal ring_passed

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
## Tutorial hints: [z, text] pairs; a hint shows once the player is past
## its z (forward is -Z) until the next one.
@export var hints: Array = []

var _built := false
## Dark halls as [z_from, z_to] (forward is -Z), from the builder.
var dark_ranges: Array = []


## Builds the cave (once). Call before reading Start; _ready calls it too.
func build() -> void:
	if _built:
		return
	_built = true
	if not segments.is_empty():
		CavernBuilder.new().build(self, segments, layout_seed)


func _ready() -> void:
	build()
	for ring in find_children("*", "Area3D", true, false):
		if ring.has_signal("passed"):
			ring.passed.connect(func(_r: Node) -> void: ring_passed.emit())
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


## Short hash of what makes this level: name and layout (records belong to
## one version of a level).
func version() -> String:
	# The full halls (with their templates): a changed template is a new version.
	var halls := segments.map(func(seg: Dictionary) -> Dictionary: return CavernBuilder.full_segment(seg))
	return "%08x" % (hash(level_name + var_to_str(halls) + str(layout_seed)) & 0xffffffff)


## The hint for a position, "" if none.
func hint_at(z: float) -> String:
	var text := ""
	for hint in hints:
		if z <= float(hint[0]):
			text = hint[1]
	return text


func add_dark_range(z_from: float, z_to: float) -> void:
	dark_ranges.append([z_from, z_to])


func is_dark_at(z: float) -> bool:
	for r in dark_ranges:
		if z <= float(r[0]) and z >= float(r[1]):
			return true
	return false


## Restart: broken stalactites grow back.
func reset_dynamic() -> void:
	for node in find_children("*", "AnimatableBody3D", true, false):
		if node.has_method("restore"):
			node.restore()


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
