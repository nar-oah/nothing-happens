extends RefCounted
class_name FlowController

var context: RunContext


func setup(run_context: RunContext) -> void:
	context = run_context


func advance_month() -> bool:
	if context.state.run_phase != RunState.RunPhase.RUNNING:
		return false
	if context.state.month == 0:
		# Leaving month 0 without revising explicitly forfeits this year's revision.
		context.state.constitution.revision_available = false
		context.time_system.advance_month(context.state)
		if context.state.year == 1 and context.state.governing_months == 0:
			context.proposal_system.draw_automatic_proposals(context)
		return true
	var report_year := context.state.year
	var report_month := context.state.month
	var report_previous_metrics := context.state.metrics.copy()
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
	context.state.governing_months += 1
	_record_month_report(report_year, report_month, report_previous_metrics)
	if context.state.run_phase == RunState.RunPhase.TERM_ENDED:
		return true
	context.proposal_system.draw_automatic_proposals(context)
	context.proposal_system.resolve_active_visits(context)
	if context.state.month == 12:
		context.annual_settlement_system.settle_year(context)
	context.time_system.advance_month(context.state)
	return true


func enact_bill(draft: DraftBillState) -> void:
	if (
		context.state.run_phase != RunState.RunPhase.RUNNING
		or not context.draft_bill_system.is_ready_to_submit(context, draft)
	):
		push_error("Cannot enact an unavailable or unresolved draft.")
		return
	var new_bill := _build_active_bill(draft)
	context.state.active_bill = new_bill
	context.parliament_system.record_authorized_proposal_slots(
		context.state, draft.proposals
	)
	context.policy_system.resolve_policy_chain(context.state)


func submit_draft(draft: DraftBillState) -> VoteResultState:
	var result := VoteResultState.new()
	if (
		context.state.run_phase != RunState.RunPhase.RUNNING
		or not context.draft_bill_system.is_ready_to_submit(context, draft)
	):
		return result
	# Saving happens before the vote, so saved_bills is the authoritative record that the
	# player has ever submitted a bill this term. Collapse uses the array itself to decide
	# whether the "nothing happens" outcome is still possible.
	context.draft_bill_system.save_draft(context.state, draft)
	result = context.vote_system.calculate_vote(draft, context, true)
	result.submitted = true
	if result.passed:
		enact_bill(draft)
		context.draft_bill_system.consume_draft_proposals(context.state, draft)
		context.state.draft_bill = DraftBillState.new()
		context.state.editing_saved_bill_index = RunState.NEW_BILL_INDEX
	context.vote_system.resolve_donation_detection(context)
	context.vote_system.clear_donations(context.state)
	return result


func _record_month_report(
	report_year: int, report_month: int, previous_metrics: MetricValues
) -> void:
	var state := context.state
	state.month_report_year = report_year
	state.month_report_month = report_month
	state.month_report_previous_metrics = previous_metrics.copy()
	state.month_report_current_metrics = state.metrics.copy()
	state.month_report_events.clear()
	for event in state.events:
		if event == null or not event.is_active() or not event.published:
			continue
		state.month_report_events.append(
			{
				"race_display_name": "" if event.race == null else event.race.display_name,
				"metric": int(event.metric),
				"value": context.event_system.get_current_requirement(event),
				"countdown": maxi(context.balance.event_lifetime_months - event.months_alive, 0),
				"strength": roundi(clampf(event.growth_progress, 0.0, 1.0) * 100.0),
				"phase": int(event.phase),
			}
		)


func _build_active_bill(draft: DraftBillState) -> ActiveBillState:
	var bill := ActiveBillState.new()
	bill.title = draft.title
	bill.start_values = context.state.metrics.copy()
	bill.pure_target = context.proposal_system.calculate_pure_target(
		bill.start_values, draft.proposals
	)
	bill.proposals = context.proposal_system.create_active_states(draft.proposals)
	bill.policies = context.policy_system.create_states(draft.policies)
	return bill
