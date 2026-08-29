extends Resource
class_name InterestGroupDefinition

@export var display_name: String
@export_multiline var description: String
@export_range(1, 999, 1) var base_column_weight: int = 3

@export_group("希望降低")
@export var decrease_tax: bool = false
@export var decrease_consumption: bool = false
@export var decrease_production: bool = false
@export var decrease_employment: bool = false
@export var decrease_investment: bool = false


func get_stance(metric: Metric.Id) -> Metric.Direction:
	return Metric.Direction.LOWER if _decreases_metric(metric) else Metric.Direction.NONE


func get_stance_metrics() -> Array[Metric.Id]:
	var result: Array[Metric.Id] = []
	for metric in Metric.all_ids():
		if _decreases_metric(metric):
			result.append(metric)
	return result


func _decreases_metric(metric: Metric.Id) -> bool:
	match metric:
		Metric.Id.TAX:
			return decrease_tax
		Metric.Id.CONSUMPTION:
			return decrease_consumption
		Metric.Id.PRODUCTION:
			return decrease_production
		Metric.Id.EMPLOYMENT:
			return decrease_employment
		Metric.Id.INVESTMENT:
			return decrease_investment
	return false


func _set(property: StringName, value: Variant) -> bool:
	match property:
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
