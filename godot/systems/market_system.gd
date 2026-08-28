extends RefCounted
class_name MarketSystem


func settle_month(context: RunContext) -> void:
	var bill := context.state.active_bill
	if bill == null or bill.proposals.is_empty():
		return
	var previous_anchor := context.proposal_system.calculate_digested_anchor(bill)
	var previous_progress := _get_bill_progress(bill)
	var deviations := _calculate_deviation(context.state.metrics, previous_anchor)
	for active_proposal in bill.proposals:
		active_proposal.advance_month(
			context.random_system, context.balance.proposal_digestion_variance
		)
	var next_anchor := context.proposal_system.calculate_digested_anchor(bill)
	var next_progress := _get_bill_progress(bill)
	var remaining_ratio := _remaining_ratio(previous_progress, next_progress)
	_apply_anchor_with_decay(context.state.metrics, next_anchor, deviations, remaining_ratio)


func _get_bill_progress(bill: ActiveBillState) -> float:
	if bill == null or bill.proposals.is_empty():
		return 1.0
	var progress := 1.0
	for proposal in bill.proposals:
		progress = minf(progress, proposal.get_digestion_progress())
	return clampf(progress, 0.0, 1.0)


func _remaining_ratio(previous_progress: float, next_progress: float) -> float:
	var previous_remaining := 1.0 - clampf(previous_progress, 0.0, 1.0)
	if previous_remaining <= 0.000001:
		return 0.0
	var next_remaining := 1.0 - clampf(next_progress, 0.0, 1.0)
	return clampf(next_remaining / previous_remaining, 0.0, 1.0)


func _calculate_deviation(current: MetricValues, anchor: MetricValues) -> MetricVector:
	var result := MetricVector.new()
	for metric in Metric.all_ids():
		result.set_value(metric, current.get_value(metric) - anchor.get_value(metric))
	return result


func _apply_anchor_with_decay(
	current: MetricValues,
	anchor: MetricValues,
	deviations: MetricVector,
	remaining_ratio: float
) -> void:
	for metric in Metric.all_ids():
		var decayed_deviation := roundi(
			float(deviations.get_value(metric)) * remaining_ratio
		)
		current.set_value(metric, anchor.get_value(metric) + decayed_deviation)
