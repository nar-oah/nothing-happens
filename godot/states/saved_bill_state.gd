extends RefCounted
class_name SavedBillState

var title: String = ""
var proposals: Array[ProposalInstance] = []
var policies: Array[PolicyDefinition] = []


func copy() -> SavedBillState:
	var result := SavedBillState.new()
	result.title = title
	for proposal in proposals:
		result.proposals.append(proposal.copy())
	result.policies.assign(policies)
	return result
