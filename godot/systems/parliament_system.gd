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


func _validate_base_groups(groups: Array[InterestGroupDefinition]) -> bool:
	var ids: Dictionary[StringName, bool] = {}
	var sort_orders: Dictionary[int, bool] = {}
	for group in groups:
		if group == null:
			push_error("Base group list contains null.")
			return false
		if group.id == &"":
			push_error("Interest group has an empty id.")
			return false
		if group.base_column_weight <= 0:
			push_error("Interest group %s must have a positive base column weight." % group.id)
			return false
		if ids.has(group.id):
			push_error("Duplicate interest group id: %s" % group.id)
			return false
		if sort_orders.has(group.fixed_sort_order):
			push_error("Duplicate interest group fixed_sort_order: %s" % group.fixed_sort_order)
			return false
		ids[group.id] = true
		sort_orders[group.fixed_sort_order] = true
	return true


func allocate_base_columns(
	seat_count: int, groups: Array[InterestGroupDefinition]
) -> Dictionary[StringName, int]:
	var allocation: Dictionary[StringName, int] = {}
	if seat_count < 0:
		push_error("Seat count cannot be negative.")
		return allocation
	if groups.is_empty():
		if seat_count > 0:
			push_error("Cannot allocate seats without interest groups.")
		return allocation
	if not _validate_base_groups(groups):
		return allocation
	var total_weight := 0
	for group in groups:
		total_weight += group.base_column_weight
		allocation[group.id] = 0
	var remainders: Dictionary[StringName, float] = {}
	var assigned_seats := 0
	for group in groups:
		var exact_quota := float(seat_count) * float(group.base_column_weight) / float(total_weight)
		var integer_part := floori(exact_quota)
		allocation[group.id] = integer_part
		remainders[group.id] = (exact_quota - float(integer_part))
		assigned_seats += integer_part
	var remaining_seats := seat_count - assigned_seats
	while remaining_seats > 0:
		var best_group: InterestGroupDefinition = null
		var best_remainder := -1.0
		for group in groups:
			var remainder := remainders[group.id]
			if remainder < 0.0:
				continue
			if best_group == null:
				best_group = group
				best_remainder = remainder
				continue
			if remainder > best_remainder + 0.000001:
				best_group = group
				best_remainder = remainder
				continue
			if (
				absf(remainder - best_remainder) <= 0.000001
				and group.fixed_sort_order < best_group.fixed_sort_order
			):
				best_group = group
				best_remainder = remainder
		if best_group == null:
			push_error("Failed to allocate remaining base seats.")
			break
		allocation[best_group.id] += 1
		remainders[best_group.id] = -1.0
		remaining_seats -= 1
	return allocation


func _sort_group_by_fixed_order(a: InterestGroupDefinition, b: InterestGroupDefinition) -> bool:
	return a.fixed_sort_order < b.fixed_sort_order


func create_base_row(
	race_id: StringName,
	seat_count: int,
	groups: Array[InterestGroupDefinition],
	first_seat_id: int = 0
) -> Array[SeatState]:
	var result: Array[SeatState] = []
	var allocation := allocate_base_columns(seat_count, groups)
	if seat_count > 0 and allocation.is_empty():
		return result
	var ordered_groups := groups.duplicate()
	ordered_groups.sort_custom(_sort_group_by_fixed_order)
	var next_seat_id := first_seat_id
	for group in ordered_groups:
		var group_seat_count: int = allocation.get(group.id, 0)
		for i in range(group_seat_count):
			var seat := SeatState.new(next_seat_id, race_id, group.id, group.id)
			result.append(seat)
			next_seat_id += 1
	return result
