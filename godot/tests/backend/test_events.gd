extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_generation_count_and_pair_identity(t)
	_test_zero_seat_race_is_ineligible(t)
	_test_fixed_interest_group_events_use_proposal_counts(t)
	_test_hidden_growth_public_window_and_resolution(t)
	_test_forced_public_information_does_not_queue_visit(t)
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


func _test_fixed_interest_group_events_use_proposal_counts(t: BackendTestContext) -> void:
	var group := t.make_group("fixed group")
	var race := t.make_race("fixed group race")
	race.fixed_interest_group = group
	var article := t.make_article(race, true, 0.10)
	var balance := _event_balance()
	balance.initial_interest_group_proposal_requirement = 5
	balance.event_spawn_count_min = 1
	balance.event_spawn_count_max = 1
	var session := t.make_session([race], [group], t.make_seats(1, "fixed group event"), [article], balance)
	var race_state := session.state.get_race(race)
	t.check(race_state.expectation_targets.is_empty(), "fixed-group race needs no metric expectation targets")
	session.state.annual_proposal_slot_counts[group] = 2
	var generated := session.event_system.try_generate_month(session.context)
	t.check_equal(generated.size(), 1, "insufficient fixed-group proposal count creates an event")
	var event := generated[0]
	t.check_equal(event.requirement_kind, EventState.RequirementKind.INTEREST_GROUP_PROPOSALS, "event records proposal-count requirement kind")
	t.check(event.interest_group == group, "event keeps the fixed interest group Resource")
	t.check_equal(event.baseline_value, 2, "event baseline uses current annual authorized proposal count")
	t.check_equal(event.full_target, 5, "first-year proposal requirement uses configured initial target")
	t.check(session.event_system.spawn_event(session.context, race, Metric.Id.TAX) == null, "fixed-group race does not generate metric events")
	event.known = true
	var visit := OfficeVisitState.new()
	visit.kind = OfficeVisitState.Kind.EVENT_INTEL
	visit.race = race
	visit.event = event
	session.state.office_visits.append(visit)
	var dialogue: Dictionary = UiSerializer.new().pending_dialogue(session)
	t.check_equal(dialogue["requirement_kind"], EventState.RequirementKind.INTEREST_GROUP_PROPOSALS, "fixed-group event dialogue exposes its requirement kind")
	t.check_equal(dialogue["interest_group_name"], "fixed group", "fixed-group event dialogue exposes the group name")
	session.state.office_visits.clear()
	session.state.annual_proposal_slot_counts[group] = 5
	session.event_system.settle_month(session.context)
	t.check_equal(event.phase, EventState.Phase.RESOLVED, "meeting the group proposal target resolves the shared event lifecycle")
	t.check_equal(session.event_system.try_generate_month(session.context).size(), 0, "meeting the annual group proposal target prevents replacement events")
	session.state.year = 2
	t.check_equal(session.race_system.get_interest_group_proposal_expectation(race_state, session.context), 6, "proposal requirement inflates with the race expectation growth rate")
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
	t.check(not event.published, "hidden event is not published")
	for index in range(8):
		session.event_system.settle_month(session.context)
	t.check_equal(event.months_alive, 9, "public window begins with three months remaining")
	t.check(event.known, "public window forces disclosure")
	t.check(event.published, "public window publishes the event")
	t.check(session.state.office_visits.is_empty(), "forced disclosure does not queue an event-intel visit")
	session.event_system.settle_month(session.context)
	t.check_equal(event.phase, EventState.Phase.RESOLVED, "satisfied known event resolves")
	t.check_equal(session.state.get_race(race).resolved_events_this_year, 1, "resolution increments annual race result")
	session.free()


func _test_forced_public_information_does_not_queue_visit(t: BackendTestContext) -> void:
	var race := t.make_race("forced public information")
	race.increase_production = true
	var balance := _event_balance()
	var session := t.make_session(
		[race], [t.make_group("group")], t.make_seats(1, "forced public"), [], balance
	)
	session.state.metrics.production = 0
	var event := session.event_system.spawn_event(
		session.context, race, Metric.Id.PRODUCTION
	)
	event.months_alive = balance.event_lifetime_months - balance.event_public_remaining_months
	session.event_system.update_information(session.context)
	t.check(event.known, "information update forces disclosure in the public window")
	t.check(event.published, "forced-public information is published immediately")
	t.check(session.state.office_visits.is_empty(), "forced-public information update queues no event-intel visit")
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
	t.check(event.known, "EventIntelProbabilityEffect reveals event early")
	t.check(not event.published, "early information remains unpublished until acknowledged or the next settlement")
	t.check_equal(session.state.office_visits.size(), 1, "probability-based early information queues one office visit")
	var visit := session.state.office_visits[0]
	t.check_equal(visit.kind, OfficeVisitState.Kind.EVENT_INTEL, "early information queues an event-intel visit")
	t.check(visit.race == race, "event-intel visit keeps the event owner's race")
	t.check(visit.event == event, "event-intel visit keeps the authoritative event instance")
	session.event_system.update_information(session.context)
	t.check_equal(session.state.office_visits.size(), 1, "an already known event is not queued twice")
	var interest_visit := OfficeVisitState.new()
	interest_visit.kind = OfficeVisitState.Kind.INTEREST_GROUP
	interest_visit.race = race
	session.state.office_visits.append(interest_visit)
	session.event_system.publish_known_events(session.context)
	t.check(event.published, "monthly publication promotes known events")
	session.event_system.cleanup_published_event_visits(session.state)
	t.check_equal(session.state.office_visits.size(), 1, "publication cleanup removes only published event-intel visits")
	t.check(session.state.office_visits[0] == interest_visit, "publication cleanup preserves interest-group visits")
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
	t.check(event.known, "failed event is known")
	t.check(event.published, "failed event is published")
	t.check_equal(session.state.collapse_level, 1, "failure adds one collapse step")
	session.free()
