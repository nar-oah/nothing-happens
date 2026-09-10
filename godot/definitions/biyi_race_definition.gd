extends RaceDefinition
class_name BiyiRaceDefinition

@export_group("阴阳半身")
@export var yang_portrait: Texture2D
@export var yang_hover_portrait: Texture2D


func get_portrait(month: int) -> Texture2D:
	if month % 2 == 0 and yang_portrait != null:
		return yang_portrait
	return portrait


func get_hover_portrait(month: int) -> Texture2D:
	if month % 2 == 0 and yang_portrait != null:
		return yang_hover_portrait
	return hover_portrait


func is_vote_metric_active(metric: Metric.Id, context) -> bool:
	if yin_yang_enabled and metric == Metric.Id.EMPLOYMENT and get_stance(metric) != Metric.Direction.NONE:
		return true
	return super.is_vote_metric_active(metric, context)


func get_effective_expectation(base_target: int, metric: Metric.Id, context, race_state) -> int:
	if yin_yang_enabled and metric == Metric.Id.EMPLOYMENT and get_stance(metric) != Metric.Direction.NONE:
		return base_target
	return super.get_effective_expectation(base_target, metric, context, race_state)
