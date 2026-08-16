extends RefCounted
class_name ProposalInstance

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
