extends InteractiveSceneElement
class_name ParliamentDoor

@export var is_left: bool = false

var visuals: Array[Sprite2D] = []


func _ready() -> void:
	super._ready()
	visual.flip_h = is_left
	visuals.append(visual)

	if visual.texture == null:
		return
	var direction := -1.0 if is_left else 1.0
	var spacing := float(visual.texture.get_width()) - 5.0
	for index in range(1, 4):
		var visual_copy := visual.duplicate() as Sprite2D
		visual_copy.name = "Visual%d" % (index + 1)
		visual_copy.position = visual.position + Vector2(direction * spacing * index, 0.0)
		add_child(visual_copy)
		visuals.append(visual_copy)


func _on_mouse_entered() -> void:
	var texture := hover_texture if is_instance_of(hover_texture, Texture2D) else normal_texture
	for item in visuals:
		item.texture = texture


func _on_mouse_exited() -> void:
	for item in visuals:
		item.texture = normal_texture
