extends RefCounted
class_name RaceSystem


func initialize_races(
	state: RunState,
	definitions: Array[RaceDefinition],
	balance: GameBalanceDefinition
) -> bool:
	state.races.clear()
	var seen: Dictionary[RaceDefinition, bool] = {}
	for definition in definitions:
		if definition == null or seen.has(definition):
			push_error("Race definitions must be unique non-null Resources.")
			state.races.clear()
			return false
		seen[definition] = true
		var race := RaceState.new(definition)
		for metric in definition.get_stance_metrics():
			race.expectation_targets[metric] = balance.initial_metric_value
		state.races.append(race)
	return true


func advance_expectations(
	state: RunState, balance: GameBalanceDefinition = null
) -> void:
	for race in state.races:
		if race.definition == null:
			continue
		var growth_rate := race.expectation_growth_rate
		if is_zero_approx(growth_rate) and balance != null:
			growth_rate = balance.race_expectation_growth_per_year
		for metric in race.definition.get_stance_metrics():
			var previous := race.get_expectation(metric)
			var direction := race.definition.get_stance(metric)
			if direction == Metric.Direction.HIGHER:
				race.expectation_targets[metric] = roundi(float(previous) * (1.0 + growth_rate))
			elif direction == Metric.Direction.LOWER:
				race.expectation_targets[metric] = roundi(float(previous) * (1.0 - growth_rate))


func allocate_opening_seats(context: RunContext) -> bool:
	var total_seats := context.state.seats.size()
	if total_seats <= 0:
		return false
	var anchor_counts: Dictionary[RaceDefinition, int] = {}
	var anchor_total := 0
	for definition in context.seat_definitions:
		if definition == null or definition.anchor_race == null:
			continue
		anchor_counts[definition.anchor_race] = int(anchor_counts.get(definition.anchor_race, 0)) + 1
		anchor_total += 1
	var random_races: Array[RaceDefinition] = []
	var zhushui: RaceDefinition
	for race in context.race_definitions:
		if race is ZhushuiRaceDefinition:
			zhushui = race
		else:
			random_races.append(race)
	if zhushui == null or int(anchor_counts.get(zhushui, 0)) != 1:
		push_error("Opening parliament requires exactly one Zhushui anchor seat.")
		return false
	var random_pool := total_seats - anchor_total
	if random_pool < 0 or random_races.is_empty():
		return false
	var final_cap := floori(float(total_seats) * context.balance.opening_max_race_seat_rate)
	var caps: Dictionary[RaceDefinition, int] = {}
	for race in random_races:
		caps[race] = maxi(final_cap - int(anchor_counts.get(race, 0)), 0)
	var legal: Array[Dictionary] = []
	_collect_opening_distributions(random_races, caps, 0, random_pool, {}, legal)
	if legal.is_empty():
		push_error("Opening race-seat constraints have no legal distribution.")
		return false
	var selected: Dictionary = legal[context.random_system.random_int(0, legal.size() - 1)]
	var final_counts: Dictionary[RaceDefinition, int] = {}
	for race in context.race_definitions:
		final_counts[race] = int(anchor_counts.get(race, 0))
	for race in random_races:
		final_counts[race] += int(selected.get(race, 0))
	return context.parliament_system.assign_race_distribution(
		context.state, context.race_definitions, final_counts
	)


func _collect_opening_distributions(
	races: Array[RaceDefinition],
	caps: Dictionary[RaceDefinition, int],
	index: int,
	remaining: int,
	current: Dictionary,
	result: Array[Dictionary]
) -> void:
	if index >= races.size():
		if remaining == 0:
			result.append(current.duplicate())
		return
	var race := races[index]
	var max_for_race := mini(int(caps.get(race, 0)), remaining)
	var remaining_cap := 0
	for next_index in range(index + 1, races.size()):
		remaining_cap += int(caps.get(races[next_index], 0))
	var minimum := maxi(remaining - remaining_cap, 0)
	for count in range(minimum, max_for_race + 1):
		current[race] = count
		_collect_opening_distributions(races, caps, index + 1, remaining - count, current, result)
	current.erase(race)


func allocate_seats(context: RunContext) -> bool:
	return allocate_annual_seats(context)


func allocate_annual_seats(context: RunContext) -> bool:
	var all_races := context.race_definitions
	var pool := context.state.seats.size()
	if all_races.is_empty() and pool > 0:
		return false
	var fixed_zhushui: RaceDefinition
	var races: Array[RaceDefinition] = []
	for race in all_races:
		if race is ZhushuiRaceDefinition:
			if fixed_zhushui != null:
				push_error("Only one Zhushui race definition can own the permanent executive seat.")
				return false
			fixed_zhushui = race
		else:
			races.append(race)
	var counts: Dictionary[RaceDefinition, int] = {}
	if fixed_zhushui != null:
		if pool <= 0:
			push_error("Zhushui requires one permanent executive seat.")
			return false
		counts[fixed_zhushui] = 1
		pool -= 1
	if races.is_empty() and pool > 0:
		return false
	var all_constraints := context.constitution_system.get_race_seat_constraints(context)
	var constraints: Dictionary[RaceDefinition, RaceSeatConstraint] = {}
	for race in races:
		constraints[race] = all_constraints[race]
	if not _validate_constraints(races, constraints, pool):
		return false
	var quotas := _calculate_bounded_quotas(context, races, constraints, pool)
	var assigned := 0
	for race in races:
		var count := floori(float(quotas.get(race, 0.0)))
		counts[race] = count
		assigned += count
	while assigned < pool:
		var selected: RaceDefinition
		var best_remainder := -1.0
		for race in races:
			var constraint: RaceSeatConstraint = constraints[race]
			if constraint.maximum_count >= 0 and counts[race] >= constraint.maximum_count:
				continue
			var remainder := float(quotas.get(race, 0.0)) - float(counts[race])
			if remainder > best_remainder:
				selected = race
				best_remainder = remainder
		if selected == null:
			push_error("Seat constraints leave no race for a remaining seat.")
			return false
		counts[selected] += 1
		assigned += 1
	return context.parliament_system.assign_race_distribution(context.state, all_races, counts)


func enforce_constitution_constraints(context: RunContext, changed_race: RaceDefinition) -> bool:
	if changed_race == null or changed_race is ZhushuiRaceDefinition:
		return true
	var constraint := context.constitution_system.get_race_seat_constraint(context, changed_race)
	var count := context.parliament_system.get_race_seat_count(context.state, changed_race)
	while count < constraint.minimum_count:
		var candidates: Array[SeatState] = []
		for seat in context.state.seats:
			if seat.race == changed_race or seat.race is ZhushuiRaceDefinition:
				continue
			if context.parliament_system.can_reassign_seat(context, seat, changed_race):
				candidates.append(seat)
		if candidates.is_empty():
			return false
		var seat := candidates[context.random_system.random_int(0, candidates.size() - 1)]
		if not context.parliament_system.reassign_seat(context, seat, changed_race):
			return false
		count += 1
	while constraint.maximum_count >= 0 and count > constraint.maximum_count:
		var moved := false
		var source_seats := context.parliament_system.get_race_seats(context.state, changed_race)
		for source in source_seats:
			if source.definition.anchor_race == changed_race:
				continue
			for target in context.race_definitions:
				if target == changed_race or target is ZhushuiRaceDefinition:
					continue
				if context.parliament_system.reassign_seat(context, source, target):
					moved = true
					count -= 1
					break
			if moved:
				break
		if not moved:
			return false
	return true


func get_effective_expectation(
	race: RaceState, metric: Metric.Id, context: RunContext
) -> int:
	if race == null or race.definition == null:
		return context.balance.initial_metric_value
	var base := race.get_expectation(metric, context.balance.initial_metric_value)
	return race.definition.get_effective_expectation(base, metric, context, race)


func get_annual_weight(race: RaceState, balance: GameBalanceDefinition) -> float:
	return maxf(
		balance.race_seat_base_weight
		+ float(race.resolved_events_this_year) * balance.race_resolved_event_weight,
		0.0
	)


func _validate_constraints(
	races: Array[RaceDefinition],
	constraints: Dictionary[RaceDefinition, RaceSeatConstraint],
	pool: int
) -> bool:
	var minimum_total := 0
	var maximum_total := 0
	for race in races:
		var constraint: RaceSeatConstraint = constraints.get(race)
		if constraint == null or constraint.minimum_count < 0:
			push_error("Every race requires a valid seat constraint.")
			return false
		if constraint.maximum_count >= 0 and constraint.maximum_count < constraint.minimum_count:
			push_error("Race maximum cannot be lower than its minimum.")
			return false
		minimum_total += constraint.minimum_count
		maximum_total += pool if constraint.maximum_count < 0 else constraint.maximum_count
	if minimum_total > pool or maximum_total < pool:
		push_error("Race seat constraints cannot fill the permanent seat pool.")
		return false
	return true


func _calculate_bounded_quotas(
	context: RunContext,
	races: Array[RaceDefinition],
	constraints: Dictionary[RaceDefinition, RaceSeatConstraint],
	pool: int
) -> Dictionary[RaceDefinition, float]:
	var result: Dictionary[RaceDefinition, float] = {}
	var active := races.duplicate()
	var remaining_pool := float(pool)
	while not active.is_empty():
		var total_weight := 0.0
		for definition in active:
			total_weight += get_annual_weight(context.state.get_race(definition), context.balance)
		var equal := total_weight <= 0.0
		if equal:
			total_weight = float(active.size())
		var constrained: RaceDefinition
		var constrained_value := 0.0
		for definition in active:
			var race_weight := 1.0 if equal else get_annual_weight(context.state.get_race(definition), context.balance)
			var quota := remaining_pool * race_weight / total_weight
			var constraint: RaceSeatConstraint = constraints[definition]
			var maximum := float(pool) if constraint.maximum_count < 0 else float(constraint.maximum_count)
			if quota < float(constraint.minimum_count):
				constrained = definition
				constrained_value = float(constraint.minimum_count)
				break
			if quota > maximum:
				constrained = definition
				constrained_value = maximum
				break
		if constrained != null:
			result[constrained] = constrained_value
			remaining_pool -= constrained_value
			active.erase(constrained)
			continue
		for definition in active:
			var race_weight := 1.0 if equal else get_annual_weight(context.state.get_race(definition), context.balance)
			result[definition] = remaining_pool * race_weight / total_weight
		break
	return result
