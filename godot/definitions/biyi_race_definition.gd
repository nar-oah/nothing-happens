extends RaceDefinition
class_name BiyiRaceDefinition

@export_group("阴项")
@export var yin_tax: bool = false
@export var yin_price: bool = false
@export var yin_wage: bool = false
@export var yin_employment: bool = false
@export var yin_trade: bool = false

@export_group("阳项")
@export var yang_tax: bool = false
@export var yang_price: bool = false
@export var yang_wage: bool = false
@export var yang_employment: bool = false
@export var yang_trade: bool = false


func on_month_start(context, race_state) -> void:
	if race_state != null:
		race_state.yin_active = _is_yin_month(context)


func modify_vote(vote_context) -> void:
	if vote_context == null or vote_context.vote == null or vote_context.seat == null:
		return
	var relation: float = (
		vote_context.seat.odd_month_relation
		if _is_yin_month(vote_context.run_context)
		else vote_context.seat.even_month_relation
	)
	vote_context.vote.add_reason(&"biyi_half_relation", relation)


func is_vote_metric_active(metric: Metric.Id, context) -> bool:
	return is_yin_metric(metric) if _is_yin_month(context) else is_yang_metric(metric)


func get_effective_expectation(
	base_target: int, metric: Metric.Id, context, race_state
) -> int:
	if race_state == null:
		return base_target
	var month_sign := get_yin_yang_month_sign(metric, context.state.month)
	var direction := get_stance(metric)
	if month_sign == 0 or direction == Metric.Direction.NONE:
		return base_target
	var adjustment := float(direction) * float(month_sign) * race_state.yin_yang_adjustment_rate
	return roundi(float(base_target) * (1.0 + adjustment))


func is_yin_metric(metric: Metric.Id) -> bool:
	match metric:
		Metric.Id.TAX:
			return yin_tax
		Metric.Id.PRICE:
			return yin_price
		Metric.Id.WAGE:
			return yin_wage
		Metric.Id.EMPLOYMENT:
			return yin_employment
		Metric.Id.TRADE:
			return yin_trade
	return false


func is_yang_metric(metric: Metric.Id) -> bool:
	match metric:
		Metric.Id.TAX:
			return yang_tax
		Metric.Id.PRICE:
			return yang_price
		Metric.Id.WAGE:
			return yang_wage
		Metric.Id.EMPLOYMENT:
			return yang_employment
		Metric.Id.TRADE:
			return yang_trade
	return false


func get_yin_yang_month_sign(metric: Metric.Id, month: int) -> int:
	var is_yin := is_yin_metric(metric)
	var is_yang := is_yang_metric(metric)
	if is_yin == is_yang:
		return 0
	var yin_month := month % 2 == 1
	return 1 if (yin_month and is_yin) or (not yin_month and is_yang) else -1


func _is_yin_month(context) -> bool:
	return context != null and context.state != null and context.state.month % 2 == 1
