extends RefCounted
class_name EventSystem


func try_generate_month(context: RunContext) -> Array[EventState]:
	var generated: Array[EventState] = []
	if context == null or context.state == null or context.balance == null:
		return generated
	var minimum := mini(context.balance.event_spawn_count_min, context.balance.event_spawn_count_max)
	var maximum := maxi(context.balance.event_spawn_count_min, context.balance.event_spawn_count_max)
	var target_count := context.random_system.random_int(minimum, maximum)
	while generated.size() < target_count:
		var races := _get_eligible_races(context)
		if races.is_empty():
			break
		var race := races[context.random_system.random_int(0, races.size() - 1)]
		var metrics := _get_eligible_metrics(context, race)
		if metrics.is_empty():
			break
		var metric := metrics[context.random_system.random_int(0, metrics.size() - 1)]
		var event := spawn_event(context, race, metric)
		if event == null:
			break
		generated.append(event)
	return generated


func spawn_event(
	context: RunContext, race: RaceDefinition, metric: Metric.Id
) -> EventState:
	if context == null or context.state == null or race == null:
		return null
	if _get_race_seat_count(context.state, race) == 0:
		return null
	if has_active_event(context.state, race, metric):
		return null
	var race_state := context.state.get_race(race)
	if race_state == null:
		return null
	var direction := race.get_stance(metric)
	if direction == Metric.Direction.NONE:
		return null
	var target := context.race_system.get_effective_expectation(race_state, metric, context)
	var baseline := context.state.metrics.get_value(metric)
	if not _has_gap(direction, baseline, target):
		return null
	var event := EventState.new(race, metric, baseline, target)
	context.state.events.append(event)
	return event


func settle_month(context: RunContext) -> void:
	if context == null or context.state == null or context.balance == null:
		return
	for event in context.state.events:
		if event == null or not event.is_active():
			continue
		event.months_alive += 1
		_update_growth_and_publication(event, context.balance)
		if event.known:
			_update_known_event(event, context)
		if event.is_active() and event.months_alive >= context.balance.event_lifetime_months:
			_fail(event, context)


func update_information(context: RunContext) -> void:
	if context == null or context.state == null or context.balance == null:
		return
	for event in context.state.events:
		if event == null or not event.is_active():
			continue
		if event.known:
			event.published = true
			continue
		_update_growth_and_publication(event, context.balance)
		if event.known:
			continue
		var probability: float = (
			float(_get_race_seat_count(context.state, event.race))
			* context.balance.event_early_reveal_probability_per_seat
			+ context.state.event_early_reveal_bonus_probability
		)
		if context.random_system.chance(probability):
			event.known = true
			event.published = true


func get_current_requirement(event: EventState) -> int:
	if event == null:
		return 0
	return roundi(
		lerpf(
			float(event.baseline_value),
			float(event.full_target),
			clampf(event.growth_progress, 0.0, 1.0)
		)
	)


func has_active_event(
	state: RunState, race: RaceDefinition, metric: Metric.Id
) -> bool:
	if state == null or race == null:
		return false
	for event in state.events:
		if event != null and event.is_active() and event.race == race and event.metric == metric:
			return true
	return false


func _get_eligible_races(context: RunContext) -> Array[RaceDefinition]:
	var result: Array[RaceDefinition] = []
	for race_state in context.state.races:
		if race_state == null or race_state.definition == null:
			continue
		var race := race_state.definition
		if _get_race_seat_count(context.state, race) == 0:
			continue
		if not _get_eligible_metrics(context, race).is_empty():
			result.append(race)
	return result


func _get_eligible_metrics(
	context: RunContext, race: RaceDefinition
) -> Array[Metric.Id]:
	var result: Array[Metric.Id] = []
	var race_state := context.state.get_race(race)
	if race_state == null:
		return result
	for metric in race.get_stance_metrics():
		if has_active_event(context.state, race, metric):
			continue
		var direction := race.get_stance(metric)
		var target := context.race_system.get_effective_expectation(race_state, metric, context)
		var current := context.state.metrics.get_value(metric)
		if _has_gap(direction, current, target):
			result.append(metric)
	return result


func _has_gap(direction: Metric.Direction, current: int, target: int) -> bool:
	if direction == Metric.Direction.HIGHER:
		return current < target
	if direction == Metric.Direction.LOWER:
		return current > target
	return false


func _get_race_seat_count(state: RunState, race: RaceDefinition) -> int:
	var result := 0
	for seat in state.seats:
		if seat != null and seat.race == race:
			result += 1
	return result


func _update_growth_and_publication(
	event: EventState, balance: GameBalanceDefinition
) -> void:
	var lifetime := maxi(balance.event_lifetime_months, 1)
	var public_remaining := clampi(balance.event_public_remaining_months, 0, lifetime)
	var remaining := maxi(lifetime - event.months_alive, 0)
	if remaining <= public_remaining:
		event.growth_progress = 1.0
		event.known = true
		event.published = true
		return
	var growth_months := maxi(lifetime - public_remaining, 1)
	event.growth_progress = maxf(
		event.growth_progress,
		clampf(float(event.months_alive) / float(growth_months), 0.0, 1.0)
	)


func _update_known_event(event: EventState, context: RunContext) -> void:
	event.satisfaction_rate = _calculate_satisfaction(event, context.state)
	if event.satisfaction_rate < context.balance.event_pause_satisfaction_threshold:
		event.phase = EventState.Phase.WORSENING
		event.relief_progress = 0.0
		return
	if event.satisfaction_rate < context.balance.event_relief_satisfaction_threshold:
		event.phase = EventState.Phase.PAUSED
		return
	event.phase = EventState.Phase.RELIEVING
	event.relief_progress = minf(
		1.0, event.relief_progress + context.balance.event_relief_progress_per_month
	)
	if event.relief_progress >= 1.0:
		_resolve(event, context.state)


func _calculate_satisfaction(event: EventState, state: RunState) -> float:
	var requirement := get_current_requirement(event)
	var required_change := absf(float(requirement - event.baseline_value))
	if is_zero_approx(required_change):
		return 1.0
	var current := state.metrics.get_value(event.metric)
	var direction := 1.0 if event.full_target > event.baseline_value else -1.0
	var achieved_change := maxf(float(current - event.baseline_value) * direction, 0.0)
	return achieved_change / required_change


func _resolve(event: EventState, state: RunState) -> void:
	if not event.is_active():
		return
	event.phase = EventState.Phase.RESOLVED
	var race_state := state.get_race(event.race)
	if race_state != null:
		race_state.resolved_events_this_year += 1


func _fail(event: EventState, context: RunContext) -> void:
	if not event.is_active():
		return
	event.phase = EventState.Phase.FAILED
	event.known = true
	event.published = true
	context.state.pending_collapse_delta += context.balance.event_failure_collapse
