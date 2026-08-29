extends Resource
class_name PolicyEffect

enum Formula {
	METRIC_VALUE,
	METRIC_GAP,
}

@export var target_metric: Metric.Id = Metric.Id.TAX
@export var formula: Formula = Formula.METRIC_GAP
@export var source_a: Metric.Id = Metric.Id.INVESTMENT
@export var source_b: Metric.Id = Metric.Id.TAX
@export var multiplier: float = 1.0


func calculate_amount(snapshot: MetricValues) -> int:
	var raw_value: float

	match formula:
		Formula.METRIC_VALUE:
			raw_value = float(snapshot.get_value(source_a))
		Formula.METRIC_GAP:
			raw_value = (float(snapshot.get_value(source_a)) - float(snapshot.get_value(source_b)))
		_:
			push_error("Unknown policy effect formula: %s" % formula)
			return 0

	return roundi(raw_value * multiplier)
