extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_generation_count_and_pair_identity(t)
	_test_zero_seat_race_is_ineligible(t)
	_test_hidden_growth_public_window_and_resolution(t)
	_test_pause_relief_and_early_reveal(t)
	_test_deadline_failure(t)


func _event_balance() -> GameBalanceDefinition:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.event_early_reveal_probability_per_seat = 0.0
	balance.event_lifetime_months = 12
	balance.event_public_remaining_months = 3
	balance.event_pause_satisfaction_threshold = 0.8
	balance.event_relief_satisfaction_threshold = 1.0
	balance.event_relief_progress_per_month = 0.5
	return balance


func _test_generation_count_and_pair_identity(t: BackendTestContext) -> void:
	var race := t.make_race("many concerns")
	race.increase_tax = true
	race.increase_price = true
	race.increase_wage = true
	race.increase_employment = true
	race.increase_trade = true
	var group := t.make_group("group")
	var balance := _event_balance()
	balance.event_spawn_count_min = 3
	balance.event_spawn_count_max = 3
	var session := t.make_session(
		[race], [group], t.make_seats(1, "events"), [], balance
	)
	for metric in Metric.all_ids():
		session.state.metrics.set_value(metric, 0)

	var first_batch := session.event_system.try_generate_month(session.context)
	t.check_equal(first_batch.size(), 3, "configured monthly target creates three events")
	var seen: Dictionary[int, bool] = {}
	for event in first_batch:
		t.check(event.race == race, "event stores the exact race Resource")
		t.check(not seen.has(event.metric), "one race can create distinct metric events")
		seen[event.metric] = true
		t.check(
			session.event_system.has_active_event(session.state, race, event.metric),
			"active event lookup uses race Resource plus metric"
		)
		t.check(
			session.event_system.spawn_event(session.context, race, event.metric) == null,
			"an active race and metric pair cannot duplicate"
		)
	var second_batch := session.event_system.try_generate_month(session.context)
	t.check_equal(second_batch.size(), 2, "generation stops after remaining eligible metrics")
	t.check_equal(
		session.event_system.try_generate_month(session.context).size(), 0,
		"generation stops when all eligible pairs are exhausted"
	)
	session.free()


func _test_zero_seat_race_is_ineligible(t: BackendTestContext) -> void:
	var seated := t.make_race("seated")
	seated.increase_tax = true
	var absent := t.make_race("zero seat")
	absent.increase_wage = true
	var seated_article := t.make_article(seated)
	var absent_article := t.make_article(absent)
	absent_article.race_max_seat_rate = 0.0
	var balance := _event_balance()
	balance.event_spawn_count_min = 2
	balance.event_spawn_count_max = 2
	var session := t.make_session(
		[seated, absent],
		[t.make_group("group")],
		t.make_seats(2, "eligibility"),
		[seated_article, absent_article],
		balance
	)
	session.state.metrics.tax = 0
	session.state.metrics.wage = 0
	t.check_equal(t.count_race_seats(session.state, absent), 0, "fixture has zero-seat race")
	var generated := session.event_system.try_generate_month(session.context)
	t.check_equal(generated.size(), 1, "only the seated race has a legal pair")
	t.check(generated[0].race == seated, "zero-seat race is never selected")
	t.check(
		session.event_system.spawn_event(session.context, absent, Metric.Id.WAGE) == null,
		"direct spawn also enforces the seat requirement"
	)
	session.free()


func _test_hidden_growth_public_window_and_resolution(t: BackendTestContext) -> void:
	var race := t.make_race("deadline")
	race.increase_wage = true
	var balance := _event_balance()
	var session := t.make_session(
		[race], [t.make_group("group")], t.make_seats(1, "lifecycle"), [], balance
	)
	session.state.metrics.wage = 0
	var event := session.event_system.spawn_event(session.context, race, Metric.Id.WAGE)
	t.check(event != null, "expectation gap creates an event")
	session.state.metrics.wage = 100
	session.event_system.settle_month(session.context)
	t.check_equal(event.months_alive, 1, "hidden event still advances its deadline")
	t.check(event.growth_progress > 0.0, "hidden event still grows")
	t.check(not event.known, "satisfying a hidden event does not reveal it")
	t.check_equal(event.phase, EventState.Phase.WORSENING, "hidden event cannot pause or relieve")

	for index in range(8):
		session.event_system.settle_month(session.context)
	t.check_equal(event.months_alive, 9, "remaining-three window begins after nine months")
	t.check_approx(event.growth_progress, 1.0, "remaining-three window forces full growth")
	t.check(event.known and event.published, "remaining-three window forces publication")
	t.check(event.public_window_entered, "public-window entry is recorded exactly once")
	session.event_system.settle_month(session.context)
	t.check_equal(event.phase, EventState.Phase.RELIEVING, "known event begins reducing demand")
	t.check_approx(event.growth_progress, 0.5, "relief speed reduces demand progress")
	session.event_system.settle_month(session.context)
	t.check_equal(event.phase, EventState.Phase.RESOLVED, "known event resolves at zero demand")
	t.check_equal(
		session.state.get_race(race).resolved_events_this_year, 1,
		"resolution increments the annual race result"
	)
	session.free()


func _test_pause_relief_and_early_reveal(t: BackendTestContext) -> void:
	var race := t.make_race("information")
	race.increase_trade = true
	var balance := _event_balance()
	var session := t.make_session(
		[race], [t.make_group("group")], t.make_seats(2, "intel"), [], balance
	)
	session.state.metrics.trade = 0
	var event := session.event_system.spawn_event(session.context, race, Metric.Id.TRADE)
	session.event_system.update_information(session.context)
	t.check(not event.known, "zero reveal probability keeps event hidden")
	balance.event_early_reveal_probability_per_seat = 0.5
	session.event_system.update_information(session.context)
	t.check(
		event.known and not event.published,
		"early reveal becomes known without entering the newspaper"
	)

	event.growth_progress = 1.0
	balance.event_pause_satisfaction_threshold = 0.4
	balance.event_relief_satisfaction_threshold = 0.8
	balance.event_relief_progress_per_month = 1.0
	session.state.metrics.trade = 50
	session.event_system.settle_month(session.context)
	t.check_equal(event.phase, EventState.Phase.PAUSED, "middle satisfaction pauses a known event")
	t.check_approx(event.growth_progress, 1.0, "pause holds demand growth")
	session.state.metrics.trade = 100
	session.event_system.settle_month(session.context)
	t.check_equal(event.phase, EventState.Phase.RESOLVED, "relief threshold resolves by progress")
	session.free()


func _test_deadline_failure(t: BackendTestContext) -> void:
	var race := t.make_race("failure")
	race.increase_employment = true
	var balance := _event_balance()
	t.check_equal(balance.event_lifetime_months, 12, "default event deadline is twelve months")
	t.check_equal(balance.collapse_step, 1, "event failure uses the shared collapse step")
	var session := t.make_session(
		[race], [t.make_group("group")], t.make_seats(1, "failure"), [], balance
	)
	session.state.metrics.employment = 0
	var event := session.event_system.spawn_event(
		session.context, race, Metric.Id.EMPLOYMENT
	)
	for index in range(12):
		session.event_system.settle_month(session.context)
	t.check_equal(event.months_alive, 12, "event fails at its twelve-month deadline")
	t.check_equal(event.phase, EventState.Phase.FAILED, "unresolved event fails at deadline")
	t.check(event.known and event.published, "failed event is public")
	t.check_equal(session.state.collapse_level, 1, "failure adds exactly one collapse step")
	t.check_equal(typeof(session.state.collapse_level), TYPE_INT, "event collapse remains int")
	t.check_equal(
		session.state.get_race(race).resolved_events_this_year, 0,
		"failure does not count as resolution"
	)
	session.free()
