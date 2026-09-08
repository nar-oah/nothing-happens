extends RefCounted
class_name SavedBillState

var title: String = ""
var proposals: Array[ProposalInstance] = []
var policies: Array[PolicyState] = []


func copy() -> SavedBillState:
	var result := SavedBillState.new()
	result.title = title
	for proposal in proposals:
		result.proposals.append(proposal.copy())
	for policy in policies:
		if policy != null:
			result.policies.append(policy.copy())
	return result
