extends RefCounted
class_name RaceSystem


func initialize_races(
	state: RunState,
	definitions: Array[RaceDefinition],
	balance: GameBalanceDefinition,
	inflation_system: InflationSystem
) -> void:
	state.races.clear()
	var seen_ids: Dictionary[StringName, bool] = {}
	for definition in definitions:
		if definition == null or definition.id == &"" or seen_ids.has(definition.id):
			push_error("Race definitions must have unique non-empty ids.")
			continue
		seen_ids[definition.id] = true
		var race := RaceState.new(definition)
		race.political_trust = (balance.initial_political_trust)
		for metric in definition.get_stance_metrics():
			var direction := definition.get_stance(metric)
			race.expectation_targets[metric] = (inflation_system.get_expectation_target(
				direction, state.year, balance
			))
		state.races.append(race)


func advance_era_expectations(
	state: RunState, balance: GameBalanceDefinition, inflation_system: InflationSystem
) -> void:
	var next_year := state.year + 1
	for race in state.races:
		if race.definition == null:
			continue
		race.expectation_targets.clear()
		for metric in race.definition.get_stance_metrics():
			var direction := race.definition.get_stance(metric)
			race.expectation_targets[metric] = (inflation_system.get_expectation_target(
				direction, next_year, balance
			))


func _all_stances(definition: RaceDefinition) -> Array[MetricStanceDefinition]:
	var result: Array[MetricStanceDefinition] = []
	var seen: Dictionary[int, bool] = {}
	for list in [
		definition.metric_stances,
		definition.odd_month_stances,
		definition.even_month_stances,
	]:
		for stance in list:
			if stance != null and not seen.has(stance.metric):
				seen[stance.metric] = true
				result.append(stance)
	return result


func allocate_seats(
	state: RunState,
	balance: GameBalanceDefinition,
	constitution_system: ConstitutionSystem,
	random_system: RandomSystem
) -> bool:
	if balance == null:
		push_error("Cannot allocate race seats without GameBalanceDefinition.")
		return false
	var total_pool := balance.variable_seat_count
	if total_pool < 0:
		push_error("Variable seat count cannot be negative.")
		return false
	var zhushui := state.get_race(Race.ZHUSHUI)
	if zhushui != null:
		zhushui.seat_count = balance.zhushui_fixed_seat_count
	var variable_races: Array[RaceState] = []
	for race in state.races:
		if race == null or race.definition == null:
			continue
		if race.get_id() == Race.ZHUSHUI:
			continue
		race.seat_count = 0
		variable_races.append(race)
	if variable_races.is_empty():
		if total_pool > 0:
			push_error("Cannot allocate variable seats without variable races.")
			return false
		return true
	var constraints := constitution_system.get_race_seat_constraints(state, balance)
	var fixed_total := 0
	var flexible_races: Array[RaceState] = []
	for race in variable_races:
		var constraint: RaceSeatConstraint = constraints.get(race.get_id())
		if constraint == null:
			push_error("Missing seat constraint for race: %s" % race.get_id())
			return false
		if constraint.fixed_count >= 0:
			race.seat_count = constraint.fixed_count
			fixed_total += constraint.fixed_count
		else:
			flexible_races.append(race)
	if fixed_total > total_pool:
		push_error("Fixed race seats exceed the variable seat pool.")
		return false
	var flexible_pool := total_pool - fixed_total
	if not _validate_flexible_constraints(flexible_races, constraints, flexible_pool):
		return false
	var quotas := _calculate_bounded_quotas(flexible_races, constraints, flexible_pool)
	var assigned := fixed_total
	for race in flexible_races:
		var quota: float = quotas.get(race.get_id(), 0.0)
		race.seat_count = floori(quota)
		assigned += race.seat_count
	var remaining := total_pool - assigned
	while remaining > 0:
		var candidates: Array[RaceState] = []
		var weights: Array[float] = []
		for race in flexible_races:
			var constraint: RaceSeatConstraint = constraints[race.get_id()]
			if constraint.maximum_count >= 0 and race.seat_count >= constraint.maximum_count:
				continue
			var quota: float = quotas[race.get_id()]
			var remainder := maxf(quota - float(race.seat_count), 0.0)
			if remainder <= 0.000001:
				continue
			candidates.append(race)
			weights.append(remainder)
		if candidates.is_empty():
			push_error("Seat allocation has remaining seats but no valid candidate.")
			return false
		var index := random_system.weighted_index(weights)
		if index < 0:
			push_error("Failed to choose race for remainder seat.")
			return false
		candidates[index].seat_count += 1
		remaining -= 1
	return true


func _validate_flexible_constraints(
	races: Array[RaceState], constraints: Dictionary[StringName, RaceSeatConstraint], pool: int
) -> bool:
	var minimum_total := 0
	var maximum_total := 0
	for race in races:
		var constraint: RaceSeatConstraint = constraints[race.get_id()]
		if constraint.minimum_count < 0:
			push_error("Race minimum seat count cannot be negative.")
			return false
		if constraint.maximum_count >= 0 and constraint.maximum_count < constraint.minimum_count:
			push_error("Race maximum seat count cannot be lower than minimum.")
			return false
		minimum_total += constraint.minimum_count
		maximum_total += (pool if constraint.maximum_count < 0 else constraint.maximum_count)
	if minimum_total > pool:
		push_error("Race minimum seat constraints exceed the available seat pool.")
		return false
	if maximum_total < pool:
		push_error("Race maximum seat constraints cannot fill the available seat pool.")
		return false
	return true


func _calculate_bounded_quotas(
	races: Array[RaceState], constraints: Dictionary[StringName, RaceSeatConstraint], pool: int
) -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {}
	var active := races.duplicate()
	var remaining_pool := float(pool)
	while not active.is_empty():
		var total_weight := 0.0
		for race in active:
			total_weight += maxf(race.political_trust, 0.0)
		var use_equal_weights := total_weight <= 0.0
		if use_equal_weights:
			total_weight = float(active.size())
		var constrained_race: RaceState = null
		var constrained_value := 0.0
		for race in active:
			var weight := 1.0 if use_equal_weights else maxf(race.political_trust, 0.0)
			var quota := remaining_pool * weight / total_weight
			var constraint: RaceSeatConstraint = constraints[race.get_id()]
			var minimum := float(constraint.minimum_count)
			var maximum := (
				float(pool) if constraint.maximum_count < 0 else float(constraint.maximum_count)
			)
			if quota < minimum:
				constrained_race = race
				constrained_value = minimum
				break
			if quota > maximum:
				constrained_race = race
				constrained_value = maximum
				break
		if constrained_race != null:
			result[constrained_race.get_id()] = constrained_value
			remaining_pool -= constrained_value
			active.erase(constrained_race)
			continue
		for race in active:
			var weight := 1.0 if use_equal_weights else maxf(race.political_trust, 0.0)
			result[race.get_id()] = (remaining_pool * weight / total_weight)
		break
	return result


func get_effective_expectation(race: RaceState, metric: Metric.Id, context: RunContext) -> int:
	if race == null or race.definition == null:
		return context.balance.initial_metric_value
	var base_target := race.get_expectation(metric, context.balance.initial_metric_value)
	var direction := race.definition.get_stance(metric)
	if direction == MetricStanceDefinition.Direction.NONE:
		return base_target
	if not context.constitution_system.uses_yin_yang_for_race(context.state, race.get_id()):
		return base_target
	var month_sign := context.balance.get_yin_yang_month_sign(metric, context.state.month)
	return base_target + int(direction) * month_sign * context.balance.yin_yang_adjustment
