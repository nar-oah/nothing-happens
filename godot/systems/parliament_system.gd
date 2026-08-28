extends RefCounted
class_name ParliamentSystem


func initialize_seats(
	state: RunState,
	definitions: Array[SeatDefinition],
	traces: Array[RaceDefinition]
) -> bool:
	state.seats.clear()
	var seen: Dictionary[SeatDefinition, bool] = {}
	var anchor_races: Dictionary[RaceDefinition, bool] = {}
	for definition in definitions:
		if definition == null or seen.has(definition):
			push_error("Seat definitions must be unique non-null Resources.")
			return false
		seen[definition] = true
		if definition.anchor_race != null:
			if definition.anchor_race not in traces or anchor_races.has(definition.anchor_race):
				push_error("Each content race can own at most one opening anchor seat.")
				return false
			anchor_races[definition.anchor_race] = true
		if definition.fixed_race != null:
			if definition.fixed_race not in traces:
				push_error("A fixed race seat must belong to a configured content race.")
				return false
			if definition.anchor_race != definition.fixed_race:
				push_error("A permanent fixed seat must use the same race as its opening anchor.")
				return false
	for definition in definitions:
		state.seats.append(SeatState.new(definition))
	return true


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


func get_fixed_seats(
	state: RunState, race: RaceDefinition = null
) -> Array[SeatState]:
	var result: Array[SeatState] = []
	for seat in state.seats:
		if seat.fixed_race == null:
			continue
		if race == null or seat.fixed_race == race:
			result.append(seat)
	return result


func get_fixed_seat_count(state: RunState, race: RaceDefinition) -> int:
	return get_fixed_seats(state, race).size()


func get_variable_seats(
	state: RunState, race: RaceDefinition = null
) -> Array[SeatState]:
	var result: Array[SeatState] = []
	for seat in state.seats:
		if seat.fixed_race != null:
			continue
		if race == null or seat.race == race:
			result.append(seat)
	return result


func get_race_seat_rate(state: RunState, race: RaceDefinition) -> float:
	if state == null:
		return 0.0
	var variable := get_variable_seats(state)
	if variable.is_empty():
		return 0.0
	var count := 0
	for seat in variable:
		if seat.race == race:
			count += 1
	return float(count) / float(variable.size())


func get_influenceable_seats(
	state: RunState, race: RaceDefinition = null
) -> Array[SeatState]:
	var result: Array[SeatState] = []
	for seat in state.seats:
		if seat.race == null or seat.race is ZhushuiRaceDefinition:
			continue
		# A race-fixed group identity (currently Yano -> 造身公所) is not part of the
		# proposal-driven influence algorithm. These seats still display their fixed group,
		# but they do not contribute to interest-group influence counts or rates.
		if seat.race.fixed_interest_group != null:
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
			allocation.clear()
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
	context: RunContext, groups: Array[InterestGroupDefinition]
) -> bool:
	if context == null:
		return false
	for seat in context.state.seats:
		seat.base_group = null
		seat.annual_group = null
		seat.actual_group = null
	for race in context.race_definitions:
		var race_seats := get_race_seats(context.state, race)
		if race_seats.is_empty():
			continue
		if race is ZhushuiRaceDefinition:
			continue
		if race.fixed_interest_group != null:
			for seat in race_seats:
				seat.base_group = race.fixed_interest_group
				seat.annual_group = race.fixed_interest_group
				seat.actual_group = _resolve_group(context.state, race.fixed_interest_group)
			continue
		var allocation := allocate_base_columns(race_seats.size(), groups)
		var allocated_count := 0
		for count in allocation.values():
			allocated_count += int(count)
		if allocated_count != race_seats.size():
			push_error("Interest-group columns did not fill a race row.")
			return false
		var seat_index := 0
		for group in groups:
			var count: int = allocation.get(group, 0)
			for _index in range(count):
				race_seats[seat_index].base_group = group
				seat_index += 1
		for seat in race_seats:
			var initial := _sample_base_weight_group(groups, context.random_system)
			seat.annual_group = initial
			seat.actual_group = _resolve_group(context.state, initial)
	return true


func _sample_base_weight_group(
	groups: Array[InterestGroupDefinition], random_system: RandomSystem
) -> InterestGroupDefinition:
	var weights: Array[float] = []
	for group in groups:
		weights.append(float(group.base_column_weight))
	var index := random_system.weighted_index(weights)
	return null if index < 0 else groups[index]


func assign_race_distribution(
	state: RunState,
	traces: Array[RaceDefinition],
	target_counts: Dictionary[RaceDefinition, int]
) -> bool:
	var remaining := target_counts.duplicate()
	var reserved: Dictionary[SeatState, bool] = {}
	# Fixed race seats are unconditional assignments, not preferences. They never enter the
	# variable pool while their runtime fixed_race binding is active.
	for seat in state.seats:
		var fixed := seat.fixed_race
		if fixed == null:
			continue
		if int(remaining.get(fixed, 0)) <= 0:
			push_error("Race distribution cannot remove an active fixed race seat.")
			return false
		seat.race = fixed
		remaining[fixed] = int(remaining[fixed]) - 1
		reserved[seat] = true
	# Preserve existing variable assignments where possible to avoid unnecessary identity
	# churn when only quotas change.
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
		for race in traces:
			if int(remaining.get(race, 0)) <= 0:
				continue
			seat.race = race
			remaining[race] = int(remaining[race]) - 1
			break
		if seat.race == null:
			push_error("Race distribution did not fill every seat.")
			return false
	for race in traces:
		if int(remaining.get(race, 0)) != 0:
			push_error("Race distribution has an unassigned quota.")
			return false
	return validate_fixed_seat_invariants(state, traces)


func validate_fixed_seat_invariants(
	state: RunState, traces: Array[RaceDefinition]
) -> bool:
	for seat in state.seats:
		if seat.fixed_race != null and seat.fixed_race in traces and seat.race != seat.fixed_race:
			push_error("A fixed race seat must remain in its owning race.")
			return false
	return true


func revoke_fixed_seat(context: RunContext, race: RaceDefinition) -> bool:
	if context == null or race == null:
		return false
	var changed := false
	for seat in context.state.seats:
		if seat.fixed_race != race:
			continue
		seat.fixed_race = null
		changed = true
	return changed


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
	var shares := get_annual_source_shares(context.state)
	var groups := _get_stable_groups(context)
	var sources: Array[InterestGroupDefinition] = []
	var weights: Array[float] = []
	for group in groups:
		if shares.has(group):
			sources.append(group)
			weights.append(shares[group])
	for seat in context.state.seats:
		if seat.race == null:
			seat.annual_group = null
			seat.actual_group = null
			continue
		if seat.race is ZhushuiRaceDefinition:
			seat.annual_group = null
			seat.actual_group = null
			continue
		if seat.race.fixed_interest_group != null:
			seat.annual_group = seat.race.fixed_interest_group
			seat.actual_group = _resolve_group(context.state, seat.race.fixed_interest_group)
			continue
		seat.annual_group = seat.base_group
		if not sources.is_empty() and context.random_system.chance(context.balance.annual_group_coloring_rate):
			var source_index := context.random_system.weighted_index(weights)
			if source_index >= 0:
				seat.annual_group = sources[source_index]
		seat.annual_group = _apply_race_group_bias(context, seat.race, seat.annual_group)
		seat.actual_group = _resolve_group(context.state, seat.annual_group)


func _apply_race_group_bias(
	context: RunContext,
	race: RaceDefinition,
	fallback: InterestGroupDefinition
) -> InterestGroupDefinition:
	var biases := context.constitution_system.get_group_biases_for_race(context, race)
	if biases.is_empty():
		return fallback
	var total_probability := 0.0
	for bias in biases:
		if bias == null or bias.interest_group == null:
			continue
		total_probability += clampf(bias.probability, 0.0, 1.0)
	if total_probability > 1.00001:
		push_error("Constitution group-bias probabilities cannot sum above 100%.")
		return fallback
	var roll := context.random_system.random_float(0.0, 1.0)
	var accumulated := 0.0
	for bias in biases:
		if bias == null or bias.interest_group == null:
			continue
		accumulated += clampf(bias.probability, 0.0, 1.0)
		if roll < accumulated:
			return _resolve_group(context.state, bias.interest_group)
	return fallback


func can_reassign_seat(
	context: RunContext, seat: SeatState, target: RaceDefinition
) -> bool:
	if (
		seat == null
		or target == null
		or target not in context.race_definitions
		or seat not in context.state.seats
		or seat.race == target
		or seat.fixed_race != null
		or not context.constitution_system.race_participates_in_variable_seat_allocation(context, target)
	):
		return false
	var target_constraint := context.constitution_system.get_race_seat_constraint(context, target)
	var target_count := get_race_seat_count(context.state, target)
	if target_constraint.maximum_count >= 0 and target_count >= target_constraint.maximum_count:
		return false
	var donor := seat.race
	if donor == null:
		return true
	var donor_constraint := context.constitution_system.get_race_seat_constraint(context, donor)
	var donor_count := get_race_seat_count(context.state, donor)
	if donor_count - 1 < donor_constraint.minimum_count:
		return false
	return true


func reassign_seat(
	context: RunContext, seat: SeatState, target: RaceDefinition
) -> bool:
	if not can_reassign_seat(context, seat, target):
		return false
	var previous := seat.race
	seat.race = target
	if validate_fixed_seat_invariants(context.state, context.race_definitions):
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
	return true


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
	for race in context.race_definitions:
		if race != null and race.fixed_interest_group != null and race.fixed_interest_group not in result:
			result.append(race.fixed_interest_group)
	for seat in context.state.seats:
		var local: InterestGroupDefinition = context.state.constitution.local_interest_groups.get(seat.definition)
		if local != null and local not in result:
			result.append(local)
	return result
