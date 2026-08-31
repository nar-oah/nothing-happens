extends Resource
class_name RaceDefinition

@export var display_name: String
@export_multiline var description: String
@export_multiline var event_description: String
@export var fixed_interest_group: InterestGroupDefinition

@export_group("制度参数")
@export_range(-1.0, 1.0, 0.01) var expectation_growth_rate: float = 0.10
@export_range(0.0, 1.0, 0.01) var visit_probability: float = 0.0
@export var yin_yang_enabled: bool = false
@export_range(0.0, 1.0, 0.01) var yin_yang_adjustment_rate: float = 0.10

@export_group("希望提高")
@export var increase_tax: bool = false
@export var increase_consumption: bool = false
@export var increase_production: bool = false
@export var increase_employment: bool = false
@export var increase_investment: bool = false


func get_stance(metric: Metric.Id) -> Metric.Direction:
	return Metric.Direction.HIGHER if _increases_metric(metric) else Metric.Direction.NONE


func get_stance_metrics() -> Array[Metric.Id]:
	var result: Array[Metric.Id] = []
	for metric in Metric.all_ids():
		if _increases_metric(metric):
			result.append(metric)
	return result


func on_month_start(_context, _race_state) -> void:
	pass


func modify_vote(_vote_context) -> void:
	pass


func is_vote_metric_active(_metric: Metric.Id, _context) -> bool:
	return true


func get_effective_expectation(
	base_target: int, metric: Metric.Id, context, _race_state
) -> int:
	if not yin_yang_enabled or context == null or context.state == null or get_stance(metric) == Metric.Direction.NONE:
		return base_target
	var sign := 1.0 if context.state.month % 2 == 1 else -1.0
	return roundi(float(base_target) * (1.0 + sign * yin_yang_adjustment_rate))


func _increases_metric(metric: Metric.Id) -> bool:
	match metric:
		Metric.Id.TAX:
			return increase_tax
		Metric.Id.CONSUMPTION:
			return increase_consumption
		Metric.Id.PRODUCTION:
			return increase_production
		Metric.Id.EMPLOYMENT:
			return increase_employment
		Metric.Id.INVESTMENT:
			return increase_investment
	return false


func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"increase_price":
			increase_consumption = bool(value)
			return true
		&"increase_wage":
			increase_production = bool(value)
			return true
		&"increase_trade":
			increase_investment = bool(value)
			return true
		&"decrease_tax", &"decrease_consumption", &"decrease_production", &"decrease_employment", &"decrease_investment", &"decrease_price", &"decrease_wage", &"decrease_trade":
			return true
	return false
