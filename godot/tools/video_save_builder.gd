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
	var restored_nanke_state := core_gap_state.get_race(
		_find_race(core_gap_restored, "南柯")
	)
	if core_gap_result["ok"] != true:
		push_error("Failed to restore core gap save: result.ok is false")
	elif core_gap_state.metrics.tax != 100:
		push_error("Failed to restore core gap save: metrics.tax is %s, expected 100" % core_gap_state.metrics.tax)
	elif core_gap_state.metrics.consumption != 80:
		push_error("Failed to restore core gap save: metrics.consumption is %s, expected 80" % core_gap_state.metrics.consumption)
	elif core_gap_state.metrics.production != 40:
		push_error("Failed to restore core gap save: metrics.production is %s, expected 40" % core_gap_state.metrics.production)
	elif core_gap_state.metrics.employment != 100:
		push_error("Failed to restore core gap save: metrics.employment is %s, expected 100" % core_gap_state.metrics.employment)
	elif core_gap_state.metrics.investment != 100:
		push_error("Failed to restore core gap save: metrics.investment is %s, expected 100" % core_gap_state.metrics.investment)
	elif core_gap_state.political_donation_pool != 10:
		push_error("Failed to restore core gap save: political_donation_pool is %s, expected 10" % core_gap_state.political_donation_pool)
	elif core_gap_state.proposal_hand.size() != 1:
		push_error("Failed to restore core gap save: proposal_hand.size is %s, expected 1" % core_gap_state.proposal_hand.size())
	elif restored_proposal.source_group != _find_group(core_gap_restored, "岁契基金"):
		push_error("Failed to restore core gap save: proposal source_group is not 岁契基金")
	elif restored_proposal.base_effect.tax != -10:
		push_error("Failed to restore core gap save: proposal tax is %s, expected -10" % restored_proposal.base_effect.tax)
	elif restored_proposal.base_effect.production != -10:
		push_error("Failed to restore core gap save: proposal production is %s, expected -10" % restored_proposal.base_effect.production)
	elif restored_proposal.base_effect.consumption != 0:
		push_error("Failed to restore core gap save: proposal consumption is %s, expected 0" % restored_proposal.base_effect.consumption)
	elif restored_proposal.lag_months != 6:
		push_error("Failed to restore core gap save: proposal lag_months is %s, expected 6" % restored_proposal.lag_months)
	elif core_gap_state.events.size() != 1:
		push_error("Failed to restore core gap save: events.size is %s, expected 1" % core_gap_state.events.size())
	elif restored_event.race != _find_race(core_gap_restored, "南柯"):
		push_error("Failed to restore core gap save: event race is not 南柯")
	elif restored_event.metric != Metric.Id.CONSUMPTION:
		push_error("Failed to restore core gap save: event metric is %s, expected CONSUMPTION" % restored_event.metric)
	elif restored_event.baseline_value != 101:
		push_error("Failed to restore core gap save: event baseline_value is %s, expected 101" % restored_event.baseline_value)
	elif restored_event.full_target != 101:
		push_error("Failed to restore core gap save: event full_target is %s, expected 101" % restored_event.full_target)
	elif restored_event.months_alive != 9:
		push_error("Failed to restore core gap save: event months_alive is %s, expected 9" % restored_event.months_alive)
	elif restored_event.growth_progress != 1.0:
		push_error("Failed to restore core gap save: event growth_progress is %s, expected 1.0" % restored_event.growth_progress)
	elif restored_event.known != true:
		push_error("Failed to restore core gap save: event known is false")
	elif restored_event.published != true:
		push_error("Failed to restore core gap save: event published is false")
	elif restored_nanke_state.expectation_targets[Metric.Id.CONSUMPTION] != 101:
		push_error("Failed to restore core gap save: 南柯 consumption expectation is %s, expected 101" % restored_nanke_state.expectation_targets[Metric.Id.CONSUMPTION])
	else:
		print("VIDEO CORE GAP SAVE OK")
	core_gap_session.free()
	core_gap_restored.free()

	var terminal_demos := [
		{
			"slot_id": "manual_900201",
			"article_name": "地区自治",
			"success_message": "VIDEO LOCAL AUTONOMY SAVE OK",
		},
		{
			"slot_id": "manual_900202",
			"article_name": "行省",
			"success_message": "VIDEO PROVINCE SAVE OK",
		},
		{
			"slot_id": "manual_900203",
			"article_name": "理想国",
			"success_message": "VIDEO UTOPIA SAVE OK",
		},
	]
	for demo in terminal_demos:
		var article_name: String = demo["article_name"]
		var terminal_session := _make_session()
		if not _build_terminal_demo(terminal_session, article_name):
			push_error("Failed to build terminal video save: %s" % article_name)
			terminal_session.free()
			continue
		var terminal_slot_id: String = demo["slot_id"]
		_write(terminal_session, terminal_slot_id)
		var terminal_restored := _make_session()
		var terminal_result := terminal_restored.load_save(terminal_slot_id)
		var terminal_error := (
			"result.ok is false"
			if terminal_result["ok"] != true
			else _terminal_demo_error(terminal_restored, article_name)
		)
		if terminal_error.is_empty():
			print(demo["success_message"])
		else:
			push_error("Failed to restore %s video save: %s" % [article_name, terminal_error])
		terminal_session.free()
		terminal_restored.free()
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
	state.metrics.consumption = 80
	state.metrics.production = 40
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
	var nanke_state := state.get_race(nanke)
	nanke_state.expectation_targets[Metric.Id.CONSUMPTION] = 101
	var event := EventState.new(nanke, Metric.Id.CONSUMPTION, 101, 101)
	event.growth_progress = 1.0
	event.satisfaction_rate = 80.0 / 101.0
	event.months_alive = (
		session.balance.event_lifetime_months
		- session.balance.event_public_remaining_months
	)
	event.known = true
	event.published = true
	event.public_window_entered = true
	event.phase = EventState.Phase.WORSENING
	state.events = [event]
	var fund := _find_group(session, "岁契基金")
	var proposal := ProposalInstance.new()
	proposal.source_group = fund
	proposal.base_effect.tax = -10
	proposal.base_effect.production = -10
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
			seat.annual_group = fund
			seat.actual_group = fund
			assigned += 1


func _build_terminal_demo(session: RunSession, article_name: String) -> bool:
	var state := session.state
	state.term = 4
	state.year = 4
	state.month = 0
	state.governing_months = 36
	state.collapse_level = 6
	state.political_donation_pool = 10
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
	var article := _find_article(session, article_name)
	if article == null:
		push_error("Terminal article not found: %s" % article_name)
		return false
	var board := session.constitution_board
	var target_index := board.get_column_index_for_article(article)
	var center_index := board.get_center_column_index()
	var inward_step := 1 if target_index < center_index else -1
	var previous_index := target_index + inward_step
	var previous_article: ConstitutionArticleDefinition
	while previous_index >= 0 and previous_index < board.columns.size():
		previous_article = board.get_article(article.row, previous_index)
		if previous_article != null:
			break
		previous_index += inward_step
	if previous_article == null or previous_article.is_terminal:
		push_error("Previous constitution article not found for: %s" % article_name)
		return false
	state.constitution.active_articles[article.row] = previous_article
	session.constitution_system.refresh_runtime(session.context)
	session.meta_progression.unlocked_constitution_columns[board.columns[target_index]] = true
	match article_name:
		"地区自治":
			_set_race_seat_majority(session, "桃花妖")
		"行省":
			_set_race_seat_majority(session, "人类")
		"理想国":
			_set_group_majority(session, "听弦塔")
	if not session.constitution_system.can_revise(session.context, article):
		push_error("Formal constitution requirements are not met for: %s" % article_name)
		return false
	if not session.constitution_system.revise(session.context, article):
		push_error("Formal constitution revision failed for: %s" % article_name)
		return false
	if article_name == "行省":
		for effect in article.effects:
			if effect is ModifyRaceEffect:
				effect.apply(session.context)
	var validation_error := _terminal_demo_error(session, article_name)
	if not validation_error.is_empty():
		push_error("Terminal constitution validation failed for %s: %s" % [article_name, validation_error])
		return false
	return true


func _terminal_demo_error(session: RunSession, article_name: String) -> String:
	var state := session.state
	if state.constitution.terminal_article == null:
		return "terminal_article is null"
	if state.constitution.terminal_article.display_name != article_name:
		return "terminal_article is %s" % state.constitution.terminal_article.display_name
	var policy_names := {
		"地区自治": "一地一议",
		"行省": "平准官仓",
		"理想国": "梦中机具",
	}
	if session.constitution_system.get_available_policy(
		session.context, policy_names[article_name]
	) == null:
		return "terminal policy is unavailable"
	match article_name:
		"地区自治":
			var peach := _find_race(session, "桃花妖")
			var peach_state := state.get_race(peach)
			if peach_state.active_definition.resource_path != "res://data/races/variants/桃源/桃花妖（地区自治）.tres":
				return "桃花妖 district-autonomy variant is inactive"
			if state.constitution.local_interest_groups.is_empty():
				return "local_interest_groups is empty"
			var local_groups := state.constitution.local_interest_groups.values()
			var local_seat_count := 0
			for seat in state.seats:
				if seat.actual_group in local_groups:
					local_seat_count += 1
			if local_seat_count < 2:
				return "fewer than two seats use local interest groups"
		"行省":
			if session.constitution_system.get_parliament_name(session.context) != "衙门":
				return "parliament name is not 衙门"
			for race in state.races:
				if race.active_definition == null or not race.active_definition.resource_path.begins_with("res://data/races/variants/官员/"):
					return "%s official variant is inactive" % race.definition.display_name
		"理想国":
			if session.constitution_system.get_parliament_name(session.context) != "理想国议会":
				return "parliament name is not 理想国议会"
			var nanke := _find_race(session, "南柯")
			var nanke_state := state.get_race(nanke)
			if nanke_state.active_definition.resource_path != "res://data/races/variants/团体/南柯（理想国）.tres":
				return "南柯 utopia variant is inactive"
			var consumption_requirement := session.race_system.get_effective_expectation(
				nanke_state, Metric.Id.CONSUMPTION, session.context
			)
			var employment_requirement := session.race_system.get_effective_expectation(
				nanke_state, Metric.Id.EMPLOYMENT, session.context
			)
			var draft := DraftBillState.new()
			var failing_target := MetricValues.new()
			failing_target.consumption = consumption_requirement - 1
			failing_target.employment = employment_requirement - 1
			if session.constitution_system.validate_draft(
				session.context, draft, failing_target
			):
				return "draft below 南柯 expectations was accepted"
			var passing_target := failing_target.copy()
			passing_target.consumption = consumption_requirement
			passing_target.employment = employment_requirement
			if not session.constitution_system.validate_draft(
				session.context, draft, passing_target
			):
				return "draft meeting 南柯 expectations was rejected"
	return ""


func _find_article(
	session: RunSession, display_name: String
) -> ConstitutionArticleDefinition:
	for article in session.constitution_articles:
		if article.display_name == display_name:
			return article
	return null


func _set_race_seat_majority(session: RunSession, race_name: String) -> void:
	var race := _find_race(session, race_name)
	for seat in session.state.seats:
		if seat.fixed_race == null:
			seat.race = race


func _set_group_majority(session: RunSession, group_name: String) -> void:
	var group := _find_group(session, group_name)
	var seats := session.parliament_system.get_influenceable_seats(session.state)
	var required_count := ceili(float(seats.size()) * 0.9)
	for index in range(required_count):
		seats[index].annual_group = group
		seats[index].actual_group = group


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
