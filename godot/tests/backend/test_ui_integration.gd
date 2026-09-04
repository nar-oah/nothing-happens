extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_protocol_envelopes(t)
	_test_core_dto_serialization(t)
	_test_full_state_and_saved_bill_indices(t)
	_test_command_errors_and_state_recovery(t)
	_test_policy_name_resolution(t)
	_test_saved_bill_reconciliation(t)
	_test_merge_refs(t)
	_test_draft_preview(t)
	_test_office_visit_dialogue_queue(t)
	_test_office_visit_donation_choice(t)
	_test_explicit_next_term_command(t)
	_test_normalized_input_regions(t)
	_test_parliament_world_seats(t)
	_test_game_root_shell(t)


func _test_protocol_envelopes(t: BackendTestContext) -> void:
	var protocol := UiProtocol.new()
	var malformed := protocol.decode("{")
	t.check(not malformed["ok"], "malformed JSON is rejected")
	t.check_equal(malformed["error"]["code"], "malformed_json", "malformed JSON has a code")
	var unknown := protocol.decode(JSON.stringify({"type": "unknown", "payload": {}}))
	t.check(not unknown["ok"], "unknown command is rejected")
	t.check_equal(unknown["error"]["code"], "unknown_type", "unknown command has a code")
	var missing_payload := protocol.decode(JSON.stringify({"type": "ui.ready"}))
	t.check(not missing_payload["ok"], "every envelope requires payload")
	t.check_equal(
		missing_payload["error"]["code"], "missing_payload", "missing payload has a code"
	)
	var ready := protocol.decode(
		protocol.encode("ui.ready", {}, "ready-request")
	)
	t.check(ready["ok"], "encoded ready envelope decodes")
	t.check_equal(ready["message"]["request_id"], "ready-request", "request id round trips")
	var visit_resolve := protocol.decode(
		protocol.encode("office.visit.resolve", {"state_version": 0}, "visit-request")
	)
	t.check(visit_resolve["ok"], "office visit command decodes")
	t.check(protocol.is_gameplay_mutation("office.visit.resolve"), "office visit is a gameplay mutation")
	var legacy_bonus := protocol.decode(
		JSON.stringify({"type": "proposal.bonus.resolve", "payload": {}})
	)
	t.check(not legacy_bonus["ok"], "legacy proposal bonus command is removed")


func _test_core_dto_serialization(t: BackendTestContext) -> void:
	var serializer := UiSerializer.new()
	var values := MetricValues.new()
	values.tax = 1
	values.consumption = 2
	values.production = 3
	values.employment = 4
	values.investment = 5
	t.check_equal(
		serializer.metric_values(values),
		{"tax": 1, "consumption": 2, "production": 3, "employment": 4, "investment": 5},
		"MetricValues serializes every named metric"
	)
	var group := t.make_group("serializer group", 4)
	group.description = "serializer group description"
	group.decrease_tax = true
	var proposal := t.make_proposal(group)
	proposal.base_effect.tax = 8
	proposal.positive_effect.investment = 5
	proposal.lag_months = 6
	proposal.donation_offer = 5.0
	proposal.bonus_choice_resolved = false
	proposal.positive_trait_accepted = false
	var proposal_dto: Dictionary = serializer.proposal(proposal)
	t.check_equal(proposal_dto["source_group"]["display_name"], "serializer group", "proposal source serializes")
	t.check_equal(
		proposal_dto["source_group"]["description"],
		"serializer group description",
		"proposal source description serializes"
	)
	t.check_equal(proposal_dto["base_effect"]["tax"], 8, "proposal base effect serializes")
	t.check_equal(proposal_dto["positive_effect"]["investment"], 5, "proposal trait serializes")
	t.check_equal(proposal_dto["lag_months"], 6, "proposal lag serializes")
	t.check(not proposal_dto["bonus_choice_resolved"], "proposal pending state serializes")
	var policy := _make_policy("serializer policy")
	var policy_dto: Dictionary = serializer.policy(policy)
	t.check_equal(policy_dto["condition"]["operator"], 3, "policy operator keeps enum value")
	t.check_equal(policy_dto["effects"][0]["formula"], 0, "policy formula keeps enum value")
	var draft := DraftBillState.new()
	draft.title = "serializer bill"
	draft.proposals.append(proposal)
	draft.policies.append(policy)
	var bill_dto: Dictionary = serializer.bill(draft)
	t.check_equal(bill_dto["title"], "serializer bill", "bill title serializes")
	t.check_equal(bill_dto["proposals"].size(), 1, "bill proposals serialize")
	t.check_equal(bill_dto["policies"].size(), 1, "bill policies serialize")


func _test_full_state_and_saved_bill_indices(t: BackendTestContext) -> void:
	var race := t.make_race("full race")
	race.description = "full race description"
	var group := t.make_group("full group")
	group.description = "full group description"
	var session := t.make_session([race], [group], t.make_seats(2, "full"))
	session.constitution_articles[0].description = "full article description"
	var saved := SavedBillState.new()
	saved.title = "saved zero"
	session.state.saved_bills.append(saved)
	var serializer := UiSerializer.new()
	var full := serializer.full_state(session, "office", "office", 7)
	t.check_equal(full["state_version"], 7, "full sync carries state version")
	t.check_equal(full["run_phase"], "RUNNING", "full sync carries the authoritative run phase")
	t.check_equal(full["term_outcome"], "NONE", "a running term has no terminal outcome")
	t.check_equal(full["governing_months"], 0, "full sync carries integer governing duration")
	t.check_equal(full["term_report"], null, "an unsettled run has no term report")
	t.check_equal(full["saved_bills"][0]["title"], "saved zero", "saved bill array preserves index")
	t.check_equal(full["editing_saved_bill_index"], null, "new bill index serializes as null")
	t.check_equal(full["constitution"]["title"], "蓬莱约法", "constitution uses its fixed title")
	t.check_equal(
		full["constitution"]["articles"][0]["content"],
		"full article description",
		"article content uses its description"
	)
	t.check_equal(
		full["races"][0]["description"], "full race description", "race description serializes"
	)
	t.check_equal(
		full["interest_groups"][0]["description"],
		"full group description",
		"interest group description serializes"
	)
	t.check_equal(full["races"][0]["seat_count"], 2, "race summary uses actual seats")
	t.check_equal(full["parliament"]["total_seats"], 2, "parliament summary uses actual pool")
	t.check_equal(full["parliament_seat_anchors"], [], "serializer defaults to no world anchors")
	t.check_equal(full["max_collapse"], session.balance.max_collapse, "status uses balance collapse limit")
	var bridge := UiBridge.new()
	bridge.setup(session)
	var ready := bridge.receive_ipc_message(_message("ui.ready", {}))
	t.check_equal(ready[0]["type"], "state.full", "ui.ready receives authoritative full sync")
	t.check_equal(ready[0]["request_id"], "test", "handshake response preserves request id")
	bridge.free()
	session.free()


func _test_explicit_next_term_command(t: BackendTestContext) -> void:
	var race := t.make_race("next term race")
	var group := t.make_group("next term group")
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.max_collapse = 1
	var session := t.make_session(
		[race], [group], t.make_seats(1, "next term"), [], balance
	)
	session.collapse_system.increase(session.context)
	var bridge := UiBridge.new()
	bridge.setup(session)
	var messages := bridge.receive_ipc_message(
		_message("term.next", {"state_version": 0})
	)
	var full: Dictionary = messages[messages.size() - 1]
	t.check_equal(full["type"], "state.full", "explicit next term returns a full state")
	t.check_equal(full["payload"]["state_version"], 1, "explicit next term advances state version")
	t.check_equal(full["payload"]["term"], 2, "explicit next term increments the term")
	t.check_equal(full["payload"]["month"], 0, "explicit next term creates month zero")
	t.check_equal(full["payload"]["run_phase"], "RUNNING", "explicit next term resets run phase")
	t.check_equal(full["payload"]["term_outcome"], "NONE", "explicit next term resets outcome")
	t.check_equal(full["payload"]["ui_mode"], "constitution", "next term enters constitution mode")
	t.check_equal(
		full["payload"]["term_report"]["outcome"],
		"NOTHING_HAPPENS",
		"the compatibility command reports the outcome"
	)
	var closed := bridge.receive_ipc_message(_message("ui.newspaper.close", {}))
	t.check_equal(closed[0]["payload"]["term_report"], null, "closing the settlement newspaper clears its report")
	bridge.free()
	session.free()


func _test_command_errors_and_state_recovery(t: BackendTestContext) -> void:
	var race := t.make_race("errors")
	var group := t.make_group("errors")
	var session := t.make_session([race], [group], t.make_seats(1, "errors"))
	var bridge := UiBridge.new()
	bridge.setup(session)
	var out_of_range := bridge.receive_ipc_message(
		_message("draft.proposal.add", {"state_version": 0, "hand_index": 4})
	)
	t.check_equal(out_of_range.size(), 2, "invalid mutation returns error and full state")
	t.check_equal(out_of_range[0]["type"], "command.error", "invalid hand index is explicit")
	t.check(out_of_range[0]["payload"]["recover_full_state"], "error announces recovery full sync")
	t.check_equal(out_of_range[1]["type"], "state.full", "invalid hand index recovers state")
	t.check_equal(bridge.state_version, 0, "rejected mutation does not advance version")
	var stale := bridge.receive_ipc_message(
		_message("bill.new", {"state_version": 3})
	)
	t.check_equal(stale[0]["payload"]["code"], "stale_state", "stale command is rejected")
	t.check_equal(stale[1]["payload"]["state_version"], 0, "stale recovery is authoritative")
	bridge.free()
	session.free()


func _test_policy_name_resolution(t: BackendTestContext) -> void:
	var race := t.make_race("policy race")
	var group := t.make_group("policy group")
	var policy := _make_policy("available policy")
	var article := t.make_article(race)
	article.policies.append(policy)
	var session := t.make_session([race], [group], t.make_seats(1, "policy"), [article])
	var bridge := UiBridge.new()
	bridge.setup(session)
	var messages := bridge.receive_ipc_message(
		_message(
			"draft.policy.add",
			{"state_version": 0, "display_name": "available policy"}
		)
	)
	t.check_equal(messages[0]["type"], "draft.sync", "policy command returns draft domain sync")
	t.check_equal(session.state.draft_bill.policies[0], policy, "policy name resolves current Resource")
	t.check_equal(bridge.state_version, 1, "successful policy mutation advances version")
	var unavailable := bridge.receive_ipc_message(
		_message("draft.policy.add", {"state_version": 1, "display_name": "missing"})
	)
	t.check_equal(unavailable[0]["payload"]["code"], "unavailable_policy", "unknown policy is rejected")
	bridge.free()
	session.free()


func _test_saved_bill_reconciliation(t: BackendTestContext) -> void:
	var race := t.make_race("saved race")
	var group := t.make_group("saved group")
	var session := t.make_session([race], [group], t.make_seats(1, "saved"))
	var current := t.make_proposal(group)
	current.base_effect.tax = 8
	session.proposal_system.add_to_hand(session.state, current)
	var saved := SavedBillState.new()
	saved.title = "recipe"
	saved.proposals.append(current.copy())
	session.state.saved_bills.append(saved)
	var bridge := UiBridge.new()
	bridge.setup(session)
	var messages := bridge.receive_ipc_message(
		_message("bill.edit", {"state_version": 0, "saved_bill_index": 0})
	)
	t.check_equal(messages[0]["type"], "draft.sync", "saved recipe returns draft sync")
	t.check_equal(session.state.draft_bill.proposals[0], current, "saved recipe reserves current hand instance")
	t.check_equal(session.state.proposal_hand.size(), 0, "reserved hand instance leaves hand")
	t.check_equal(messages[0]["payload"]["editing_saved_bill_index"], 0, "saved index syncs")
	bridge.free()
	session.free()


func _test_merge_refs(t: BackendTestContext) -> void:
	var race := t.make_race("merge race")
	var group := t.make_group("merge group")
	var session := t.make_session([race], [group], t.make_seats(1, "merge"))
	var base := t.make_proposal(group)
	base.base_effect.tax = 7
	var positive := t.make_proposal(group)
	positive.positive_effect.production = 6
	var third := t.make_proposal(group)
	for current in [base, positive, third]:
		session.proposal_system.add_to_hand(session.state, current)
	var bridge := UiBridge.new()
	bridge.setup(session)
	var messages := bridge.receive_ipc_message(
		_message(
			"proposal.merge",
			{
				"state_version": 0,
				"hand_indices": [0, 1, 2],
				"negative_base_index": 0,
				"selected_positive_index": 1,
			}
		)
	)
	t.check_equal(messages[0]["type"], "proposal.sync", "valid merge returns proposal sync")
	t.check_equal(messages[0]["payload"]["result"]["kind"], "merge", "merge result is discriminated")
	t.check_equal(session.state.proposal_hand.size(), 1, "authoritative merge consumes three mothers")
	t.check_equal(session.state.proposal_hand[0].base_effect.tax, 7, "negative base ref is honored")
	t.check_equal(bridge.state_version, 1, "merge advances version once")
	bridge.free()
	session.free()


func _test_draft_preview(t: BackendTestContext) -> void:
	var race := t.make_race("preview race")
	var group := t.make_group("preview group")
	var policy := _make_policy("preview policy")
	var article := t.make_article(race)
	article.policies.append(policy)
	var session := t.make_session([race], [group], t.make_seats(1, "preview"), [article])
	var proposal := t.make_proposal(group)
	proposal.base_effect.tax = 7
	session.state.draft_bill.proposals.append(proposal)
	session.state.draft_bill.policies.append(policy)
	var preview := UiSerializer.new().draft_preview(session)
	t.check_equal(preview["current_metrics"]["tax"], 100, "preview includes current metrics")
	t.check_equal(preview["pure_proposal_target"]["tax"], 107, "preview uses pure proposal target")
	t.check_equal(preview["immediate_policy_result"]["investment"], 110, "preview uses policy chain")
	t.check_equal(preview["projected_metrics"]["tax"], 107, "projected metrics include proposal")
	t.check_equal(preview["projected_metrics"]["investment"], 110, "projected metrics include policy")
	t.check_equal(preview["vote"]["seat_votes"].size(), 1, "preview uses authoritative seat vote")
	session.free()


func _test_office_visit_dialogue_queue(t: BackendTestContext) -> void:
	var race := t.make_race("canonical dialogue race")
	var active_race := t.make_race("active dialogue race")
	var group := t.make_group("canonical dialogue group")
	var active_group := t.make_group("active dialogue group")
	var session := t.make_session([race], [group], t.make_seats(1, "dialogue"))
	session.state.month = 1
	session.state.get_race(race).active_definition = active_race
	session.state.constitution.group_variants[group] = active_group
	var proposal := t.make_proposal(group)
	proposal.positive_effect.investment = 8
	proposal.donation_offer = 8.0
	proposal.bonus_choice_resolved = false
	proposal.positive_trait_accepted = false
	session.proposal_system.add_to_hand(session.state, proposal)
	var serializer := UiSerializer.new()
	t.check_equal(
		serializer.pending_dialogue(session), null, "pending proposal alone creates no dialogue"
	)
	var proposal_visit := _interest_group_visit(race, proposal)
	var event := EventState.new(race, Metric.Id.PRODUCTION, 20, 100)
	event.known = true
	event.growth_progress = 0.4
	var event_visit := _event_intel_visit(race, event)
	session.state.office_visits.append(proposal_visit)
	session.state.office_visits.append(event_visit)
	var proposal_dialogue: Dictionary = serializer.pending_dialogue(session)
	t.check_equal(
		proposal_dialogue,
		{
			"kind": "interest_group",
			"race_name": "active dialogue race",
			"group_name": "active dialogue group",
			"positive_metric": int(Metric.Id.INVESTMENT),
			"positive_value": 8,
			"donation_offer": 8.0,
		},
		"interest-group dialogue contains only structured visit data"
	)
	t.check(not proposal_dialogue.has("proposal"), "dialogue DTO does not expose ProposalInstance")
	t.check(not proposal_dialogue.has("hand_index"), "dialogue DTO has no proposal hand index")
	var bridge := UiBridge.new()
	bridge.setup(session)
	t.check_equal(bridge.ui_mode, "office", "queued visit does not automatically open dialogue")
	t.check(bridge.open_current_office_visit(), "current office visit opens explicitly")
	t.check_equal(bridge.ui_mode, "dialogue", "explicit visit open enters dialogue mode")
	t.check_equal(session.state.office_visits.size(), 2, "opening a visit does not consume it")
	var messages := bridge.receive_ipc_message(
		_message("office.visit.resolve", {"state_version": 0, "accept_trait": true})
	)
	t.check_equal(messages[0]["type"], "state.full", "visit resolution returns full state")
	t.check_equal(bridge.state_version, 1, "visit resolution advances state version")
	t.check_equal(session.state.office_visits.size(), 1, "visit resolution pops only one item")
	t.check(session.state.office_visits[0] == event_visit, "next queued visit keeps its identity")
	t.check(proposal.has_positive_trait(), "accepting a visit keeps its positive trait")
	t.check(proposal.bonus_choice_resolved and proposal.positive_trait_accepted, "accepting uses proposal gameplay API")
	t.check_equal(bridge.ui_mode, "office", "resolving first visit returns to office")
	t.check_equal(messages[0]["payload"]["ui_mode"], "office", "full state remains in office")
	t.check_equal(
		messages[0]["payload"]["pending_dialogue"],
		{
			"kind": "event_intel",
			"race_name": "active dialogue race",
			"metric": int(Metric.Id.PRODUCTION),
			"requirement": 52,
			"strength": 40,
		},
		"event-intel dialogue contains structured current requirement"
	)
	var unopened_messages := bridge.receive_ipc_message(
		_message("office.visit.resolve", {"state_version": 1})
	)
	t.check_equal(unopened_messages[0]["type"], "command.error", "office mode cannot resolve the next visit")
	t.check_equal(bridge.state_version, 1, "rejected unopened visit does not advance version")
	t.check(session.state.office_visits[0] == event_visit, "rejected unopened visit keeps the queue")
	t.check(bridge.open_current_office_visit(), "second visit also requires an explicit open")
	var event_messages := bridge.receive_ipc_message(
		_message("office.visit.resolve", {"state_version": 1})
	)
	t.check_equal(session.state.office_visits.size(), 0, "event acknowledgement pops the visit")
	t.check(event.known, "event acknowledgement does not rewrite known event state")
	t.check_equal(event_messages[0]["payload"]["ui_mode"], "office", "event returns to office")
	t.check(not bridge.open_current_office_visit(), "empty visit queue cannot open dialogue")
	bridge.free()
	session.free()


func _test_office_visit_donation_choice(t: BackendTestContext) -> void:
	var race := t.make_race("donation visitor")
	var group := t.make_group("donation group")
	var session := t.make_session([race], [group], t.make_seats(1, "donation"))
	session.state.month = 1
	var proposal := t.make_proposal(group)
	proposal.positive_effect.tax = 5
	proposal.donation_offer = 10.0
	proposal.bonus_choice_resolved = false
	proposal.positive_trait_accepted = false
	session.proposal_system.add_to_hand(session.state, proposal)
	session.state.office_visits.append(_interest_group_visit(race, proposal))
	var bridge := UiBridge.new()
	bridge.setup(session)
	bridge.open_current_office_visit()
	bridge.receive_ipc_message(
		_message("office.visit.resolve", {"state_version": 0, "accept_trait": false})
	)
	t.check(not proposal.has_positive_trait(), "donation choice clears the proposal trait")
	t.check(proposal.bonus_choice_resolved and not proposal.positive_trait_accepted, "donation choice uses proposal gameplay API")
	t.check_approx(session.state.political_donation_pool, 10.0, "donation choice funds the pool")
	t.check(session.state.office_visits.is_empty(), "donation choice consumes its visit")
	bridge.free()
	session.free()


func _test_normalized_input_regions(t: BackendTestContext) -> void:
	var texture := CefTextureInput.new()
	texture.size = Vector2(200.0, 100.0)
	texture.set_blocker_regions([{"x": 0.1, "y": 0.2, "width": 0.3, "height": 0.4}])
	t.check(texture._has_point(Vector2(40.0, 30.0)), "point inside normalized blocker hits CEF")
	t.check(not texture._has_point(Vector2(180.0, 80.0)), "point outside blockers passes to world")
	texture.free()


func _test_parliament_world_seats(t: BackendTestContext) -> void:
	var seat_scene: PackedScene = load("res://worlds/parliament_seat.tscn")
	var standalone: ParliamentSeat = seat_scene.instantiate()
	Engine.get_main_loop().root.add_child(standalone)
	t.check(standalone.get_node("Visual") is Sprite2D, "ParliamentSeat owns a Sprite2D Visual")
	t.check(standalone.get_node("UIAnchor") is Marker2D, "ParliamentSeat owns a Marker2D UIAnchor")
	var first := t.make_race("first parliament portrait")
	first.portrait = ImageTexture.new()
	standalone.seat_index = 4
	standalone.set_race(first)
	t.check_equal(standalone.seat_index, 4, "ParliamentSeat retains its RunState index")
	t.check(standalone.visual.texture == first.portrait, "ParliamentSeat displays RaceDefinition portrait")
	var viewport_size := standalone.get_viewport_rect().size
	standalone.position = viewport_size * 0.5
	var normalized := standalone.get_normalized_ui_anchor()
	t.check_approx(normalized.x, 0.5, "ParliamentSeat normalizes anchor x in the viewport")
	t.check_approx(normalized.y, 0.5, "ParliamentSeat normalizes anchor y in the viewport")
	standalone.free()

	var world_scene: PackedScene = load("res://worlds/parliament_world.tscn")
	var world: ParliamentWorld = world_scene.instantiate()
	var authored: ParliamentSeat = seat_scene.instantiate()
	authored.seat_index = 0
	authored.position = Vector2(120.0, 240.0)
	world.get_node("Seats").add_child(authored)
	Engine.get_main_loop().root.add_child(world)
	var second := t.make_race("second parliament portrait")
	second.portrait = ImageTexture.new()
	var third := t.make_race("third parliament portrait")
	third.portrait = ImageTexture.new()
	var races: Array[RaceDefinition] = [first, second, third]
	world.set_seat_races(races)
	t.check_equal(world.seats.size(), races.size(), "ParliamentWorld follows the dynamic seat count")
	t.check(world.seats[0] == authored, "ParliamentWorld reuses editor-authored seats")
	for index in range(races.size()):
		t.check_equal(world.seats[index].seat_index, index, "ParliamentWorld assigns stable seat indices")
		t.check(world.seats[index].race == races[index], "ParliamentWorld assigns each active race")
		t.check(world.seats[index].visual.texture == races[index].portrait, "ParliamentWorld updates each portrait")
	world.set_seat_races([second, first, third])
	t.check_equal(world.seats[0].position, Vector2(120.0, 240.0), "race updates preserve editor-authored seat positions")
	world.set_seat_races([second])
	t.check_equal(world.seats.size(), 1, "ParliamentWorld removes seats beyond RunState size")
	t.check_equal(world.seats_root.get_child_count(), 1, "removed seats leave the active scene tree")
	var anchors := world.get_seat_anchors()
	t.check_equal(anchors.size(), 1, "ParliamentWorld returns one anchor per current seat")
	t.check_equal(anchors[0].keys().size(), 3, "seat anchors contain no duplicated support data")
	t.check_equal(anchors[0]["seat_index"], 0, "seat anchor keeps its seat index")
	t.check(anchors[0]["x"] >= 0.0 and anchors[0]["x"] <= 1.0, "seat anchor x stays normalized")
	t.check(anchors[0]["y"] >= 0.0 and anchors[0]["y"] <= 1.0, "seat anchor y stays normalized")
	world.free()


func _test_game_root_shell(t: BackendTestContext) -> void:
	var scene: PackedScene = load("res://core/game_root.tscn")
	var root: Node = scene.instantiate()
	Engine.get_main_loop().root.add_child(root)
	t.check(root.has_node("RunSession"), "GameRoot owns RunSession")
	t.check(root.has_node("SceneManager/World"), "GameRoot owns SceneManager World")
	t.check(root.has_node("UiBridge"), "GameRoot owns one UiBridge")
	t.check(root.has_node("WorldInputRouter"), "GameRoot owns WorldInputRouter")
	t.check(root.has_node("UiLayer/CefTexture"), "GameRoot creates one full-screen CEF slot")
	t.check_equal(root.get_node("UiLayer").get_child_count(), 1, "UiLayer owns one browser node")
	var bridge: UiBridge = root.get_node("UiBridge")
	var ready := bridge.receive_ipc_message(_message("ui.ready", {}))
	t.check_equal(ready[0]["type"], "state.full", "production GameRoot completes handshake")
	t.check_equal(ready[0]["payload"]["metrics"]["tax"], 100, "production snapshot uses RunState")
	var session: RunSession = root.get_node("RunSession")
	var race_state := session.state.races[0]
	var active_race := t.make_race("active office visitor")
	active_race.portrait = ImageTexture.new()
	race_state.active_definition = active_race
	var event := EventState.new(race_state.definition, Metric.Id.TAX, 0, 100)
	event.known = true
	session.state.office_visits.append(_event_intel_visit(race_state.definition, event))
	bridge.set_ui_mode("office")
	var manager: SceneManager = root.get_node("SceneManager")
	var office := manager.current_world
	t.check(office.call("has_visitors"), "loaded OfficeWorld receives the visitor queue")
	t.check(office.call("get_current_visitor") == active_race, "OfficeWorld receives active race definition")
	bridge.open_current_office_visit()
	bridge.receive_ipc_message(_message("office.visit.resolve", {"state_version": 0}))
	t.check(not office.call("has_visitors"), "resolved visit resyncs the current OfficeWorld")
	var seat_state: SeatState = session.state.seats[0]
	var seat_race_state: RaceState = session.state.get_race(seat_state.race)
	var parliament_race := t.make_race("active parliament race")
	parliament_race.portrait = ImageTexture.new()
	seat_race_state.active_definition = parliament_race
	bridge.set_ui_mode("parliament")
	var parliament: ParliamentWorld = manager.current_world
	t.check_equal(parliament.seats.size(), session.state.seats.size(), "loaded ParliamentWorld follows RunState seats")
	t.check(parliament.seats[0].race == parliament_race, "ParliamentWorld receives active race definition")
	t.check(parliament.seats[0].visual.texture == parliament_race.portrait, "active race portrait reaches ParliamentWorld")
	var parliament_ready := bridge.receive_ipc_message(_message("ui.ready", {}))
	t.check_equal(
		parliament_ready[0]["payload"]["parliament_seat_anchors"].size(),
		session.state.seats.size(),
		"parliament full state includes every world seat anchor"
	)
	root.free()


func _make_policy(display_name: String) -> PolicyDefinition:
	var condition := MetricCondition.new()
	condition.left_metric = Metric.Id.TAX
	condition.operator = MetricCondition.Operator.GREATER_THAN_OR_EQUAL
	condition.right_metric = Metric.Id.INVESTMENT
	var effect := PolicyEffect.new()
	effect.target_metric = Metric.Id.INVESTMENT
	effect.formula = PolicyEffect.Formula.METRIC_VALUE
	effect.source_a = Metric.Id.TAX
	effect.multiplier = 0.1
	var policy := PolicyDefinition.new()
	policy.display_name = display_name
	policy.condition = condition
	policy.effects.append(effect)
	return policy


func _interest_group_visit(
	race: RaceDefinition, proposal: ProposalInstance
) -> OfficeVisitState:
	var visit := OfficeVisitState.new()
	visit.kind = OfficeVisitState.Kind.INTEREST_GROUP
	visit.race = race
	visit.proposal = proposal
	return visit


func _event_intel_visit(race: RaceDefinition, event: EventState) -> OfficeVisitState:
	var visit := OfficeVisitState.new()
	visit.kind = OfficeVisitState.Kind.EVENT_INTEL
	visit.race = race
	visit.event = event
	return visit


func _message(message_type: String, payload: Dictionary) -> String:
	return JSON.stringify({"type": message_type, "request_id": "test", "payload": payload})
