extends RefCounted
class_name CollapseSystem


func record_intervention(context: RunContext, kind: StringName, pressure: float) -> void:
	var state := context.state
	state.has_intervened = true
	state.intervention_records.append(
		InterventionRecordState.new(kind, state.absolute_month(), maxf(pressure, 0.0))
	)
	if state.silent_observation:
		state.silent_observation = false
		if state.collapse_level >= context.balance.max_collapse:
			state.run_failed = true


func settle_month(context: RunContext) -> void:
	var state := context.state
	var balance := context.balance
	if state.run_failed or state.ending_id != &"":
		return
	if state.silent_observation and not state.has_intervened:
		state.collapse_level = maxf(
			0.0, state.collapse_level - balance.silent_recovery_per_month
		)
		state.pending_collapse_delta = 0.0
		if state.collapse_level <= 0.0:
			state.ending_id = &"nothing_happens"
		return
	state.regulation_pressure = _calculate_regulation_pressure(state, balance)
	var delta := (
		state.pending_collapse_delta + state.regulation_pressure * balance.pressure_to_collapse
	)
	if _has_negative_metric(state.metrics):
		delta += balance.negative_metric_monthly_pressure
	state.pending_collapse_delta = 0.0
	state.collapse_level = clampf(state.collapse_level + delta, 0.0, balance.max_collapse)
	if state.collapse_level >= balance.max_collapse:
		if state.has_intervened:
			state.run_failed = true
		else:
			state.silent_observation = true


func _calculate_regulation_pressure(
	state: RunState, balance: GameBalanceDefinition
) -> float:
	var result := 0.0
	var current_month := state.absolute_month()
	for record in state.intervention_records:
		var age := maxi(current_month - record.month_index, 0)
		result += record.pressure * pow(balance.pressure_decay_per_month, age)
	return result


func _has_negative_metric(values: MetricValues) -> bool:
	for metric in Metric.all_ids():
		if values.get_value(metric) < 0:
			return true
	return false
