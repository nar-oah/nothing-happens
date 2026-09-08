extends NewspaperFrontDefinition
class_name BillPassedNewspaperFrontDefinition

@export var default_bill_name: String
@export var named_bill_format: String
@export_multiline var no_reduction_text: String
@export_multiline var reduction_text_format: String
@export var reduction_item_format: String
@export var list_separator: String = "、"


func resolve(
	state: RunState,
	_balance: GameBalanceDefinition,
	_previous_collapse: int
) -> Variant:
	var bill := state.newspaper_pending_bill
	if bill == null:
		return null
	var stripped_title := bill.title.strip_edges()
	var bill_name := (
		_t(default_bill_name)
		if stripped_title.is_empty()
		else _t(named_bill_format) % stripped_title
	)
	var reductions := _expected_monthly_bill_reductions(bill)
	var reduction_text := (
		_t(no_reduction_text)
		if reductions.is_empty()
		else _t(reduction_text_format) % _t(list_separator).join(reductions)
	)
	return make_front(_t(title) % bill_name, _t(content) % reduction_text)


func _expected_monthly_bill_reductions(bill: ActiveBillState) -> PackedStringArray:
	var totals: Dictionary = {}
	for metric in Metric.all_ids():
		totals[metric] = 0.0
	for active_proposal in bill.proposals:
		if active_proposal == null or active_proposal.proposal == null:
			continue
		var proposal := active_proposal.proposal
		var effect := proposal.get_total_effect()
		var lag := maxi(proposal.lag_months, 1)
		for metric in Metric.all_ids():
			totals[metric] = float(totals[metric]) + float(effect.get_value(metric)) / float(lag)
	var reductions := PackedStringArray()
	for metric in Metric.all_ids():
		var delta := float(totals[metric])
		if delta >= -0.05:
			continue
		reductions.append(
			_t(reduction_item_format)
			% [_t(Metric.display_name(metric)), _format_front_number(absf(delta))]
		)
	return reductions


func _format_front_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return "%.1f" % value
