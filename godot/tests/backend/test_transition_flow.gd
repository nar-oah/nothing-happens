extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_time_system_constitution_month(t)
	_test_constitution_uses_parliament_world(t)
	_test_year_boundary_enters_constitution(t)
	_test_constitution_month_returns_to_office(t)
	_test_active_variant_growth_uses_month_zero_economy(t)
	_test_term_lifecycle_resets_run_state(t)
	_test_zhushui_fixed_executive_seat(t)


func _test_time_system_constitution_month(t: BackendTestContext) -> void:
	var state := RunState.new()
	state.year = 1
	state.month = 12
	var time_system := TimeSystem.new()
	time_system.advance_month(state)
	t.check_equal(state.year, 2, "December advances to next year")
	t.check_equal(state.month, 0, "December enters constitution month zero")
	time_system.advance_month(state)
	t.check_equal(state.month, 1, "constitution month advances into January")


func _test_constitution_uses_parliament_world(t: BackendTestContext) -> void:
	var race := t.make_race("constitution world race")
	var session := t.make_session([race], [t.make_group("group")], t.make_seats(1, "constitution world"))
	var bridge := UiBridge.new()
	bridge.setup(session)
	t.check_equal(bridge.ui_mode, "constitution", "month zero opens constitution mode")
	t.check_equal(bridge.world_scene, "parliament", "constitution mode uses parliament world")
	bridge.free()
	session.free()


func _test_year_boundary_enters_constitution(t: BackendTestContext) -> void:
	var race := t.make_race("year boundary")
	var session := t.make_session([race], [t.make_group("group")], t.make_seats(1, "boundary"))
	session.state.year = 1
	session.state.month = 12
	session.state.collapse_level = 2
	var bridge := UiBridge.new()
	bridge.setup(session)
	var messages := bridge.receive_ipc_message(_message("month.advance", {"state_version": 0}))
	var full: Dictionary = messages[messages.size() - 1]
	t.check_equal(full["payload"]["year"], 2, "year boundary advances year")
	t.check_equal(full["payload"]["month"], 0, "year boundary enters month zero")
	t.check_equal(full["payload"]["ui_mode"], "constitution", "month zero enters constitution view")
	t.check_equal(full["payload"]["world_scene"], "parliament", "month zero keeps parliament world")
	bridge.free()
	session.free()


func _test_constitution_month_returns_to_office(t: BackendTestContext) -> void:
	var race := t.make_race("constitution exit")
	var session := t.make_session([race], [t.make_group("group")], t.make_seats(1, "exit"))
	session.state.year = 2
	session.state.month = 0
	var before := session.state.metrics.copy()
	var bridge := UiBridge.new()
	bridge.setup(session)
	var messages := bridge.receive_ipc_message(_message("month.advance", {"state_version": 0}))
	var full: Dictionary = messages[messages.size() - 1]
	t.check_equal(full["payload"]["month"], 1, "month zero advances to January")
	t.check_equal(full["payload"]["ui_mode"], "office", "January returns to office view")
	t.check_equal(full["payload"]["world_scene"], "office", "January returns to office world")
	t.check_equal(session.state.metrics.tax, before.tax, "month zero skips normal metric settlement")
	bridge.free()
	session.free()


func _test_active_variant_growth_uses_month_zero_economy(t: BackendTestContext) -> void:
	var canonical := t.make_race("growth canonical")
	var variant := t.make_race("growth variant")
	variant.increase_production = true
	variant.expectation_growth_rate = 0.10
	var article := t.make_article(canonical)
	var modify := ModifyRaceEffect.new()
	modify.target_races = [canonical]
	modify.source_races = [variant]
	article.effects.append(modify)
	var session := t.make_session([canonical], [t.make_group("group")], t.make_seats(1, "growth"), [article])
	var race_state := session.state.get_race(canonical)
	t.check(race_state.definition == canonical, "transition keeps canonical race identity")
	t.check(race_state.active_definition == variant, "transition exposes active race variant")
	t.check_equal(race_state.get_expectation(Metric.Id.PRODUCTION, 0), 110, "opening target uses active variant growth")
	session.state.metrics.production = 200
	session.annual_settlement_system.settle_year(session.context)
	t.check_equal(race_state.get_expectation(Metric.Id.PRODUCTION, 0), 220, "annual settlement rebuilds target from new month-zero economy")
	session.free()


func _test_term_lifecycle_resets_run_state(t: BackendTestContext) -> void:
	var race := t.make_race("term race")
	var group := t.make_group("term group")
	group.decrease_tax = true
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 1
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	var session := t.make_session([race], [group], t.make_seats(2, "term"), [], balance)
	t.check_equal(session.state.month, 0, "new term starts in month zero")
	t.check(session.advance_month(), "month zero can be confirmed")
	t.check_equal(session.state.month, 1, "confirmation enters January")
	t.check_equal(session.state.proposal_hand.size(), 1, "January receives opening proposal")
	session.state.collapse_level = balance.max_collapse - balance.collapse_step
	var ended_state := session.state
	session.collapse_system.increase(session.context)
	t.check_equal(session.state.run_phase, RunState.RunPhase.TERM_ENDED, "collapse maximum ends term")
	t.check(session.advance_month(), "ended term settles into next term")
	t.check(session.state != ended_state, "term settlement creates fresh RunState")
	t.check_equal(session.state.term, 2, "next term increments term number")
	t.check_equal(session.state.year, 1, "next term resets year")
	t.check_equal(session.state.month, 0, "next term resets to constitution month")
	t.check_equal(session.state.collapse_level, 0, "next term resets collapse")
	session.free()


func _test_zhushui_fixed_executive_seat(t: BackendTestContext) -> void:
	var zhushui := ZhushuiRaceDefinition.new()
	zhushui.display_name = "驻岁"
	var other := t.make_race("other race")
	var seats: Array[SeatDefinition] = [t.make_seat("久视", zhushui)]
	for index in range(5):
		seats.append(t.make_seat("variable_%s" % index))
	var session := t.make_session([zhushui, other], [t.make_group("group")], seats)
	t.check_equal(session.parliament_system.get_race_seat_count(session.state, zhushui), 1, "Zhushui keeps exactly one executive seat")
	var fixed_seat := session.parliament_system.get_race_seats(session.state, zhushui)[0]
	t.check_equal(fixed_seat.actual_group, null, "Zhushui executive seat has no interest-group influence")
	t.check(not session.parliament_system.can_reassign_seat(session.context, fixed_seat, other), "fixed executive seat cannot be reassigned")
	session.free()


func _message(message_type: String, payload: Dictionary) -> String:
	return JSON.stringify({"type": message_type, "request_id": "test", "payload": payload})
