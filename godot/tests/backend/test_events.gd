extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_generation_count_and_pair_identity(t)
	_test_zero_seat_race_is_ineligible(t)
	_test_hidden_growth_public_window_and_resolution(t)
	_test_pause_relief_and_effect_early_reveal(t)
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
	race.increase_consumption = true
	race.increase_production = true
	race.increase_employment = true
	race.increase_investment = true
	var balance := _event_balance()
	balance.event_spawn_count_min = 3
	balance.event_spawn_count_max = 3
	var session := t.make_session([race], [t.make_group("group")], t.make_seats(1, "events"), [], balance)
	for metric in Metric.all_ids():
		session.state.metrics.set_value(metric, 0)
	var first_batch := session.event_system.try_generate_month(session.context)
	t.check_equal(first_batch.size(), 3, "configured monthly target creates three events")
	var seen: Dictionary[int, bool] = {}
	for event in first_batch:
		t.check(event.race == race, "event stores canonical race Resource")
		t.check(not seen.has(event.metric), "one race can create distinct metric events")
		seen[event.metric] = true
		t.check(session.event_system.spawn_event(session.context, race, event.metric) == null, "active race and metric pair cannot duplicate")
	t.check_equal(session.event_system.try_generate_month(session.context).size(), 2, "generation uses remaining eligible metrics")
	t.check_equal(session.event_system.try_generate_month(session.context).size(), 0, "generation stops when pairs are exhausted")
	session.free()


func _test_zero_seat_race_is_ineligible(t: BackendTestContext) -> void:
	var seated := t.make_race("seated")
	seated.increase_tax = true
	var absent := t.make_race("zero seat")
	absent.increase_production = true
	var absent_article := t.make_article(absent)
	var seat_effect := RaceSeatEffect.new()
	seat_effect.races = [absent]
	seat_effect.participates_in_variable_seat_allocation = false
	absent_article.effects.append(seat_effect)
	var balance := _event_balance()
	balance.event_spawn_count_min = 2
	balance.event_spawn_count_max = 2
	var session := t.make_session([seated, absent], [t.make_group("group")], t.make_seats(2, "eligibility"), [t.make_article(seated), absent_article], balance)
	session.state.metrics.tax = 0
	session.state.metrics.production = 0
	t.check_equal(t.count_race_seats(session.state, absent), 0, "RaceSeatEffect creates a zero-seat race")
	var generated := session.event_system.try_generate_month(session.context)
	t.check_equal(generated.size(), 1, "only seated race has a legal event pair")
	t.check(generated[0].race == seated, "zero-seat race is never selected")
	t.check(session.event_system.spawn_event(session.context, absent, Metric.Id.PRODUCTION) == null, "direct spawn also enforces seat requirement")
	session.free()


func _test_hidden_growth_public_window_and_resolution(t: BackendTestContext) -> void:
	var race := t.make_race("deadline")
	race.increase_production = true
	var session := t.make_session([race], [t.make_group("group")], t.make_seats(1, "lifecycle"), [], _event_balance())
	session.state.metrics.production = 0
	var event := session.event_system.spawn_event(session.context, race, Metric.Id.PRODUCTION)
	t.check(event != null, "expectation gap creates an event")
	session.state.metrics.production = 100
	session.event_system.settle_month(session.context)
	t.check_equal(event.months_alive, 1, "hidden event advances deadline")
	t.check(event.growth_progress > 0.0, "hidden event grows")
	t.check(not event.known, "satisfying hidden event does not reveal it")
	for index in range(8):
		session.event_system.settle_month(session.context)
	t.check_equal(event.months_alive, 9, "public window begins with three months remaining")
	t.check(event.known and event.published, "public window forces publication")
	t.check(session.state.office_visits.is_empty(), "forced publication does not queue an event-intel visit")
	session.event_system.settle_month(session.context)
	t.check_equal(event.phase, EventState.Phase.RESOLVED, "satisfied known event resolves")
	t.check_equal(session.state.get_race(race).resolved_events_this_year, 1, "resolution increments annual race result")
	session.free()


func _test_pause_relief_and_effect_early_reveal(t: BackendTestContext) -> void:
	var race := t.make_race("information")
	race.increase_investment = true
	var article := t.make_article(race)
	var intel := EventIntelProbabilityEffect.new()
	intel.races = [race]
	intel.probability_modifier = 1.0
	article.effects.append(intel)
	var balance := _event_balance()
	var session := t.make_session([race], [t.make_group("group")], t.make_seats(2, "intel"), [article], balance)
	session.state.metrics.investment = 0
	var event := session.event_system.spawn_event(session.context, race, Metric.Id.INVESTMENT)
	session.event_system.update_information(session.context)
	t.check(event.known and not event.published, "EventIntelProbabilityEffect reveals event without publishing it")
	t.check_equal(session.state.office_visits.size(), 1, "probability-based early information queues one office visit")
	var visit := session.state.office_visits[0]
	t.check_equal(visit.kind, OfficeVisitState.Kind.EVENT_INTEL, "early information queues an event-intel visit")
	t.check(visit.race == race, "event-intel visit keeps the event owner's race")
	t.check(visit.event == event, "event-intel visit keeps the authoritative event instance")
	session.event_system.update_information(session.context)
	t.check_equal(session.state.office_visits.size(), 1, "an already known event is not queued twice")
	event.growth_progress = 1.0
	balance.event_pause_satisfaction_threshold = 0.4
	balance.event_relief_satisfaction_threshold = 0.8
	balance.event_relief_progress_per_month = 1.0
	session.state.metrics.investment = 50
	session.event_system.settle_month(session.context)
	t.check_equal(event.phase, EventState.Phase.PAUSED, "middle satisfaction pauses known event")
	session.state.metrics.investment = 100
	session.event_system.settle_month(session.context)
	t.check_equal(event.phase, EventState.Phase.RESOLVED, "relief threshold resolves by progress")
	session.free()


func _test_deadline_failure(t: BackendTestContext) -> void:
	var race := t.make_race("failure")
	race.increase_employment = true
	var balance := _event_balance()
	var session := t.make_session([race], [t.make_group("group")], t.make_seats(1, "failure"), [], balance)
	session.state.metrics.employment = 0
	var event := session.event_system.spawn_event(session.context, race, Metric.Id.EMPLOYMENT)
	for index in range(12):
		session.event_system.settle_month(session.context)
	t.check_equal(event.months_alive, 12, "event fails at deadline")
	t.check_equal(event.phase, EventState.Phase.FAILED, "unresolved event fails")
	t.check(event.known and event.published, "failed event is public")
	t.check_equal(session.state.collapse_level, 1, "failure adds one collapse step")
	session.free()
