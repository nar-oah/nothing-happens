extends Resource
class_name RaceDefinition

@export var display_name: String
@export var fixed_interest_group: InterestGroupDefinition

@export_group("希望提高")
@export var increase_tax: bool = false
@export var increase_price: bool = false
@export var increase_wage: bool = false
@export var increase_employment: bool = false
@export var increase_trade: bool = false

@export_group("希望降低")
@export var decrease_tax: bool = false
@export var decrease_price: bool = false
@export var decrease_wage: bool = false
@export var decrease_employment: bool = false
@export var decrease_trade: bool = false


func get_stance(metric: Metric.Id) -> Metric.Direction:
	match metric:
		Metric.Id.TAX:
			return _resolve_stance(increase_tax, decrease_tax, metric)
		Metric.Id.PRICE:
			return _resolve_stance(increase_price, decrease_price, metric)
		Metric.Id.WAGE:
			return _resolve_stance(increase_wage, decrease_wage, metric)
		Metric.Id.EMPLOYMENT:
			return _resolve_stance(increase_employment, decrease_employment, metric)
		Metric.Id.TRADE:
			return _resolve_stance(increase_trade, decrease_trade, metric)
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


func get_effective_expectation(
	base_target: int, _metric: Metric.Id, _context, _race_state
) -> int:
	return base_target


func _resolve_stance(increase: bool, decrease: bool, metric: Metric.Id) -> Metric.Direction:
	if increase and decrease:
		push_error(
			"Race %s cannot both increase and decrease %s."
			% [_debug_name(), Metric.display_name(metric)]
		)
		return Metric.Direction.NONE
	if increase:
		return Metric.Direction.HIGHER
	if decrease:
		return Metric.Direction.LOWER
	return Metric.Direction.NONE


func _debug_name() -> String:
	if not display_name.is_empty():
		return display_name
	if not resource_path.is_empty():
		return resource_path
	return "<unnamed>"
