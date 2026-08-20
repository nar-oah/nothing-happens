extends RefCounted
class_name FlowController

var context: RunContext


func setup(run_context: RunContext) -> void:
	context = run_context


func advance_month() -> void:
	if context.state.run_failed or context.state.ending_id != &"":
		return
	for definition in context.race_definitions:
		var race_state := context.state.get_race(definition)
		if race_state != null:
			definition.on_month_start(context, race_state)
	context.constitution_system.on_month_start(context)
	context.market_system.settle_month(context)
	context.policy_system.resolve_policy_chain(context.state)
	context.event_system.try_generate_month(context)
	context.event_system.settle_month(context)
	context.event_system.update_information(context)
	context.collapse_system.settle_month(context)
	if context.state.run_failed or context.state.ending_id != &"":
		return
	context.proposal_system.draw_automatic_proposals(context)
	context.proposal_system.resolve_active_visits(context)
	if context.state.month == 12:
		context.annual_settlement_system.settle_year(context)
	context.time_system.advance_month(context.state)


func enact_bill(draft: DraftBillState) -> void:
	if not context.draft_bill_system.is_ready_to_submit(context, draft):
		push_error("Cannot enact an unavailable or unresolved draft.")
		return
	var new_bill := _build_active_bill(draft)
	context.state.active_bill = new_bill
	context.parliament_system.record_authorized_proposal_slots(
		context.state, draft.proposals
	)
	for proposal in draft.proposals:
		context.state.pending_collapse_delta += proposal.collapse_impact
	context.policy_system.resolve_policy_chain(context.state)


func submit_draft(draft: DraftBillState) -> VoteResultState:
	var result := VoteResultState.new()
	if not context.draft_bill_system.is_ready_to_submit(context, draft):
		return result
	context.collapse_system.record_intervention(
		context,
		&"bill_submission",
		float(draft.slot_count()) * context.balance.bill_submission_pressure_per_slot
	)
	result = context.vote_system.calculate_vote(draft, context, true)
	result.submitted = true
	context.vote_system.clear_donations(context.state)
	if not result.passed:
		return result
	enact_bill(draft)
	context.state.draft_bill = DraftBillState.new()
	return result


func _build_active_bill(draft: DraftBillState) -> ActiveBillState:
	var bill := ActiveBillState.new()
	bill.start_values = context.state.metrics.copy()
	bill.pure_target = context.proposal_system.calculate_pure_target(
		bill.start_values, draft.proposals
	)
	bill.proposals = context.proposal_system.create_active_states(draft.proposals)
	bill.policies = context.policy_system.create_states(draft.policies)
	return bill
