extends RefCounted


func run(t) -> void:
	_test_configurable_collapse_routes(t)
	_test_pressure_decay_and_negative_metric(t)
	_test_bill_digestion_and_market_movement(t)
	_test_policy_trigger_chain(t)


func _make_collapse_session(t, balance: GameBalanceDefinition) -> RunSession:
	return t.make_session(
		[t.make_race("collapse")],
		[t.make_group("group")],
		t.make_seats(1, "collapse"),
		[],
		balance
	)


func _test_configurable_collapse_routes(t) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.max_collapse = 10.0
	balance.silent_recovery_per_month = 5.0
	balance.pressure_to_collapse = 0.0
	balance.negative_metric_monthly_pressure = 0.0
	var silent := _make_collapse_session(t, balance)
	silent.state.collapse_level = 9.0
	silent.state.pending_collapse_delta = 1.0
	silent.collapse_system.settle_month(silent.context)
	t.check(silent.state.silent_observation, "unintervened max collapse enters observation")
	silent.collapse_system.settle_month(silent.context)
	t.check_approx(silent.state.collapse_level, 5.0, "silent recovery uses balance amount")
	silent.collapse_system.settle_month(silent.context)
	t.check_equal(silent.state.ending_id, &"nothing_happens", "silent recovery reaches ending")
	silent.free()

	var failed := _make_collapse_session(t, balance)
	failed.collapse_system.record_intervention(failed.context, &"test_intervention", 0.0)
	failed.state.pending_collapse_delta = 10.0
	failed.collapse_system.settle_month(failed.context)
	t.check(failed.state.run_failed, "intervened max collapse fails the run")
	failed.free()


func _test_pressure_decay_and_negative_metric(t) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.max_collapse = 100.0
	balance.pressure_decay_per_month = 0.5
	balance.pressure_to_collapse = 1.0
	balance.negative_metric_monthly_pressure = 3.0
	var session := _make_collapse_session(t, balance)
	session.collapse_system.record_intervention(session.context, &"configured", 4.0)
	session.collapse_system.settle_month(session.context)
	t.check_approx(session.state.regulation_pressure, 4.0, "fresh intervention contributes full pressure")
	t.check_approx(session.state.collapse_level, 4.0, "pressure conversion reads balance")
	session.state.month = 2
	session.collapse_system.settle_month(session.context)
	t.check_approx(session.state.regulation_pressure, 2.0, "pressure decays by configured ratio")
	t.check_approx(session.state.collapse_level, 6.0, "decayed pressure still converts")
	balance.pressure_to_collapse = 0.0
	session.state.metrics.tax = -1
	session.collapse_system.settle_month(session.context)
	t.check_approx(session.state.collapse_level, 9.0, "negative metric adds configured pressure")
	session.free()


func _test_bill_digestion_and_market_movement(t) -> void:
	var race := t.make_race("market")
	var group := t.make_group("source")
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.digestion_progress_min = 0.5
	balance.digestion_progress_max = 0.5
	balance.market_response_ratio = 1.0
	balance.market_noise_ratio = 0.0
	var session := t.make_session(
		[race], [group], t.make_seats(1, "market"), [], balance
	)
	var proposal := t.make_proposal(group)
	proposal.base_effect.tax = 20
	proposal.digestion_speed = 1.0
	var draft := DraftBillState.new()
	draft.proposals.append(proposal)
	session.enact_bill(draft)
	session.market_system.settle_month(session.context)
	t.check_approx(
		session.state.active_bill.proposals[0].digestion_progress,
		0.5,
		"bill digestion progress reads configured range"
	)
	t.check_equal(session.state.metrics.tax, 110, "market reaches half-digested anchor")
	session.market_system.settle_month(session.context)
	t.check_approx(session.state.active_bill.proposals[0].digestion_progress, 1.0, "bill fully digests")
	t.check_equal(session.state.metrics.tax, 120, "market reaches fully-digested anchor")
	session.free()


func _test_policy_trigger_chain(t) -> void:
	var first := PolicyDefinition.new()
	first.display_name = "first"
	first.collapse_impact = 1.0
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
	second.collapse_impact = 2.0
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
	t.check_approx(state.pending_collapse_delta, 3.0, "policy collapse impacts accumulate")
