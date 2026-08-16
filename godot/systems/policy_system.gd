extends RefCounted
class_name PolicySystem


func create_states(definitions: Array[PolicyDefinition]) -> Array[PolicyState]:
	var result: Array[PolicyState] = []
	for definition in definitions:
		result.append(PolicyState.new(definition))
	return result


func resolve_policy_chain(state: RunState) -> void:
	var bill := state.active_bill
	if bill == null:
		return
	while true:
		var triggered_batch := _find_triggered_batch(bill, state.metrics)
		if triggered_batch.is_empty():
			return
		_resolve_batch(triggered_batch, state.metrics)


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
			push_error("Policy has no condition: %s" % definition.id)
			continue
		if definition.condition.is_met(values):
			result.append(policy_state)
	return result


func _resolve_batch(batch: Array[PolicyState], current_values: MetricValues) -> void:
	var snapshot := current_values.copy()
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
	current_values.apply_delta(total_delta)
