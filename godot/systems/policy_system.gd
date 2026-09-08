extends RefCounted
class_name PolicySystem

var last_triggered_definitions: Array[PolicyDefinition] = []


func create_states(instances: Array[PolicyState]) -> Array[PolicyState]:
	var result: Array[PolicyState] = []
	for instance in instances:
		if instance != null:
			result.append(PolicyState.new(instance.definition, instance.delay_months))
	return result


func calculate_planned_result(
	pure_target: MetricValues, policies: Array[PolicyState]
) -> MetricValues:
	var result := pure_target.copy()
	var batches: Dictionary = {}
	for policy in policies:
		if policy == null or policy.definition == null:
			continue
		if not batches.has(policy.delay_months):
			batches[policy.delay_months] = []
		batches[policy.delay_months].append(policy)
	var delays: Array[int] = []
	for delay in batches:
		delays.append(delay)
	delays.sort()
	for delay in delays:
		var snapshot := result.copy()
		var total_delta := MetricVector.new()
		for policy: PolicyState in batches[delay]:
			for effect in policy.definition.effects:
				if effect != null:
					total_delta.add_value(
						effect.target_metric,
						effect.calculate_amount(snapshot)
					)
		result.apply_delta(total_delta)
	return result


func schedule_policies(state: RunState, policies: Array[PolicyState]) -> void:
	for policy in policies:
		if policy == null or policy.definition == null:
			continue
		policy.elapsed_months = 0
		policy.triggered = false
		state.scheduled_policies.append(policy)


func advance_month_and_resolve(state: RunState) -> void:
	for policy in state.scheduled_policies:
		if policy != null and not policy.triggered:
			policy.elapsed_months += 1
	resolve_due_policies(state)


func resolve_due_policies(state: RunState) -> void:
	last_triggered_definitions.clear()
	var due: Array[PolicyState] = []
	for policy in state.scheduled_policies:
		if (
			policy != null
			and not policy.triggered
			and policy.elapsed_months >= policy.delay_months
		):
			due.append(policy)
	if due.is_empty():
		return
	var snapshot := state.metrics.copy()
	var total_delta := MetricVector.new()
	for policy in due:
		policy.triggered = true
		last_triggered_definitions.append(policy.definition)
		for effect in policy.definition.effects:
			if effect != null:
				total_delta.add_value(
					effect.target_metric,
					effect.calculate_amount(snapshot)
				)
	state.metrics.apply_delta(total_delta)
	for policy in due:
		state.scheduled_policies.erase(policy)
