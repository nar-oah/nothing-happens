extends RefCounted
class_name ActiveProposalState

var proposal: ProposalInstance
var digested_months: int = 0


func _init(source_proposal: ProposalInstance) -> void:
	proposal = source_proposal


func advance_month() -> void:
	if not is_fully_digested():
		digested_months += 1


func get_digestion_progress() -> float:
	if proposal == null:
		return 0.0
	return minf(1.0, float(digested_months) / float(maxi(proposal.lag_months, 1)))


func is_fully_digested() -> bool:
	return get_digestion_progress() >= 1.0
