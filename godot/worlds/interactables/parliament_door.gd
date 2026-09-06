extends InteractiveSceneElement
class_name ParliamentDoor

@export var is_left: bool = false


func _ready() -> void:
	super._ready()
	visual.flip_h = is_left
