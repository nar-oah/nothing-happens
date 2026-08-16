extends RefCounted
class_name ActiveBillState

var start_values: MetricValues
var pure_target: MetricValues
var proposals: Array[ActiveProposalState] = []


func _init() -> void:
	start_values = MetricValues.new()
	pure_target = MetricValues.new()
