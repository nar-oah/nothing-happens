extends Node2D
class_name ParliamentSeat

@export var seat_index: int = -1
@onready var visual: Sprite2D = $Visual
@onready var ui_anchor: Marker2D = $UIAnchor

var race: RaceDefinition


func set_race(value: RaceDefinition, month: int = 1) -> void:
	race = value
	visual.texture = null if value == null else value.get_portrait(month)


func get_normalized_ui_anchor() -> Vector2:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Vector2.ZERO
	var anchor_position := ui_anchor.get_global_transform_with_canvas().origin
	return Vector2(
		anchor_position.x / viewport_size.x,
		anchor_position.y / viewport_size.y
	)
