extends ConstitutionEffect
class_name DraftMetricRequirementEffect

@export var races: Array[RaceDefinition] = []
@export var metrics: Array[Metric.Id] = []


func _init() -> void:
	display_name = "草案指标门槛"
	timing = Timing.BEFORE_DRAFT_SUBMIT


func validate_draft(
	context: RunContext, _draft: DraftBillState, pure_target: MetricValues
) -> bool:
	if context == null or pure_target == null:
		return false
	for metric in metrics:
		for race in context.race_definitions:
			if not _matches_race(races, race):
				continue
			var race_state := context.state.get_race(race)
			if race_state == null:
				continue
			var requirement := context.race_system.get_effective_expectation(race_state, metric, context)
			if pure_target.get_value(metric) < requirement:
				return false
	return true


func get_description() -> String:
	return "草案的%s纯提案目标不得低于%s的年度期望" % [_format_metrics(metrics), _format_races(races)]
