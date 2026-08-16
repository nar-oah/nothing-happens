extends RefCounted
class_name RunState

var year: int = 1
var month: int = 1
var metrics: MetricValues
var active_bill: ActiveBillState


func _init() -> void:
	metrics = MetricValues.new()
