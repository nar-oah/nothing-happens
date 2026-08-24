extends Node
class_name SceneManager

signal world_changed(scene_name: String, world: Node)

@export var office_scene: PackedScene
@export var parliament_scene: PackedScene

@onready var world: Node = $World

var current_world: Node
var current_scene_name: String = ""


func show_office() -> void:
	_show(office_scene, "office")


func show_parliament() -> void:
	_show(parliament_scene, "parliament")


func _show(scene: PackedScene, scene_name: String) -> void:
	if scene == null or current_scene_name == scene_name:
		return
	if current_world != null:
		current_world.free()
	current_world = scene.instantiate()
	world.add_child(current_world)
	current_scene_name = scene_name
	world_changed.emit(scene_name, current_world)
