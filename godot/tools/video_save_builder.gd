extends Node

const OUTPUT_DIR := "user://saves"
const Balance = preload("res://data/config/game_balance.tres")
const Board = preload("res://data/constitutions/constitution_board.tres")


func _ready() -> void:
	if (
		not DirAccess.dir_exists_absolute(OUTPUT_DIR)
		and DirAccess.make_dir_recursive_absolute(OUTPUT_DIR) != OK
	):
		push_error("VIDEO SAVE BUILD FAILED: cannot create %s" % OUTPUT_DIR)
		get_tree().quit()
		return

	var core_session := _make_session()
	core_session.random_system.set_seed(0x900101)
	if not _build_core_gap_demo(core_session):
		core_session.free()
		get_tree().quit()
		return
	_write(core_session, "manual_900101")
	var core_restored := _make_session()
	var core_result := core_restored.load_save("manual_900101")
	var core_error := (
		"load_save failed: %s" % str(core_result.get("error", {}))
		if not bool(core_result.get("ok", false))
		else _core_demo_error(core_restored)
	)
	if not core_error.is_empty():
		push_error("VIDEO CORE PARLIAMENT SAVE FAILED: %s" % core_error)
		core_session.free()
		core_restored.free()
		get_tree().quit()
		return
	print("VIDEO CORE PARLIAMENT SAVE OK")
	core_session.free()
	core_restored.free()

	var terminal_saves := [
		{
			"slot_id": "manual_900201",
			"article": "地区自治",
			"success": "VIDEO LOCAL AUTONOMY SAVE OK",
		},
		{
			"slot_id": "manual_900202",
			"article": "理想国",
			"success": "VIDEO UTOPIA SAVE OK",
		},
	]
	for entry in terminal_saves:
		var terminal_session := _make_session()
		var article_name: String = entry["article"]
		if not _build_terminal_demo(terminal_session, article_name):
			terminal_session.free()
			get_tree().quit()
			return
		var slot_id: String = entry["slot_id"]
		_write(terminal_session, slot_id)
		var terminal_restored := _make_session()
		var terminal_result := terminal_restored.load_save(slot_id)
		var terminal_error := (
			"load_save failed: %s" % str(terminal_result.get("error", {}))
			if not bool(terminal_result.get("ok", false))
			else _terminal_demo_error(terminal_restored, article_name)
		)
		if not terminal_error.is_empty():
			push_error("VIDEO %s SAVE FAILED: %s" % [article_name, terminal_error])
			terminal_session.free()
			terminal_restored.free()
			get_tree().quit()
			return
		print(entry["success"])
		terminal_session.free()
		terminal_restored.free()

	var collapse_session := _make_session()
	_build_high_collapse_demo(collapse_session)
	_write(collapse_session, "manual_900301")
	var collapse_restored := _make_session()
	var collapse_result := collapse_restored.load_save("manual_900301")
	var collapse_error := (
		"load_save failed: %s" % str(collapse_result.get("error", {}))
		if not bool(collapse_result.get("ok", false))
		else _high_collapse_error(collapse_restored)
	)
	if not collapse_error.is_empty():
		push_error("VIDEO HIGH COLLAPSE SAVE FAILED: %s" % collapse_error)
		collapse_session.free()
		collapse_restored.free()
		get_tree().quit()
		return
	print("VIDEO HIGH COLLAPSE SAVE OK")
	collapse_session.free()
	collapse_restored.free()

	var ending_session := _make_session()
	if not _build_nothing_happens_demo(ending_session):
		ending_session.free()
		get_tree().quit()
		return
	_write(ending_session, "manual_900401")
	var ending_restored := _make_session()
	var ending_result := ending_restored.load_save("manual_900401")
	var ending_error := (
		"load_save failed: %s" % str(ending_result.get("error", {}))
		if not bool(ending_result.get("ok", false))
		else _nothing_happens_error(ending_restored)
	)
	if not ending_error.is_empty():
		push_error("VIDEO NOTHING HAPPENS SAVE FAILED: %s" % ending_error)
		ending_session.free()
		ending_restored.free()
		get_tree().quit()
		return
	var ending_runner := _make_session()
	var runner_result := ending_runner.load_save("manual_900401")
	if not bool(runner_result.get("ok", false)):
		ending_error = "advance verification load failed: %s" % str(runner_result.get("error", {}))
	elif not ending_runner.advance_month():
		ending_error = "advance_month returned false"
	elif int(ending_runner.term_report.get("outcome", -1)) != RunState.TermOutcome.NOTHING_HAPPENS:
		ending_error = "term_report outcome is not NOTHING_HAPPENS"
	elif ending_runner.state.term != 4:
		ending_error = "term after settlement is %d, expected 4" % ending_runner.state.term
	if not ending_error.is_empty():
		push_error("VIDEO NOTHING HAPPENS SAVE FAILED: %s" % ending_error)
		ending_session.free()
		ending_restored.free()
		ending_runner.free()
		get_tree().quit()
		return
	print("VIDEO NOTHING HAPPENS SAVE OK")
	ending_session.free()
	ending_restored.free()
	ending_runner.free()

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


func _write(session: RunSession, slot_id: String) -> void:
	var result := RunSaveStore.write_save(session, slot_id)
	if bool(result.get("ok", false)):
		print("VIDEO SAVE: %s" % session.save_directory.path_join(slot_id + ".json"))
	else:
		push_error("VIDEO SAVE WRITE FAILED [%s]: %s" % [slot_id, str(result.get("error", {}))])


func _build_core_gap_demo(session: RunSession) -> bool:
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
	_clear_demo_state(state)

	for race_state in state.races:
		if race_state == null or race_state.active_definition == null:
			continue
		race_state.expectation_targets.clear()
		for metric in race_state.active_definition.get_stance_metrics():
			race_state.expectation_targets[metric] = state.metrics.get_value(metric) + 10

	var nanke := _find_race(session, "南柯")
	var fund := _find_group(session, "岁契基金")
	if nanke == null or fund == null:
		push_error("VIDEO CORE PARLIAMENT SAVE FAILED: missing 南柯 or 岁契基金 resource")
		return false
	var nanke_state := state.get_race(nanke)
	if nanke_state == null:
		push_error("VIDEO CORE PARLIAMENT SAVE FAILED: missing 南柯 runtime state")
		return false
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
	var candidates: Array[int] = []
	var original_annual: Array[InterestGroupDefinition] = []
	var original_actual: Array[InterestGroupDefinition] = []
	for seat_index in range(state.seats.size()):
		var seat := state.seats[seat_index]
		original_annual.append(seat.annual_group)
		original_actual.append(seat.actual_group)
		if seat.race != null and seat.race != yanyou and seat.race != zhushui:
			candidates.append(seat_index)
	for influenced_count in range(candidates.size() + 1):
		for seat_index in range(state.seats.size()):
			state.seats[seat_index].annual_group = original_annual[seat_index]
			state.seats[seat_index].actual_group = original_actual[seat_index]
		for candidate_index in range(influenced_count):
			var seat := state.seats[candidates[candidate_index]]
			seat.annual_group = fund
			seat.actual_group = fund
		if _core_vote_error(session, proposal).is_empty():
			return true
	push_error("VIDEO CORE PARLIAMENT SAVE FAILED: no seat layout yields a 1-3 donation plan")
	return false


func _core_demo_error(session: RunSession) -> String:
	var state := session.state
	if state.term != 2 or state.year != 1 or state.month != 4 or state.governing_months != 15:
		return "date or governing_months did not restore"
	if state.collapse_level != 2 or not is_equal_approx(state.political_donation_pool, 10.0):
		return "collapse or political donation pool did not restore"
	if (
		state.metrics.tax != 100
		or state.metrics.consumption != 80
		or state.metrics.production != 40
		or state.metrics.employment != 100
		or state.metrics.investment != 100
	):
		return "metrics did not restore as 100 / 80 / 40 / 100 / 100"
	if not state.draft_bill.is_empty() or state.active_bill != null:
		return "saved draft is not empty"
	if state.proposal_hand.size() != 1:
		return "proposal_hand size is %d, expected 1" % state.proposal_hand.size()
	var proposal := state.proposal_hand[0]
	var fund := _find_group(session, "岁契基金")
	if proposal.source_group != fund:
		return "proposal source is not 岁契基金"
	if (
		proposal.base_effect.tax != -10
		or proposal.base_effect.consumption != 0
		or proposal.base_effect.production != -10
		or proposal.lag_months != 6
		or not proposal.positive_effect.is_zero()
	):
		return "proposal effects or lag did not restore"
	if state.events.size() != 1:
		return "events size is %d, expected 1" % state.events.size()
	var event := state.events[0]
	var nanke := _find_race(session, "南柯")
	if event.race != nanke or event.metric != Metric.Id.CONSUMPTION:
		return "event race or metric did not restore"
	if event.baseline_value != 101 or event.full_target != 101:
		return "event baseline or full target did not restore"
	if (
		event.months_alive != session.balance.event_lifetime_months - session.balance.event_public_remaining_months
		or not is_equal_approx(event.growth_progress, 1.0)
		or not event.known
		or not event.published
		or not event.public_window_entered
		or event.phase != EventState.Phase.WORSENING
	):
		return "event public worsening state did not restore"
	var nanke_state := state.get_race(nanke)
	if nanke_state == null or nanke_state.expectation_targets.get(Metric.Id.CONSUMPTION) != 101:
		return "南柯 consumption expectation is not 101"
	return _core_vote_error(session, proposal)


func _core_vote_error(session: RunSession, proposal: ProposalInstance) -> String:
	var policy := session.constitution_system.get_available_policy(session.context, "乡约平粜")
	if policy == null:
		return "乡约平粜 is not available"
	var validation_draft := DraftBillState.new()
	validation_draft.proposals.append(proposal)
	validation_draft.policies.append(PolicyState.new(policy, 3))
	var pure_target := session.proposal_system.calculate_pure_target(
		session.state.metrics, validation_draft.proposals
	)
	var projected := session.vote_system.calculate_projected_metrics(
		validation_draft, pure_target, session.context
	)
	if projected.consumption <= 101:
		return "projected consumption is %d, expected above 101" % projected.consumption
	var preview := session.vote_system.preview_vote(validation_draft, session.context)
	if preview.support_count <= 0:
		return "vote preview has no supporting seat"
	var has_non_support := false
	for vote in preview.seat_votes:
		if vote.position != SeatVoteState.Position.SUPPORT:
			has_non_support = true
			break
	if not has_non_support:
		return "vote preview has no non-SUPPORT seat"
	if preview.support_count >= preview.present_count():
		return "vote preview is unanimous among present seats"
	var plan := session.vote_system.get_minimum_donation_plan(validation_draft, session.context)
	if plan.is_empty():
		return "minimum donation plan is unavailable"
	var cost := float(plan.get("cost", 0.0))
	if cost < 1.0 or cost > 3.0:
		return "minimum donation cost is %.1f, expected 1-3" % cost
	return ""


func _build_terminal_demo(session: RunSession, article_name: String) -> bool:
	var state := session.state
	state.term = 4
	state.year = 4
	state.month = 0
	state.collapse_level = 6
	_clear_demo_state(state)
	var article := _find_article(session, article_name)
	if article == null or not article.is_terminal or article.row == null:
		push_error("VIDEO %s SAVE FAILED: terminal article not found" % article_name)
		return false
	var board := session.constitution_board
	var target_column := board.get_column_index_for_article(article)
	var center_column := board.get_center_column_index()
	var outward_direction := -1 if target_column < center_column else 1
	var previous_article: ConstitutionArticleDefinition
	var column_index := target_column - outward_direction
	while column_index >= 0 and column_index < board.columns.size():
		previous_article = board.get_article(article.row, column_index)
		if previous_article != null:
			break
		column_index -= outward_direction
	if previous_article == null or previous_article.is_terminal:
		push_error("VIDEO %s SAVE FAILED: adjacent non-terminal article not found" % article_name)
		return false
	state.constitution.active_articles[article.row] = previous_article
	session.constitution_system.refresh_runtime(session.context)
	session.meta_progression.unlocked_constitution_columns[board.columns[target_column]] = true
	match article_name:
		"地区自治":
			_set_race_seat_majority(session, "桃花妖")
		"理想国":
			_set_group_majority(session, "听弦塔")
		_:
			push_error("VIDEO TERMINAL SAVE FAILED: unsupported article %s" % article_name)
			return false
	if not session.constitution_system.can_revise(session.context, article):
		push_error("VIDEO %s SAVE FAILED: formal can_revise returned false" % article_name)
		return false
	if not session.constitution_system.revise(session.context, article):
		push_error("VIDEO %s SAVE FAILED: formal revise returned false" % article_name)
		return false
	var validation_error := _terminal_demo_error(session, article_name)
	if not validation_error.is_empty():
		push_error("VIDEO %s SAVE FAILED: %s" % [article_name, validation_error])
		return false
	return true


func _terminal_demo_error(session: RunSession, article_name: String) -> String:
	var state := session.state
	if state.term != 4 or state.year != 4 or state.month != 0 or state.collapse_level != 6:
		return "common terminal-demo state did not restore"
	if state.constitution.terminal_article == null:
		return "terminal_article is null"
	if state.constitution.terminal_article.display_name != article_name:
		return "terminal_article is %s" % state.constitution.terminal_article.display_name
	match article_name:
		"地区自治":
			var peach := _find_race(session, "桃花妖")
			var peach_state := state.get_race(peach)
			if (
				peach_state == null
				or peach_state.active_definition == null
				or peach_state.active_definition.resource_path
				!= "res://data/races/variants/桃源/桃花妖（地区自治）.tres"
			):
				return "桃花妖 did not switch to the 地区自治 variant"
			if state.constitution.local_interest_groups.is_empty():
				return "local_interest_groups is empty"
			var local_groups := state.constitution.local_interest_groups.values()
			var local_seats := 0
			for seat in state.seats:
				if seat.actual_group in local_groups:
					local_seats += 1
			if local_seats < 2:
				return "only %d seats use local interest groups" % local_seats
			if session.constitution_system.get_available_policy(session.context, "一地一议") == null:
				return "一地一议 is not available"
		"理想国":
			if session.constitution_system.get_parliament_name(session.context) != "理想国议会":
				return "parliament name is not 理想国议会"
			var nanke := _find_race(session, "南柯")
			var nanke_state := state.get_race(nanke)
			if (
				nanke_state == null
				or nanke_state.active_definition == null
				or nanke_state.active_definition.resource_path
				!= "res://data/races/variants/团体/南柯（理想国）.tres"
			):
				return "南柯 did not switch to the 理想国 variant"
			if session.constitution_system.get_available_policy(session.context, "梦中机具") == null:
				return "梦中机具 is not available"
			var draft_error := _utopia_draft_error(session, nanke_state)
			if not draft_error.is_empty():
				return draft_error
		_:
			return "unsupported terminal article %s" % article_name
	return ""


func _utopia_draft_error(session: RunSession, nanke_state: RaceState) -> String:
	var consumption_target := session.race_system.get_effective_expectation(
		nanke_state, Metric.Id.CONSUMPTION, session.context
	)
	var employment_target := session.race_system.get_effective_expectation(
		nanke_state, Metric.Id.EMPLOYMENT, session.context
	)
	var draft := DraftBillState.new()
	var low_consumption := MetricValues.new()
	low_consumption.consumption = consumption_target - 1
	low_consumption.employment = employment_target
	if session.constitution_system.validate_draft(session.context, draft, low_consumption):
		return "draft below the consumption expectation was accepted"
	var low_employment := MetricValues.new()
	low_employment.consumption = consumption_target
	low_employment.employment = employment_target - 1
	if session.constitution_system.validate_draft(session.context, draft, low_employment):
		return "draft below the employment expectation was accepted"
	var passing := MetricValues.new()
	passing.consumption = consumption_target
	passing.employment = employment_target
	if not session.constitution_system.validate_draft(session.context, draft, passing):
		return "draft meeting both expectations was rejected"
	return ""


func _find_article(
	session: RunSession, display_name: String
) -> ConstitutionArticleDefinition:
	for article in session.constitution_articles:
		if article != null and article.display_name == display_name:
			return article
	return null


func _set_race_seat_majority(session: RunSession, race_name: String) -> void:
	var race := _find_race(session, race_name)
	if race == null:
		return
	for seat in session.state.seats:
		if seat.fixed_race == null:
			seat.race = race


func _set_group_majority(session: RunSession, group_name: String) -> void:
	var group := _find_group(session, group_name)
	if group == null:
		return
	var seats := session.parliament_system.get_influenceable_seats(session.state)
	var required_count := ceili(float(seats.size()) * 0.9)
	for index in range(required_count):
		seats[index].annual_group = group
		seats[index].actual_group = group


func _build_high_collapse_demo(session: RunSession) -> void:
	var state := session.state
	state.term = 3
	state.year = 2
	state.month = 6
	state.governing_months = 18
	state.political_donation_pool = 10
	state.collapse_level = ceili(float(session.balance.max_collapse) * 0.9)
	_clear_demo_state(state)


func _high_collapse_error(session: RunSession) -> String:
	var state := session.state
	if state.term != 3 or state.year != 2 or state.month != 6 or state.governing_months != 18:
		return "date or governing_months did not restore"
	if not is_equal_approx(state.political_donation_pool, 10.0):
		return "political donation pool did not restore"
	if state.collapse_level >= session.balance.max_collapse:
		return "collapse reached max_collapse"
	if float(state.collapse_level) / float(session.balance.max_collapse) < 0.9:
		return "collapse ratio is below 0.9"
	if state.run_phase != RunState.RunPhase.RUNNING:
		return "run_phase is not RUNNING"
	if (
		not state.events.is_empty()
		or not state.office_visits.is_empty()
		or not state.draft_bill.is_empty()
		or not state.saved_bills.is_empty()
		or state.active_bill != null
		or not state.scheduled_policies.is_empty()
		or state.newspaper_pending_bill != null
	):
		return "high-collapse unrelated state was not cleared"
	return ""


func _build_nothing_happens_demo(session: RunSession) -> bool:
	var state := session.state
	state.term = 3
	state.year = 2
	state.month = 6
	state.governing_months = 18
	state.run_phase = RunState.RunPhase.RUNNING
	state.term_outcome = RunState.TermOutcome.NONE
	state.collapse_level = session.balance.max_collapse - session.balance.collapse_step
	_clear_demo_state(state)
	state.annual_proposal_slot_counts.clear()
	for race_state in state.races:
		if race_state == null or race_state.definition == null:
			continue
		race_state.expectation_targets.clear()
		if race_state.definition.fixed_interest_group != null:
			var expected_count := session.race_system.get_interest_group_proposal_expectation(
				race_state, session.context
			)
			state.annual_proposal_slot_counts[race_state.definition.fixed_interest_group] = expected_count
			continue
		var active := race_state.active_definition
		if active == null:
			active = race_state.definition
		for metric in active.get_stance_metrics():
			race_state.expectation_targets[metric] = 0
	var human := _find_race(session, "人类")
	if human == null:
		push_error("VIDEO NOTHING HAPPENS SAVE FAILED: missing 人类 resource")
		return false
	var target := state.metrics.tax + 10
	var event := EventState.new(human, Metric.Id.TAX, target, target)
	event.growth_progress = 1.0
	event.satisfaction_rate = float(state.metrics.tax) / float(target)
	event.months_alive = session.balance.event_lifetime_months - 1
	event.known = true
	event.published = true
	event.public_window_entered = true
	event.phase = EventState.Phase.WORSENING
	state.events = [event]
	var error := _nothing_happens_error(session)
	if not error.is_empty():
		push_error("VIDEO NOTHING HAPPENS SAVE FAILED: %s" % error)
		return false
	return true


func _nothing_happens_error(session: RunSession) -> String:
	var state := session.state
	if state.term != 3 or state.year != 2 or state.month != 6 or state.governing_months != 18:
		return "date or governing_months did not restore"
	if state.run_phase != RunState.RunPhase.RUNNING or state.term_outcome != RunState.TermOutcome.NONE:
		return "pre-ending run state is not RUNNING / NONE"
	if state.collapse_level != session.balance.max_collapse - session.balance.collapse_step:
		return "pre-ending collapse level did not restore"
	if not state.saved_bills.is_empty():
		return "saved_bills is not empty"
	if state.events.size() != 1:
		return "events size is %d, expected 1" % state.events.size()
	var event := state.events[0]
	var human := _find_race(session, "人类")
	var target := state.metrics.tax + 10
	if event.race != human or event.metric != Metric.Id.TAX:
		return "ending event race or metric did not restore"
	if event.baseline_value != target or event.full_target != target:
		return "ending event target did not restore"
	if (
		event.months_alive != session.balance.event_lifetime_months - 1
		or not is_equal_approx(event.growth_progress, 1.0)
		or not event.known
		or not event.published
		or not event.public_window_entered
		or event.phase != EventState.Phase.WORSENING
	):
		return "ending event state did not restore"
	return ""


func _find_group(
	session: RunSession, display_name: String
) -> InterestGroupDefinition:
	for group in session.interest_groups:
		if group != null and group.display_name == display_name:
			return group
	return null


func _find_race(session: RunSession, display_name: String) -> RaceDefinition:
	for race in session.race_definitions:
		if race != null and race.display_name == display_name:
			return race
	return null


func _clear_demo_state(state: RunState) -> void:
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


func _resources(directory: String) -> Array[Resource]:
	var result: Array[Resource] = []
	var files := DirAccess.get_files_at(directory)
	files.sort()
	for filename in files:
		if filename.ends_with(".tres"):
			result.append(load(directory.path_join(filename)))
	return result
