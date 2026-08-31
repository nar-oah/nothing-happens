extends ConstitutionEffect
class_name StrikeEffect

@export var interest_group: InterestGroupDefinition
@export var races: Array[RaceDefinition] = []
@export var metric: Metric.Id = Metric.Id.EMPLOYMENT


func _init() -> void:
	timing = Timing.BEFORE_SUPPORT_CALCULATION


func get_description() -> String:
	var group_name := "" if interest_group == null else interest_group.display_name
	return "受%s影响的%s在草案使%s低于年初值时缺席表决" % [group_name, _format_races(races), Metric.display_name(metric)]
