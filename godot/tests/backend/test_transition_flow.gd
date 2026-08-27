extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_time_system_constitution_month(t)
	_test_constitution_uses_parliament_world(t)
	_test_year_boundary_enters_constitution(t)
	_test_constitution_month_returns_to_office(t)


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
	var bridge := UiBridge.new()
	bridge.setup(session)
	var messages := bridge.receive_ipc_message(
		_message("month.advance", {"state_version": 0})
	)
	var full: Dictionary = messages[messages.size() - 1]
	t.check_equal(full["type"], "state.full", "month advance returns a full state")
	t.check_equal(full["payload"]["year"], 2, "year boundary advances the year")
	t.check_equal(full["payload"]["month"], 0, "year boundary enters month zero")
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
	bridge.free()
	session.free()


func _message(message_type: String, payload: Dictionary) -> String:
	return JSON.stringify({"type": message_type, "request_id": "test", "payload": payload})
