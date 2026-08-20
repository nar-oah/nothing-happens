extends RefCounted
class_name ParliamentSystem


func initialize_seats(state: RunState, definitions: Array[SeatDefinition]) -> void:
	state.seats.clear()
	var seen: Dictionary[SeatDefinition, bool] = {}
	for definition in definitions:
		if definition == null or seen.has(definition):
			push_error("Seat definitions must be unique non-null Resources.")
			continue
		seen[definition] = true
		state.seats.append(SeatState.new(definition))


func get_race_seat_count(state: RunState, race: RaceDefinition) -> int:
	var count := 0
	for seat in state.seats:
		if seat.race == race:
			count += 1
	return count


func get_race_seats(state: RunState, race: RaceDefinition) -> Array[SeatState]:
	var result: Array[SeatState] = []
	for seat in state.seats:
		if seat.race == race:
			result.append(seat)
	return result


func get_race_seat_rate(state: RunState, race: RaceDefinition) -> float:
	if state.seats.is_empty():
		return 0.0
	return float(get_race_seat_count(state, race)) / float(state.seats.size())


func get_influenceable_seats(
	state: RunState, race: RaceDefinition = null
) -> Array[SeatState]:
	var result: Array[SeatState] = []
	for seat in state.seats:
		if seat.base_group == null and seat.actual_group == null:
			continue
		if race == null or seat.race == race:
			result.append(seat)
	return result


func get_group_influence_count(
	state: RunState, group: InterestGroupDefinition, race: RaceDefinition = null
) -> int:
	var count := 0
	for seat in get_influenceable_seats(state, race):
		if seat.actual_group == group:
			count += 1
	return count


func get_group_influence_rate(
	state: RunState, group: InterestGroupDefinition, race: RaceDefinition = null
) -> float:
	var seats := get_influenceable_seats(state, race)
	if seats.is_empty():
		return 0.0
	return float(get_group_influence_count(state, group, race)) / float(seats.size())


func allocate_base_columns(
	seat_count: int, groups: Array[InterestGroupDefinition]
) -> Dictionary[InterestGroupDefinition, int]:
	var allocation: Dictionary[InterestGroupDefinition, int] = {}
	if seat_count < 0 or (seat_count > 0 and groups.is_empty()):
		push_error("Cannot allocate base columns for the supplied content.")
		return allocation
	var total_weight := 0
	for group in groups:
		if group == null or allocation.has(group) or group.base_column_weight <= 0:
			push_error("Interest groups must be unique and have positive column weight.")
			return allocation
		allocation[group] = 0
		total_weight += group.base_column_weight
	var remainders: Dictionary[InterestGroupDefinition, float] = {}
	var assigned := 0
	for group in groups:
		var exact := float(seat_count) * float(group.base_column_weight) / float(total_weight)
		var whole := floori(exact)
		allocation[group] = whole
		remainders[group] = exact - float(whole)
		assigned += whole
	while assigned < seat_count:
		var best: InterestGroupDefinition
		var best_remainder := -1.0
		for group in groups:
			var remainder: float = remainders[group]
			if remainder > best_remainder:
				best = group
				best_remainder = remainder
		if best == null:
			break
		allocation[best] += 1
		remainders[best] = -1.0
		assigned += 1
	return allocation


func initialize_base_groups(
	state: RunState, groups: Array[InterestGroupDefinition]
) -> void:
	var allocation := allocate_base_columns(state.seats.size(), groups)
	var seat_index := 0
	for group in groups:
		var count: int = allocation.get(group, 0)
		for index in range(count):
			if seat_index >= state.seats.size():
				return
			state.seats[seat_index].base_group = group
			state.seats[seat_index].annual_group = group
			state.seats[seat_index].actual_group = group
			seat_index += 1


func assign_race_distribution(
	state: RunState,
	races: Array[RaceDefinition],
	target_counts: Dictionary[RaceDefinition, int]
) -> bool:
	var remaining := target_counts.duplicate()
	var reserved: Dictionary[SeatState, bool] = {}
	for seat in state.seats:
		var anchor := seat.definition.anchor_race
		if anchor != null and int(remaining.get(anchor, 0)) > 0:
			seat.race = anchor
			remaining[anchor] = int(remaining[anchor]) - 1
			reserved[seat] = true
	for seat in state.seats:
		if reserved.has(seat):
			continue
		if seat.race != null and int(remaining.get(seat.race, 0)) > 0:
			remaining[seat.race] = int(remaining[seat.race]) - 1
			reserved[seat] = true
	for seat in state.seats:
		if reserved.has(seat):
			continue
		seat.race = null
		for race in races:
			if int(remaining.get(race, 0)) <= 0:
				continue
			seat.race = race
			remaining[race] = int(remaining[race]) - 1
			break
		if seat.race == null:
			push_error("Race distribution did not fill every permanent seat.")
			return false
	for race in races:
		if int(remaining.get(race, 0)) != 0:
			push_error("Race distribution has an unassigned quota.")
			return false
	return validate_anchor_invariants(state, races)


func validate_anchor_invariants(
	state: RunState, races: Array[RaceDefinition]
) -> bool:
	for race in races:
		var count := get_race_seat_count(state, race)
		if count != 1:
			continue
		var anchor := _get_anchor_seat(state, race)
		if anchor != null and anchor.race != race:
			push_error("A race's final seat must occupy its anchor.")
			return false
	return true


func record_authorized_proposal_slots(
	state: RunState, proposals: Array[ProposalInstance]
) -> void:
	for proposal in proposals:
		if proposal == null or proposal.source_group == null:
			continue
		state.annual_proposal_slot_counts[proposal.source_group] = (
			int(state.annual_proposal_slot_counts.get(proposal.source_group, 0)) + 1
		)


func get_annual_source_shares(
	state: RunState
) -> Dictionary[InterestGroupDefinition, float]:
	var result: Dictionary[InterestGroupDefinition, float] = {}
	var total := 0
	for count in state.annual_proposal_slot_counts.values():
		total += maxi(int(count), 0)
	if total <= 0:
		return result
	for group in state.annual_proposal_slot_counts:
		var count: int = state.annual_proposal_slot_counts[group]
		if count > 0:
			result[group] = float(count) / float(total)
	return result


func apply_annual_coloring(context: RunContext) -> void:
	for seat in context.state.seats:
		seat.annual_group = _resolve_group(context.state, seat.base_group)
		seat.actual_group = seat.annual_group
	var shares := get_annual_source_shares(context.state)
	if shares.is_empty():
		return
	var groups := _get_stable_groups(context)
	var sources: Array[InterestGroupDefinition] = []
	var weights: Array[float] = []
	for group in groups:
		if shares.has(group):
			sources.append(group)
			weights.append(shares[group])
	for seat in get_influenceable_seats(context.state):
		if sources.is_empty() or not context.random_system.chance(
			context.balance.annual_group_coloring_rate
		):
			continue
		var index := context.random_system.weighted_index(weights)
		if index >= 0:
			seat.annual_group = _resolve_group(context.state, sources[index])
			seat.actual_group = seat.annual_group


func can_reassign_seat(
	context: RunContext, seat: SeatState, target: RaceDefinition
) -> bool:
	if (
		seat == null
		or target == null
		or target not in context.race_definitions
		or seat not in context.state.seats
		or seat.race == target
	):
		return false
	var target_constraint := context.constitution_system.get_race_seat_constraint(
		context, target
	)
	var target_count := get_race_seat_count(context.state, target)
	if target_constraint.maximum_count >= 0 and target_count >= target_constraint.maximum_count:
		return false
	var target_anchor := _get_anchor_seat(context.state, target)
	if target_count == 0 and target_anchor != null and seat != target_anchor:
		return false
	var donor := seat.race
	if donor == null:
		return true
	var donor_constraint := context.constitution_system.get_race_seat_constraint(context, donor)
	var donor_count := get_race_seat_count(context.state, donor)
	if donor_count - 1 < donor_constraint.minimum_count:
		return false
	if donor_count - 1 == 1:
		var anchor := _get_anchor_seat(context.state, donor)
		if anchor != null and (anchor == seat or anchor.race != donor):
			return false
	return true


func reassign_seat(
	context: RunContext, seat: SeatState, target: RaceDefinition
) -> bool:
	if not can_reassign_seat(context, seat, target):
		return false
	var previous := seat.race
	seat.race = target
	if validate_anchor_invariants(context.state, context.race_definitions):
		return true
	seat.race = previous
	return false


func use_petition(context: RunContext) -> bool:
	var state := context.state
	if state.petition_race == null or state.petition_used_this_year >= state.petition_limit:
		return false
	var candidates: Array[SeatState] = []
	for seat in state.seats:
		if can_reassign_seat(context, seat, state.petition_race):
			candidates.append(seat)
	if candidates.is_empty():
		return false
	var selected := candidates[context.random_system.random_int(0, candidates.size() - 1)]
	if not reassign_seat(context, selected, state.petition_race):
		return false
	state.petition_used_this_year += 1
	context.collapse_system.record_intervention(
		context, &"imperial_petition", context.balance.petition_intervention_pressure
	)
	return true


func _get_anchor_seat(state: RunState, race: RaceDefinition) -> SeatState:
	for seat in state.seats:
		if seat.definition.anchor_race == race:
			return seat
	return null


func _resolve_group(
	state: RunState, group: InterestGroupDefinition
) -> InterestGroupDefinition:
	var current := group
	var visited: Dictionary[InterestGroupDefinition, bool] = {}
	while current != null and state.constitution.group_mergers.has(current):
		if visited.has(current):
			break
		visited[current] = true
		current = state.constitution.group_mergers[current]
	return current


func _get_stable_groups(context: RunContext) -> Array[InterestGroupDefinition]:
	var result: Array[InterestGroupDefinition] = []
	for group in context.interest_groups:
		if group != null and group not in result:
			result.append(group)
	for seat in context.state.seats:
		var local: InterestGroupDefinition = context.state.constitution.local_interest_groups.get(
			seat.definition
		)
		if local != null and local not in result:
			result.append(local)
	return result
