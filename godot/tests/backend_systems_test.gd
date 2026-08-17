extends SceneTree

var failures: int = 0
var assertions: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_race_seats_and_full_parliament()
	_test_authorization_stats_and_coloring()
	_test_positive_traits_and_merge()
	_test_draft_editing_and_vote()
	_test_event_lifecycle_and_trust()
	_test_constitution_and_special_races()
	_test_special_voting_rules()
	_test_constitution_revision_threshold()
	_test_annual_settlement()
	_test_flow_reaches_new_year()
	_test_collapse_routes()
	if failures == 0:
		print("BACKEND TESTS PASSED: %s assertions" % assertions)
	else:
		push_error("BACKEND TESTS FAILED: %s of %s assertions" % [failures, assertions])
	quit(failures)


func _test_race_seats_and_full_parliament() -> void:
	var race_definition := _make_race(&"race_a", 4)
	var race := RaceState.new(race_definition)
	var race_system := RaceSystem.new()
	race.political_trust = 0.0
	_check_equal(race_system.calculate_annual_seat_count(race), 1, "minimum trust seats")
	race.political_trust = 50.0
	_check_equal(race_system.calculate_annual_seat_count(race), 4, "pivot trust seats")
	race.political_trust = 100.0
	_check_equal(race_system.calculate_annual_seat_count(race), 8, "maximum trust seats")
	var groups: Array[InterestGroupDefinition] = [
		_make_group(&"strong", 6, 0),
		_make_group(&"standard", 3, 1),
		_make_group(&"local", 1, 2),
	]
	race.seat_count = 10
	var race_b := RaceState.new(_make_race(&"race_b", 10))
	var races: Array[RaceState] = [race, race_b]
	var parliament := ParliamentSystem.new()
	var seats := parliament.create_full_parliament(races, groups)
	_check_equal(seats.size(), 20, "all race rows generated")
	var strong_count := 0
	for seat in seats:
		if seat.base_group_id == &"strong":
			strong_count += 1
	_check_equal(strong_count, 12, "formal 6:3:1 base weights")
	_check_equal(Metric.proposal_negative_sign(Metric.Id.TAX), 1, "tax proposal cost rises")


func _test_authorization_stats_and_coloring() -> void:
	var state := RunState.new()
	var parliament := ParliamentSystem.new()
	var random := RandomSystem.new()
	random.set_seed(7)
	var groups: Array[InterestGroupDefinition] = [
		_make_group(&"a", 1, 0),
		_make_group(&"b", 1, 1),
	]
	state.races = [RaceState.new(_make_race(&"race", 6))]
	state.races[0].seat_count = 6
	parliament.rebuild_all_rows(state, groups)
	parliament.apply_annual_coloring(state, groups, random, 1.0)
	for seat in state.seats:
		_check_equal(seat.actual_group_id, seat.base_group_id, "no slots restore base column")
	var proposal := _make_proposal(&"b")
	var proposals: Array[ProposalInstance] = [proposal]
	parliament.record_authorized_proposal_slots(state, proposals)
	parliament.record_authorized_proposal_slots(state, proposals)
	_check_equal(state.annual_proposal_slot_counts[&"b"], 2, "repeat law grants new slots")
	parliament.apply_annual_coloring(state, groups, random, 1.0)
	for seat in state.seats:
		_check_equal(seat.actual_group_id, &"b", "source share colors across columns")


func _test_positive_traits_and_merge() -> void:
	var system := ProposalSystem.new()
	var state := RunState.new()
	var negative_base := _make_proposal(&"guild")
	negative_base.base_effect.tax = 7
	var positive_a := _make_proposal(&"guild")
	positive_a.positive_effect.wage = 10
	var positive_b := _make_proposal(&"guild")
	positive_b.positive_effect.trade = 8
	state.proposal_hand = [negative_base, positive_a, positive_b]
	var mothers: Array[ProposalInstance] = [negative_base, positive_a, positive_b]
	var merged := system.merge_three(state, mothers, negative_base, positive_a)
	_check(merged != null, "same-group three-to-one succeeds")
	_check_equal(state.proposal_hand.size(), 1, "merge consumes three mothers")
	_check_equal(merged.base_effect.tax, 7, "merge preserves chosen negative base")
	_check_equal(merged.positive_effect.wage, 14, "discarded trait converts at configured ratio")
	_check_equal(merged.positive_effect.non_zero_metrics().size(), 1, "merged card keeps one trait")
	var generated := _make_proposal(&"guild")
	var random := RandomSystem.new()
	random.set_seed(12)
	system.add_positive_trait(generated, 3, InflationSystem.new(), random)
	_check_equal(
		generated.positive_effect.non_zero_metrics().size(), 1, "visitor trait has one metric"
	)
	var metric: Metric.Id = generated.positive_effect.non_zero_metrics()[0]
	_check(
		generated.positive_effect.get_value(metric) * Metric.favorable_sign(metric) > 0,
		"visitor trait uses favorable direction"
	)
	_check(
		(
			system.calculate_visit_probability(0.01, 0.5)
			> system.calculate_visit_probability(0.9, 0.5)
		),
		"weak group visits more often"
	)


func _test_draft_editing_and_vote() -> void:
	var stance := _make_stance(Metric.Id.WAGE, MetricStanceDefinition.Direction.HIGHER, 100, 0)
	var race := _make_race(&"workers", 3)
	race.fixed_seat_count = 3
	race.metric_stances = [stance]
	var group := _make_group(&"union", 1, 0)
	group.metric_stances = [stance]
	var session := _make_session([race], [group])
	session.state.metrics.wage = 50
	var proposal := _make_proposal(&"union")
	proposal.base_effect.wage = 10
	session.state.proposal_hand.append(proposal)
	_check(
		session.draft_bill_system.move_proposal_from_hand(session.state, 0), "move card to draft"
	)
	_check_equal(session.state.proposal_hand.size(), 0, "hand loses drafted card")
	var preview := session.vote_system.preview_vote(session.state.draft_bill, session.context)
	_check_equal(preview.support_count, 3, "members support movement toward expectation")
	_check(preview.passed, "preview has parliamentary majority")
	var result := session.submit_draft()
	_check(result.submitted and result.passed, "non-empty draft passes vote")
	_check(session.state.has_intervened, "bill submission records intervention")
	_check(session.state.active_bill != null, "passed draft becomes active law")
	_check_equal(session.state.annual_proposal_slot_counts[&"union"], 1, "passed slot is recorded")
	var empty_result := session.submit_draft()
	_check(not empty_result.submitted, "empty draft is not an intervention")
	session.free()


func _test_event_lifecycle_and_trust() -> void:
	var race := _make_race(&"event_race", 2)
	race.fixed_seat_count = 2
	var group := _make_group(&"group", 1, 0)
	var session := _make_session([race], [group])
	var requirement := EventRequirementDefinition.new()
	requirement.metric = Metric.Id.WAGE
	requirement.direction = EventRequirementDefinition.Direction.HIGHER
	requirement.base_amount = 100
	var eruption_definition := _make_event(&"eruption", &"event_race", requirement)
	eruption_definition.worsening_per_month = 0.1
	eruption_definition.crisis_months = 3
	var eruption := session.event_system.spawn_event(session.state, eruption_definition)
	eruption.base_intensity = 0.9
	for i in range(3):
		session.event_system.settle_month(session.context)
	_check_equal(eruption.phase, EventState.Phase.ERUPTED, "three uncontrolled full months erupt")
	_check(eruption.known and eruption.published, "full event is permanently public")
	var relief_definition := _make_event(&"relief", &"event_race", requirement)
	var relief := session.event_system.spawn_event(session.state, relief_definition)
	session.state.metrics.wage = 100
	session.event_system.settle_month(session.context)
	_check_equal(relief.phase, EventState.Phase.RELIEVING, "first floor relief is retained")
	session.event_system.settle_month(session.context)
	_check_equal(relief.phase, EventState.Phase.RESOLVED, "second floor relief resolves event")
	var race_state := session.state.get_race(&"event_race")
	_check_equal(race_state.erupted_events_this_year, 1, "eruption trust ledger count")
	_check_equal(race_state.resolved_events_this_year, 1, "resolution trust ledger count")
	_check_equal(race_state.pending_trust_delta, -4.0, "event trust deltas wait for year end")
	session.free()


func _test_constitution_and_special_races() -> void:
	var yano := _make_race(Race.YANO, 2)
	yano.fixed_seat_count = 2
	yano.special_group_id = &"factory"
	var peach := _make_race(Race.PEACH_BLOSSOM, 2)
	peach.fixed_seat_count = 2
	peach.local_group_prefix = &"county"
	var human := _make_race(Race.HUMAN, 3)
	human.fixed_seat_count = 3
	human.special_group_id = &"transport"
	var article := ConstitutionArticleDefinition.new()
	article.id = &"special_rules"
	article.axis_id = &"initial"
	article.is_initial = true
	article.flags = [&"free_trade", &"yano_recognized", &"peach_closed"]
	var groups: Array[InterestGroupDefinition] = [
		_make_group(&"factory", 6, 0),
		_make_group(&"transport", 6, 1),
		_make_group(&"minor", 1, 2),
	]
	var session := _make_session([yano, peach, human], groups, [], [article])
	_check_equal(
		session.state.get_race(Race.HUMAN).seat_count, 1, "free trade keeps one human seat"
	)
	var peach_groups: Dictionary[StringName, bool] = {}
	for seat in session.state.seats:
		if seat.race_id == Race.YANO:
			_check_equal(seat.actual_group_id, &"factory", "recognized yano fixed to factory")
		elif seat.race_id == Race.PEACH_BLOSSOM:
			peach_groups[seat.actual_group_id] = true
		elif seat.race_id == Race.HUMAN:
			_check_equal(seat.actual_group_id, &"transport", "free-trade human fixed to transport")
	_check_equal(peach_groups.size(), 2, "closed peach seats get unique local groups")
	_check_equal(
		session.state.constitution.annual_petition_count, 1, "20 percent transport grants petition"
	)
	_check(session.constitution_system.use_petition(session.context), "petition can be consumed")
	_check_equal(session.state.constitution.annual_petition_count, 0, "petition count decreases")
	session.free()


func _test_special_voting_rules() -> void:
	var zhushui := _make_race(Race.ZHUSHUI, 4)
	var nanke := _make_race(Race.NANKE, 1)
	nanke.fixed_seat_count = 1
	nanke.special_group_id = &"union"
	nanke.strike_wage_floor = 10
	var biyi := _make_race(Race.BIYI, 1)
	biyi.fixed_seat_count = 1
	var group := _make_group(&"union", 1, 0)
	var session := _make_session([zhushui, nanke, biyi], [group])
	for seat in session.state.seats:
		if seat.race_id == Race.BIYI:
			seat.odd_month_relation = 10.0
			seat.even_month_relation = -10.0
	var actual := session.vote_system.calculate_vote(
		session.state.draft_bill, session.context, true
	)
	_check_equal(
		_vote_for_race(actual, session.state, Race.ZHUSHUI),
		SeatVoteState.Position.SUPPORT,
		"zhushui always supports"
	)
	_check_equal(
		_vote_for_race(actual, session.state, &"nanke"),
		SeatVoteState.Position.ABSENT,
		"nanke strike cannot be bought away"
	)
	_check_equal(
		_vote_for_race(actual, session.state, &"biyi"),
		SeatVoteState.Position.SUPPORT,
		"odd-month biyi half uses own relation"
	)
	session.state.month = 2
	var even_vote := session.vote_system.calculate_vote(
		session.state.draft_bill, session.context, false
	)
	_check_equal(
		_vote_for_race(even_vote, session.state, &"biyi"),
		SeatVoteState.Position.OPPOSE,
		"even-month biyi half replaces attitude"
	)
	session.free()


func _test_constitution_revision_threshold() -> void:
	var race := _make_race(&"majority", 3)
	race.fixed_seat_count = 3
	var group := _make_group(&"group", 1, 0)
	var initial := ConstitutionArticleDefinition.new()
	initial.id = &"center"
	initial.axis_id = &"race_axis"
	initial.is_initial = true
	var next := ConstitutionArticleDefinition.new()
	next.id = &"branch_one"
	next.axis_id = &"race_axis"
	next.level = 1
	next.direction = 1
	next.prerequisite_id = &"center"
	next.threshold_kind = ConstitutionArticleDefinition.ThresholdKind.RACE_SEAT_RATE
	next.threshold_target_id = &"majority"
	next.threshold_rate = 0.9
	var session := _make_session([race], [group], [], [initial, next])
	_check(
		session.constitution_system.can_revise(session.state, next),
		"90 percent threshold reads annual snapshot"
	)
	_check(session.revise_constitution(next), "valid one-step constitution revision succeeds")
	_check(
		not session.state.constitution.revision_available, "revision consumes annual opportunity"
	)
	_check(session.state.has_intervened, "constitution revision records intervention")
	session.free()


func _test_annual_settlement() -> void:
	var stance := _make_stance(Metric.Id.TRADE, MetricStanceDefinition.Direction.HIGHER, 100, 10)
	var race := _make_race(&"annual", 4)
	race.metric_stances = [stance]
	var groups: Array[InterestGroupDefinition] = [
		_make_group(&"a", 1, 0),
		_make_group(&"b", 1, 1),
	]
	var session := _make_session([race], groups)
	var race_state := session.state.get_race(&"annual")
	race_state.pending_trust_delta = 50.0
	var proposal := _make_proposal(&"b")
	var proposals: Array[ProposalInstance] = [proposal]
	session.parliament_system.record_authorized_proposal_slots(session.state, proposals)
	session.annual_settlement_system.settle_year(session.context)
	_check_equal(race_state.political_trust, 100.0, "annual trust is applied first")
	_check_equal(race_state.seat_count, 8, "new trust determines annual row size")
	_check_equal(session.state.seats.size(), 8, "whole parliament rebuilt with new rows")
	_check_equal(race_state.get_expectation(Metric.Id.TRADE), 110, "era expectation tightens last")
	_check_equal(
		session.state.last_annual_proposal_slot_counts[&"b"], 1, "annual slot ledger retained"
	)
	_check_equal(session.state.last_annual_source_shares[&"b"], 1.0, "annual source share retained")
	_check(
		session.state.annual_proposal_slot_counts.is_empty(), "new year slot ledger starts empty"
	)
	_check(session.state.constitution.revision_available, "one annual revision window opens")
	session.free()


func _test_collapse_routes() -> void:
	var system := CollapseSystem.new()
	var silent_state := RunState.new()
	silent_state.collapse_level = 99.0
	silent_state.pending_collapse_delta = 1.0
	system.settle_month(silent_state)
	_check(silent_state.silent_observation, "no-intervention collapse enters silent observation")
	for i in range(13):
		system.settle_month(silent_state)
	_check_equal(
		silent_state.ending_id, &"nothing_happens", "silent recovery reaches unique ending"
	)
	var failed_state := RunState.new()
	failed_state.collapse_level = 99.0
	system.record_intervention(failed_state, &"bill_submission", 1.0)
	failed_state.pending_collapse_delta = 1.0
	system.settle_month(failed_state)
	_check(failed_state.run_failed, "intervened collapse ends the term")
	var interrupted := RunState.new()
	interrupted.collapse_level = 100.0
	interrupted.silent_observation = true
	system.record_intervention(interrupted, &"constitution_revision", 1.0)
	_check(interrupted.run_failed, "intervention interrupts silent observation immediately")


func _test_flow_reaches_new_year() -> void:
	var stance := _make_stance(Metric.Id.WAGE, MetricStanceDefinition.Direction.HIGHER, 20, 5)
	var race := _make_race(&"flow", 2)
	race.metric_stances = [stance]
	var session := _make_session([race], [_make_group(&"group", 1, 0)])
	session.state.month = 12
	var race_state := session.state.get_race(&"flow")
	race_state.pending_trust_delta = 50.0
	session.advance_month()
	_check_equal(session.state.year, 2, "December flow enters next year")
	_check_equal(session.state.month, 1, "new year starts at first month")
	_check_equal(race_state.seat_count, 4, "flow runs trust and seats before new year")
	_check_equal(
		race_state.get_expectation(Metric.Id.WAGE), 25, "flow tightens expectation before new year"
	)
	session.free()


func _make_session(
	races: Array[RaceDefinition],
	groups: Array[InterestGroupDefinition],
	events: Array[EventDefinition] = [],
	articles: Array[ConstitutionArticleDefinition] = []
) -> RunSession:
	var session := RunSession.new()
	session.configure_content(races, groups, events, articles)
	session.automatic_draw_count = 0
	session.start_new_run()
	return session


func _make_race(id: StringName, seats: int) -> RaceDefinition:
	var result := RaceDefinition.new()
	result.id = id
	result.display_name = String(id)
	result.minimum_seats = 1
	result.initial_seats = seats
	result.maximum_seats = maxi(seats * 2, seats)
	return result


func _make_group(id: StringName, weight: int, order: int) -> InterestGroupDefinition:
	var result := InterestGroupDefinition.new()
	result.id = id
	result.display_name = String(id)
	result.base_column_weight = weight
	result.fixed_sort_order = order
	var proposal := ProposalDefinition.new()
	proposal.id = StringName("%s_proposal" % id)
	proposal.source_group_id = id
	proposal.affects_price = true
	result.proposal_definition = proposal
	return result


func _make_stance(
	metric: Metric.Id, direction: MetricStanceDefinition.Direction, target: int, step: int
) -> MetricStanceDefinition:
	var result := MetricStanceDefinition.new()
	result.metric = metric
	result.direction = direction
	result.initial_target = target
	result.annual_step = step
	return result


func _make_proposal(group_id: StringName) -> ProposalInstance:
	var result := ProposalInstance.new()
	result.definition_id = StringName("%s_card" % group_id)
	result.source_group_id = group_id
	return result


func _make_event(
	id: StringName, race_id: StringName, requirement: EventRequirementDefinition
) -> EventDefinition:
	var result := EventDefinition.new()
	result.id = id
	result.race_id = race_id
	result.requirements = [requirement]
	return result


func _vote_for_race(
	result: VoteResultState, state: RunState, race_id: StringName
) -> SeatVoteState.Position:
	for vote in result.seat_votes:
		for seat in state.seats:
			if seat.seat_id == vote.seat_id and seat.race_id == race_id:
				return vote.position
	return SeatVoteState.Position.ABSTAIN


func _check(condition: bool, message: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAILED: %s" % message)


func _check_equal(actual: Variant, expected: Variant, message: String) -> void:
	_check(actual == expected, "%s (actual=%s expected=%s)" % [message, actual, expected])
