extends RaceDefinition
class_name BiyiRaceDefinition

@export_group("阴项")
@export var yin_tax: bool = false
@export var yin_consumption: bool = false
@export var yin_production: bool = false
@export var yin_employment: bool = false
@export var yin_investment: bool = false

@export_group("阳项")
@export var yang_tax: bool = false
@export var yang_consumption: bool = false
@export var yang_production: bool = false
@export var yang_employment: bool = false
@export var yang_investment: bool = false


func modify_vote(vote_context) -> void:
	if not yin_yang_enabled or vote_context == null or vote_context.vote == null or vote_context.seat == null:
		return
	var relation: float = (
		vote_context.seat.odd_month_relation
		if _is_yin_month(vote_context.run_context)
		else vote_context.seat.even_month_relation
	)
	vote_context.vote.add_reason(&"biyi_half_relation", relation)


func is_vote_metric_active(metric: Metric.Id, context) -> bool:
	if not yin_yang_enabled:
		return true
	return is_yin_metric(metric) if _is_yin_month(context) else is_yang_metric(metric)


func get_effective_expectation(
	base_target: int, metric: Metric.Id, context, _race_state
) -> int:
	if not yin_yang_enabled:
		return base_target
	var month_sign := get_yin_yang_month_sign(metric, context.state.month)
	if month_sign == 0 or get_stance(metric) == Metric.Direction.NONE:
		return base_target
	return roundi(float(base_target) * (1.0 + float(month_sign) * yin_yang_adjustment_rate))


func is_yin_metric(metric: Metric.Id) -> bool:
	match metric:
		Metric.Id.TAX:
			return yin_tax
		Metric.Id.CONSUMPTION:
			return yin_consumption
		Metric.Id.PRODUCTION:
			return yin_production
		Metric.Id.EMPLOYMENT:
			return yin_employment
		Metric.Id.INVESTMENT:
			return yin_investment
	return false


func is_yang_metric(metric: Metric.Id) -> bool:
	match metric:
		Metric.Id.TAX:
			return yang_tax
		Metric.Id.CONSUMPTION:
			return yang_consumption
		Metric.Id.PRODUCTION:
			return yang_production
		Metric.Id.EMPLOYMENT:
			return yang_employment
		Metric.Id.INVESTMENT:
			return yang_investment
	return false


func get_yin_yang_month_sign(metric: Metric.Id, month: int) -> int:
	var is_yin := is_yin_metric(metric)
	var is_yang := is_yang_metric(metric)
	if is_yin == is_yang:
		return 0
	var yin_month := month % 2 == 1
	return 1 if (yin_month and is_yin) or (not yin_month and is_yang) else -1


func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"yin_price":
			yin_consumption = bool(value)
			return true
		&"yin_wage":
			yin_production = bool(value)
			return true
		&"yin_trade":
			yin_investment = bool(value)
			return true
		&"yang_price":
			yang_consumption = bool(value)
			return true
		&"yang_wage":
			yang_production = bool(value)
			return true
		&"yang_trade":
			yang_investment = bool(value)
			return true
	return super._set(property, value)


func _is_yin_month(context) -> bool:
	return context != null and context.state != null and context.state.month % 2 == 1
