extends RefCounted
class_name ProposalSystem


func calculate_total_effect(proposals: Array[ProposalInstance]) -> MetricVector:
	var total := MetricVector.new()

	for proposal in proposals:
		total.add(proposal.get_total_effect())

	return total


func calculate_pure_target(
	start_values: MetricValues, proposals: Array[ProposalInstance]
) -> MetricValues:
	var target := start_values.copy()
	var total_effect := calculate_total_effect(proposals)

	target.apply_delta(total_effect)

	return target


func create_active_states(proposals: Array[ProposalInstance]) -> Array[ActiveProposalState]:
	var result: Array[ActiveProposalState] = []

	for proposal in proposals:
		result.append(ActiveProposalState.new(proposal))

	return result
