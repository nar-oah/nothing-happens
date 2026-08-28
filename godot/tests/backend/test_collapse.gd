extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_monthly_negative_metric_step(t)
	_test_monthly_collapse_never_decreases(t)
	_test_annual_recovery(t)
	_test_december_collapse_precedes_recovery(t)
	_test_bill_digestion_and_market_movement(t)
	_test_policy_trigger_chain(t)


func _make_collapse_session(
	t: BackendTestContext, balance: GameBalanceDefinition
) -> RunSession:
	return t.make_session(
		[t.make_race("collapse")],
		[t.make_group("group")],
		t.make_seats(1, "collapse"),
		[],
		balance
	)


func _test_monthly_negative_metric_step(t: BackendTestContext) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.max_collapse = 100
	balance.collapse_step = 3
	var no_negative := _make_collapse_session(t, balance)
	no_negative.collapse_system.settle_month(no_negative.context)
	t.check_equal(typeof(no_negative.state.collapse_level), TYPE_INT, "collapse level is stored as int")
	t.check_equal(no_negative.state.collapse_level, 0, "a month without negative metrics adds no collapse")
	no_negative.free()

	var one_negative := _make_collapse_session(t, balance)
	one_negative.state.metrics.tax = -1
	one_negative.collapse_system.settle_month(one_negative.context)
	t.check_equal(one_negative.state.collapse_level, 3, "one negative metric adds one collapse step")
	one_negative.free()

	var five_negative := _make_collapse_session(t, balance)
	for metric in Metric.all_ids():
		five_negative.state.metrics.set_value(metric, -1)
	five_negative.collapse_system.settle_month(five_negative.context)
	t.check_equal(five_negative.state.collapse_level, 3, "five negative metrics still add one collapse step")
	t.check_equal(typeof(five_negative.state.collapse_level), TYPE_INT, "collapse remains int after settlement")
	five_negative.free()


func _test_monthly_collapse_never_decreases(t: BackendTestContext) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	var session := _make_collapse_session(t, balance)
	session.state.collapse_level = 7
	for month in range(1, 13):
		session.state.month = month
		session.collapse_system.settle_month(session.context)
		t.check_equal(session.state.collapse_level, 7, "normal months never reduce collapse")
	session.free()


func _test_annual_recovery(t: BackendTestContext) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.annual_collapse_recovery = 2
	var session := _make_collapse_session(t, balance)
	session.state.month = 1
	session.state.collapse_level = 3
	session.collapse_system.recover_annual(session.context)
	t.check_equal(session.state.collapse_level, 3, "annual recovery cannot run in a normal month")
	session.state.month = 0
	session.collapse_system.recover_annual(session.context)
	t.check_equal(session.state.collapse_level, 1, "month zero applies annual collapse recovery")
	session.collapse_system.recover_annual(session.context)
	t.check_equal(session.state.collapse_level, 0, "annual recovery cannot reduce collapse below zero")
	session.free()


func _test_december_collapse_precedes_recovery(t: BackendTestContext) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.max_collapse = 3
	balance.collapse_step = 1
	balance.annual_collapse_recovery = 3
	var session := _make_collapse_session(t, balance)
	session.state.month = 12
	session.state.collapse_level = 2
	session.state.metrics.tax = -1
	t.check(session.advance_month(), "December settlement runs")
	t.check_equal(session.state.collapse_level, 3, "December reaches collapse maximum before recovery")
	t.check_equal(session.state.run_phase, RunState.RunPhase.TERM_ENDED, "December maximum ends the term")
	t.check_equal(session.state.year, 1, "failed December does not enter the next year")
	t.check_equal(session.state.month, 12, "failed December does not enter month zero")
	session.free()


func _test_bill_digestion_and_market_movement(t: BackendTestContext) -> void:
	var race := t.make_race("market")
	var group := t.make_group("source")
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.proposal_digestion_variance = 0.0
	var session := t.make_session(
		[race], [group], t.make_seats(1, "market"), [], balance
	)
	var proposal := t.make_proposal(group)
	proposal.base_effect.tax = 20
	proposal.lag_months = 4
	var draft := DraftBillState.new()
	draft.title = "four month bill"
	draft.proposals.append(proposal)
	session.enact_bill(draft)
	t.check_equal(session.state.active_bill.title, draft.title, "active bill retains its title")
	session.market_system.settle_month(session.context)
	t.check_approx(
		session.state.active_bill.proposals[0].get_digestion_progress(),
		0.25,
		"a four-month lag digests one quarter per month"
	)
	t.check_equal(session.state.metrics.tax, 105, "market directly reaches the one-quarter digested anchor")
	session.market_system.settle_month(session.context)
	session.market_system.settle_month(session.context)
	t.check(
		not session.state.active_bill.proposals[0].is_fully_digested(),
		"a four-month lag is incomplete after three months"
	)
	session.market_system.settle_month(session.context)
	t.check_equal(
		session.state.active_bill.proposals[0].digested_months,
		4,
		"the fourth month records complete digestion"
	)
	t.check_approx(
		session.state.active_bill.proposals[0].get_digestion_progress(),
		1.0,
		"a four-month lag completes on the fourth month"
	)
	t.check_equal(session.state.metrics.tax, 120, "market reaches fully-digested target without a second response layer")
	session.free()


func _test_policy_trigger_chain(t: BackendTestContext) -> void:
	var first := PolicyDefinition.new()
	first.display_name = "first"
	first.condition = MetricCondition.new()
	first.condition.left_metric = Metric.Id.TAX
	first.condition.operator = MetricCondition.Operator.GREATER_THAN
	first.condition.right_metric = Metric.Id.PRICE
	var first_effect := PolicyEffect.new()
	first_effect.target_metric = Metric.Id.WAGE
	first_effect.formula = PolicyEffect.Formula.METRIC_VALUE
	first_effect.source_a = Metric.Id.TAX
	first_effect.multiplier = 1.0
	first.effects = [first_effect]

	var second := PolicyDefinition.new()
	second.display_name = "second"
	second.condition = MetricCondition.new()
	second.condition.left_metric = Metric.Id.WAGE
	second.condition.operator = MetricCondition.Operator.GREATER_THAN_OR_EQUAL
	second.condition.right_metric = Metric.Id.TAX
	var second_effect := PolicyEffect.new()
	second_effect.target_metric = Metric.Id.TRADE
	second_effect.formula = PolicyEffect.Formula.METRIC_VALUE
	second_effect.source_a = Metric.Id.WAGE
	second_effect.multiplier = 2.0
	second.effects = [second_effect]

	var state := RunState.new()
	state.metrics.tax = 10
	state.metrics.price = 5
	state.metrics.wage = 0
	state.metrics.trade = 0
	state.active_bill = ActiveBillState.new()
	var system := PolicySystem.new()
	state.active_bill.policies = system.create_states([first, second])
	system.resolve_policy_chain(state)
	t.check_equal(state.metrics.wage, 10, "first policy applies from initial condition")
	t.check_equal(state.metrics.trade, 20, "second policy triggers from first policy result")
	t.check(state.active_bill.policies[0].triggered, "first policy is marked triggered")
	t.check(state.active_bill.policies[1].triggered, "second policy is marked triggered")
	t.check_equal(state.collapse_level, 0, "policies do not add collapse")
