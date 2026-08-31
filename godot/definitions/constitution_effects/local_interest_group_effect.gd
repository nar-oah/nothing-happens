extends ConstitutionEffect
class_name LocalInterestGroupEffect

@export var races: Array[RaceDefinition] = []
@export var decrease_metric: Metric.Id = Metric.Id.TAX
@export_range(1, 999, 1) var base_column_weight: int = 1


func _init() -> void:
	timing = Timing.AFTER_GROUP_ALLOCATION


func get_description() -> String:
	return "%s席位改由对应地方利益集团影响；地方集团要求降低%s" % [_format_races(races), Metric.display_name(decrease_metric)]
