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
		var active_copy := proposal.copy()
		result.append(ActiveProposalState.new(active_copy))
	return result


func calculate_digested_anchor(bill: ActiveBillState) -> MetricValues:
	var tax := float(bill.start_values.tax)
	var price := float(bill.start_values.price)
	var wage := float(bill.start_values.wage)
	var employment := float(bill.start_values.employment)
	var trade := float(bill.start_values.trade)

	for active_proposal in bill.proposals:
		var effect := active_proposal.proposal.get_total_effect()
		var progress := clampf(active_proposal.digestion_progress, 0.0, 1.0)

		tax += effect.tax * progress
		price += effect.price * progress
		wage += effect.wage * progress
		employment += effect.employment * progress
		trade += effect.trade * progress

	var result := MetricValues.new()

	result.tax = roundi(tax)
	result.price = roundi(price)
	result.wage = roundi(wage)
	result.employment = roundi(employment)
	result.trade = roundi(trade)

	return result
