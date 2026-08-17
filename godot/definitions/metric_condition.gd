extends Resource
class_name MetricCondition

enum Operator {
	LESS_THAN,
	LESS_THAN_OR_EQUAL,
	GREATER_THAN,
	GREATER_THAN_OR_EQUAL,
}

@export var left_metric: Metric.Id = Metric.Id.TAX
@export var operator: Operator = Operator.LESS_THAN
@export var right_metric: Metric.Id = Metric.Id.TRADE
@export var right_multiplier: float = 1.0


func is_met(values: MetricValues) -> bool:
	var left_value := float(values.get_value(left_metric))
	var right_value := float(values.get_value(right_metric)) * right_multiplier

	match operator:
		Operator.LESS_THAN:
			return left_value < right_value
		Operator.LESS_THAN_OR_EQUAL:
			return left_value <= right_value
		Operator.GREATER_THAN:
			return left_value > right_value
		Operator.GREATER_THAN_OR_EQUAL:
			return left_value >= right_value
		_:
			push_error("Unknown metric condition operator: %s" % operator)
			return false
