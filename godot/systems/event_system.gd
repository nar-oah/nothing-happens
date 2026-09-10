extends RefCounted
class_name EventSystem


func try_generate_month(context: RunContext) -> Array[EventState]:
	var generated: Array[EventState] = []
	if context == null or context.state == null or context.balance == null:
		return generated
	var minimum := mini(context.balance.event_spawn_count_min, context.balance.event_spawn_count_max)
	var maximum := maxi(context.balance.event_spawn_count_min, context.balance.event_spawn_count_max)
	var target_count := context.random_system.random_int(minimum, maximum)
	return _generate_events(context, target_count)


func generate_legacy_events(context: RunContext) -> Array[EventState]:
	var generated := _generate_events(context, 2)
	for event in generated:
		event.growth_progress = 0.5
		event.known = true
		event.published = true
	return generated


func _generate_events(context: RunContext, target_count: int) -> Array[EventState]:
	var generated: Array[EventState] = []
	if context == null or context.state == null or context.balance == null:
		return generated
	while generated.size() < target_count:
		var races := _get_eligible_races(context)
		if races.is_empty():
			break
		var race := races[context.random_system.random_int(0, races.size() - 1)]
		var race_state := context.state.get_race(race)
		if race_state != null and _get_fixed_interest_group(race_state) != null:
			var group_event := spawn_interest_group_event(context, race)
			if group_event == null:
				break
			generated.append(group_event)
			continue
		var metrics := _get_eligible_metrics(context, race)
		if metrics.is_empty():
			break
		var metric := metrics[context.random_system.random_int(0, metrics.size() - 1)]
		var event := spawn_event(context, race, metric)
		if event == null:
			break
		generated.append(event)
	return generated


func spawn_event(context: RunContext, race: RaceDefinition, metric: Metric.Id) -> EventState:
	if context == null or context.state == null or race == null or _get_race_seat_count(context.state, race) == 0:
		return null
	var race_state := context.state.get_race(race)
	if race_state == null or _get_fixed_interest_group(race_state) != null:
		return null
	if has_active_event(context.state, race, metric):
		return null
	var active := race_state.active_definition
	if (
		active == null
		or active.get_stance(metric) == Metric.Direction.NONE
		or not active.is_vote_metric_active(metric, context)
	):
		return null
	var target := context.race_system.get_effective_expectation(race_state, metric, context)
	var baseline := context.state.metrics.get_value(metric)
	if baseline >= target:
		return null
	var event := EventState.new(race, metric, baseline, target)
	context.state.events.append(event)
	return event


func spawn_interest_group_event(context: RunContext, race: RaceDefinition) -> EventState:
	if context == null or context.state == null or race == null or _get_race_seat_count(context.state, race) == 0:
		return null
	var race_state := context.state.get_race(race)
	if race_state == null:
		return null
	var group := _get_fixed_interest_group(race_state)
	if group == null or has_active_interest_group_event(context.state, race):
		return null
	var target := context.race_system.get_interest_group_proposal_expectation(race_state, context)
	var baseline := _get_interest_group_proposal_count(context, group)
	if baseline >= target:
		return null
	var event := EventState.new(
		race,
		Metric.Id.TAX,
		baseline,
		target,
		EventState.RequirementKind.INTEREST_GROUP_PROPOSALS,
		group
	)
	context.state.events.append(event)
	return event


func settle_month(context: RunContext) -> void:
	if context == null or context.state == null or context.balance == null:
		return
	for event in context.state.events:
		if event == null or not event.is_active():
			continue
		if event.known:
			_update_known_event(event, context)
			if event.is_active():
				_update_deadline_from_phase(event, context.balance)
				if event.phase == EventState.Phase.WORSENING:
					_force_public_window(event, context.balance)
		else:
			event.months_alive = mini(event.months_alive + 1, maxi(context.balance.event_lifetime_months, 1))
			var forced_public := _force_public_window(event, context.balance)
			if forced_public:
				_update_known_event(event, context)
			else:
				_advance_growth(event, context.balance)
		if event.is_active() and event.months_alive >= context.balance.event_lifetime_months:
			_fail(event, context)
	_remove_resolved_events(context.state)


func update_information(context: RunContext) -> void:
	if context == null or context.state == null or context.balance == null:
		return
	for event in context.state.events:
		if event == null or not event.is_active() or event.published or event.known:
			continue
		if _force_public_window(event, context.balance):
			_update_known_event(event, context)
			continue
		var probability := (
			float(_get_race_seat_count(context.state, event.race))
			* context.balance.event_early_reveal_probability_per_seat
			+ context.constitution_system.get_event_intel_probability_modifier(context, event.race)
		)
		if context.random_system.chance(clampf(probability, 0.0, 1.0)):
			event.known = true
			var visit := OfficeVisitState.new()
			visit.kind = OfficeVisitState.Kind.EVENT_INTEL
			visit.race = event.race
			visit.event = event
			context.state.office_visits.append(visit)
			_update_known_event(event, context)
	_remove_resolved_events(context.state)


func publish_known_events(context: RunContext) -> void:
	if context == null or context.state == null:
		return
	for event in context.state.events:
		if event != null and event.known and not event.published:
			event.published = true


func cleanup_published_event_visits(state: RunState) -> void:
	if state == null:
		return
	for index in range(state.office_visits.size() - 1, -1, -1):
		var visit := state.office_visits[index]
		if (
			visit != null
			and visit.kind == OfficeVisitState.Kind.EVENT_INTEL
			and visit.event != null
			and visit.event.published
		):
			state.office_visits.remove_at(index)


func get_current_requirement(event: EventState) -> int:
	if event == null:
		return 0
	return roundi(lerpf(float(event.baseline_value), float(event.full_target), clampf(event.growth_progress, 0.0, 1.0)))


func has_active_event(state: RunState, race: RaceDefinition, metric: Metric.Id) -> bool:
	if state == null or race == null:
		return false
	for event in state.events:
		if (
			event != null
			and event.is_active()
			and event.requirement_kind == EventState.RequirementKind.METRIC
			and event.race == race
			and event.metric == metric
		):
			return true
	return false


func has_active_interest_group_event(state: RunState, race: RaceDefinition) -> bool:
	if state == null or race == null:
		return false
	for event in state.events:
		if (
			event != null
			and event.is_active()
			and event.requirement_kind == EventState.RequirementKind.INTEREST_GROUP_PROPOSALS
			and event.race == race
		):
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
		if _get_fixed_interest_group(race_state) != null:
			if _has_eligible_interest_group_event(context, race_state):
				result.append(race)
			continue
		if not _get_eligible_metrics(context, race).is_empty():
			result.append(race)
	return result


func _get_eligible_metrics(context: RunContext, race: RaceDefinition) -> Array[Metric.Id]:
	var result: Array[Metric.Id] = []
	var race_state := context.state.get_race(race)
	if race_state == null or race_state.active_definition == null or _get_fixed_interest_group(race_state) != null:
		return result
	var active := race_state.active_definition
	for metric in active.get_stance_metrics():
		if not active.is_vote_metric_active(metric, context):
			continue
		if has_active_event(context.state, race, metric):
			continue
		var target := context.race_system.get_effective_expectation(race_state, metric, context)
		if context.state.metrics.get_value(metric) < target:
			result.append(metric)
	return result


func _has_eligible_interest_group_event(context: RunContext, race_state: RaceState) -> bool:
	var group := _get_fixed_interest_group(race_state)
	if group == null or has_active_interest_group_event(context.state, race_state.definition):
		return false
	var target := context.race_system.get_interest_group_proposal_expectation(race_state, context)
	return _get_interest_group_proposal_count(context, group) < target


func _get_fixed_interest_group(race_state: RaceState) -> InterestGroupDefinition:
	if race_state == null or race_state.definition == null:
		return null
	return race_state.definition.fixed_interest_group


func _get_interest_group_proposal_count(
	context: RunContext, group: InterestGroupDefinition
) -> int:
	if context == null or context.state == null or group == null:
		return 0
	var target_identity := context.constitution_system.resolve_group_identity(context, group)
	if target_identity == null:
		return 0
	var result := 0
	for source in context.state.annual_proposal_slot_counts:
		var source_group := source as InterestGroupDefinition
		if source_group == null:
			continue
		if context.constitution_system.resolve_group_identity(context, source_group) == target_identity:
			result += maxi(int(context.state.annual_proposal_slot_counts[source_group]), 0)
	return result


func _get_race_seat_count(state: RunState, race: RaceDefinition) -> int:
	var result := 0
	for seat in state.seats:
		if seat != null and seat.race == race:
			result += 1
	return result


func _force_public_window(event: EventState, balance: GameBalanceDefinition) -> bool:
	var lifetime := maxi(balance.event_lifetime_months, 1)
	var public_remaining := clampi(balance.event_public_remaining_months, 0, lifetime)
	var remaining := maxi(lifetime - event.months_alive, 0)
	if remaining <= public_remaining and not event.public_window_entered:
		event.growth_progress = 1.0
		event.known = true
		event.published = true
		event.public_window_entered = true
		event.phase = EventState.Phase.WORSENING
		return true
	return false


func _advance_growth(event: EventState, balance: GameBalanceDefinition) -> void:
	var lifetime := maxi(balance.event_lifetime_months, 1)
	var public_remaining := clampi(balance.event_public_remaining_months, 0, lifetime)
	var growth_months := maxi(lifetime - public_remaining, 1)
	event.growth_progress = clampf(event.growth_progress + 1.0 / float(growth_months), 0.0, 1.0)


func _update_deadline_from_phase(event: EventState, balance: GameBalanceDefinition) -> void:
	var lifetime := maxi(balance.event_lifetime_months, 1)
	match event.phase:
		EventState.Phase.WORSENING:
			event.months_alive = mini(event.months_alive + 1, lifetime)
		EventState.Phase.RELIEVING:
			if is_zero_approx(event.growth_progress):
				event.months_alive = 0
			else:
				event.months_alive = maxi(event.months_alive - 1, 0)
		_:
			pass


func _update_known_event(event: EventState, context: RunContext) -> void:
	event.satisfaction_rate = _calculate_satisfaction(event, context)
	if event.satisfaction_rate < context.balance.event_pause_satisfaction_threshold:
		event.phase = EventState.Phase.WORSENING
		_advance_growth(event, context.balance)
		return
	if event.satisfaction_rate < context.balance.event_relief_satisfaction_threshold:
		event.phase = EventState.Phase.PAUSED
		return
	if event.full_target == 0 and event.baseline_value < 0:
		_resolve(event, context.state)
		return
	# Reaching zero strength is itself a visible final relief state. Only resolve on
	# the next settlement if the event is still satisfied; this keeps the zero-strength,
	# full-countdown state in the newspaper for one edition and lets a renewed shortfall
	# worsen the same event instead of making it disappear and respawn.
	if is_zero_approx(event.growth_progress):
		_resolve(event, context.state)
		return
	event.phase = EventState.Phase.RELIEVING
	event.growth_progress = maxf(0.0, event.growth_progress - context.balance.event_relief_progress_per_month)


func _calculate_satisfaction(event: EventState, context: RunContext) -> float:
	var requirement := get_current_requirement(event)
	var current := _get_current_value(event, context)
	if current >= requirement:
		return 1.0
	if requirement <= 0:
		return 0.0
	return clampf(float(current) / float(requirement), 0.0, 1.0)


func _get_current_value(event: EventState, context: RunContext) -> int:
	if event == null or context == null or context.state == null:
		return 0
	if event.requirement_kind == EventState.RequirementKind.INTEREST_GROUP_PROPOSALS:
		return _get_interest_group_proposal_count(context, event.interest_group)
	return context.state.metrics.get_value(event.metric)


func _resolve(event: EventState, state: RunState) -> void:
	if not event.is_active():
		return
	event.phase = EventState.Phase.RESOLVED
	event.months_alive = 0
	var race_state := state.get_race(event.race)
	if race_state != null:
		race_state.resolved_events_this_year += 1
	_remove_event_visits(state, event)


func _remove_event_visits(state: RunState, event: EventState) -> void:
	if state == null or event == null:
		return
	for index in range(state.office_visits.size() - 1, -1, -1):
		var visit := state.office_visits[index]
		if visit != null and visit.kind == OfficeVisitState.Kind.EVENT_INTEL and visit.event == event:
			state.office_visits.remove_at(index)


func _remove_resolved_events(state: RunState) -> void:
	if state == null:
		return
	for index in range(state.events.size() - 1, -1, -1):
		var event := state.events[index]
		if event != null and event.phase == EventState.Phase.RESOLVED:
			state.events.remove_at(index)


func _fail(event: EventState, context: RunContext) -> void:
	if not event.is_active():
		return
	event.phase = EventState.Phase.FAILED
	event.known = true
	event.published = true
	context.collapse_system.increase(context)
