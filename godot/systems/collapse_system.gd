extends RefCounted
class_name CollapseSystem

const MAX_COLLAPSE: float = 100.0
const PRESSURE_DECAY_PER_MONTH: float = 0.75
const PRESSURE_TO_COLLAPSE: float = 0.12
const NEGATIVE_METRIC_MONTHLY_PRESSURE: float = 1.0
const SILENT_RECOVERY_PER_MONTH: float = 8.0


func record_intervention(state: RunState, kind: StringName, pressure: float) -> void:
	state.has_intervened = true
	state.intervention_records.append(
		InterventionRecordState.new(kind, state.absolute_month(), maxf(pressure, 0.0))
	)
	if state.silent_observation:
		state.silent_observation = false
		if state.collapse_level >= MAX_COLLAPSE:
			state.run_failed = true


func settle_month(state: RunState) -> void:
	if state.run_failed or state.ending_id != &"":
		return
	if state.silent_observation and not state.has_intervened:
		state.collapse_level = maxf(0.0, state.collapse_level - SILENT_RECOVERY_PER_MONTH)
		state.pending_collapse_delta = 0.0
		if state.collapse_level <= 0.0:
			state.ending_id = &"nothing_happens"
		return
	state.regulation_pressure = _calculate_regulation_pressure(state)
	var delta := state.pending_collapse_delta + state.regulation_pressure * PRESSURE_TO_COLLAPSE
	if _has_negative_metric(state.metrics):
		delta += NEGATIVE_METRIC_MONTHLY_PRESSURE
	state.pending_collapse_delta = 0.0
	state.collapse_level = clampf(state.collapse_level + delta, 0.0, MAX_COLLAPSE)
	if state.collapse_level >= MAX_COLLAPSE:
		if state.has_intervened:
			state.run_failed = true
		else:
			state.silent_observation = true


func get_event_density_multiplier(state: RunState) -> float:
	return 1.0 + minf(state.regulation_pressure / 50.0, 1.5)


func _calculate_regulation_pressure(state: RunState) -> float:
	var result := 0.0
	var current_month := state.absolute_month()
	for record in state.intervention_records:
		var age := maxi(current_month - record.month_index, 0)
		result += record.pressure * pow(PRESSURE_DECAY_PER_MONTH, age)
	return result


func _has_negative_metric(values: MetricValues) -> bool:
	for metric in Metric.all_ids():
		if values.get_value(metric) < 0:
			return true
	return false
