extends RefCounted
class_name ActiveProposalState

var proposal: ProposalInstance
var digestion_progress: float = 0.0


func _init(source_proposal: ProposalInstance) -> void:
	proposal = source_proposal


func is_fully_digested() -> bool:
	return digestion_progress >= 1.0
