extends Area2D
class_name OfficeVisitor

signal clicked

@export_range(0.1, 1.0, 0.05) var hitbox_ratio: float = 0.8
var normal_texture: Texture2D
var hover_texture: Texture2D
@onready var visual: Sprite2D = $Visual
@onready var hitbox: CollisionShape2D = $Hitbox


func set_portrait(portrait: Texture2D, hover: Texture2D) -> void:
	visual.texture = portrait
	normal_texture = portrait
	hover_texture = hover
	_update_hitbox()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _update_hitbox() -> void:
	var shape := hitbox.shape as RectangleShape2D
	shape.size = visual.texture.get_size() * hitbox_ratio


func _on_mouse_entered() -> void:
	visual.texture = hover_texture if is_instance_of(hover_texture, Texture2D) else normal_texture


func _on_mouse_exited() -> void:
	visual.texture = normal_texture


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit()
