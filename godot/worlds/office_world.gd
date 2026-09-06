extends Node2D

signal parliament_requested
signal visitor_requested
signal simple_dialogue_requested(
	initial_text: String,
	left_option: String,
	right_option: String,
	left_content: String,
	right_content: String
)

@export var assistant_race: RaceDefinition
@export var assistant_dialogue: SimpleDialogueDefinition
@onready var visitor: OfficeVisitor = $CenterAnchor/Visitor
@onready var assistant_door: Sprite2D = $RightAnchor/Assistant

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


func _on_door_clicked(_dialogue: SimpleDialogueDefinition) -> void:
	parliament_requested.emit()


func _on_visitor_clicked() -> void:
	if has_visitors():
		visitor_requested.emit()
		assistant_door.visible = true
	else:
		request_simple_dialogue(assistant_dialogue)


func request_simple_dialogue(dialogue: SimpleDialogueDefinition) -> void:
	if dialogue == null:
		return
	simple_dialogue_requested.emit(
		_t(dialogue.initial_text),
		_t(dialogue.left_option),
		_t(dialogue.right_option),
		_t(dialogue.left_content),
		_t(dialogue.right_content)
	)


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
	assistant_door.visible = false
	var race := get_current_visitor() if has_visitors() else assistant_race
	if race == null:
		return
	visitor.set_portrait(race.get_portrait(current_month), race.get_hover_portrait(current_month))


func _on_painting_clicked(dialogue: SimpleDialogueDefinition) -> void:
	request_simple_dialogue(dialogue)


func _on_lamp_clicked(dialogue: SimpleDialogueDefinition) -> void:
	request_simple_dialogue(dialogue)


func _on_high_lamp_clicked(dialogue: SimpleDialogueDefinition) -> void:
	request_simple_dialogue(dialogue)


func _on_ornament_clicked(dialogue: SimpleDialogueDefinition) -> void:
	request_simple_dialogue(dialogue)


func _t(text: String) -> String:
	return text if text.is_empty() else str(TranslationServer.translate(text))
