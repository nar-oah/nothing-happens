extends RefCounted
class_name RaceSystem


func initialize_races(state: RunState, definitions: Array[RaceDefinition]) -> void:
	state.races.clear()
	var seen_ids: Dictionary[StringName, bool] = {}
	for definition in definitions:
		if definition == null or definition.id == &"" or seen_ids.has(definition.id):
			push_error("Race definitions must have unique non-empty ids.")
			continue
		seen_ids[definition.id] = true
		var race := RaceState.new(definition, state.year)
		for stance in _all_stances(definition):
			if stance.direction != MetricStanceDefinition.Direction.NONE:
				race.expectation_targets[stance.metric] = stance.target_for_year(state.year)
		state.races.append(race)


func calculate_annual_seat_count(race: RaceState) -> int:
	if race == null or race.definition == null:
		return 0
	var definition := race.definition
	if definition.id == Race.ZHUSHUI:
		return 1
	if definition.fixed_seat_count >= 0:
		return definition.fixed_seat_count
	var trust := clampf(race.political_trust, 0.0, 100.0)
	var pivot := clampf(definition.initial_political_trust, 0.01, 99.99)
	var seat_value: float
	if trust <= pivot:
		seat_value = lerpf(definition.minimum_seats, definition.initial_seats, trust / pivot)
	else:
		seat_value = lerpf(
			definition.initial_seats, definition.maximum_seats, (trust - pivot) / (100.0 - pivot)
		)
	return clampi(roundi(seat_value), definition.minimum_seats, definition.maximum_seats)


func recalculate_all_seat_counts(state: RunState) -> void:
	for race in state.races:
		race.seat_count = calculate_annual_seat_count(race)


func advance_era_expectations(state: RunState) -> void:
	for race in state.races:
		if race.definition == null:
			continue
		for stance in _all_stances(race.definition):
			if stance.direction == MetricStanceDefinition.Direction.NONE:
				continue
			race.expectation_targets[stance.metric] = stance.target_for_year(state.year + 1)
	if state.constitution.has_flag(&"trust_established"):
		var human := state.get_race(Race.HUMAN)
		if human != null:
			for race in state.races:
				race.expectation_targets = human.expectation_targets.duplicate()


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
