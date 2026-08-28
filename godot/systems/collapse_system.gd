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
		RunState.TermOutcome.NOTHING_HAPPENS
		if state.saved_bills.is_empty()
		else RunState.TermOutcome.COLLAPSE
	)


func recover_annual(context: RunContext) -> void:
	var state := context.state
	if state.run_phase != RunState.RunPhase.RUNNING:
		return
	state.collapse_level = maxi(
		state.collapse_level - maxi(context.balance.annual_collapse_recovery, 0),
		0
	)
