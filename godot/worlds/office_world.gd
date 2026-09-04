extends Node2D

signal parliament_requested

var visitor_races: Array[RaceDefinition] = []


func _ready() -> void:
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()


func _update_layout() -> void:
	var size := get_viewport_rect().size
	$LeftAnchor.position = Vector2(0, size.y)
	$CenterAnchor.position = Vector2(size.x / 2.0, size.y)
	$RightAnchor.position = size


func _on_door_clicked() -> void:
	parliament_requested.emit()


func set_visitor_races(value: Array[RaceDefinition]) -> void:
	visitor_races = value


func has_visitors() -> bool:
	return not visitor_races.is_empty()


func get_current_visitor() -> RaceDefinition:
	return null if visitor_races.is_empty() else visitor_races[0]
