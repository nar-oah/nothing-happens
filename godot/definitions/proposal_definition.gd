extends Resource
class_name ProposalDefinition

@export var id: StringName
@export var display_name: String
@export var source_group_id: StringName
@export_range(0.0, 100.0, 0.5) var political_support: float = 8.0
@export var collapse_impact: float = 0.0

@export_group("负面指标槽位")
@export var affects_tax: bool = false
@export var affects_price: bool = false
@export var affects_wage: bool = false
@export var affects_employment: bool = false
@export var affects_trade: bool = false


func get_negative_slots() -> Array[Metric.Id]:
	var result: Array[Metric.Id] = []
	if affects_tax:
		result.append(Metric.Id.TAX)
	if affects_price:
		result.append(Metric.Id.PRICE)
	if affects_wage:
		result.append(Metric.Id.WAGE)
	if affects_employment:
		result.append(Metric.Id.EMPLOYMENT)
	if affects_trade:
		result.append(Metric.Id.TRADE)
	return result
