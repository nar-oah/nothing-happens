extends RefCounted
class_name ParliamentSystem


func get_group_influence_count(state: RunState, group_id: StringName) -> int:
	var count := 0
	for seat in state.seats:
		if seat.actual_group_id == group_id:
			count += 1
	return count


func get_group_influence_rate(state: RunState, group_id: StringName) -> float:
	var assigned_seat_count := 0
	for seat in state.seats:
		if seat.actual_group_id != &"":
			assigned_seat_count += 1
	if assigned_seat_count == 0:
		return 0.0
	var influence_count := get_group_influence_count(state, group_id)
	return float(influence_count) / float(assigned_seat_count)
