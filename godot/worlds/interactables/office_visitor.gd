extends Area2D
class_name OfficeVisitor

signal clicked

@export_range(0.1, 1.0, 0.05) var hitbox_ratio: float = 0.8
@onready var visual: Sprite2D = $Visual
@onready var hitbox: CollisionShape2D = $Hitbox


func set_portrait(texture: Texture2D) -> void:
	visual.texture = texture
	_update_hitbox()


func _update_hitbox() -> void:
	var shape := hitbox.shape as RectangleShape2D
	shape.size = visual.texture.get_size() * hitbox_ratio


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit()
