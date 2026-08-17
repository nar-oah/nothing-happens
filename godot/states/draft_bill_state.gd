extends RefCounted
class_name DraftBillState

var proposals: Array[ProposalInstance] = []
var policies: Array[PolicyDefinition] = []


func is_empty() -> bool:
	return proposals.is_empty() and policies.is_empty()


func slot_count() -> int:
	return proposals.size() + policies.size()
