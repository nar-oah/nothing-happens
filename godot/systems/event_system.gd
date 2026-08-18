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


func try_generate_month(context: RunContext) -> Array[EventState]:
	var generated: Array[EventState] = []
	_update_gap_durations(context)
	for race in context.state.races:
		if race == null or race.definition == null:
			continue
		if _has_active_event_for_race(context.state, race.get_id()):
			continue
		var gap_pressure := _race_gap_pressure(race, context)
		if gap_pressure <= 0.0:
			continue
		var duration_pressure := _race_gap_duration_pressure(race)
		var probability := (
			context.balance.event_monthly_spawn_chance
			* (1.0 + gap_pressure * 2.0 + duration_pressure)
		)
		probability *= (context.collapse_system.get_event_density_multiplier(context.state))
		if context.random_system.chance(clampf(probability, 0.0, 0.95)):
			var event := spawn_race_event(context, race.get_id())
			if event != null:
				generated.append(event)
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
		var race := context.state.get_race(event.race_id)
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


func get_current_requirements(event: EventState, context: RunContext) -> Dictionary[int, int]:
	var result: Dictionary[int, int] = {}
	if event == null:
		return result
	for metric_value in event.requirement_targets:
		var metric = metric_value as Metric.Id
		result[metric] = _get_current_target(event, metric, context)
	return result


func _worsen(event: EventState, context: RunContext) -> void:
	event.phase = EventState.Phase.WORSENING
	event.relief_streak = 0
	event.base_intensity = minf(
		MAX_INTENSITY, event.base_intensity + context.balance.event_worsening_per_month
	)
	_update_effective_intensity(event, context.state)
	if event.effective_intensity >= MAX_INTENSITY:
		event.known = true
		event.published = true
		event.crisis_progress += 1
	if event.crisis_progress >= context.balance.event_crisis_months:
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
		context.balance.event_relief_per_month
		+ float(event.relief_streak - 1) * context.balance.event_relief_streak_bonus
		+ overfulfillment * context.balance.event_overfulfillment_bonus
	)
	event.base_intensity = maxf(BASE_INTENSITY, event.base_intensity - relief)
	_update_effective_intensity(event, context.state)


func _resolve(event: EventState, context: RunContext) -> void:
	event.phase = EventState.Phase.RESOLVED
	context.political_trust_system.record_event_result(
		context.state, event.race_id, context.balance.event_trust_on_resolve, true
	)
	context.state.pending_collapse_delta += (context.balance.event_collapse_on_resolve)


func _erupt(event: EventState, context: RunContext) -> void:
	event.phase = EventState.Phase.ERUPTED
	event.known = true
	event.published = true
	context.political_trust_system.record_event_result(
		context.state, event.race_id, context.balance.event_trust_on_erupt, false
	)
	context.state.pending_collapse_delta += (context.balance.event_collapse_on_erupt)


func _update_effective_intensity(event: EventState, state: RunState) -> void:
	var bonus := JINYI_EFFECTIVE_BONUS if state.constitution.has_flag(&"jinyiwei") else 0.0
	event.effective_intensity = minf(MAX_INTENSITY, event.base_intensity + bonus)


func _has_active_event_for_race(state: RunState, race_id: StringName) -> bool:
	for event in state.events:
		if event.race_id == race_id and event.is_active():
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


func spawn_race_event(context: RunContext, race_id: StringName) -> EventState:
	var race := context.state.get_race(race_id)
	if race == null or race.definition == null:
		return null
	var targets: Dictionary[int, int] = {}
	for metric in race.definition.get_stance_metrics():
		var target := race.get_expectation(metric, context.balance.initial_metric_value)
		var current_target := context.race_system.get_effective_expectation(race, metric, context)
		var current := context.state.metrics.get_value(metric)
		var direction := race.definition.get_stance(metric)
		var has_gap := (
			current < current_target
			if direction == MetricStanceDefinition.Direction.HIGHER
			else current > current_target
		)
		if has_gap:
			targets[metric] = target
	if targets.is_empty():
		return null
	var event := EventState.new(race_id, targets, context.state.metrics)
	context.state.events.append(event)
	return event


func _get_full_target(event: EventState, metric: Metric.Id, context: RunContext) -> int:
	var target: int = event.requirement_targets.get(metric, event.baseline.get_value(metric))
	var race := context.state.get_race(event.race_id)
	if race == null or race.definition == null:
		return target
	var direction := race.definition.get_stance(metric)
	if context.constitution_system.uses_yin_yang_for_race(context.state, event.race_id):
		var month_sign := context.balance.get_yin_yang_month_sign(metric, context.state.month)
		target += (int(direction) * month_sign * context.balance.yin_yang_adjustment)
	var baseline := event.baseline.get_value(metric)
	if direction == MetricStanceDefinition.Direction.HIGHER:
		return maxi(baseline, target)
	if direction == MetricStanceDefinition.Direction.LOWER:
		return mini(baseline, target)
	return baseline


func _get_current_target(event: EventState, metric: Metric.Id, context: RunContext) -> int:
	var start := float(event.baseline.get_value(metric))
	var target := float(_get_full_target(event, metric, context))
	return roundi(lerpf(start, target, event.effective_intensity))


func _metric_satisfaction(event: EventState, metric: Metric.Id, context: RunContext) -> float:
	var baseline := event.baseline.get_value(metric)
	var target := _get_current_target(event, metric, context)
	var required := absf(float(target - baseline))
	if required <= 0.000001:
		return 1.0
	var current := context.state.metrics.get_value(metric)
	var direction := 1.0 if target >= baseline else -1.0
	var achieved := maxf(float(current - baseline) * direction, 0.0)
	return achieved / required


func _calculate_satisfaction(event: EventState, context: RunContext) -> float:
	if event.requirement_targets.is_empty():
		return 1.0
	var result := INF
	for metric_value in event.requirement_targets:
		var metric = metric_value as Metric.Id
		result = minf(result, _metric_satisfaction(event, metric, context))
	return 1.0 if is_inf(result) else result
