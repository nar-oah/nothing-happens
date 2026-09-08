extends RefCounted
class_name DraftBillState

var title: String = ""
var proposals: Array[ProposalInstance] = []
var policies: Array[PolicyState] = []


func is_empty() -> bool:
	return proposals.is_empty() and policies.is_empty()


func slot_count() -> int:
	return proposals.size() + policies.size()


func get_lag_months() -> int:
	var result := 0
	for proposal in proposals:
		if proposal != null:
			result = maxi(result, proposal.lag_months)
	return result


func get_policy_delay_min() -> int:
	return ceili(float(get_lag_months()) / 2.0)


func get_policy_delay_max() -> int:
	return get_lag_months()


func is_policy_delay_valid(delay_months: int) -> bool:
	return delay_months >= get_policy_delay_min() and delay_months <= get_policy_delay_max()


func clamp_policy_delays() -> void:
	var minimum := get_policy_delay_min()
	var maximum := get_policy_delay_max()
	for policy in policies:
		if policy != null:
			policy.delay_months = clampi(policy.delay_months, minimum, maximum)
