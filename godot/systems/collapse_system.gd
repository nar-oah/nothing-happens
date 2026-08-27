extends RefCounted
class_name CollapseSystem


func record_intervention(context: RunContext, kind: StringName, pressure: float) -> void:
	var state := context.state
	state.has_intervened = true
	state.intervention_records.append(
		InterventionRecordState.new(kind, state.absolute_month(), maxf(pressure, 0.0))
	)


func settle_month(context: RunContext) -> void:
	var state := context.state
	var balance := context.balance
	if state.run_failed or state.ending_id != &"":
		return
	state.regulation_pressure = _calculate_regulation_pressure(state, balance)
	var pressure_delta := roundi(state.regulation_pressure * balance.pressure_to_collapse)
	var delta: int = state.pending_collapse_delta + maxi(pressure_delta, 0)
	if _has_negative_metric(state.metrics):
		delta += balance.negative_metric_monthly_pressure
	state.pending_collapse_delta = 0
	state.collapse_level = clampi(
		state.collapse_level + maxi(delta, 0),
		0,
		balance.max_collapse
	)
	if state.collapse_level >= balance.max_collapse:
		if state.has_intervened:
			state.run_failed = true
		else:
			state.ending_id = &"nothing_happens"


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
