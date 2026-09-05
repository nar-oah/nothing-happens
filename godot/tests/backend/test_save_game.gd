extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")
const Fixture = preload("res://tests/backend/save_test_fixture.gd")


func run(t: BackendTestContext) -> void:
	_test_round_trip_and_continuation(t)
	_test_manual_and_automatic_slots(t)
	_test_invalid_snapshot_does_not_replace_state(t)
	_test_bridge_load_refreshes_world(t)


func _test_round_trip_and_continuation(t: BackendTestContext) -> void:
	var directory := _directory("round_trip")
	var control := Fixture.make_session(directory)
	Fixture.populate(control)
	var expected := _snapshot(control)
	var saved := control.create_manual_save()
	t.check(saved.get("ok", false), "a complete real-resource snapshot saves as JSON")
	if not saved.get("ok", false):
		control.free()
		Fixture.clean(directory)
		return
	var restored := Fixture.make_session(directory)
	var old_context := restored.context
	var old_flow := restored.flow_controller
	var old_random := restored.random_system
	var result := restored.load_save(saved["slot_id"])
	t.check(result.get("ok", false), "a saved snapshot loads into a separate session")
	if not result.get("ok", false):
		control.free()
		restored.free()
		Fixture.clean(directory)
		return
	t.check_equal(restored.random_system.rng.state, control.random_system.rng.state, "RNG restores its exact 64-bit current state")
	t.check(_snapshot(restored) == expected, "all persisted state survives JSON round trip exactly")
	t.check(restored.context != old_context, "load rebuilds RunContext")
	t.check(restored.flow_controller != old_flow, "load rebuilds FlowController")
	t.check(restored.random_system != old_random, "load rebuilds runtime systems")
	t.check(restored.context.state == restored.state, "rebuilt context references loaded RunState")
	t.check(restored.context.meta_progression == restored.meta_progression, "rebuilt context references loaded meta progression")
	t.check(restored.flow_controller.context == restored.context, "rebuilt flow references loaded context")
	_check_references(t, restored, control)
	for index in range(13):
		t.check(control.advance_month(), "control advances continuation month %s" % index)
		t.check(restored.advance_month(), "loaded session advances continuation month %s" % index)
		t.check_equal(restored.random_system.rng.state, control.random_system.rng.state, "continued RNG stream matches at month %s" % index)
		t.check(_snapshot(restored) == _snapshot(control), "events, digestion, policies, annual seats and constitution match after month %s" % index)
	t.check(control.state.year >= 3, "continuation crosses an annual seat-allocation boundary")
	t.check(control.state.active_bill.proposals[0].is_fully_digested(), "continuation actually completes proposal digestion")
	t.check(control.state.active_bill.policies[0].triggered, "continuation actually triggers an untriggered saved policy")
	control.free()
	restored.free()
	Fixture.clean(directory)


func _check_references(t: BackendTestContext, loaded: RunSession, control: RunSession) -> void:
	var state := loaded.state
	t.check(state != control.state, "loaded runtime objects are independent of the source")
	t.check(state.office_visits[0].proposal == state.proposal_hand[0], "office proposal visit shares the actual hand instance")
	t.check(state.office_visits[1].event == state.events[0], "office event visit shares the actual event instance")
	t.check(state.proposal_acquisition_order[0] == state.proposal_hand[0], "acquisition order shares the actual hand instance")
	t.check(state.proposal_acquisition_order[1] == state.draft_bill.proposals[0], "reserved draft retains acquisition identity")
	t.check(state.newspaper_pending_bill == state.active_bill, "newspaper pending bill shares the active bill")
	t.check(state.saved_bills[0].proposals[0] != state.draft_bill.proposals[0], "saved bill proposal copies stay independent")
	t.check(state.draft_bill.policies[0] == Fixture.Policy, "static policy UID resolves the canonical resource")
	t.check(state.constitution.terminal_article == Fixture.LocalArticle, "terminal constitution UID resolves the canonical article")
	t.check(state.constitution.active_articles[Fixture.LocalArticle.row] == Fixture.LocalArticle, "resource-keyed constitution selections survive")
	t.check(loaded.meta_progression.is_column_unlocked(Fixture.Board.columns[2]), "resource-keyed meta column unlock survives")
	var local: InterestGroupDefinition = state.constitution.local_interest_groups[state.seats[0].definition]
	t.check(local == state.seats[0].actual_group, "runtime local group shares its seat reference")
	t.check(local == state.proposal_hand[0].source_group, "runtime local group shares its proposal reference")
	t.check(local != control.state.seats[0].actual_group, "runtime local group is rebuilt independently")
	t.check_equal(local.display_name, state.seats[0].definition.display_name, "runtime local group properties survive")
	t.check_equal(state.active_bill.proposals[0].digestion_progress, 0.2738492327483928, "digestion progress retains full float precision")
	t.check_equal(state.events[0].growth_progress, 0.471938291723891, "event growth retains full float precision")
	t.check_equal(state.seats[1].fixed_race, control.state.seats[1].fixed_race, "runtime fixed-seat override survives")
	t.check_equal(state.vote_donations[state.seats[0].definition], 13.5, "resource-keyed vote donations survive")
	t.check_equal(state.petition_used_this_year, 2, "used petition allowance survives")
	loaded.cancel_bill_editing()
	t.check(state.proposal_hand[1] == state.proposal_acquisition_order[1], "loaded draft returns to its original hand position")
	control.cancel_bill_editing()


func _test_manual_and_automatic_slots(t: BackendTestContext) -> void:
	var directory := _directory("slots")
	var session := Fixture.make_session(directory)
	var slots := session.list_saves()
	t.check_equal(slots.size(), 1, "new session creates only one initial automatic save")
	t.check(slots.back()["automatic"], "automatic slot is last")
	var automatic_id: String = slots.back()["slot_id"]
	var first := session.create_manual_save()
	var second := session.create_manual_save()
	t.check(first["ok"] and second["ok"], "manual saves can be created consecutively")
	t.check(first["slot_id"] != second["slot_id"], "consecutive manual saves have distinct identifiers")
	t.check_equal(session.list_saves().size(), 3, "manual creation retains both manual saves and automatic slot")
	t.check_equal(session.list_saves().back()["slot_id"], automatic_id, "automatic slot stays last after manual creation")
	t.check(session.advance_month(), "first stable month advances")
	t.check(session.advance_month(), "second stable month advances")
	t.check_equal(session.list_saves().back()["month"], session.state.month, "automatic metadata reflects the completed stable month")
	var auto_json := FileAccess.get_file_as_string(directory.path_join("auto.json"))
	t.check(session.overwrite_manual_save(first["slot_id"])["ok"], "existing manual save is overwritten")
	t.check_equal(session.list_saves().size(), 3, "manual overwrite does not append another slot")
	t.check(not session.overwrite_manual_save(automatic_id)["ok"], "manual overwrite rejects the automatic slot")
	t.check(session.load_save(second["slot_id"])["ok"], "older manual save loads")
	t.check_equal(session.state.month, 0, "manual load restores the older date")
	t.check_equal(FileAccess.get_file_as_string(directory.path_join("auto.json")), auto_json, "manual load preserves the latest automatic file")
	var startup := Fixture.make_session(directory)
	t.check_equal(FileAccess.get_file_as_string(directory.path_join("auto.json")), auto_json, "application startup preserves an existing automatic save")
	t.check(session.load_save(automatic_id)["ok"], "latest automatic save loads")
	t.check_equal(session.state.month, 2, "automatic save contains the fully advanced month")
	t.check_equal(DirAccess.get_files_at(directory).size(), 3, "monthly autosaves always replace a single file")
	t.check(not session.load_save("../outside")["ok"], "save loading rejects paths outside the slot directory")
	startup.free()
	session.free()
	Fixture.clean(directory)


func _test_invalid_snapshot_does_not_replace_state(t: BackendTestContext) -> void:
	var directory := _directory("invalid")
	var session := Fixture.make_session(directory)
	var snapshot := RunSnapshot.capture(session)
	snapshot["version"] = 999
	t.check(not RunSnapshot.decode(snapshot)["ok"], "unsupported save versions are rejected")
	var before := session.state
	var rng_state := session.random_system.rng.state
	var file := FileAccess.open(directory.path_join("auto.json"), FileAccess.WRITE)
	file.store_string("{broken json")
	file.close()
	t.check(not session.load_save("auto")["ok"], "corrupt JSON cannot load")
	t.check(session.state == before, "failed load leaves the current RunState untouched")
	t.check_equal(session.random_system.rng.state, rng_state, "failed load leaves RNG untouched")
	session.free()
	Fixture.clean(directory)


func _test_bridge_load_refreshes_world(t: BackendTestContext) -> void:
	var directory := _directory("bridge")
	var scene: PackedScene = load("res://core/game_root.tscn")
	var root := scene.instantiate()
	var session: RunSession = root.get_node("RunSession")
	session.save_directory = directory
	Engine.get_main_loop().root.add_child(root)
	var bridge: UiBridge = root.get_node("UiBridge")
	var manager: SceneManager = root.get_node("SceneManager")
	var messages := bridge.receive_ipc_message(_message("saves.list", {}))
	t.check_equal(messages.back()["type"], "saves.list", "bridge exposes the save list DTO")
	t.check_equal(messages.back()["payload"]["saves"].size(), 1, "bridge list includes automatic save")
	messages = bridge.receive_ipc_message(_message("saves.create", {"state_version": bridge.state_version}))
	t.check_equal(messages.back()["type"], "saves.list", "manual creation refreshes save list DTO")
	var slot_id: String = messages.back()["payload"]["saves"][0]["slot_id"]
	var old_world := manager.current_world
	var old_state := session.state
	session.state.seats[0].race = session.race_definitions[1]
	messages = bridge.receive_ipc_message(_message("saves.load", {"slot_id": slot_id, "state_version": bridge.state_version}))
	t.check_equal(messages.back()["type"], "state.full", "load sends the complete replacement DTO")
	t.check_equal(messages.back()["payload"]["ui_mode"], "constitution", "month-zero load rebuilds constitution UI")
	t.check_equal(messages.back()["payload"]["world_scene"], "parliament", "month-zero load selects parliament world")
	t.check(session.state != old_state, "bridge loads replacement Godot state")
	t.check(manager.current_world != old_world, "load reconstructs the current world even when its scene is unchanged")
	var parliament: ParliamentWorld = manager.current_world
	t.check_equal(parliament.seats.size(), session.state.seats.size(), "rebuilt parliament reflects every loaded seat")
	t.check(parliament.seats[0].race == session.constitution_system.get_active_race_definition(session.context, session.state.seats[0].race), "rebuilt parliament reflects loaded race identities")
	session.state.month = 6
	var visit := OfficeVisitState.new()
	visit.kind = OfficeVisitState.Kind.EVENT_INTEL
	visit.race = session.state.seats[0].race
	visit.event = EventState.new(visit.race, Metric.Id.TAX, 100, 150)
	session.state.events = [visit.event]
	session.state.office_visits = [visit]
	bridge.set_ui_mode("office", false)
	messages = bridge.receive_ipc_message(_message("saves.overwrite", {"slot_id": slot_id, "state_version": bridge.state_version}))
	t.check_equal(messages.back()["type"], "saves.list", "manual overwrite refreshes save list DTO")
	old_world = manager.current_world
	var saved_rng := session.random_system.rng.state
	session.state.office_visits.clear()
	session.state.month = 8
	var previous_version := bridge.state_version
	messages = bridge.receive_ipc_message(_message("saves.load", {"slot_id": slot_id, "state_version": previous_version}))
	t.check_equal(bridge.state_version, previous_version + 1, "load increments bridge state version")
	t.check_equal(messages.back()["payload"]["month"], 6, "replacement DTO exposes loaded calendar")
	t.check_equal(messages.back()["payload"]["ui_mode"], "office", "running-month load rebuilds office UI")
	t.check(manager.current_world != old_world, "running-month load rebuilds current office world")
	t.check(manager.current_world.call("has_visitors"), "rebuilt office receives loaded visitor queue")
	t.check(messages.back()["payload"]["pending_dialogue"] != null, "Svelte receives loaded pending dialogue")
	t.check_equal(session.random_system.rng.state, saved_rng, "world and full DTO refresh do not consume RNG")
	messages = bridge.receive_ipc_message(_message("saves.load", {"slot_id": slot_id, "state_version": previous_version}))
	t.check_equal(messages[0]["payload"]["code"], "stale_state", "pre-load UI commands are rejected after state replacement")
	root.free()
	Fixture.clean(directory)


func _snapshot(session: RunSession) -> String:
	return JSON.stringify(RunSnapshot.capture(session), "", true, true)


func _directory(label: String) -> String:
	return "user://test_saves_%s_%s_%s" % [label, OS.get_process_id(), Time.get_ticks_usec()]


func _message(message_type: String, payload: Dictionary) -> String:
	return JSON.stringify({"type": message_type, "request_id": "save-test", "payload": payload})
