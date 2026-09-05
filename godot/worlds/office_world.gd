extends Node2D

signal parliament_requested
signal visitor_requested

@export var assistant_race: RaceDefinition
@onready var visitor: OfficeVisitor = $CenterAnchor/Visitor

var visitor_races: Array[RaceDefinition] = []
var current_month: int = 1


func _ready() -> void:
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()
	_refresh_visitor()


func _update_layout() -> void:
	var size := get_viewport_rect().size
	$LeftAnchor.position = Vector2(0, size.y)
	$CenterAnchor.position = Vector2(size.x / 2.0, size.y)
	$RightAnchor.position = size


func _on_door_clicked() -> void:
	parliament_requested.emit()


func _on_visitor_clicked() -> void:
	if has_visitors():
		visitor_requested.emit()


func set_visitor_races(value: Array[RaceDefinition]) -> void:
	visitor_races = value
	_refresh_visitor()


func set_assistant_race(value: RaceDefinition) -> void:
	assistant_race = value
	_refresh_visitor()


func set_month(value: int) -> void:
	current_month = value
	_refresh_visitor()


func has_visitors() -> bool:
	return not visitor_races.is_empty()


func get_current_visitor() -> RaceDefinition:
	return null if visitor_races.is_empty() else visitor_races[0]


func _refresh_visitor() -> void:
	var race := get_current_visitor() if has_visitors() else assistant_race
	if race == null:
		return
	visitor.set_portrait(race.get_portrait(current_month))
