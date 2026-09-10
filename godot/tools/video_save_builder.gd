extends Node

const OUTPUT_DIR := "user://video_saves"
const Balance = preload("res://data/config/game_balance.tres")
const Board = preload("res://data/constitutions/constitution_board.tres")


func _ready() -> void:
	if DirAccess.make_dir_recursive_absolute(OUTPUT_DIR) != OK:
		push_error("Failed to create video save directory: %s" % OUTPUT_DIR)
		get_tree().quit()
		return
	var session := _make_session()
	session.random_system.set_seed(0x23456789abcdef)
	var state := session.state
	state.term = 9
	state.year = 9
	state.month = 9
	state.political_donation_pool = 99
	var slot_id := "manual_900001"
	_write(session, slot_id)
	var restored := _make_session()
	var result := restored.load_save(slot_id)
	if result["ok"] != true:
		push_error("Failed to restore video save: result.ok is false")
	elif restored.state.term != 9:
		push_error("Failed to restore video save: state.term is %s, expected 9" % restored.state.term)
	elif restored.state.year != 9:
		push_error("Failed to restore video save: state.year is %s, expected 9" % restored.state.year)
	elif restored.state.month != 9:
		push_error("Failed to restore video save: state.month is %s, expected 9" % restored.state.month)
	elif restored.state.political_donation_pool != 99:
		push_error("Failed to restore video save: state.political_donation_pool is %s, expected 99" % restored.state.political_donation_pool)
	else:
		print("VIDEO SAVE BUILD OK")
	session.free()
	restored.free()

	var core_gap_session := _make_session()
	core_gap_session.random_system.set_seed(0x900101)
	_build_core_gap_demo(core_gap_session)
	var core_gap_slot_id := "manual_900101"
	_write(core_gap_session, core_gap_slot_id)
	var core_gap_restored := _make_session()
	var core_gap_result := core_gap_restored.load_save(core_gap_slot_id)
	var core_gap_state := core_gap_restored.state
	var restored_proposal: ProposalInstance = (
		null if core_gap_state.proposal_hand.is_empty() else core_gap_state.proposal_hand[0]
	)
	var restored_event: EventState = (
		null if core_gap_state.events.is_empty() else core_gap_state.events[0]
	)
	if core_gap_result["ok"] != true:
		push_error("Failed to restore core gap save: result.ok is false")
	elif core_gap_state.metrics.tax != 100:
		push_error("Failed to restore core gap save: metrics.tax is %s, expected 100" % core_gap_state.metrics.tax)
	elif core_gap_state.metrics.consumption != 70:
		push_error("Failed to restore core gap save: metrics.consumption is %s, expected 70" % core_gap_state.metrics.consumption)
	elif core_gap_state.metrics.production != 150:
		push_error("Failed to restore core gap save: metrics.production is %s, expected 150" % core_gap_state.metrics.production)
	elif core_gap_state.metrics.employment != 100:
		push_error("Failed to restore core gap save: metrics.employment is %s, expected 100" % core_gap_state.metrics.employment)
	elif core_gap_state.metrics.investment != 100:
		push_error("Failed to restore core gap save: metrics.investment is %s, expected 100" % core_gap_state.metrics.investment)
	elif core_gap_state.political_donation_pool != 10:
		push_error("Failed to restore core gap save: political_donation_pool is %s, expected 10" % core_gap_state.political_donation_pool)
	elif core_gap_state.proposal_hand.size() != 1:
		push_error("Failed to restore core gap save: proposal_hand.size is %s, expected 1" % core_gap_state.proposal_hand.size())
	elif restored_proposal.source_group != _find_group(core_gap_restored, "永乐局"):
		push_error("Failed to restore core gap save: proposal source_group is not 永乐局")
	elif restored_proposal.base_effect.consumption != -20:
		push_error("Failed to restore core gap save: proposal consumption is %s, expected -20" % restored_proposal.base_effect.consumption)
	elif restored_proposal.base_effect.production != -5:
		push_error("Failed to restore core gap save: proposal production is %s, expected -5" % restored_proposal.base_effect.production)
	elif restored_proposal.lag_months != 6:
		push_error("Failed to restore core gap save: proposal lag_months is %s, expected 6" % restored_proposal.lag_months)
	elif core_gap_state.events.size() != 1:
		push_error("Failed to restore core gap save: events.size is %s, expected 1" % core_gap_state.events.size())
	elif restored_event.race != _find_race(core_gap_restored, "南柯"):
		push_error("Failed to restore core gap save: event race is not 南柯")
	elif restored_event.metric != Metric.Id.CONSUMPTION:
		push_error("Failed to restore core gap save: event metric is %s, expected CONSUMPTION" % restored_event.metric)
	elif restored_event.full_target != 95:
		push_error("Failed to restore core gap save: event full_target is %s, expected 95" % restored_event.full_target)
	elif restored_event.known != true:
		push_error("Failed to restore core gap save: event known is false")
	elif restored_event.published != true:
		push_error("Failed to restore core gap save: event published is false")
	else:
		print("VIDEO CORE GAP SAVE OK")
	core_gap_session.free()
	core_gap_restored.free()
	get_tree().quit()


func _make_session() -> RunSession:
	var session := RunSession.new()
	session.balance = Balance
	session.save_directory = OUTPUT_DIR
	session.autosave_enabled = false
	var races: Array[RaceDefinition] = []
	var groups: Array[InterestGroupDefinition] = []
	var seats: Array[SeatDefinition] = []
	races.assign(_resources("res://data/races"))
	groups.assign(_resources("res://data/interest_groups"))
	seats.assign(_resources("res://data/seats"))
	session.configure_content(races, groups, seats, [], Board)
	session.start_new_run()
	return session


func _build_core_gap_demo(session: RunSession) -> void:
	var state := session.state
	state.term = 2
	state.year = 1
	state.month = 4
	state.governing_months = 15
	state.collapse_level = 2
	state.political_donation_pool = 10
	state.metrics.tax = 100
	state.metrics.consumption = 70
	state.metrics.production = 150
	state.metrics.employment = 100
	state.metrics.investment = 100
	state.year_start_metrics = state.metrics.copy()
	state.proposal_hand.clear()
	state.proposal_acquisition_order.clear()
	state.office_visits.clear()
	state.events.clear()
	state.saved_bills.clear()
	state.draft_bill = DraftBillState.new()
	state.active_bill = null
	state.scheduled_policies.clear()
	state.newspaper_pending_bill = null
	state.newspaper_triggered_policies.clear()
	state.newspaper_front.clear()
	for race in state.races:
		race.expectation_targets.clear()
		for metric in race.active_definition.get_stance_metrics():
			race.expectation_targets[metric] = state.metrics.get_value(metric) + 10
	var nanke := _find_race(session, "南柯")
	var event := EventState.new(nanke, Metric.Id.CONSUMPTION, 70, 95)
	event.growth_progress = 1.0
	event.satisfaction_rate = 70.0 / 95.0
	event.months_alive = 2
	event.known = true
	event.published = true
	event.public_window_entered = true
	event.phase = EventState.Phase.WORSENING
	state.events = [event]
	var yongle := _find_group(session, "永乐局")
	var proposal := ProposalInstance.new()
	proposal.source_group = yongle
	proposal.base_effect.consumption = -20
	proposal.base_effect.production = -5
	proposal.lag_months = 6
	proposal.donation_offer = 0
	proposal.bonus_choice_resolved = true
	proposal.positive_trait_accepted = true
	state.add_proposal_to_hand(proposal)
	var yanyou := _find_race(session, "偃偶")
	var zhushui := _find_race(session, "驻岁")
	var assigned := 0
	for seat in state.seats:
		if assigned >= 6:
			break
		if seat.race != null and seat.race != yanyou and seat.race != zhushui:
			seat.annual_group = yongle
			seat.actual_group = yongle
			assigned += 1


func _find_group(session: RunSession, display_name: String) -> InterestGroupDefinition:
	for group in session.interest_groups:
		if group.display_name == display_name:
			return group
	return null


func _find_race(session: RunSession, display_name: String) -> RaceDefinition:
	for race in session.race_definitions:
		if race.display_name == display_name:
			return race
	return null


func _write(session: RunSession, slot_id: String) -> void:
	var result := RunSaveStore.write_save(session, slot_id)
	var path := session.save_directory.path_join(slot_id + ".json")
	if result["ok"]:
		print("Generated video save: %s" % path)
	else:
		push_error("Failed to generate video save: %s" % result["error"]["message"])


func _resources(directory: String) -> Array[Resource]:
	var result: Array[Resource] = []
	var files := DirAccess.get_files_at(directory)
	files.sort()
	for filename in files:
		if filename.ends_with(".tres"):
			result.append(load(directory.path_join(filename)))
	return result
