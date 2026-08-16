extends RefCounted
class_name RunState

var year: int = 1
var month: int = 1
var metrics: MetricValues


func _init() -> void:
	metrics = MetricValues.new()
