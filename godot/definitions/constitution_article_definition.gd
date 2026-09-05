extends Resource
class_name ConstitutionArticleDefinition

@export var display_name: String
@export_multiline var description: String
@export var row: ConstitutionRowDefinition
@export var is_terminal: bool = false

# Kept as content-navigation metadata for boardless test/content configurations. Runtime
# constitution behavior is exclusively composed from effects below.
@export var race: RaceDefinition
@export var is_initial: bool = false
@export var prerequisite: ConstitutionArticleDefinition
@export var seat_condition: ConstitutionSeatCondition
@export var conditions: Array[ConstitutionCondition] = []

@export_group("内容")
@export var policies: Array[PolicyDefinition] = []
@export var effects: Array[ConstitutionEffect] = []


func get_race() -> RaceDefinition:
	if row != null and row.race != null:
		return row.race
	return race


func can_activate(context: RunContext) -> bool:
	for condition in conditions:
		if condition != null and not condition.is_met(context):
			return false
	return seat_condition == null or seat_condition.is_met(context)


func get_requirement_description() -> String:
	var descriptions := PackedStringArray()
	for condition in conditions:
		if condition != null:
			descriptions.append(condition.get_description())
	if seat_condition != null and seat_condition not in conditions:
		descriptions.append(seat_condition.get_description())
	if descriptions.is_empty():
		return "无"
	var description := "\n\n".join(descriptions)
	return "须同时满足：\n" + description if descriptions.size() > 1 else description
