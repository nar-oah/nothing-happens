extends RefCounted
class_name ParliamentSystem


func initialize_seats(
	state: RunState,
	definitions: Array[SeatDefinition],
	races: Array[RaceDefinition]
) -> bool:
	state.seats.clear()
	var seen: Dictionary[SeatDefinition, bool] = {}
	for definition in definitions:
		if definition == null or seen.has(definition):
			push_error("Seat definitions must be unique non-null Resources.")
			return false
		seen[definition] = true
		if definition.fixed_race != null and definition.fixed_race not in traces:
			push_error("A fixed race seat must belong to a configured content race.")
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


func get_fixed_seats(state: RunState, race: RaceDefinition = null) -> Array[SeatState]:
	var result: Array[SeatState] = []
	for seat in state.seats:
		if seat.fixed_race == null:
			continue
		if race == null or seat.fixed_race == race:
			result.append(seat)
	return result


func get_fixed_seat_count(state: RunState, race: RaceDefinition) -> int:
	return get_fixed_seats(state, race).size()


func get_variable_seats(state: RunState, race: RaceDefinition = null) -> Array[SeatState]:
	var result: Array[SeatState] = []
	for seat in state.seats:
		if seat.fixed_race != null:
			continue
		if race == null or seat.race == race:
			result.append(seat)
	return result


func get_race_seat_rate(state: RunState, race: RaceDefinition) -> float:
	var variable := get_variable_seats(state)
	if variable.is_empty():
		return 0.0
	var count := 0
	for seat in variable:
		if seat.race == race:
			count += 1
	return float(count) / float(variable.size())


func get_influenceable_seats(state: RunState, race: RaceDefinition = null) -> Array[SeatState]:
	var result: Array[SeatState] = []
	for seat in state.seats:
		if seat.race == null or seat.race is ZhushuiRaceDefinition:
			continue
		if seat.race.fixed_interest_group != null:
			continue
		if race == null or seat.race == race:
			result.append(seat)
	return result


func get_group_influence_count(
	state: RunState, group: InterestGroupDefinition, race: RaceDefinition = null
) -> int:
	var target := _resolve_group(state, group)
	var count := 0
	for seat in get_influenceable_seats(state, race):
		if _resolve_group(state, seat.actual_group) == target:
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
		return allocation
	var total_weight := 0
	for group in groups:
		if group == null or allocation.has(group) or group.base_column_weight <= 0:
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
			if remainders[group] > best_remainder:
				best = group
				best_remainder = remainders[group]
		if best == null:
			break
		allocation[best] += 1
		remainders[best] = -1.0
		assigned += 1
	return allocation


func initialize_base_groups(
	context: RunContext, groups: Array[InterestGroupDefinition]
) -> bool:
	for seat in context.state.seats:
		seat.base_group = null
		seat.annual_group = null
		seat.actual_group = null
	for race in context.race_definitions:
		var race_seats := get_race_seats(context.state, race)
		if race_seats.is_empty() or race is ZhushuiRaceDefinition:
			continue
		if race.fixed_interest_group != null:
			for seat in race_seats:
				seat.base_group = race.fixed_interest_group
				seat.annual_group = race.fixed_interest_group
				seat.actual_group = _resolve_group(context.state, race.fixed_interest_group)
			continue
		var allocation := allocate_base_columns(race_seats.size(), groups)
		var seat_index := 0
		for group in groups:
			for _index in range(int(allocation.get(group, 0))):
				if seat_index < race_seats.size():
					race_seats[seat_index].base_group = group
					seat_index += 1
		if seat_index != race_seats.size():
			return false
		for seat in race_seats:
			seat.annual_group = _sample_base_weight_group(groups, context.random_system)
			seat.actual_group = _resolve_group(context.state, seat.annual_group)
	return true


func normalize_groups_after_race_change(context: RunContext) -> void:
	for seat in context.state.seats:
		if seat.race == null or seat.race is ZhushuiRaceDefinition:
			seat.base_group = null
			seat.annual_group = null
			seat.actual_group = null
			continue
		if seat.race.fixed_interest_group != null:
			seat.base_group = seat.race.fixed_interest_group
			seat.annual_group = seat.race.fixed_interest_group
			seat.actual_group = _resolve_group(context.state, seat.race.fixed_interest_group)
			continue
		if seat.base_group == null:
			seat.base_group = _sample_base_weight_group(context.interest_groups, context.random_system)
		if seat.annual_group == null:
			seat.annual_group = seat.base_group
		seat.actual_group = _resolve_group(context.state, seat.annual_group)


func _sample_base_weight_group(
	groups: Array[InterestGroupDefinition], random_system: RandomSystem
) -> InterestGroupDefinition:
	if groups.is_empty():
		return null
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
	for seat in state.seats:
		var fixed := seat.fixed_race
		if fixed == null:
			continue
		if int(remaining.get(fixed, 0)) <= 0:
			return false
		seat.race = fixed
		remaining[fixed] = int(remaining[fixed]) - 1
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
		for race in traces:
			if int(remaining.get(race, 0)) > 0:
				seat.race = race
				remaining[race] = int(remaining[race]) - 1
				break
		if seat.race == null:
			return false
	for race in traces:
		if int(remaining.get(race, 0)) != 0:
			return false
	return validate_fixed_seat_invariants(state, traces)


func validate_fixed_seat_invariants(state: RunState, traces: Array[RaceDefinition]) -> bool:
	for seat in state.seats:
		if seat.fixed_race != null and seat.fixed_race in traces and seat.race != seat.fixed_race:
			return false
	return true


func apply_race_seat_effect(context: RunContext, effect: RaceSeatEffect) -> void:
	for seat in context.state.seats:
		if seat.definition == null or seat.definition.fixed_race == null:
			continue
		var owner := seat.definition.fixed_race
		if not effect.applies_to(owner):
			continue
		seat.fixed_race = owner if effect.fixed_seat_enabled else null
		if seat.fixed_race != null:
			seat.race = seat.fixed_race


func record_authorized_proposal_slots(
	state: RunState, proposals: Array[ProposalInstance]
) -> void:
	for proposal in proposals:
		if proposal == null or proposal.source_group == null:
			continue
		var source := _resolve_group(state, proposal.source_group)
		state.annual_proposal_slot_counts[source] = int(state.annual_proposal_slot_counts.get(source, 0)) + 1


func get_annual_source_shares(state: RunState) -> Dictionary[InterestGroupDefinition, float]:
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
	var sources: Array[InterestGroupDefinition] = []
	var weights: Array[float] = []
	for group in context.interest_groups:
		var identity := _resolve_group(context.state, group)
		if identity != null and shares.has(identity) and identity not in sources:
			sources.append(identity)
			weights.append(shares[identity])
	for seat in context.state.seats:
		if seat.race == null or seat.race is ZhushuiRaceDefinition:
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
		seat.actual_group = _resolve_group(context.state, seat.annual_group)


func apply_influence_bonus(
	context: RunContext, effect: InterestGroupInfluenceBonusEffect
) -> void:
	if effect.interest_group == null or is_zero_approx(effect.bonus_rate):
		return
	var target := _resolve_group(context.state, effect.interest_group)
	for race in context.race_definitions:
		if not effect.applies_to(race):
			continue
		var eligible := get_influenceable_seats(context.state, race)
		if eligible.is_empty():
			continue
		var current := 0
		for seat in eligible:
			if _resolve_group(context.state, seat.actual_group) == target:
				current += 1
		var delta := roundi(float(eligible.size()) * effect.bonus_rate)
		var desired := clampi(current + delta, 0, eligible.size())
		if desired > current:
			for seat in eligible:
				if current >= desired:
					break
				if _resolve_group(context.state, seat.actual_group) == target:
					continue
				seat.actual_group = target
				current += 1
		elif desired < current:
			for seat in eligible:
				if current <= desired:
					break
				if _resolve_group(context.state, seat.actual_group) != target:
					continue
				seat.actual_group = _fallback_group(context, seat, target)
				current -= 1


func apply_local_interest_groups(context: RunContext, effect: LocalInterestGroupEffect) -> void:
	for seat in context.state.seats:
		if seat == null or seat.definition == null or not effect.applies_to(seat.race):
			continue
		var local: InterestGroupDefinition = context.state.constitution.local_interest_groups.get(seat.definition)
		if local == null:
			local = InterestGroupDefinition.new()
			local.display_name = seat.definition.display_name
			local.description = seat.definition.description
			local.base_column_weight = effect.base_column_weight
			_set_group_decrease_metric(local, effect.decrease_metric)
			context.state.constitution.local_interest_groups[seat.definition] = local
		seat.actual_group = local


func _set_group_decrease_metric(group: InterestGroupDefinition, metric: Metric.Id) -> void:
	group.decrease_tax = metric == Metric.Id.TAX
	group.decrease_consumption = metric == Metric.Id.CONSUMPTION
	group.decrease_production = metric == Metric.Id.PRODUCTION
	group.decrease_employment = metric == Metric.Id.EMPLOYMENT
	group.decrease_investment = metric == Metric.Id.INVESTMENT


func _fallback_group(
	context: RunContext, seat: SeatState, excluded: InterestGroupDefinition
) -> InterestGroupDefinition:
	var candidates: Array[InterestGroupDefinition] = [seat.annual_group, seat.base_group]
	for candidate in candidates:
		var resolved := _resolve_group(context.state, candidate)
		if resolved != null and resolved != excluded:
			return resolved
	for group in context.interest_groups:
		var resolved := _resolve_group(context.state, group)
		if resolved != null and resolved != excluded:
			return resolved
	return null


func can_reassign_seat(context: RunContext, seat: SeatState, target: RaceDefinition) -> bool:
	return (
		seat != null
		and target != null
		and target in context.race_definitions
		and seat in context.state.seats
		and seat.race != target
		and seat.fixed_race == null
		and context.constitution_system.race_participates_in_variable_seat_allocation(context, target)
	)


func reassign_seat(context: RunContext, seat: SeatState, target: RaceDefinition) -> bool:
	if not can_reassign_seat(context, seat, target):
		return false
	seat.race = target
	return true


func use_petition(context: RunContext, event: EventState = null) -> bool:
	var limit := context.constitution_system.get_petition_limit(context)
	if limit <= 0 or context.state.petition_used_this_year >= limit:
		return false
	if event != null and not context.constitution_system.can_petition_event(context, event.race):
		return false
	context.state.petition_used_this_year += 1
	return true


func get_petition_remaining(context: RunContext) -> int:
	return maxi(context.constitution_system.get_petition_limit(context) - context.state.petition_used_this_year, 0)


func _resolve_group(state: RunState, group: InterestGroupDefinition) -> InterestGroupDefinition:
	var current := group
	var visited: Dictionary[InterestGroupDefinition, bool] = {}
	while current != null and state.constitution.group_mergers.has(current):
		if visited.has(current):
			break
		visited[current] = true
		current = state.constitution.group_mergers[current]
	return current
