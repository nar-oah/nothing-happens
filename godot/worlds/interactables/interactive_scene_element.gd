extends Area2D
class_name InteractiveSceneElement

signal clicked(dialogue: SimpleDialogueDefinition)
@export var hover_texture: Texture2D
@export var dialogue: SimpleDialogueDefinition
@onready var visual: Sprite2D = $Visual
var normal_texture: Texture2D


func _ready() -> void:
	normal_texture = visual.texture
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	visual.texture = hover_texture if is_instance_of(hover_texture, Texture2D) else normal_texture


func _on_mouse_exited() -> void:
	visual.texture = normal_texture


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(dialogue)
