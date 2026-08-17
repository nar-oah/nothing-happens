extends RefCounted
class_name EventSystem

const BASE_INTENSITY: float = 0.5
const MAX_INTENSITY: float = 1.0
const WORSEN_THRESHOLD: float = 0.8
const RELIEF_THRESHOLD: float = 1.0
const JINYI_EFFECTIVE_BONUS: float = 0.2
const INTEL_BASE_PROBABILITY: float = 0.02
const INTEL_PER_SEAT: float = 0.025
const INTEL_MIN_PROBABILITY: float = 0.05
const INTEL_MAX_PROBABILITY: float = 0.65
const JINYI_EXTRA_INTEL_PROBABILITY: float = 0.15


func spawn_event(state: RunState, definition: EventDefinition) -> EventState:
	if definition == null:
		return null
	var event := EventState.new(definition, state.metrics)
	state.events.append(event)
	return event


func try_generate_month(context: RunContext) -> Array[EventState]:
	var generated: Array[EventState] = []
	_update_gap_durations(context)
	for definition in context.event_definitions:
		if definition == null or _has_active_event(context.state, definition.id):
			continue
		var race := context.state.get_race(definition.race_id)
		if race == null:
			continue
		var gap_pressure := _race_gap_pressure(race, context)
		var duration_pressure := _race_gap_duration_pressure(race)
		var probability := definition.local_issue_chance
		if gap_pressure > 0.0:
			probability += (
				definition.monthly_spawn_chance * (1.0 + gap_pressure * 2.0 + duration_pressure)
			)
		probability *= context.collapse_system.get_event_density_multiplier(context.state)
		if context.random_system.chance(clampf(probability, 0.0, 0.95)):
			generated.append(spawn_event(context.state, definition))
	return generated


func settle_month(context: RunContext) -> void:
	for event in context.state.events:
		if not event.is_active() or event.definition == null:
			continue
		event.months_alive += 1
		_update_effective_intensity(event, context.state)
		event.satisfaction_rate = _calculate_satisfaction(event, context)
		if event.satisfaction_rate < WORSEN_THRESHOLD:
			_worsen(event, context)
		elif event.satisfaction_rate < RELIEF_THRESHOLD:
			_pause(event)
		else:
			_relieve(event, context)


func update_information(context: RunContext) -> void:
	var has_jinyiwei := context.state.constitution.has_flag(&"jinyiwei")
	for event in context.state.events:
		if not event.is_active() or event.known:
			continue
		_update_effective_intensity(event, context.state)
		if event.effective_intensity >= MAX_INTENSITY:
			event.known = true
			event.published = true
			continue
		var race := context.state.get_race(event.definition.race_id)
		var seats := 0 if race == null else race.seat_count
		var probability := clampf(
			INTEL_BASE_PROBABILITY + INTEL_PER_SEAT * seats,
			INTEL_MIN_PROBABILITY,
			INTEL_MAX_PROBABILITY
		)
		if context.random_system.chance(probability):
			event.known = true
		elif has_jinyiwei and context.random_system.chance(JINYI_EXTRA_INTEL_PROBABILITY):
			event.known = true


func get_current_requirements(event: EventState) -> Dictionary[int, int]:
	var result: Dictionary[int, int] = {}
	if event == null or event.definition == null:
		return result
	for requirement in event.definition.requirements:
		if requirement != null:
			result[requirement.metric] = requirement.current_target(
				event.baseline, event.effective_intensity
			)
	return result


func _worsen(event: EventState, context: RunContext) -> void:
	event.phase = EventState.Phase.WORSENING
	event.relief_streak = 0
	event.base_intensity = minf(
		MAX_INTENSITY, event.base_intensity + event.definition.worsening_per_month
	)
	_update_effective_intensity(event, context.state)
	if event.effective_intensity >= MAX_INTENSITY:
		event.known = true
		event.published = true
		event.crisis_progress += 1
	if event.crisis_progress >= event.definition.crisis_months:
		_erupt(event, context)


func _pause(event: EventState) -> void:
	event.phase = EventState.Phase.PAUSED
	event.relief_streak = 0


func _relieve(event: EventState, context: RunContext) -> void:
	if event.base_intensity <= BASE_INTENSITY and event.relief_streak > 0:
		_resolve(event, context)
		return
	event.phase = EventState.Phase.RELIEVING
	event.relief_streak += 1
	var overfulfillment := maxf(event.satisfaction_rate - RELIEF_THRESHOLD, 0.0)
	var relief := (
		event.definition.relief_per_month
		+ float(event.relief_streak - 1) * event.definition.relief_streak_bonus
		+ overfulfillment * event.definition.overfulfillment_bonus
	)
	event.base_intensity = maxf(BASE_INTENSITY, event.base_intensity - relief)
	_update_effective_intensity(event, context.state)


func _resolve(event: EventState, context: RunContext) -> void:
	event.phase = EventState.Phase.RESOLVED
	context.political_trust_system.record_event_result(
		context.state, event.definition.race_id, event.definition.trust_on_resolve, true
	)
	context.state.pending_collapse_delta += event.definition.collapse_on_resolve


func _erupt(event: EventState, context: RunContext) -> void:
	event.phase = EventState.Phase.ERUPTED
	event.known = true
	event.published = true
	context.political_trust_system.record_event_result(
		context.state, event.definition.race_id, event.definition.trust_on_erupt, false
	)
	context.state.pending_collapse_delta += event.definition.collapse_on_erupt


func _update_effective_intensity(event: EventState, state: RunState) -> void:
	var bonus := JINYI_EFFECTIVE_BONUS if state.constitution.has_flag(&"jinyiwei") else 0.0
	event.effective_intensity = minf(MAX_INTENSITY, event.base_intensity + bonus)


func _calculate_satisfaction(event: EventState, context: RunContext) -> float:
	if event.definition.requirements.is_empty():
		return 1.0
	var result := INF
	for requirement in event.definition.requirements:
		if requirement != null:
			result = minf(
				result,
				requirement.satisfaction(
					context.state.metrics, event.baseline, event.effective_intensity
				)
			)
	return 1.0 if is_inf(result) else result


func _has_active_event(state: RunState, definition_id: StringName) -> bool:
	for event in state.events:
		if event.definition != null and event.definition.id == definition_id and event.is_active():
			return true
	return false


func _update_gap_durations(context: RunContext) -> void:
	for race in context.state.races:
		if race.definition == null:
			continue
		for metric in race.definition.get_stance_metrics():
			var direction := race.definition.get_stance(metric)

			var target := context.race_system.get_effective_expectation(race, metric, context)
			var value := context.state.metrics.get_value(metric)
			var has_gap := (
				value < target
				if direction == MetricStanceDefinition.Direction.HIGHER
				else value > target
			)
			race.expectation_gap_months[metric] = (
				race.expectation_gap_months.get(metric, 0) + 1 if has_gap else 0
			)


func _race_gap_pressure(race: RaceState, context: RunContext) -> float:
	var total := 0.0
	var count := 0
	for metric in race.definition.get_stance_metrics():
		var direction := race.definition.get_stance(metric)
		var target := context.race_system.get_effective_expectation(race, metric, context)
		var value := context.state.metrics.get_value(metric)
		var gap := maxf(float(target - value), 0.0)
		if direction == MetricStanceDefinition.Direction.LOWER:
			gap = maxf(float(value - target), 0.0)
		total += (gap / maxf(absf(float(target)), 1.0))
		count += 1
	return 0.0 if count == 0 else total / float(count)


func _race_gap_duration_pressure(race: RaceState) -> float:
	if race.expectation_gap_months.is_empty():
		return 0.0
	var longest := 0
	for months in race.expectation_gap_months.values():
		longest = maxi(longest, int(months))
	return minf(float(longest) * 0.05, 1.0)


func _effective_requirement_base_amount(
	event: EventState, requirement: EventRequirementDefinition, context: RunContext
) -> int:
	var amount := requirement.base_amount
	if not context.constitution_system.uses_yin_yang_for_race(
		context.state, event.definition.race_id
	):
		return amount
	var month_sign := context.balance.get_yin_yang_month_sign(
		requirement.metric, context.state.month
	)
	return maxi(0, amount + month_sign * context.balance.yin_yang_adjustment)
