extends RefCounted
class_name FlowController

var context: RunContext


func setup(run_context: RunContext) -> void:
	context = run_context


func advance_month() -> void:
	context.market_system.settle_month(context)
	context.policy_system.resolve_policy_chain(context.state)
	context.time_system.advance_month(context.state)


func enact_bill(draft: DraftBillState) -> void:
	if draft == null:
		push_error("Cannot enact a null draft.")
		return
	var new_bill := _build_active_bill(draft)
	context.state.active_bill = new_bill
	context.policy_system.resolve_policy_chain(context.state)


func _build_active_bill(draft: DraftBillState) -> ActiveBillState:
	var bill := ActiveBillState.new()
	bill.start_values = context.state.metrics.copy()
	bill.pure_target = context.proposal_system.calculate_pure_target(
		bill.start_values, draft.proposals
	)
	bill.proposals = context.proposal_system.create_active_states(draft.proposals)
	bill.policies = context.policy_system.create_states(draft.policies)
	return bill
