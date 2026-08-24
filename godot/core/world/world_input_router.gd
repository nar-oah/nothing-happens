extends Node
class_name WorldInputRouter

signal world_clicked(position: Vector2, button_index: MouseButton)
signal world_interaction(action: StringName, payload: Dictionary)

var scene_manager: SceneManager


func setup(manager: SceneManager) -> void:
	scene_manager = manager


func report_interaction(action: StringName, payload: Dictionary = {}) -> void:
	world_interaction.emit(action, payload)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	world_clicked.emit(event.position, event.button_index)
	if (
		scene_manager != null
		and scene_manager.current_world != null
		and scene_manager.current_world.has_method("handle_world_input")
	):
		scene_manager.current_world.call("handle_world_input", event)
