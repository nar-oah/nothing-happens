extends RefCounted
class_name PolicySystem

var last_triggered_definitions: Array[PolicyDefinition] = []


func create_states(definitions: Array[PolicyDefinition]) -> Array[PolicyState]:
	var result: Array[PolicyState] = []
	for definition in definitions:
		result.append(PolicyState.new(definition))
	return result


func resolve_policy_chain(state: RunState) -> void:
	last_triggered_definitions.clear()
	var bill := state.active_bill
	if bill == null:
		return
	while true:
		var triggered_batch := _find_triggered_batch(bill, state.metrics)
		if triggered_batch.is_empty():
			return
		for policy_state in triggered_batch:
			if policy_state != null and policy_state.definition != null:
				last_triggered_definitions.append(policy_state.definition)
		_resolve_batch(triggered_batch, state)


func calculate_immediate_result(
	current: MetricValues, definitions: Array[PolicyDefinition]
) -> MetricValues:
	var simulation := RunState.new()
	simulation.metrics = current.copy()
	var bill := ActiveBillState.new()
	bill.policies = create_states(definitions)
	simulation.active_bill = bill
	resolve_policy_chain(simulation)
	return simulation.metrics


func calculate_draft_result(
	current: MetricValues,
	pure_target: MetricValues,
	definitions: Array[PolicyDefinition]
) -> MetricValues:
	var simulation := RunState.new()
	simulation.metrics = current.copy()
	var bill := ActiveBillState.new()
	bill.policies = create_states(definitions)
	simulation.active_bill = bill
	resolve_policy_chain(simulation)
	var immediate_delta := MetricVector.new()
	for metric in Metric.all_ids():
		immediate_delta.set_value(
			metric,
			simulation.metrics.get_value(metric) - current.get_value(metric)
		)
	simulation.metrics = pure_target.copy()
	simulation.metrics.apply_delta(immediate_delta)
	resolve_policy_chain(simulation)
	return simulation.metrics


func _find_triggered_batch(bill: ActiveBillState, values: MetricValues) -> Array[PolicyState]:
	var result: Array[PolicyState] = []
	for policy_state in bill.policies:
		if policy_state.triggered:
			continue
		var definition := policy_state.definition
		if definition == null:
			push_error("PolicyState has no PolicyDefinition.")
			continue
		if definition.condition == null:
			push_error("Policy has no condition: %s" % definition.display_name)
			continue
		if definition.condition.is_met(values):
			result.append(policy_state)
	return result


func _resolve_batch(batch: Array[PolicyState], state: RunState) -> void:
	var snapshot := state.metrics.copy()
	for policy_state in batch:
		policy_state.triggered = true
	var total_delta := MetricVector.new()
	for policy_state in batch:
		var definition := policy_state.definition
		for effect in definition.effects:
			if effect == null:
				continue
			var amount := effect.calculate_amount(snapshot)
			total_delta.add_value(effect.target_metric, amount)
	state.metrics.apply_delta(total_delta)
