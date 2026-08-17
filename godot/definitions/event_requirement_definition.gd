extends Resource
class_name EventRequirementDefinition

enum Direction {
	LOWER = -1,
	HIGHER = 1,
}

@export var metric: Metric.Id = Metric.Id.TAX
@export var direction: Direction = Direction.HIGHER
@export_range(0, 999999, 1) var base_amount: int = 0


func current_required_amount(effective_intensity: float) -> float:
	return float(base_amount) * clampf(effective_intensity, 0.0, 1.0)


func satisfaction(
	current: MetricValues, baseline: MetricValues, effective_intensity: float
) -> float:
	var required := current_required_amount(effective_intensity)
	if required <= 0.0:
		return 1.0
	var achieved := float(current.get_value(metric))
	if direction == Direction.LOWER:
		achieved = float(baseline.get_value(metric) - current.get_value(metric))
	return achieved / required


func current_target(baseline: MetricValues, effective_intensity: float) -> int:
	var required := roundi(current_required_amount(effective_intensity))
	return required if direction == Direction.HIGHER else baseline.get_value(metric) - required
