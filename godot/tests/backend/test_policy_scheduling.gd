extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_delay_bounds_defaults_and_clamping(t)
	_test_zero_delay_executes_on_enactment(t)
	_test_new_bill_keeps_old_schedule_and_batches_same_month(t)
	_test_different_months_resolve_in_order(t)
	_test_month_flow_orders_market_policy_and_event(t)
	_test_negative_policy_effect_is_preserved(t)
	_test_single_policy_planning_preview(t)
	_test_planning_preview_groups_by_delay(t)


func _test_delay_bounds_defaults_and_clamping(t: BackendTestContext) -> void:
	var race := t.make_race("delay bounds")
	var group := t.make_group("delay source")
	var first := PolicyDefinition.new()
	first.display_name = "first delay policy"
	var second := PolicyDefinition.new()
	second.display_name = "second delay policy"
	var article := t.make_article(race)
	article.policies = [first, second]
	var session := t.make_session(
		[race], [group], t.make_seats(1, "delay bounds"), [article]
	)
	var draft := session.state.draft_bill
	t.check_equal(draft.get_lag_months(), 0, "a bill without proposals has zero lag")
	t.check_equal(draft.get_policy_delay_min(), 0, "a zero-lag bill allows zero delay")
	t.check(session.draft_bill_system.add_available_policy(session.context, first), "a policy can be added to a zero-lag bill")
	t.check_equal(draft.policies[0].delay_months, 0, "a new policy defaults to the legal zero delay")

	var five_month := t.make_proposal(group)
	five_month.lag_months = 5
	session.state.add_proposal_to_hand(five_month)
	t.check(session.draft_bill_system.move_proposal_from_hand(session.state, 0), "a proposal enters the draft")
	t.check_equal(draft.get_policy_delay_min(), 3, "odd bill lag rounds the minimum delay upward")
	t.check_equal(draft.get_policy_delay_max(), 5, "maximum policy delay equals bill lag")
	t.check_equal(draft.policies[0].delay_months, 3, "adding a proposal clamps an existing delay to the new minimum")
	t.check(session.draft_bill_system.set_policy_delay(session.state, 0, 5), "the inclusive maximum delay is accepted")
	t.check(not session.draft_bill_system.set_policy_delay(session.state, 0, 2), "a delay below the minimum is rejected")
	t.check(not session.draft_bill_system.set_policy_delay(session.state, 0, 6), "a delay above the maximum is rejected")
	t.check(session.draft_bill_system.add_available_policy(session.context, second), "a second policy can be added")
	t.check_equal(draft.policies[1].delay_months, 3, "a newly added policy uses the current legal minimum")
	t.check(draft.policies[0] != draft.policies[1], "each draft policy has an independent policy state")

	var eight_month := t.make_proposal(group)
	eight_month.lag_months = 8
	session.state.add_proposal_to_hand(eight_month)
	t.check(session.draft_bill_system.move_proposal_from_hand(session.state, 0), "a longer proposal enters the draft")
	t.check_equal(draft.policies[0].delay_months, 5, "a still-legal selected delay is preserved")
	t.check_equal(draft.policies[1].delay_months, 4, "a selected delay below a raised minimum is clamped")
	t.check(session.draft_bill_system.return_proposal_to_hand(session.state, 1), "the longer proposal leaves the draft")
	t.check_equal(draft.policies[1].delay_months, 4, "a still-legal delay survives a reduced range")
	t.check(session.draft_bill_system.return_proposal_to_hand(session.state, 0), "the last proposal leaves the draft")
	t.check_equal(draft.policies[0].delay_months, 0, "removing all lag clamps the maximum down to zero")
	t.check_equal(draft.policies[1].delay_months, 0, "all policy instances clamp independently")
	t.check(draft.policies[0].definition == first, "changing delay keeps the shared definition reference unchanged")
	session.free()


func _test_zero_delay_executes_on_enactment(t: BackendTestContext) -> void:
	var policy := _make_metric_policy(
		"immediate", Metric.Id.INVESTMENT, PolicyEffect.Formula.METRIC_VALUE,
		Metric.Id.TAX, Metric.Id.CONSUMPTION, 1.0
	)
	var session := _make_policy_session(t, [policy], "immediate")
	var draft := DraftBillState.new()
	draft.policies.append(PolicyState.new(policy, 0))
	var before := session.state.metrics.investment
	session.enact_bill(draft)
	t.check_equal(session.state.metrics.investment, before + session.state.metrics.tax, "zero-delay policy executes when the bill is enacted")
	t.check(session.state.active_bill.policies[0].triggered, "the enacted policy instance records execution")
	t.check(session.state.scheduled_policies.is_empty(), "an immediately executed policy leaves no pending queue item")
	session.free()


func _test_new_bill_keeps_old_schedule_and_batches_same_month(t: BackendTestContext) -> void:
	var production_policy := _make_metric_policy(
		"old scheduled", Metric.Id.PRODUCTION, PolicyEffect.Formula.METRIC_VALUE,
		Metric.Id.TAX, Metric.Id.CONSUMPTION, 1.0
	)
	var investment_policy := _make_metric_policy(
		"new scheduled", Metric.Id.INVESTMENT, PolicyEffect.Formula.METRIC_VALUE,
		Metric.Id.PRODUCTION, Metric.Id.CONSUMPTION, 2.0
	)
	var session := _make_policy_session(
		t, [production_policy, investment_policy], "overlapping bills"
	)
	session.state.metrics.tax = 10
	session.state.metrics.production = 2
	session.state.metrics.investment = 0
	var first := _draft_with_lag(
		session.context.interest_groups[0], production_policy, 4, 4, "first bill"
	)
	session.enact_bill(first)
	var enacted_policy := session.state.scheduled_policies[0]
	first.policies[0].delay_months = 2
	t.check_equal(
		enacted_policy.delay_months,
		4,
		"changing the draft after enactment cannot alter the locked scheduled delay"
	)
	session.policy_system.advance_month_and_resolve(session.state)
	session.policy_system.advance_month_and_resolve(session.state)
	var old_schedule := session.state.scheduled_policies[0]
	t.check_equal(old_schedule.elapsed_months, 2, "the first bill records its elapsed settlement months")

	var second := _draft_with_lag(
		session.context.interest_groups[0], investment_policy, 2, 2, "second bill"
	)
	session.enact_bill(second)
	t.check_equal(session.state.active_bill.title, "second bill", "the newer bill becomes active")
	t.check_equal(session.state.scheduled_policies.size(), 2, "the newer bill does not replace an older pending policy")
	t.check(session.state.scheduled_policies[0] == old_schedule, "the original scheduled instance remains in the queue")
	session.policy_system.advance_month_and_resolve(session.state)
	t.check_equal(session.state.scheduled_policies.size(), 2, "neither policy executes one month before their shared due month")
	session.policy_system.advance_month_and_resolve(session.state)
	t.check_equal(session.state.metrics.production, 12, "the older policy executes after its fourth settlement")
	t.check_equal(session.state.metrics.investment, 4, "same-month policies calculate from one pre-execution snapshot")
	t.check(session.state.scheduled_policies.is_empty(), "the complete due batch is removed from the pending queue")
	session.free()


func _test_different_months_resolve_in_order(t: BackendTestContext) -> void:
	var first := _make_metric_policy(
		"month one", Metric.Id.PRODUCTION, PolicyEffect.Formula.METRIC_VALUE,
		Metric.Id.TAX, Metric.Id.CONSUMPTION, 1.0
	)
	var second := _make_metric_policy(
		"month two", Metric.Id.INVESTMENT, PolicyEffect.Formula.METRIC_VALUE,
		Metric.Id.PRODUCTION, Metric.Id.CONSUMPTION, 2.0
	)
	var state := RunState.new()
	state.metrics.tax = 10
	state.metrics.production = 2
	state.metrics.investment = 0
	var system := PolicySystem.new()
	var policies: Array[PolicyState] = [
		PolicyState.new(first, 1), PolicyState.new(second, 2),
	]
	system.schedule_policies(state, policies)
	system.advance_month_and_resolve(state)
	t.check_equal(state.metrics.production, 12, "the first-month policy executes first")
	t.check_equal(state.metrics.investment, 0, "the later policy remains pending")
	t.check_equal(state.scheduled_policies[0].elapsed_months, 1, "the later policy retains elapsed month progress")
	system.advance_month_and_resolve(state)
	t.check_equal(state.metrics.investment, 24, "a later-month policy reads effects from earlier months")
	t.check(state.scheduled_policies.is_empty(), "all ordered policies leave the queue after execution")


func _test_month_flow_orders_market_policy_and_event(t: BackendTestContext) -> void:
	var race := t.make_race("settlement order")
	var group := t.make_group("settlement source")
	var policy := _make_metric_policy(
		"settlement policy", Metric.Id.INVESTMENT, PolicyEffect.Formula.METRIC_VALUE,
		Metric.Id.TAX, Metric.Id.CONSUMPTION, 1.0
	)
	var article := t.make_article(race)
	article.policies = [policy]
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.event_early_reveal_probability_per_seat = 0.0
	balance.proposal_digestion_variance = 0.0
	var session := t.make_session(
		[race], [group], t.make_seats(1, "settlement order"), [article], balance
	)
	session.state.metrics.tax = 100
	session.state.metrics.investment = 0
	var proposal := t.make_proposal(group)
	proposal.lag_months = 1
	proposal.base_effect.tax = 10
	var draft := DraftBillState.new()
	draft.proposals.append(proposal)
	draft.policies.append(PolicyState.new(policy, 1))
	session.enact_bill(draft)

	var event := EventState.new(race, Metric.Id.INVESTMENT, 0, 100)
	event.known = true
	event.published = true
	event.growth_progress = 1.0
	session.state.events.append(event)
	session.state.month = 1
	t.check(session.advance_month(), "the settlement-order month advances")
	t.check_equal(session.state.metrics.tax, 110, "the market settles the proposal first")
	t.check_equal(
		session.state.metrics.investment,
		110,
		"the due policy reads the post-market metric snapshot"
	)
	t.check_equal(
		event.phase,
		EventState.Phase.RELIEVING,
		"event settlement observes the policy result from the same month"
	)
	session.free()


func _test_negative_policy_effect_is_preserved(t: BackendTestContext) -> void:
	var policy := _make_metric_policy(
		"negative effect", Metric.Id.EMPLOYMENT, PolicyEffect.Formula.METRIC_GAP,
		Metric.Id.TAX, Metric.Id.CONSUMPTION, 1.0
	)
	var state := RunState.new()
	state.metrics.tax = 2
	state.metrics.consumption = 7
	state.metrics.employment = 0
	state.scheduled_policies.append(PolicyState.new(policy, 0))
	PolicySystem.new().resolve_due_policies(state)
	t.check_equal(state.metrics.employment, -5, "a signed policy calculation may produce a negative metric")


func _test_single_policy_planning_preview(t: BackendTestContext) -> void:
	var policy := _make_metric_policy(
		"single preview", Metric.Id.INVESTMENT, PolicyEffect.Formula.METRIC_VALUE,
		Metric.Id.TAX, Metric.Id.CONSUMPTION, 2.0
	)
	var pure_target := MetricValues.new()
	pure_target.tax = 7
	pure_target.investment = 1
	var instance := PolicyState.new(policy, 3)
	instance.elapsed_months = 2
	var policies: Array[PolicyState] = [instance]
	var projected := PolicySystem.new().calculate_planned_result(pure_target, policies)
	t.check_equal(projected.investment, 15, "planning preview applies a single policy to the pure proposal target")
	t.check_equal(pure_target.investment, 1, "planning preview leaves its input metrics unchanged")
	t.check_equal(instance.elapsed_months, 2, "planning preview does not advance scheduled state")
	t.check(not instance.triggered, "planning preview does not mark policy state as executed")


func _test_planning_preview_groups_by_delay(t: BackendTestContext) -> void:
	var first := _make_metric_policy(
		"preview production", Metric.Id.PRODUCTION, PolicyEffect.Formula.METRIC_VALUE,
		Metric.Id.TAX, Metric.Id.CONSUMPTION, 1.0
	)
	var second := _make_metric_policy(
		"preview investment", Metric.Id.INVESTMENT, PolicyEffect.Formula.METRIC_VALUE,
		Metric.Id.PRODUCTION, Metric.Id.CONSUMPTION, 2.0
	)
	var pure_target := MetricValues.new()
	pure_target.tax = 10
	pure_target.production = 2
	var first_state := PolicyState.new(first, 1)
	var second_state := PolicyState.new(second, 1)
	var policies: Array[PolicyState] = [second_state, first_state]
	var system := PolicySystem.new()
	var same_month := system.calculate_planned_result(pure_target, policies)
	t.check_equal(same_month.production, 12, "same-delay preview policies all apply")
	t.check_equal(same_month.investment, 4, "same-delay preview policies use one batch snapshot")
	second_state.delay_months = 2
	var later_month := system.calculate_planned_result(pure_target, policies)
	t.check_equal(later_month.production, 12, "changing delay preserves the earlier policy result")
	t.check_equal(later_month.investment, 24, "a later-delay preview policy reads the earlier batch result")


func _make_policy_session(
	t: BackendTestContext, policies: Array[PolicyDefinition], label: String
) -> RunSession:
	var race := t.make_race(label)
	var article := t.make_article(race)
	article.policies = policies
	return t.make_session(
		[race], [t.make_group("%s source" % label)], t.make_seats(1, label), [article]
	)


func _draft_with_lag(
	group: InterestGroupDefinition,
	policy: PolicyDefinition,
	lag_months: int,
	delay_months: int,
	title: String
) -> DraftBillState:
	var proposal := ProposalInstance.new()
	proposal.source_group = group
	proposal.lag_months = lag_months
	var draft := DraftBillState.new()
	draft.title = title
	draft.proposals.append(proposal)
	draft.policies.append(PolicyState.new(policy, delay_months))
	return draft


func _make_metric_policy(
	display_name: String,
	target: Metric.Id,
	formula: PolicyEffect.Formula,
	source_a: Metric.Id,
	source_b: Metric.Id,
	multiplier: float
) -> PolicyDefinition:
	var effect := PolicyEffect.new()
	effect.target_metric = target
	effect.formula = formula
	effect.source_a = source_a
	effect.source_b = source_b
	effect.multiplier = multiplier
	var result := PolicyDefinition.new()
	result.display_name = display_name
	result.effects.append(effect)
	return result
