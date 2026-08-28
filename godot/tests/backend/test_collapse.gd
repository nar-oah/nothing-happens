extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_configurable_collapse_routes(t)
	_test_integer_monotonic_collapse(t)
	_test_pressure_decay_and_negative_metric(t)
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


func _test_configurable_collapse_routes(t: BackendTestContext) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.max_collapse = 10
	balance.pressure_to_collapse = 0.0
	balance.negative_metric_monthly_pressure = 0
	var ordinary := _make_collapse_session(t, balance)
	ordinary.state.collapse_level = 9
	ordinary.state.pending_collapse_delta = 1
	ordinary.collapse_system.settle_month(ordinary.context)
	t.check_equal(ordinary.state.collapse_level, 10, "collapse reaches the configured integer maximum")
	t.check(ordinary.state.run_failed, "maximum collapse always ends the current term")
	t.check_equal(ordinary.state.ending_id, &"", "maximum collapse no longer enters a recovery ending route")
	ordinary.free()

	var intervened := _make_collapse_session(t, balance)
	intervened.collapse_system.record_intervention(intervened.context, &"test_intervention", 0.0)
	intervened.state.pending_collapse_delta = 10
	intervened.collapse_system.settle_month(intervened.context)
	t.check(intervened.state.run_failed, "intervened max collapse also fails the run")
	intervened.free()


func _test_integer_monotonic_collapse(t: BackendTestContext) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.max_collapse = 100
	balance.pressure_to_collapse = 0.12
	balance.pressure_decay_per_month = 0.75
	balance.negative_metric_monthly_pressure = 0
	var session := _make_collapse_session(t, balance)
	t.check_equal(typeof(session.state.collapse_level), TYPE_INT, "collapse level is stored as int")
	t.check_equal(
		typeof(session.state.pending_collapse_delta),
		TYPE_INT,
		"pending collapse delta is stored as int"
	)
	session.collapse_system.record_intervention(session.context, &"fractional_pressure", 5.0)
	session.collapse_system.settle_month(session.context)
	t.check_equal(session.state.collapse_level, 1, "fractional pressure conversion is rounded once to int")
	t.check_equal(typeof(session.state.collapse_level), TYPE_INT, "pressure cannot produce float collapse")
	session.state.month = 2
	session.collapse_system.settle_month(session.context)
	t.check_equal(session.state.collapse_level, 1, "decaying pressure never reduces collapse")
	session.state.regulation_pressure = 0.0
	session.state.intervention_records.clear()
	session.state.pending_collapse_delta = -3
	session.collapse_system.settle_month(session.context)
	t.check_equal(session.state.collapse_level, 1, "negative deltas cannot reduce collapse")
	session.free()


func _test_pressure_decay_and_negative_metric(t: BackendTestContext) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.max_collapse = 100
	balance.pressure_decay_per_month = 0.5
	balance.pressure_to_collapse = 1.0
	balance.negative_metric_monthly_pressure = 3
	var session := _make_collapse_session(t, balance)
	session.collapse_system.record_intervention(session.context, &"configured", 4.0)
	session.collapse_system.settle_month(session.context)
	t.check_approx(session.state.regulation_pressure, 4.0, "fresh intervention contributes full pressure")
	t.check_equal(session.state.collapse_level, 4, "pressure conversion produces integer collapse")
	session.state.month = 2
	session.collapse_system.settle_month(session.context)
	t.check_approx(session.state.regulation_pressure, 2.0, "pressure decays by configured ratio")
	t.check_equal(session.state.collapse_level, 6, "decayed pressure still converts to integer collapse")
	balance.pressure_to_collapse = 0.0
	session.state.metrics.tax = -1
	session.collapse_system.settle_month(session.context)
	t.check_equal(session.state.collapse_level, 9, "negative metric adds configured integer collapse")
	session.free()


func _test_bill_digestion_and_market_movement(t: BackendTestContext) -> void:
	var race := t.make_race("market")
	var group := t.make_group("source")
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.market_response_ratio = 1.0
	balance.market_noise_ratio = 0.0
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
	t.check_equal(session.state.metrics.tax, 105, "market reaches the one-quarter anchor")
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
	t.check_equal(session.state.metrics.tax, 120, "market reaches fully-digested anchor")
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
	t.check_equal(state.pending_collapse_delta, 0, "policies do not add collapse")
