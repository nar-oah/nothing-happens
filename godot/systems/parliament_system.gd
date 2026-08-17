extends RefCounted
class_name ParliamentSystem

const ANNUAL_COLORING_RATE: float = 0.65


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


func get_race_seat_rate(state: RunState, race_id: StringName) -> float:
	if state.seats.is_empty():
		return 0.0
	var count := 0
	for seat in state.seats:
		if seat.race_id == race_id:
			count += 1
	return float(count) / float(state.seats.size())


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


func create_full_parliament(
	races: Array[RaceState], groups: Array[InterestGroupDefinition]
) -> Array[SeatState]:
	var result: Array[SeatState] = []
	var next_seat_id := 0
	for race in races:
		if race == null or race.definition == null:
			continue
		var row := create_base_row(race.get_id(), race.seat_count, groups, next_seat_id)
		result.append_array(row)
		next_seat_id += row.size()
	return result


func rebuild_all_rows(
	state: RunState, groups: Array[InterestGroupDefinition]
) -> void:
	state.seats = create_full_parliament(state.races, groups)


func replace_race_row(
	state: RunState, race: RaceState, groups: Array[InterestGroupDefinition]
) -> void:
	var existing_by_race: Dictionary[StringName, Array] = {}
	for seat in state.seats:
		if not existing_by_race.has(seat.race_id):
			existing_by_race[seat.race_id] = []
		existing_by_race[seat.race_id].append(seat)
	var result: Array[SeatState] = []
	for row_race in state.races:
		if row_race.get_id() == race.get_id():
			result.append_array(create_base_row(race.get_id(), race.seat_count, groups))
		else:
			for seat in existing_by_race.get(row_race.get_id(), []):
				result.append(seat)
	for i in range(result.size()):
		result[i].seat_id = i
	state.seats = result


func record_authorized_proposal_slots(
	state: RunState, proposals: Array[ProposalInstance]
) -> void:
	for proposal in proposals:
		if proposal == null or proposal.source_group_id == &"":
			continue
		state.annual_proposal_slot_counts[proposal.source_group_id] = (
			state.annual_proposal_slot_counts.get(proposal.source_group_id, 0) + 1
		)


func get_annual_source_shares(state: RunState) -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {}
	var total := 0
	for count in state.annual_proposal_slot_counts.values():
		total += maxi(int(count), 0)
	if total <= 0:
		return result
	for group_id in state.annual_proposal_slot_counts:
		var count: int = state.annual_proposal_slot_counts[group_id]
		if count > 0:
			result[group_id] = float(count) / float(total)
	return result


func apply_annual_coloring(
	state: RunState,
	groups: Array[InterestGroupDefinition],
	random_system: RandomSystem,
	coloring_rate: float = ANNUAL_COLORING_RATE
) -> void:
	for seat in state.seats:
		seat.actual_group_id = seat.base_group_id
		seat.influence_priority = 5
	var shares := get_annual_source_shares(state)
	if shares.is_empty():
		return
	var source_ids: Array[StringName] = []
	var weights: Array[float] = []
	for group in groups:
		if group != null and shares.has(group.id):
			source_ids.append(group.id)
			weights.append(shares[group.id])
	if source_ids.is_empty():
		return
	for seat in state.seats:
		if not random_system.chance(coloring_rate):
			continue
		var index := random_system.weighted_index(weights)
		if index >= 0:
			seat.actual_group_id = source_ids[index]
