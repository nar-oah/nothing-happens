extends ConstitutionEffect
class_name ModifyRaceEffect

@export var target_races: Array[RaceDefinition] = []
@export var source_races: Array[RaceDefinition] = []


func _init() -> void:
	display_name = "种族制度状态"


func apply(context: RunContext) -> void:
	if context == null or context.state == null:
		return
	var count := mini(target_races.size(), source_races.size())
	for index in range(count):
		var target := target_races[index]
		var source := source_races[index]
		if target == null or source == null:
			continue
		var state := context.state.get_race(target)
		if state != null:
			state.active_definition = source


func get_description() -> String:
	return _t("修改种族：%s") % _format_races(target_races)
