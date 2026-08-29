extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_time_system_constitution_month(t)
	_test_constitution_uses_parliament_world(t)
	_test_year_boundary_enters_constitution(t)
	_test_constitution_month_returns_to_office(t)
	_test_normal_month_creates_newspaper_report(t)
	_test_month_report_serializes_events(t)
	_test_constitution_expectation_growth_uses_month_zero_economy(t)
	_test_opening_draw_and_term_lifecycle(t)
	_test_zhushui_fixed_executive_seat(t)


func _test_time_system_constitution_month(t: BackendTestContext) -> void:
	var state := RunState.new()
	state.year = 1
	state.month = 12
	var time_system := TimeSystem.new()
	time_system.advance_month(state)
	t.check_equal(state.year, 2, "December advances to the next year")
	t.check_equal(state.month, 0, "December advances into constitution month zero")
	time_system.advance_month(state)
	t.check_equal(state.year, 2, "constitution month does not advance the year again")
	t.check_equal(state.month, 1, "constitution month advances into January")


func _test_constitution_uses_parliament_world(t: BackendTestContext) -> void:
	var race := t.make_race("constitution world race")
	var group := t.make_group("constitution world group")
	var session := t.make_session([race], [group], t.make_seats(1, "constitution world"))
	var bridge := UiBridge.new()
	bridge.setup(session)
	t.check_equal(bridge.ui_mode, "constitution", "a new month-zero term opens constitution mode")
	t.check_equal(bridge.world_scene, "parliament", "a new month-zero term uses parliament world")
	t.check(bridge.set_ui_mode("constitution", false), "constitution mode is accepted")
	t.check_equal(bridge.ui_mode, "constitution", "constitution mode remains authoritative")
	t.check_equal(bridge.world_scene, "parliament", "constitution mode uses parliament world")
	bridge.free()
	session.free()


func _test_year_boundary_enters_constitution(t: BackendTestContext) -> void:
	var race := t.make_race("year boundary race")
	var group := t.make_group("year boundary group")
	var session := t.make_session([race], [group], t.make_seats(1, "year boundary"))
	session.state.year = 1
	session.state.month = 12
	session.state.collapse_level = 2
	var bridge := UiBridge.new()
	bridge.setup(session)
	var messages := bridge.receive_ipc_message(
		_message("month.advance", {"state_version": 0})
	)
	var full: Dictionary = messages[messages.size() - 1]
	t.check_equal(full["type"], "state.full", "month advance returns a full state")
	t.check_equal(full["payload"]["year"], 2, "year boundary advances the year")
	t.check_equal(full["payload"]["month"], 0, "year boundary enters month zero")
	t.check_equal(full["payload"]["collapse_level"], 1, "year boundary applies the configured annual recovery")
	t.check_equal(full["payload"]["ui_mode"], "constitution", "month zero enters constitution view")
	t.check_equal(full["payload"]["world_scene"], "parliament", "month zero keeps parliament world")
	bridge.free()
	session.free()


func _test_constitution_month_returns_to_office(t: BackendTestContext) -> void:
	var race := t.make_race("constitution exit race")
	var group := t.make_group("constitution exit group")
	var session := t.make_session([race], [group], t.make_seats(1, "constitution exit"))
	session.state.year = 2
	session.state.month = 0
	session.state.month_report_year = 1
	session.state.month_report_month = 12
	session.state.month_report_previous_metrics = session.state.metrics.copy()
	session.state.month_report_current_metrics = session.state.metrics.copy()
	var before_metrics := session.state.metrics.copy()
	var bridge := UiBridge.new()
	bridge.setup(session)
	bridge.set_ui_mode("constitution", false)
	var messages := bridge.receive_ipc_message(
		_message("month.advance", {"state_version": 0})
	)
	var full: Dictionary = messages[messages.size() - 1]
	t.check_equal(full["payload"]["month"], 1, "month zero advances directly into January")
	t.check_equal(full["payload"]["ui_mode"], "office", "January returns to office view")
	t.check_equal(full["payload"]["world_scene"], "office", "January returns to office world")
	t.check_equal(
		session.state.metrics.tax,
		before_metrics.tax,
		"month zero skips normal monthly metric settlement"
	)
	t.check_equal(
		full["payload"]["month_report"]["month"],
		12,
		"month zero preserves the previous normal month report"
	)
	bridge.free()
	session.free()


func _test_normal_month_creates_newspaper_report(t: BackendTestContext) -> void:
	var race := t.make_race("newspaper report race")
	var group := t.make_group("newspaper report group")
	var session := t.make_session([race], [group], t.make_seats(1, "newspaper report"))
	session.state.month = 1
	session.state.metrics.tax = 37
	var bridge := UiBridge.new()
	bridge.setup(session)
	var messages := bridge.receive_ipc_message(
		_message("month.advance", {"state_version": 0})
	)
	var full: Dictionary = messages[messages.size() - 1]
	var report: Dictionary = full["payload"]["month_report"]
	t.check_equal(report["year"], 1, "newspaper report records the settled year")
	t.check_equal(report["month"], 1, "newspaper report records the settled month")
	t.check_equal(
		report["previous_metrics"]["tax"],
		37,
		"newspaper report preserves pre-settlement metrics"
	)
	t.check_equal(
		report["current_metrics"]["tax"],
		full["payload"]["metrics"]["tax"],
		"newspaper report preserves post-settlement metrics"
	)
	bridge.free()
	session.free()


func _test_month_report_serializes_events(t: BackendTestContext) -> void:
	var state := RunState.new()
	state.month_report_year = 3
	state.month_report_month = 7
	state.month_report_previous_metrics = state.metrics.copy()
	state.month_report_current_metrics = state.metrics.copy()
	state.month_report_events.append(
		{
			"race_display_name": "驻岁",
			"metric": int(Metric.Id.TAX),
			"value": 42,
			"countdown": 3,
			"strength": 60,
			"phase": int(EventState.Phase.PAUSED),
		}
	)
	var report: Dictionary = UiSerializer.new().month_report(state)
	t.check_equal(report["events"].size(), 1, "newspaper report serializes event snapshots")
	t.check_equal(
		report["events"][0]["race_display_name"],
		"驻岁",
		"newspaper event keeps its race display name"
	)
	t.check_equal(report["events"][0]["value"], 42, "newspaper event keeps its requirement")


func _test_constitution_expectation_growth_uses_month_zero_economy(t: BackendTestContext) -> void:
	var race := t.make_race("constitution growth race")
	race.increase_production = true
	var group := t.make_group("constitution growth group")
	var article := t.make_article(race, true, 0.10)
	var session := t.make_session(
		[race], [group], t.make_seats(1, "constitution growth"), [article]
	)
	var race_state := session.state.get_race(race)
	t.check_approx(race_state.expectation_growth_rate, 0.10, "active article supplies race-local growth")
	t.check_equal(race_state.get_expectation(Metric.Id.PRODUCTION), 110, "opening target uses the month-zero economy")
	session.state.metrics.production = 200
	session.annual_settlement_system.settle_year(session.context)
	t.check_equal(
		race_state.get_expectation(Metric.Id.PRODUCTION),
		220,
		"annual settlement rebuilds expectation from the new month-zero economy"
	)
	session.free()


func _test_opening_draw_and_term_lifecycle(t: BackendTestContext) -> void:
	var race := t.make_race("term reset race")
	var group := t.make_group("term reset group")
	group.decrease_tax = true
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 2
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.event_early_reveal_probability_per_seat = 0.0
	var session := t.make_session(
		[race], [group], t.make_seats(2, "term reset"), [], balance
	)
	t.check_equal(session.state.term, 1, "a new run starts its first term")
	t.check_equal(session.state.year, 1, "a new term starts in year one")
	t.check_equal(session.state.month, 0, "a new term starts in month zero")
	t.check_equal(session.state.proposal_hand.size(), 0, "month zero has no opening proposals yet")
	t.check(session.advance_month(), "the player can confirm month zero")
	t.check_equal(session.state.month, 1, "confirming month zero enters January")
	t.check_equal(session.state.governing_months, 0, "month zero is not a governing month")
	t.check_equal(session.state.proposal_hand.size(), 2, "January receives the opening proposals")

	session.state.collapse_level = balance.max_collapse - balance.collapse_step
	var ended_state := session.state
	session.collapse_system.increase(session.context)
	t.check_equal(session.state.run_phase, RunState.RunPhase.TERM_ENDED, "collapse maximum ends the term")
	t.check_equal(
		session.state.term_outcome,
		RunState.TermOutcome.NOTHING_HAPPENS,
		"a term with no saved submission receives Nothing Happens"
	)
	var ended_month := session.state.month
	t.check(not session.advance_month(), "advance_month is blocked after the term ends")
	t.check(session.state == ended_state, "blocked advance preserves the complete ended state")
	t.check_equal(session.state.month, ended_month, "blocked advance does not move the month")
	t.check_equal(session.state.term, 1, "blocked advance does not create the next term")

	t.check(session.start_next_term(), "the next term starts only through the explicit API")
	t.check(session.state != ended_state, "the explicit API creates a fresh RunState")
	t.check_equal(session.state.term, 2, "the explicit next term increments the term number")
	t.check_equal(session.state.year, 1, "the next term resets to year one")
	t.check_equal(session.state.month, 0, "the next term resets to month zero")
	t.check_equal(session.state.collapse_level, 0, "the next term resets collapse")
	t.check_equal(session.state.governing_months, 0, "the next term resets governing duration")
	t.check_equal(session.state.proposal_hand.size(), 0, "the next term waits until January to draw")
	t.check_equal(session.state.events.size(), 0, "the next term starts without stale events")

	var submitted := t.make_session(
		[race], [group], t.make_seats(2, "submitted outcome"), [], balance
	)
	submitted.state.saved_bills.append(SavedBillState.new())
	submitted.state.collapse_level = balance.max_collapse - balance.collapse_step
	submitted.collapse_system.increase(submitted.context)
	t.check_equal(
		submitted.state.term_outcome,
		RunState.TermOutcome.COLLAPSE,
		"a term with a saved submission receives the collapse outcome"
	)
	submitted.free()
	session.free()


func _test_zhushui_fixed_executive_seat(t: BackendTestContext) -> void:
	var zhushui := ZhushuiRaceDefinition.new()
	zhushui.display_name = "驻岁"
	var other := t.make_race("other race")
	var group := t.make_group("fixed seat group")
	group.decrease_tax = true
	var seats: Array[SeatDefinition] = [t.make_seat("久视", zhushui)]
	for index in range(5):
		seats.append(t.make_seat("variable_%s" % index))
	var session := t.make_session([zhushui, other], [group], seats)
	t.check_equal(
		session.parliament_system.get_race_seat_count(session.state, zhushui),
		1,
		"Zhushui always owns exactly one executive seat"
	)
	var fixed_seat := session.parliament_system.get_race_seats(session.state, zhushui)[0]
	t.check_equal(fixed_seat.actual_group, null, "Zhushui executive seat has no interest-group influence")
	t.check(
		not session.parliament_system.can_reassign_seat(session.context, fixed_seat, other),
		"Zhushui executive seat cannot be reassigned"
	)
	session.free()


func _message(message_type: String, payload: Dictionary) -> String:
	return JSON.stringify({"type": message_type, "request_id": "test", "payload": payload})
