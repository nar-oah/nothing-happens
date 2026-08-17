extends RefCounted
class_name TimeSystem


func advance_month(state: RunState) -> void:
	state.month += 1

	if state.month > 12:
		state.month = 1
		state.year += 1
