extends Resource
class_name RaceDefinition

@export var display_name: String
@export_multiline var description: String
@export var fixed_interest_group: InterestGroupDefinition

@export_group("希望提高")
@export var increase_tax: bool = false
@export var increase_consumption: bool = false
@export var increase_production: bool = false
@export var increase_employment: bool = false
@export var increase_investment: bool = false

@export_group("希望降低")
@export var decrease_tax: bool = false
@export var decrease_consumption: bool = false
@export var decrease_production: bool = false
@export var decrease_employment: bool = false
@export var decrease_investment: bool = false


func get_stance(metric: Metric.Id) -> Metric.Direction:
	match metric:
		Metric.Id.TAX:
			return _resolve_stance(increase_tax, decrease_tax, metric)
		Metric.Id.CONSUMPTION:
			return _resolve_stance(increase_consumption, decrease_consumption, metric)
		Metric.Id.PRODUCTION:
			return _resolve_stance(increase_production, decrease_production, metric)
		Metric.Id.EMPLOYMENT:
			return _resolve_stance(increase_employment, decrease_employment, metric)
		Metric.Id.INVESTMENT:
			return _resolve_stance(increase_investment, decrease_investment, metric)
	return Metric.Direction.NONE


func get_stance_metrics() -> Array[Metric.Id]:
	var result: Array[Metric.Id] = []
	for metric in Metric.all_ids():
		if get_stance(metric) != Metric.Direction.NONE:
			result.append(metric)
	return result


func on_month_start(_context, _race_state) -> void:
	pass


func modify_vote(_vote_context) -> void:
	pass


func is_vote_metric_active(_metric: Metric.Id, _context) -> bool:
	return true


func get_effective_expectation(base_target: int, _metric: Metric.Id, _context, _race_state) -> int:
	return base_target


func _resolve_stance(increase: bool, decrease: bool, metric: Metric.Id) -> Metric.Direction:
	if increase and decrease:
		push_error(
			(
				"Race %s cannot both increase and decrease %s."
				% [_debug_name(), Metric.display_name(metric)]
			)
		)
		return Metric.Direction.NONE
	if increase:
		return Metric.Direction.HIGHER
	if decrease:
		return Metric.Direction.LOWER
	return Metric.Direction.NONE


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
		&"decrease_price":
			decrease_consumption = bool(value)
			return true
		&"decrease_wage":
			decrease_production = bool(value)
			return true
		&"decrease_trade":
			decrease_investment = bool(value)
			return true
	return false


func _debug_name() -> String:
	if not display_name.is_empty():
		return display_name
	if not resource_path.is_empty():
		return resource_path
	return "<unnamed>"
