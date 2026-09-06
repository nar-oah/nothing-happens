extends Resource
class_name RaceDefinition

const YinYangRuleDefinitionScript = preload("res://definitions/yin_yang_rule_definition.gd")

@export var display_name: String
@export_multiline var description: String
@export_multiline var event_description: String
@export var fixed_interest_group: InterestGroupDefinition
@export var portrait: Texture2D
@export var hover_portrait: Texture2D

@export_group("制度参数")
@export_range(-1.0, 1.0, 0.01) var expectation_growth_rate: float = 0.10
@export var yin_yang_enabled: bool = false

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


func get_portrait(_month: int) -> Texture2D:
	return portrait


func get_hover_portrait(_month: int) -> Texture2D:
	return hover_portrait


func on_month_start(_context, _race_state) -> void:
	pass


func modify_vote(_vote_context) -> void:
	pass


func is_vote_metric_active(metric: Metric.Id, context) -> bool:
	if not yin_yang_enabled:
		return true
	var rule: YinYangRuleDefinitionScript = _get_yin_yang_rule(context)
	if rule == null or context.state == null:
		return true
	return rule.is_yin_metric(metric) == _is_yin_month(context)


func get_effective_expectation(base_target: int, metric: Metric.Id, context, _race_state) -> int:
	if (
		not yin_yang_enabled
		or context == null
		or context.state == null
		or context.balance == null
		or get_stance(metric) == Metric.Direction.NONE
	):
		return base_target
	var rule: YinYangRuleDefinitionScript = _get_yin_yang_rule(context)
	if rule == null:
		return base_target
	var strengthened: bool = rule.is_yin_metric(metric) == _is_yin_month(context)
	var sign := 1.0 if strengthened else -1.0
	return roundi(float(base_target) * (1.0 + sign * context.balance.yin_yang_adjustment_rate))


func _get_yin_yang_rule(context) -> YinYangRuleDefinitionScript:
	if context == null or context.balance == null:
		return null
	return context.balance.yin_yang_rule


func _is_yin_month(context) -> bool:
	return context != null and context.state != null and context.state.month % 2 == 1


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
