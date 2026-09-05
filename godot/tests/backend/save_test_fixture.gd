extends RefCounted

const Balance = preload("res://data/config/game_balance.tres")
const Board = preload("res://data/constitutions/constitution_board.tres")
const LocalArticle = preload("res://data/constitutions/地区自治.tres")
const Policy = preload("res://data/policies/乡约平粜.tres")
const OtherPolicy = preload("res://data/policies/统一定价.tres")


static func make_session(directory: String) -> RunSession:
	var session := RunSession.new()
	session.balance = Balance
	session.save_directory = directory
	var races: Array[RaceDefinition] = []
	var groups: Array[InterestGroupDefinition] = []
	var seats: Array[SeatDefinition] = []
	races.assign(_resources("res://data/races"))
	groups.assign(_resources("res://data/interest_groups"))
	seats.assign(_resources("res://data/seats"))
	session.configure_content(races, groups, seats, [], Board)
	session.start_new_run()
	return session


static func populate(session: RunSession) -> void:
	var state := session.state
	state.term = 3
	state.year = 2
	state.month = 6
	state.governing_months = 17
	state.metrics.tax = 107
	state.metrics.consumption = 94
	state.metrics.production = 143
	state.metrics.employment = 119
	state.metrics.investment = 87
	state.collapse_level = 8
	state.constitution.active_articles[LocalArticle.row] = LocalArticle
	state.constitution.terminal_article = LocalArticle
	session.constitution_system.refresh_runtime(session.context)
	session.constitution_system.run_effects(session.context, ConstitutionEffect.Timing.AFTER_GROUP_ALLOCATION)
	state.constitution.revision_available = false
	var group := session.interest_groups[0]
	state.constitution.group_mergers[session.interest_groups[1]] = group
	state.constitution.group_variants[group] = load("res://data/interest_groups/variants/永乐局（自由贸易）.tres")
	state.annual_proposal_slot_counts[group] = 7
	state.last_annual_proposal_slot_counts[group] = 4
	state.last_annual_source_shares[group] = 0.375
	state.vote_donations[state.seats[0].definition] = 13.5
	state.political_donation_pool = 42.75
	state.petition_used_this_year = 2
	state.seats[1].annual_group = session.interest_groups[2]
	state.seats[1].fixed_race = state.seats[1].race
	for race in state.races:
		race.resolved_events_this_year = 2
		race.last_year_resolved_events = 3
		for metric in race.active_definition.get_stance_metrics():
			race.expectation_targets[metric] = state.metrics.get_value(metric) + 50
	var hand := _proposal(state.seats[0].actual_group)
	hand.bonus_choice_resolved = false
	hand.positive_trait_accepted = false
	hand.office_visit_created = true
	var draft := _proposal(group)
	draft.base_effect.production = -7
	state.add_proposal_to_hand(hand)
	state.add_proposal_to_hand(draft)
	session.draft_bill_system.move_proposal_from_hand(state, 1)
	state.draft_bill.title = "待议《存档》"
	state.draft_bill.policies = [Policy]
	var saved := SavedBillState.new()
	saved.title = "已保存法案"
	saved.proposals = [draft.copy()]
	saved.policies = [Policy]
	state.saved_bills = [saved]
	state.editing_saved_bill_index = 0
	var active := ActiveBillState.new()
	active.title = "正在消化的法案"
	active.start_values = state.year_start_metrics.copy()
	active.proposals = [ActiveProposalState.new(_proposal(group))]
	active.proposals[0].digested_months = 3
	active.proposals[0].digestion_progress = 0.2738492327483928
	active.pure_target = session.proposal_system.calculate_pure_target(active.start_values, [active.proposals[0].proposal])
	active.policies = [PolicyState.new(Policy), PolicyState.new(OtherPolicy)]
	active.policies[1].triggered = true
	state.active_bill = active
	state.newspaper_pending_bill = active
	state.newspaper_triggered_policies = [OtherPolicy]
	var event := EventState.new(state.seats[0].race, Metric.Id.PRODUCTION, 100, 180)
	event.growth_progress = 0.471938291723891
	event.satisfaction_rate = 0.42
	event.months_alive = 4
	event.known = true
	var group_event := EventState.new(state.seats[1].race, Metric.Id.TAX, 2, 12, EventState.RequirementKind.INTEREST_GROUP_PROPOSALS, group)
	group_event.growth_progress = 0.7
	group_event.months_alive = 8
	group_event.known = true
	group_event.published = true
	group_event.public_window_entered = true
	group_event.phase = EventState.Phase.PAUSED
	state.events = [event, group_event]
	var proposal_visit := OfficeVisitState.new()
	proposal_visit.kind = OfficeVisitState.Kind.INTEREST_GROUP
	proposal_visit.race = state.seats[0].race
	proposal_visit.proposal = hand
	var event_visit := OfficeVisitState.new()
	event_visit.kind = OfficeVisitState.Kind.EVENT_INTEL
	event_visit.race = event.race
	event_visit.event = event
	state.office_visits = [proposal_visit, event_visit]
	state.month_report_year = 2
	state.month_report_month = 5
	state.month_report_previous_metrics = state.year_start_metrics.copy()
	state.month_report_current_metrics = state.metrics.copy()
	state.month_report_events = [{"race_display_name": event.race.display_name, "metric": 2, "value": 123, "countdown": 8, "strength": 47, "phase": 0}]
	state.newspaper_front = {"title": "既有头版", "content": "恢复后保持原文。"}
	session.meta_progression.available_governing_months = 97
	session.meta_progression.lifetime_governing_months = 143
	session.meta_progression.unlocked_constitution_columns[Board.columns[2]] = true
	session.meta_progression.unlocked_constitution_columns[Board.columns[4]] = true
	session.term_report = {"outcome": RunState.TermOutcome.COLLAPSE, "previous_governing_months": 80, "current_governing_months": 97}
	session._last_awarded_term = 2
	session._previous_newspaper_collapse = 7
	session.random_system.set_seed(0x23456789abcdef)
	for index in range(9):
		session.random_system.random_float(0.0, 1.0)


static func clean(directory: String) -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	for filename in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(filename))
	DirAccess.remove_absolute(directory)


static func _resources(directory: String) -> Array[Resource]:
	var result: Array[Resource] = []
	var files := DirAccess.get_files_at(directory)
	files.sort()
	for filename in files:
		if filename.ends_with(".tres"):
			result.append(load(directory.path_join(filename)))
	return result


static func _proposal(group: InterestGroupDefinition) -> ProposalInstance:
	var result := ProposalInstance.new()
	result.source_group = group
	result.base_effect.tax = -11
	result.positive_effect.investment = 6
	result.lag_months = 9
	result.donation_offer = 6.25
	return result
