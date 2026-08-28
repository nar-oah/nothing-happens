extends RefCounted
class_name CollapseSystem


func increase(context: RunContext) -> void:
	var state := context.state
	if state.run_phase != RunState.RunPhase.RUNNING:
		return
	state.collapse_level = clampi(
		state.collapse_level + context.balance.collapse_step,
		0,
		context.balance.max_collapse
	)
	if state.collapse_level < context.balance.max_collapse:
		return
	state.run_phase = RunState.RunPhase.TERM_ENDED
	state.term_outcome = (
		RunState.TermOutcome.COLLAPSE
		if state.has_submitted_bill
		else RunState.TermOutcome.NOTHING_HAPPENS
	)


func settle_month(context: RunContext) -> void:
	var state := context.state
	if state.run_phase != RunState.RunPhase.RUNNING:
		return
	if _has_negative_metric(state.metrics):
		increase(context)


func recover_annual(context: RunContext) -> void:
	var state := context.state
	if state.run_phase != RunState.RunPhase.RUNNING or state.month != 0:
		return
	state.collapse_level = maxi(
		state.collapse_level - context.balance.annual_collapse_recovery,
		0
	)


func _has_negative_metric(values: MetricValues) -> bool:
	for metric in Metric.all_ids():
		if values.get_value(metric) < 0:
			return true
	return false
