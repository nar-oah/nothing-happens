extends RefCounted
class_name FlowController

var state: RunState
var time_system: TimeSystem


func setup(run_state: RunState, run_time_system: TimeSystem) -> void:
	state = run_state
	time_system = run_time_system


func advance_month() -> void:
	time_system.advance_month(state)
