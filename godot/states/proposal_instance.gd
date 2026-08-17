extends RefCounted
class_name ProposalInstance

var definition_id: StringName
var source_group_id: StringName
var base_effect: MetricVector
var positive_effect: MetricVector
var digestion_speed: float = 1.0
var political_support: float = 8.0
var collapse_impact: float = 0.0


func _init() -> void:
	base_effect = MetricVector.new()
	positive_effect = MetricVector.new()


func get_total_effect() -> MetricVector:
	var result := base_effect.copy()
	result.add(positive_effect)
	return result


func has_positive_trait() -> bool:
	return not positive_effect.is_zero()


func get_positive_metric() -> int:
	var metrics := positive_effect.non_zero_metrics()
	return -1 if metrics.is_empty() else metrics[0]


func copy() -> ProposalInstance:
	var result := ProposalInstance.new()
	result.definition_id = definition_id
	result.source_group_id = source_group_id
	result.base_effect = base_effect.copy()
	result.positive_effect = positive_effect.copy()
	result.digestion_speed = digestion_speed
	result.political_support = political_support
	result.collapse_impact = collapse_impact
	return result
