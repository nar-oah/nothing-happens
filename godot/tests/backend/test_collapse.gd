extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_negative_metrics_do_not_directly_add_collapse(t)
	_test_annual_recovery(t)
	_test_event_failure_adds_shared_collapse_step(t)
	_test_maximum_without_submitted_bill_is_nothing_happens(t)
	_test_maximum_with_submitted_bill_is_collapse(t)
	_test_bill_digestion_and_market_movement(t)


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


func _test_negative_metrics_do_not_directly_add_collapse(t: BackendTestContext) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.max_collapse = 100
	balance.collapse_step = 3
	var session := _make_collapse_session(t, balance)
	for metric in Metric.all_ids():
		session.state.metrics.set_value(metric, -1)
	for month in range(1, 13):
		session.state.month = month
		t.check(session.advance_month(), "a negative-metric month still advances")
		if session.state.month == 0:
			# Month zero is not a normal gameplay month; resume at month one for this direct-risk test.
			session.state.month = 1
	t.check_equal(session.state.collapse_level, 0, "negative metrics never directly add collapse")
	t.check_equal(typeof(session.state.collapse_level), TYPE_INT, "collapse level remains an integer")
	session.free()


func _test_annual_recovery(t: BackendTestContext) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.annual_collapse_recovery = 2
	var session := _make_collapse_session(t, balance)
	session.state.collapse_level = 7
	session.collapse_system.recover_annual(session.context)
	t.check_equal(session.state.collapse_level, 5, "annual recovery subtracts its configured integer amount")
	session.state.collapse_level = 1
	session.collapse_system.recover_annual(session.context)
	t.check_equal(session.state.collapse_level, 0, "annual recovery floors collapse at zero")
	session.free()


func _test_event_failure_adds_shared_collapse_step(t: BackendTestContext) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.event_lifetime_months = 4
	balance.event_public_remaining_months = 1
	balance.collapse_step = 3
	balance.max_collapse = 100
	var race := t.make_race("event")
	var session := t.make_session(
		[race], [t.make_group("group")], t.make_seats(1, "event"), [], balance
	)
	var event := EventState.new(race, Metric.Id.TAX, 100, 110)
	event.months_alive = balance.event_lifetime_months - 1
	session.state.events.append(event)
	session.event_system.settle_month(session.context)
	t.check_equal(event.phase, EventState.Phase.FAILED, "an expired event fails")
	t.check_equal(session.state.collapse_level, 3, "event failure adds the shared collapse step")
	session.free()


func _test_maximum_without_submitted_bill_is_nothing_happens(t: BackendTestContext) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.max_collapse = 3
	balance.collapse_step = 1
	var session := _make_collapse_session(t, balance)
	session.state.collapse_level = 2
	t.check(session.state.saved_bills.is_empty(), "fresh term has no submitted/saved bills")
	session.collapse_system.increase(session.context)
	t.check_equal(session.state.collapse_level, 3, "collapse reaches maximum")
	t.check_equal(session.state.run_phase, RunState.RunPhase.TERM_ENDED, "maximum ends the term")
	t.check_equal(
		session.state.term_outcome,
		RunState.TermOutcome.NOTHING_HAPPENS,
		"maximum with an empty submitted-bill array triggers nothing happens"
	)
	session.free()


func _test_maximum_with_submitted_bill_is_collapse(t: BackendTestContext) -> void:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.max_collapse = 3
	balance.collapse_step = 1
	var session := _make_collapse_session(t, balance)
	session.state.saved_bills.append(SavedBillState.new())
	session.state.collapse_level = 2
	session.collapse_system.increase(session.context)
	t.check_equal(
		session.state.term_outcome,
		RunState.TermOutcome.COLLAPSE,
		"maximum with any submitted/saved bill triggers collapse"
	)
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
