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
			state.races.clear()
			return false
		seen[definition] = true
		var race := RaceState.new(definition)
		for metric in definition.get_stance_metrics():
			race.expectation_targets[metric] = balance.initial_metric_value
		state.races.append(race)
	return true


func rebuild_annual_expectations(context: RunContext) -> void:
	var baseline := context.state.year_start_metrics
	if baseline == null:
		baseline = context.state.metrics
	for race_state in context.state.races:
		if race_state == null or race_state.definition == null:
			continue
		var active := race_state.active_definition
		if active == null:
			active = race_state.definition
		race_state.expectation_targets.clear()
		var growth_rate := get_expectation_growth_rate(race_state, context)
		for metric in active.get_stance_metrics():
			var base := baseline.get_value(metric)
			race_state.expectation_targets[metric] = roundi(float(base) * (1.0 + growth_rate))


func get_expectation_growth_rate(race: RaceState, context: RunContext) -> float:
	if race == null or race.definition == null or context == null:
		return 0.0
	var active := race.active_definition
	if active == null:
		active = race.definition
	var growth_rate := active.expectation_growth_rate
	if context.constitution_system != null:
		growth_rate *= context.constitution_system.get_expectation_growth_multiplier(
			context, race.definition
		)
	return clampf(growth_rate, -1.0, 10.0)


func get_interest_group_proposal_expectation(
	race: RaceState, context: RunContext
) -> int:
	if context == null or context.balance == null:
		return 0
	var initial := context.balance.initial_interest_group_proposal_requirement
	if race == null or race.definition == null:
		return initial
	var years_elapsed := 0
	if context.state != null:
		years_elapsed = maxi(context.state.year - 1, 0)
	var growth_rate := get_expectation_growth_rate(race, context)
	return maxi(
		roundi(float(initial) * pow(1.0 + growth_rate, float(years_elapsed))),
		0
	)


func allocate_opening_seats(context: RunContext) -> bool:
	var random_seats := context.parliament_system.get_variable_seats(context.state)
	var pool := random_seats.size()
	var eligible := _eligible_races(context)
	if pool > 0 and eligible.is_empty():
		return false
	var cap := floori(float(pool) * context.balance.opening_max_race_seat_rate)
	var caps: Dictionary[RaceDefinition, int] = {}
	for race in eligible:
		caps[race] = cap
	var legal: Array[Dictionary] = []
	_collect_opening_distributions(eligible, caps, 0, pool, {}, legal)
	if legal.is_empty():
		return false
	var selected: Dictionary = legal[context.random_system.random_int(0, legal.size() - 1)]
	var counts: Dictionary[RaceDefinition, int] = {}
	for race in context.race_definitions:
		counts[race] = context.parliament_system.get_fixed_seat_count(context.state, race) + int(selected.get(race, 0))
	return context.parliament_system.assign_race_distribution(context.state, context.race_definitions, counts)


func _collect_opening_distributions(
	races: Array[RaceDefinition], caps: Dictionary[RaceDefinition, int], index: int,
	remaining: int, current: Dictionary, result: Array[Dictionary]
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
	var pool := context.parliament_system.get_variable_seats(context.state).size()
	var races := _eligible_races(context)
	if pool > 0 and races.is_empty():
		return false
	var counts: Dictionary[RaceDefinition, int] = {}
	for race in context.race_definitions:
		counts[race] = context.parliament_system.get_fixed_seat_count(context.state, race)
	if pool == 0:
		return context.parliament_system.assign_race_distribution(context.state, context.race_definitions, counts)
	var weights: Array[float] = []
	var total_weight := 0.0
	for race in races:
		var weight := get_annual_weight(context.state.get_race(race), context.balance)
		weights.append(weight)
		total_weight += weight
	if total_weight <= 0.0:
		weights.clear()
		for _race in races:
			weights.append(1.0)
		total_weight = float(races.size())
	var quotas: Array[float] = []
	var assigned := 0
	for index in range(races.size()):
		var quota := float(pool) * weights[index] / total_weight
		quotas.append(quota)
		var whole := floori(quota)
		counts[races[index]] = int(counts[races[index]]) + whole
		assigned += whole
	while assigned < pool:
		var best_index := -1
		var best_remainder := -1.0
		for index in range(races.size()):
			var variable_count := int(counts[races[index]]) - context.parliament_system.get_fixed_seat_count(context.state, races[index])
			var remainder := quotas[index] - float(variable_count)
			if remainder > best_remainder:
				best_remainder = remainder
				best_index = index
		if best_index < 0:
			return false
		counts[races[best_index]] = int(counts[races[best_index]]) + 1
		assigned += 1
	return context.parliament_system.assign_race_distribution(context.state, context.race_definitions, counts)


func reconcile_seat_participation(context: RunContext) -> bool:
	var eligible := _eligible_races(context)
	var variable := context.parliament_system.get_variable_seats(context.state)
	if not variable.is_empty() and eligible.is_empty():
		return false
	for seat in variable:
		if seat.race != null and seat.race in eligible:
			continue
		seat.race = eligible[context.random_system.random_int(0, eligible.size() - 1)]
	return context.parliament_system.validate_fixed_seat_invariants(context.state, context.race_definitions)


func _eligible_races(context: RunContext) -> Array[RaceDefinition]:
	var result: Array[RaceDefinition] = []
	for race in context.race_definitions:
		if context.constitution_system.race_participates_in_variable_seat_allocation(context, race):
			result.append(race)
	return result


func get_effective_expectation(
	race: RaceState, metric: Metric.Id, context: RunContext
) -> int:
	if race == null or race.definition == null:
		return context.balance.initial_metric_value
	var active := race.active_definition
	if active == null:
		active = race.definition
	var base := race.get_expectation(metric, context.balance.initial_metric_value)
	return active.get_effective_expectation(base, metric, context, race)


func get_annual_weight(race: RaceState, balance: GameBalanceDefinition) -> float:
	if race == null:
		return 0.0
	return maxf(balance.race_seat_base_weight + float(race.resolved_events_this_year) * balance.race_resolved_event_weight, 0.0)
