extends RefCounted
class_name RaceSystem


func initialize_races(
	state: RunState,
	definitions: Array[RaceDefinition],
	balance: GameBalanceDefinition
) -> void:
	state.races.clear()
	var seen: Dictionary[RaceDefinition, bool] = {}
	for definition in definitions:
		if definition == null or seen.has(definition):
			push_error("Race definitions must be unique non-null Resources.")
			continue
		seen[definition] = true
		var race := RaceState.new(definition)
		for metric in definition.get_stance_metrics():
			race.expectation_targets[metric] = balance.initial_metric_value
		state.races.append(race)


func advance_expectations(state: RunState) -> void:
	for race in state.races:
		if race.definition == null:
			continue
		for metric in race.definition.get_stance_metrics():
			var previous := race.get_expectation(metric)
			var direction := race.definition.get_stance(metric)
			if direction == Metric.Direction.HIGHER:
				race.expectation_targets[metric] = roundi(
					float(previous) * (1.0 + race.expectation_growth_rate)
				)
			elif direction == Metric.Direction.LOWER:
				race.expectation_targets[metric] = roundi(
					float(previous) * (1.0 - race.expectation_growth_rate)
				)


func allocate_seats(context: RunContext) -> bool:
	var races := context.race_definitions
	var pool := context.state.seats.size()
	if races.is_empty() and pool > 0:
		return false
	var constraints := context.constitution_system.get_race_seat_constraints(context)
	if not _validate_constraints(races, constraints, pool):
		return false
	var quotas := _calculate_bounded_quotas(context, races, constraints, pool)
	var counts: Dictionary[RaceDefinition, int] = {}
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
	return context.parliament_system.assign_race_distribution(context.state, races, counts)


func get_effective_expectation(
	race: RaceState, metric: Metric.Id, context: RunContext
) -> int:
	if race == null or race.definition == null:
		return context.balance.initial_metric_value
	var base := race.get_expectation(metric, context.balance.initial_metric_value)
	return race.definition.get_effective_expectation(metric, base, context, race)


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
			var race_weight := (
				1.0
				if equal
				else get_annual_weight(context.state.get_race(definition), context.balance)
			)
			var quota := remaining_pool * race_weight / total_weight
			var constraint: RaceSeatConstraint = constraints[definition]
			var maximum := (
				float(pool)
				if constraint.maximum_count < 0
				else float(constraint.maximum_count)
			)
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
