extends ConstitutionEffect
class_name ExpectationGrowthEffect

@export var races: Array[RaceDefinition] = []
@export_range(-1.0, 1.0, 0.01) var growth_modifier: float = 0.0


func _init() -> void:
	display_name = "年度期望增长"


func get_expectation_growth_multiplier(race: RaceDefinition) -> float:
	return maxf(0.0, 1.0 + growth_modifier) if _matches_race(races, race) else 1.0


func get_description() -> String:
	return _t("%s年度期望增长率%s") % [_format_races(races), _format_signed_percent(growth_modifier)]
