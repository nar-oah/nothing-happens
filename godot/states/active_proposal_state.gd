extends RefCounted
class_name ActiveProposalState

var proposal: ProposalInstance
var digested_months: int = 0
var digestion_progress: float = 0.0


func _init(source_proposal: ProposalInstance) -> void:
	proposal = source_proposal


func advance_month(random_system: RandomSystem, variance: float) -> void:
	if is_fully_digested() or proposal == null:
		return
	digested_months += 1
	var base_step := 1.0 / float(maxi(proposal.lag_months, 1))
	var clamped_variance := clampf(variance, 0.0, 1.0)
	var multiplier := random_system.random_float(
		1.0 - clamped_variance, 1.0 + clamped_variance
	)
	digestion_progress = minf(1.0, digestion_progress + base_step * multiplier)


func get_digestion_progress() -> float:
	return clampf(digestion_progress, 0.0, 1.0)


func is_fully_digested() -> bool:
	return get_digestion_progress() >= 1.0
