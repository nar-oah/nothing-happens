extends ConstitutionEffect
class_name EventIntelProbabilityEffect

@export var races: Array[RaceDefinition] = []
@export_range(-1.0, 1.0, 0.01) var probability_modifier: float = 0.0


func get_description() -> String:
	return "%s事件提前获知概率%s" % [_format_races(races), _format_signed_percent(probability_modifier)]
