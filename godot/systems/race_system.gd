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


func rebuild_annual_expectations(context: RunContext) -> void:
	if context == null or context.state == null:
		return
	var baseline := context.state.year_start_metrics
	if baseline == null:
		baseline = context.state.metrics
	for race_state in context.state.races:
		if race_state == null or race_state.definition == null:
			continue
		race_state.expectation_targets.clear()
		var growth_rate := clampf(race_state.expectation_growth_rate, -1.0, 1.0)
		for metric in race_state.definition.get_stance_metrics():
			var base := baseline.get_value(metric)
			var direction := race_state.definition.get_stance(metric)
			if direction == Metric.Direction.HIGHER:
				race_state.expectation_targets[metric] = roundi(float(base) * (1.0 + growth_rate))
			elif direction == Metric.Direction.LOWER:
				race_state.expectation_targets[metric] = roundi(float(base) * (1.0 - growth_rate))


func allocate_opening_seats(context: RunContext) -> bool:
	if context == null or context.state == null or context.state.seats.is_empty():
		return false
	var random_seats: Array[SeatState] = context.parliament_system.get_variable_seats(context.state)
	var random_pool := random_seats.size()
	var eligible: Array[RaceDefinition] = []
	for race in context.race_definitions:
		if context.constitution_system.race_participates_in_variable_seat_allocation(context, race):
			eligible.append(race)
	if random_pool > 0 and eligible.is_empty():
		push_error("Opening parliament has random seats but no eligible race.")
		return false
	var random_cap := floori(float(random_pool) * context.balance.opening_max_race_seat_rate)
	var caps: Dictionary[RaceDefinition, int] = {}
	for race in eligible:
		caps[race] = random_cap
	var legal: Array[Dictionary] = []
	_collect_opening_distributions(eligible, caps, 0, random_pool, {}, legal)
	if legal.is_empty():
		push_error("Opening race-seat constraints have no legal random distribution.")
		return false
	var selected: Dictionary = legal[context.random_system.random_int(0, legal.size() - 1)]
	var seat_index := 0
	for race in eligible:
		var count := int(selected.get(race, 0))
		for _index in range(count):
			if seat_index >= random_seats.size():
				push_error("Opening random distribution exceeded the random seat pool.")
				return false
			random_seats[seat_index].race = race
			seat_index += 1
	return seat_index == random_seats.size()


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
	if context == null or context.state == null:
		return false
	var variable_pool := context.parliament_system.get_variable_seats(context.state).size()
	var races: Array[RaceDefinition] = []
	var counts: Dictionary[RaceDefinition, int] = {}
	var constraints: Dictionary[RaceDefinition, RaceSeatConstraint] = {}
	for race in context.race_definitions:
		counts[race] = context.parliament_system.get_fixed_seat_count(context.state, race)
		if not context.constitution_system.race_participates_in_variable_seat_allocation(context, race):
			continue
		races.append(race)
		constraints[race] = context.constitution_system.get_variable_race_seat_constraint(context, race)
	if variable_pool > 0 and races.is_empty():
		push_error("Variable seat pool has no eligible race.")
		return false
	if not _validate_constraints(races, constraints, variable_pool):
		return false
	var quotas := _calculate_bounded_quotas(context, races, constraints, variable_pool)
	var assigned := 0
	var variable_counts: Dictionary[RaceDefinition, int] = {}
	for race in races:
		var count := floori(float(quotas.get(race, 0.0)))
		variable_counts[race] = count
		assigned += count
	while assigned < variable_pool:
		var selected: RaceDefinition
		var best_remainder := -1.0
		for race in races:
			var constraint: RaceSeatConstraint = constraints[race]
			var current_count := int(variable_counts.get(race, 0))
			if constraint.maximum_count >= 0 and current_count >= constraint.maximum_count:
				continue
			var remainder := float(quotas.get(race, 0.0)) - float(current_count)
			if remainder > best_remainder:
				selected = race
				best_remainder = remainder
		if selected == null:
			push_error("Seat constraints leave no race for a remaining variable seat.")
			return false
		variable_counts[selected] = int(variable_counts.get(selected, 0)) + 1
		assigned += 1
	for race in races:
		counts[race] = int(counts.get(race, 0)) + int(variable_counts.get(race, 0))
	return context.parliament_system.assign_race_distribution(
		context.state, context.race_definitions, counts
	)


func enforce_constitution_constraints(context: RunContext, changed_race: RaceDefinition) -> bool:
	if context == null or changed_race == null:
		return false
	var constraint := context.constitution_system.get_race_seat_constraint(context, changed_race)
	var count := context.parliament_system.get_race_seat_count(context.state, changed_race)
	while count < constraint.minimum_count:
		var candidates: Array[SeatState] = []
		for seat in context.state.seats:
			if seat.race == changed_race or seat.fixed_race != null:
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
			if source.fixed_race != null:
				continue
			for target in context.race_definitions:
				if target == changed_race:
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
	if race == null:
		return 0.0
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
	if races.is_empty():
		return pool == 0
	var minimum_total := 0
	var maximum_total := 0
	for race in races:
		var constraint: RaceSeatConstraint = constraints.get(race)
		if constraint == null or constraint.minimum_count < 0:
			push_error("Every eligible race requires a valid variable-seat constraint.")
			return false
		if constraint.maximum_count >= 0 and constraint.maximum_count < constraint.minimum_count:
			push_error("Race maximum cannot be lower than its minimum.")
			return false
		minimum_total += constraint.minimum_count
		maximum_total += pool if constraint.maximum_count < 0 else constraint.maximum_count
	if minimum_total > pool or maximum_total < pool:
		push_error("Race seat constraints cannot fill the variable seat pool.")
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
			var race_weight := (
				1.0
				if equal
				else get_annual_weight(context.state.get_race(definition), context.balance)
			)
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
			var race_weight := (
				1.0
				if equal
				else get_annual_weight(context.state.get_race(definition), context.balance)
			)
			result[definition] = remaining_pool * race_weight / total_weight
		break
	return result