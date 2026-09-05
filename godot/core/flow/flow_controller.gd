extends RefCounted
class_name FlowController

var context: RunContext


func setup(run_context: RunContext) -> void:
	context = run_context


func advance_month() -> bool:
	if context.state.run_phase != RunState.RunPhase.RUNNING:
		return false
	if context.state.month == 0:
		context.state.constitution.revision_available = false
		context.time_system.advance_month(context.state)
		if context.state.year == 1 and context.state.governing_months == 0:
			context.proposal_system.draw_automatic_proposals(context)
		return true
	var report_year := context.state.year
	var report_month := context.state.month
	var report_previous_metrics := context.state.metrics.copy()
	context.event_system.publish_known_events(context)
	for race_state in context.state.races:
		if race_state == null:
			continue
		var active := race_state.active_definition
		if active != null:
			active.on_month_start(context, race_state)
	context.market_system.settle_month(context)
	context.policy_system.resolve_policy_chain(context.state)
	_record_triggered_policies(context.policy_system.last_triggered_definitions)
	context.event_system.try_generate_month(context)
	context.event_system.settle_month(context)
	context.event_system.update_information(context)
	context.event_system.cleanup_published_event_visits(context.state)
	context.state.governing_months += 1
	_record_month_report(report_year, report_month, report_previous_metrics)
	if context.state.run_phase == RunState.RunPhase.TERM_ENDED:
		return true
	context.proposal_system.draw_automatic_proposals(context)
	if context.state.month == 12:
		context.annual_settlement_system.settle_year(context)
	context.time_system.advance_month(context.state)
	return true


func enact_bill(draft: DraftBillState) -> void:
	if context.state.run_phase != RunState.RunPhase.RUNNING or not context.draft_bill_system.is_ready_to_submit(context, draft):
		push_error("Cannot enact an unavailable or unresolved draft.")
		return
	var new_bill := _build_active_bill(draft)
	context.state.active_bill = new_bill
	context.state.newspaper_pending_bill = new_bill
	context.parliament_system.record_authorized_proposal_slots(context.state, draft.proposals)
	context.policy_system.resolve_policy_chain(context.state)
	_record_triggered_policies(context.policy_system.last_triggered_definitions)


func submit_draft(draft: DraftBillState) -> VoteResultState:
	var result := VoteResultState.new()
	if context.state.run_phase != RunState.RunPhase.RUNNING or not context.draft_bill_system.is_ready_to_submit(context, draft):
		return result
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


func _record_triggered_policies(definitions: Array[PolicyDefinition]) -> void:
	for definition in definitions:
		if definition == null or definition in context.state.newspaper_triggered_policies:
			continue
		context.state.newspaper_triggered_policies.append(definition)


func _record_month_report(report_year: int, report_month: int, previous_metrics: MetricValues) -> void:
	var state := context.state
	state.month_report_year = report_year
	state.month_report_month = report_month
	state.month_report_previous_metrics = previous_metrics.copy()
	state.month_report_current_metrics = state.metrics.copy()
	state.month_report_events.clear()
	for event in state.events:
		if event == null or not event.is_active() or not event.published:
			continue
		var active_race := context.constitution_system.get_active_race_definition(context, event.race)
		var event_report := {
			"race_display_name": "" if active_race == null else active_race.display_name,
			"event_description": "" if active_race == null else active_race.event_description,
			"metric": int(event.metric),
			"value": context.event_system.get_current_requirement(event),
			"countdown": maxi(context.balance.event_lifetime_months - event.months_alive, 0),
			"strength": roundi(clampf(event.growth_progress, 0.0, 1.0) * 100.0),
			"phase": int(event.phase),
		}
		if event.requirement_kind == EventState.RequirementKind.INTEREST_GROUP_PROPOSALS:
			var active_group := context.constitution_system.get_active_group_definition(context, event.interest_group)
			event_report["requirement_kind"] = int(event.requirement_kind)
			event_report["interest_group_name"] = "" if active_group == null else active_group.display_name
		state.month_report_events.append(event_report)


func _build_active_bill(draft: DraftBillState) -> ActiveBillState:
	var bill := ActiveBillState.new()
	bill.title = draft.title
	bill.start_values = context.state.metrics.copy()
	bill.pure_target = context.proposal_system.calculate_pure_target(bill.start_values, draft.proposals)
	bill.proposals = context.proposal_system.create_active_states(draft.proposals)
	bill.policies = context.policy_system.create_states(draft.policies)
	return bill
