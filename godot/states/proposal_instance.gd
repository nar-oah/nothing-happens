extends RefCounted
class_name ProposalInstance

var source_group: InterestGroupDefinition
var base_effect: MetricVector
var positive_effect: MetricVector
var digestion_speed: float = 1.0
var collapse_impact: float = 0.0
var donation_offer: float = 0.0
var bonus_choice_resolved: bool = false


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
	result.source_group = source_group
	result.base_effect = base_effect.copy()
	result.positive_effect = positive_effect.copy()
	result.digestion_speed = digestion_speed
	result.collapse_impact = collapse_impact
	result.donation_offer = donation_offer
	result.bonus_choice_resolved = bonus_choice_resolved
	return result
