extends RefCounted
class_name TimeSystem


func advance_month(state: RunState) -> void:
	if state.month == 12:
		state.year += 1
		state.month = 0
		return
	state.month += 1
