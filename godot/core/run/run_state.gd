extends RefCounted
class_name RunState

var year: int = 1
var month: int = 1
var metrics: MetricValues
var active_bill: ActiveBillState
var proposal_hand: Array[ProposalInstance] = []


func _init() -> void:
	metrics = MetricValues.new()
