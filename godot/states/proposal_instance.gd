extends RefCounted
class_name ProposalInstance

var definition_id: StringName
var source_group_id: StringName
var base_effect: MetricVector
var positive_effect: MetricVector
var digestion_speed: float = 1.0


func _init() -> void:
	base_effect = MetricVector.new()
	positive_effect = MetricVector.new()


func get_total_effect() -> MetricVector:
	var result := base_effect.copy()
	result.add(positive_effect)
	return result


func copy() -> ProposalInstance:
	var result := ProposalInstance.new()
	result.definition_id = definition_id
	result.source_group_id = source_group_id
	result.base_effect = base_effect.copy()
	result.positive_effect = positive_effect.copy()
	result.digestion_speed = digestion_speed
	return result
