extends Area2D
class_name OfficeVisitor

signal clicked

@export_range(0.1, 1.0, 0.05) var hitbox_ratio: float = 0.8
@onready var visual: Sprite2D = $Visual
@onready var hitbox: CollisionShape2D = $Hitbox


func set_portrait(portrait: Texture2D, hover: Texture2D) -> void:
	visual.texture = portrait
	_update_hitbox()
	mouse_entered.connect(_on_mouse_entered.call(portrait, hover))
	mouse_exited.connect(_on_mouse_exited.call(portrait))


func _update_hitbox() -> void:
	var shape := hitbox.shape as RectangleShape2D
	shape.size = visual.texture.get_size() * hitbox_ratio


func _on_mouse_entered(portrait: Texture2D, hover: Texture2D) -> void:
	visual.texture = hover if is_instance_of(hover, Texture2D) else portrait


func _on_mouse_exited(portrait: Texture2D) -> void:
	visual.texture = portrait


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit()
