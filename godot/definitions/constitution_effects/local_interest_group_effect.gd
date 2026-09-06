extends ConstitutionEffect
class_name LocalInterestGroupEffect

@export var races: Array[RaceDefinition] = []
@export var decrease_metric: Metric.Id = Metric.Id.TAX
@export_range(1, 999, 1) var base_column_weight: int = 1


func _init() -> void:
	display_name = "地方利益集团"
	timing = Timing.AFTER_GROUP_ALLOCATION


func apply(context: RunContext) -> void:
	if context != null and context.parliament_system != null:
		context.parliament_system.apply_local_interest_groups(context, self)


func applies_to(race: RaceDefinition) -> bool:
	return _matches_race(races, race)


func get_description() -> String:
	return _t("%s席位改由对应地方利益集团影响；地方集团要求降低%s") % [_format_races(races), _t(Metric.display_name(decrease_metric))]
