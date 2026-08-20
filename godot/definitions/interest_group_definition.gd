extends Resource
class_name InterestGroupDefinition

@export var display_name: String
@export_range(1, 999, 1) var base_column_weight: int = 3

@export_group("希望降低")
@export var decrease_tax: bool = false
@export var decrease_price: bool = false
@export var decrease_wage: bool = false
@export var decrease_employment: bool = false
@export var decrease_trade: bool = false


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
		Metric.Id.PRICE:
			return decrease_price
		Metric.Id.WAGE:
			return decrease_wage
		Metric.Id.EMPLOYMENT:
			return decrease_employment
		Metric.Id.TRADE:
			return decrease_trade
	return false
