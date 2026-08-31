extends ConstitutionEffect
class_name ModifyRaceEffect

@export var target_races: Array[RaceDefinition] = []
@export var source_races: Array[RaceDefinition] = []


func get_description() -> String:
	var names := _format_races(target_races)
	return "修改种族：%s" % names
