extends Resource
class_name RaceDefinition

@export var id: StringName
@export var display_name: String

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

@export var special_group_id: StringName
@export var local_group_prefix: StringName = &"local"


func get_stance(metric: Metric.Id) -> MetricStanceDefinition.Direction:
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
	return MetricStanceDefinition.Direction.NONE


func get_stance_metrics() -> Array[Metric.Id]:
	var result: Array[Metric.Id] = []
	for metric in Metric.all_ids():
		if get_stance(metric) != MetricStanceDefinition.Direction.NONE:
			result.append(metric)
	return result


func _resolve_stance(
	increase: bool, decrease: bool, metric: Metric.Id
) -> MetricStanceDefinition.Direction:
	if increase and decrease:
		push_error(
			(
				"Race %s cannot both increase and decrease %s."
				% [
					id,
					Metric.display_name(metric),
				]
			)
		)
		return MetricStanceDefinition.Direction.NONE
	if increase:
		return MetricStanceDefinition.Direction.HIGHER
	if decrease:
		return MetricStanceDefinition.Direction.LOWER
	return MetricStanceDefinition.Direction.NONE
