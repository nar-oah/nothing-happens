extends RefCounted


func run(t) -> void:
	_test_race_seats_and_full_parliament(t)
	_test_authorization_stats_and_coloring(t)
	_test_positive_traits_and_merge(t)
	_test_draft_editing_and_vote(t)


func _test_race_seats_and_full_parliament(t) -> void:
	var races: Array[RaceDefinition] = [
		t.make_race(Race.ZHUSHUI),
		t.make_race(Race.NANKE),
		t.make_race(Race.BIYI),
		t.make_race(Race.YANO),
		t.make_race(Race.PEACH_BLOSSOM),
		t.make_race(Race.HUMAN),
	]
	var group := t.make_group(&"group", 1, 0)
	var groups: Array[InterestGroupDefinition] = [group]
	var session := t.make_session(races, groups, [], 20)

	t.check_equal(
		session.state.get_race(Race.NANKE).seat_count, 4, "equal trust gives Nanke four seats"
	)
	t.check_equal(
		session.state.get_race(Race.BIYI).seat_count, 4, "equal trust gives Biyi four seats"
	)
	t.check_equal(
		session.state.get_race(Race.YANO).seat_count, 4, "equal trust gives Yano four seats"
	)
	t.check_equal(
		session.state.get_race(Race.PEACH_BLOSSOM).seat_count,
		4,
		"equal trust gives Peach Blossom four seats"
	)
	t.check_equal(
		session.state.get_race(Race.HUMAN).seat_count, 4, "equal trust gives Human four seats"
	)
	t.check_equal(
		session.state.get_race(Race.ZHUSHUI).seat_count, 1, "Zhushui has one governing seat"
	)
	t.check_equal(session.state.seats.size(), 21, "twenty variable seats plus one Zhushui seat")

	var state := session.state
	state.get_race(Race.NANKE).political_trust = 100.0
	state.get_race(Race.BIYI).political_trust = 0.0
	state.get_race(Race.YANO).political_trust = 0.0
	state.get_race(Race.PEACH_BLOSSOM).political_trust = 0.0
	state.get_race(Race.HUMAN).political_trust = 0.0

	session.race_system.allocate_seats(
		state, session.balance, session.constitution_system, session.random_system
	)

	t.check_equal(
		state.get_race(Race.NANKE).seat_count, 16, "dominant trust receives all non-reserved seats"
	)
	t.check_equal(state.get_race(Race.BIYI).seat_count, 1, "minimum seat is preserved")
	session.free()


func _test_authorization_stats_and_coloring(t) -> void:
	var state := RunState.new()
	var parliament := ParliamentSystem.new()
	var random := RandomSystem.new()
	random.set_seed(7)

	var groups: Array[InterestGroupDefinition] = [
		t.make_group(&"a", 1, 0),
		t.make_group(&"b", 1, 1),
	]
	state.races = [RaceState.new(t.make_race(&"race"))]
	state.races[0].seat_count = 6

	parliament.rebuild_all_rows(state, groups)
	parliament.apply_annual_coloring(state, groups, random, 1.0)
	for seat in state.seats:
		t.check_equal(seat.actual_group_id, seat.base_group_id, "no slots restore base column")

	var proposal := t.make_proposal(&"b")
	var proposals: Array[ProposalInstance] = [proposal]
	parliament.record_authorized_proposal_slots(state, proposals)
	parliament.record_authorized_proposal_slots(state, proposals)
	t.check_equal(state.annual_proposal_slot_counts[&"b"], 2, "repeat law grants new slots")

	parliament.apply_annual_coloring(state, groups, random, 1.0)
	for seat in state.seats:
		t.check_equal(seat.actual_group_id, &"b", "source share colors across columns")


func _test_positive_traits_and_merge(t) -> void:
	var system := ProposalSystem.new()
	var state := RunState.new()

	var negative_base := t.make_proposal(&"guild")
	negative_base.base_effect.tax = 7
	var positive_a := t.make_proposal(&"guild")
	positive_a.positive_effect.wage = 10
	var positive_b := t.make_proposal(&"guild")
	positive_b.positive_effect.trade = 8

	state.proposal_hand = [negative_base, positive_a, positive_b]
	var mothers: Array[ProposalInstance] = [negative_base, positive_a, positive_b]
	var merged := system.merge_three(state, mothers, negative_base, positive_a)

	t.check(merged != null, "same-group three-to-one succeeds")
	t.check_equal(state.proposal_hand.size(), 1, "merge consumes three mothers")
	t.check_equal(merged.base_effect.tax, 7, "merge preserves chosen negative base")
	t.check_equal(merged.positive_effect.wage, 14, "discarded trait converts at configured ratio")
	t.check_equal(
		merged.positive_effect.non_zero_metrics().size(), 1, "merged card keeps one trait"
	)

	var generated := t.make_proposal(&"guild")
	var random := RandomSystem.new()
	random.set_seed(12)
	system.add_positive_trait(
		generated, 3, InflationSystem.new(), GameBalanceDefinition.new(), random
	)

	t.check_equal(
		generated.positive_effect.non_zero_metrics().size(), 1, "visitor trait has one metric"
	)
	var metric: Metric.Id = generated.positive_effect.non_zero_metrics()[0]
	t.check(
		generated.positive_effect.get_value(metric) * Metric.favorable_sign(metric) > 0,
		"visitor trait uses favorable direction"
	)
	t.check(
		(
			system.calculate_visit_probability(0.01, 0.5)
			> system.calculate_visit_probability(0.9, 0.5)
		),
		"weak group visits more often"
	)


func _test_draft_editing_and_vote(t) -> void:
	var race := t.make_race(&"workers")
	race.increase_wage = true
	var group := t.make_group(&"union", 1, 0)
	group.metric_stances = [t.make_stance(Metric.Id.WAGE, MetricStanceDefinition.Direction.HIGHER)]

	var races: Array[RaceDefinition] = [race]
	var groups: Array[InterestGroupDefinition] = [group]
	var session := t.make_session(races, groups, [], 3)
	session.state.metrics.wage = 50

	var proposal := t.make_proposal(&"union")
	proposal.base_effect.wage = 10
	session.state.proposal_hand.append(proposal)

	t.check(
		session.draft_bill_system.move_proposal_from_hand(session.state, 0), "move card to draft"
	)
	t.check_equal(session.state.proposal_hand.size(), 0, "hand loses drafted card")

	var preview := session.vote_system.preview_vote(session.state.draft_bill, session.context)
	t.check_equal(preview.support_count, 3, "members support movement toward expectation")
	t.check(preview.passed, "preview has parliamentary majority")

	var result := session.submit_draft()
	t.check(result.submitted and result.passed, "non-empty draft passes vote")
	t.check(session.state.has_intervened, "bill submission records intervention")
	t.check(session.state.active_bill != null, "passed draft becomes active law")
	t.check_equal(session.state.annual_proposal_slot_counts[&"union"], 1, "passed slot is recorded")

	var empty_result := session.submit_draft()
	t.check(not empty_result.submitted, "empty draft is not an intervention")
	session.free()
