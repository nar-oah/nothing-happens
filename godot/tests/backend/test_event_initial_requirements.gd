extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_metric_event_starts_below_pause_threshold(t)
	_test_interest_group_event_starts_below_pause_threshold(t)
	_test_negative_metric_event_keeps_zero_floor_path(t)


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


func _test_metric_event_starts_below_pause_threshold(t: BackendTestContext) -> void:
	var race := t.make_race("initial metric requirement")
	race.increase_production = true
	var balance := _event_balance()
	var session := t.make_session(
		[race],
		[t.make_group("metric group")],
		t.make_seats(1, "initial metric requirement"),
		[t.make_article(race, true, 0.10)],
		balance
	)
	session.state.events.clear()
	var race_state := session.state.get_race(race)
	race_state.expectation_targets[Metric.Id.PRODUCTION] = 110
	session.state.metrics.production = 100
	var event := session.event_system.spawn_event(session.context, race, Metric.Id.PRODUCTION)
	t.check(event != null, "a positive expectation gap creates a metric event")
	var requirement := session.event_system.get_current_requirement(event)
	t.check_equal(requirement, 126, "80% pause threshold raises 100 current value to a 126 initial requirement")
	t.check(float(session.state.metrics.production) / float(requirement) < balance.event_pause_satisfaction_threshold, "generated metric event starts strictly below the pause threshold")
	t.check_equal(event.full_target, 126, "full target is raised with the initial requirement instead of decreasing as the event worsens")
	event.known = true
	session.event_system.settle_month(session.context)
	t.check_equal(event.phase, EventState.Phase.WORSENING, "an immediately known generated event worsens instead of pausing")
	session.free()


func _test_interest_group_event_starts_below_pause_threshold(t: BackendTestContext) -> void:
	var group := t.make_group("initial proposal group")
	var race := t.make_race("initial proposal requirement")
	race.fixed_interest_group = group
	var balance := _event_balance()
	balance.initial_interest_group_proposal_requirement = 5
	var session := t.make_session(
		[race],
		[group],
		t.make_seats(1, "initial proposal requirement"),
		[t.make_article(race, true, 0.10)],
		balance
	)
	session.state.events.clear()
	session.state.annual_proposal_slot_counts[group] = 2
	var event := session.event_system.spawn_interest_group_event(session.context, race)
	t.check(event != null, "an insufficient proposal count creates a fixed-group event")
	var requirement := session.event_system.get_current_requirement(event)
	t.check_equal(requirement, 3, "80% pause threshold raises proposal count 2 to an initial requirement of 3")
	t.check(float(2) / float(requirement) < balance.event_pause_satisfaction_threshold, "generated fixed-group event starts strictly below the pause threshold")
	t.check_equal(event.full_target, 5, "a larger configured proposal target remains authoritative")
	session.free()


func _test_negative_metric_event_keeps_zero_floor_path(t: BackendTestContext) -> void:
	var race := t.make_race("negative metric requirement")
	race.increase_tax = true
	var balance := _event_balance()
	var session := t.make_session(
		[race],
		[t.make_group("negative group")],
		t.make_seats(1, "negative metric requirement"),
		[t.make_article(race, true, -1.0)],
		balance
	)
	session.state.events.clear()
	var race_state := session.state.get_race(race)
	race_state.expectation_targets[Metric.Id.TAX] = 0
	session.state.metrics.tax = -10
	var event := session.event_system.spawn_event(session.context, race, Metric.Id.TAX)
	t.check(event != null, "negative metric below a zero expectation still creates an event")
	t.check_equal(event.baseline_value, -10, "negative metric events keep their original baseline for the zero-floor special case")
	t.check_equal(event.full_target, 0, "negative metric events keep the zero target")
	session.free()
