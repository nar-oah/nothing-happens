extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_resource_identity(t)
	_test_group_stance_and_generated_proposal(t)
	_test_proposal_gameplay_equivalence(t)
	_test_duplicate_equivalent_matching(t)
	_test_positive_trait_and_donation_choice(t)
	_test_pending_choice_blocks_submission(t)
	_test_merge_uses_group_resource_identity(t)
	_test_resource_keyed_annual_sources_and_stable_order(t)
	_test_failed_draft_does_not_record_sources(t)
	_test_visit_probability_comes_from_race_state(t)


func _test_resource_identity(t: BackendTestContext) -> void:
	var race := t.make_race("same name")
	var other_resource := t.make_race("same name")
	var group := t.make_group("group")
	var definitions := t.make_seats(3, "identity")
	var session := t.make_session([race], [group], definitions)

	var race_state := session.state.get_race(race)
	t.check(race_state != null, "RunState resolves a race by its Resource")
	t.check(race_state.definition == race, "RaceState retains the exact RaceDefinition")
	t.check(session.state.get_race(other_resource) == null, "matching display text is not identity")
	t.check_equal(session.state.seats.size(), definitions.size(), "one permanent state per seat")
	for index in range(definitions.size()):
		t.check(
			session.state.seats[index].definition == definitions[index],
			"SeatState retains its exact SeatDefinition"
		)
		t.check(session.state.seats[index].race == race, "seat race is a direct Resource")
	session.free()


func _test_group_stance_and_generated_proposal(t: BackendTestContext) -> void:
	var group := t.make_group("guild")
	group.decrease_tax = true
	group.decrease_wage = true
	t.check_equal(group.get_stance(Metric.Id.TAX), Metric.Direction.LOWER, "tax stance is lower")
	t.check_equal(group.get_stance(Metric.Id.WAGE), Metric.Direction.LOWER, "wage stance is lower")
	t.check_equal(group.get_stance(Metric.Id.TRADE), Metric.Direction.NONE, "unset stance is none")
	t.check_equal(group.get_stance_metrics().size(), 2, "bool stances enumerate both metrics")

	var balance := GameBalanceDefinition.new()
	balance.proposal_negative_magnitude_min = 10
	balance.proposal_negative_magnitude_max = 10
	balance.proposal_lag_months_min = 4
	balance.proposal_lag_months_max = 4
	balance.proposal_magnitude_growth_per_year = 0.10
	var state := RunState.new()
	state.year = 2
	var random := RandomSystem.new()
	random.set_seed(4)
	var proposal := ProposalSystem.new().generate_proposal(
		group, state, InflationSystem.new(), balance, random
	)

	t.check(proposal != null, "group stance directly generates a proposal")
	t.check(proposal.source_group == group, "proposal stores its source Resource")
	t.check_equal(proposal.base_effect.tax, 11, "tax downside uses compounded magnitude")
	t.check_equal(proposal.base_effect.wage, -11, "wage downside uses compounded magnitude")
	t.check_equal(proposal.base_effect.trade, 0, "unconcerned metrics stay empty")
	t.check_equal(proposal.lag_months, 4, "lag month range is balance-driven")


func _test_proposal_gameplay_equivalence(t: BackendTestContext) -> void:
	var group := t.make_group("equivalent source")
	var proposal := t.make_proposal(group)
	proposal.base_effect.tax = 8
	proposal.positive_effect.wage = 5
	proposal.lag_months = 4
	proposal.donation_offer = 5.0
	proposal.bonus_choice_resolved = true
	proposal.positive_trait_accepted = true
	var system := ProposalSystem.new()
	var equivalent := proposal.copy()
	t.check(proposal != equivalent, "equivalent proposals may be different runtime instances")
	t.check(
		system.are_gameplay_equivalent(proposal, equivalent),
		"copied gameplay content is equivalent"
	)
	equivalent.lag_months = 5
	t.check(
		not system.are_gameplay_equivalent(proposal, equivalent),
		"lag months participate in gameplay equivalence"
	)
	equivalent = proposal.copy()
	equivalent.positive_trait_accepted = false
	t.check(
		not system.are_gameplay_equivalent(proposal, equivalent),
		"positive trait final state participates in gameplay equivalence"
	)
	equivalent = proposal.copy()
	equivalent.base_effect.tax += 1
	t.check(
		not system.are_gameplay_equivalent(proposal, equivalent),
		"metric effects participate in gameplay equivalence"
	)
	var ordinary := t.make_proposal(group)
	ordinary.base_effect.tax = 8
	ordinary.lag_months = 4
	var converted := ordinary.copy()
	converted.donation_offer = 20.0
	converted.positive_trait_accepted = false
	t.check(
		system.are_gameplay_equivalent(ordinary, converted),
		"settled bonus bookkeeping does not change future gameplay"
	)
	var stale_choice_flag := ordinary.copy()
	stale_choice_flag.bonus_choice_resolved = false
	t.check(
		system.are_gameplay_equivalent(ordinary, stale_choice_flag),
		"a choice flag without a positive trait has no future gameplay effect"
	)
	var pending := ordinary.copy()
	pending.positive_effect.wage = 5
	pending.bonus_choice_resolved = false
	pending.positive_trait_accepted = false
	pending.donation_offer = 10.0
	var different_offer := pending.copy()
	different_offer.donation_offer = 11.0
	t.check(
		not system.are_gameplay_equivalent(pending, different_offer),
		"an actionable donation choice participates in equivalence"
	)
	var accepted := pending.copy()
	accepted.bonus_choice_resolved = true
	accepted.positive_trait_accepted = true
	var accepted_with_historical_offer := accepted.copy()
	accepted_with_historical_offer.donation_offer = 99.0
	t.check(
		system.are_gameplay_equivalent(accepted, accepted_with_historical_offer),
		"a resolved accepted trait ignores its historical donation offer"
	)


func _test_duplicate_equivalent_matching(t: BackendTestContext) -> void:
	var proposal := t.make_proposal(t.make_group("duplicate source"))
	proposal.base_effect.trade = -7
	proposal.lag_months = 3
	var replacement := proposal.copy()
	var matches := ProposalSystem.new().match_equivalent_proposals(
		[proposal.copy(), proposal.copy()], [replacement]
	)
	t.check_equal(matches.size(), 2, "matching preserves every saved proposal slot")
	t.check(matches[0] == replacement, "an equivalent hand proposal fills the first slot")
	t.check(matches[1] == null, "one hand instance cannot fill a duplicate second slot")


func _test_positive_trait_and_donation_choice(t: BackendTestContext) -> void:
	var system := ProposalSystem.new()
	var inflation := InflationSystem.new()
	var balance := GameBalanceDefinition.new()
	balance.proposal_positive_magnitude_min = 10
	balance.proposal_positive_magnitude_max = 10
	balance.proposal_magnitude_growth_per_year = 0.10
	balance.donation_per_positive_point = 2.0
	var random := RandomSystem.new()
	random.set_seed(8)

	var accepted := ProposalInstance.new()
	system.add_positive_trait(accepted, 2, inflation, balance, random)
	var accepted_metric := accepted.get_positive_metric() as Metric.Id
	t.check_equal(
		absi(accepted.positive_effect.get_value(accepted_metric)), 11,
		"positive trait compounds by proposal era growth"
	)
	t.check_approx(accepted.donation_offer, 22.0, "offer derives from positive magnitude")
	var accepted_state := RunState.new()
	accepted_state.proposal_hand.append(accepted)
	t.check(
		not DraftBillSystem.new().move_proposal_from_hand(accepted_state, 0),
		"unresolved positive choice cannot enter a draft"
	)
	t.check(system.resolve_bonus_choice(accepted_state, accepted, true), "trait can be accepted")
	t.check(accepted.has_positive_trait(), "accepting preserves the positive trait")
	t.check_approx(accepted_state.political_donation_pool, 0.0, "accepting grants no donation")
	t.check(
		not system.resolve_bonus_choice(accepted_state, accepted, false),
		"the bonus choice cannot be resolved twice"
	)

	var converted := ProposalInstance.new()
	system.add_positive_trait(converted, 2, inflation, balance, random)
	var converted_state := RunState.new()
	converted_state.proposal_hand.append(converted)
	t.check(system.resolve_bonus_choice(converted_state, converted, false), "trait can be converted")
	t.check(not converted.has_positive_trait(), "conversion clears the trait")
	t.check_approx(converted_state.political_donation_pool, 22.0, "conversion funds the pool")


func _test_merge_uses_group_resource_identity(t: BackendTestContext) -> void:
	var group := t.make_group("guild")
	var base := t.make_proposal(group)
	base.base_effect.tax = 7
	var positive_a := t.make_proposal(group)
	positive_a.positive_effect.wage = 10
	var positive_b := t.make_proposal(group)
	positive_b.positive_effect.trade = 8
	var state := RunState.new()
	state.proposal_hand = [base, positive_a, positive_b]
	var balance := GameBalanceDefinition.new()
	balance.merge_conversion_ratio = 0.5
	balance.merge_upgrade_exponent = 1.0
	var merged := ProposalSystem.new().merge_three(
		state, [base, positive_a, positive_b], base, balance, positive_a
	)

	t.check(merged != null, "three proposals with one source Resource merge")
	t.check_equal(state.proposal_hand.size(), 1, "merge consumes its three mothers")
	t.check(merged.source_group == group, "merged proposal keeps source Resource")
	t.check_equal(merged.base_effect.tax, 7, "merge keeps selected negative base")
	t.check_equal(merged.positive_effect.wage, 14, "discarded trait converts by balance ratio")
	t.check(not state.has_submitted_bill, "proposal synthesis does not record a bill submission")

	var pending := t.make_proposal(group)
	pending.positive_effect.wage = 5
	pending.bonus_choice_resolved = false
	pending.positive_trait_accepted = false
	var plain_a := t.make_proposal(group)
	var plain_b := t.make_proposal(group)
	var pending_state := RunState.new()
	pending_state.proposal_hand = [pending, plain_a, plain_b]
	t.check(
		ProposalSystem.new().merge_three(
			pending_state, [pending, plain_a, plain_b], plain_a, balance, pending
		) == null,
		"merge cannot consume an unresolved positive choice"
	)
	t.check_equal(pending_state.proposal_hand.size(), 3, "rejected merge keeps every mother")


func _test_pending_choice_blocks_submission(t: BackendTestContext) -> void:
	var race := t.make_race("pending choice")
	var group := t.make_group("pending source")
	var session := t.make_session([race], [group], t.make_seats(1, "pending"))
	var proposal := t.make_proposal(group)
	proposal.positive_effect.tax = -5
	proposal.donation_offer = 5.0
	proposal.bonus_choice_resolved = false
	proposal.positive_trait_accepted = false
	session.state.draft_bill.proposals.append(proposal)
	t.check(
		not session.draft_bill_system.is_ready_to_submit(session.context, session.state.draft_bill),
		"draft with unresolved positive choice is not ready"
	)
	var result := session.submit_draft()
	t.check(not result.submitted, "unresolved positive choice cannot be submitted")
	t.check(not session.state.has_submitted_bill, "rejected pending choice records no submission")
	session.free()


func _test_resource_keyed_annual_sources_and_stable_order(t: BackendTestContext) -> void:
	var first := t.make_group("same", 1)
	var second := t.make_group("same", 1)
	var parliament := ParliamentSystem.new()
	var allocation := parliament.allocate_base_columns(3, [first, second])
	t.check_equal(allocation[first], 2, "array order wins an equal remainder")
	t.check_equal(allocation[second], 1, "later equal group receives the smaller share")
	var reversed := parliament.allocate_base_columns(3, [second, first])
	t.check_equal(reversed[second], 2, "reversing the array reverses the stable tie")

	var state := RunState.new()
	parliament.record_authorized_proposal_slots(state, [t.make_proposal(second)])
	parliament.record_authorized_proposal_slots(state, [t.make_proposal(second)])
	t.check(state.annual_proposal_slot_counts.has(second), "annual count uses group Resource key")
	t.check(not state.annual_proposal_slot_counts.has(first), "same display name does not alias keys")
	t.check_equal(state.annual_proposal_slot_counts[second], 2, "enacted slots accumulate")
	t.check_approx(parliament.get_annual_source_shares(state)[second], 1.0, "share keeps key")


func _test_failed_draft_does_not_record_sources(t: BackendTestContext) -> void:
	var race := t.make_race("neutral")
	var seated := t.make_group("seated")
	var source := t.make_group("source")
	var session := t.make_session([race], [seated, source], t.make_seats(1, "failure"))
	var proposal := t.make_proposal(source)
	session.state.draft_bill.proposals.append(proposal)
	var result := session.submit_draft()
	t.check(result.submitted and not result.passed, "neutral draft fails its vote")
	t.check(session.state.has_submitted_bill, "failed vote still records a real submission")
	t.check_equal(session.state.collapse_level, 0, "submitting a bill does not itself add collapse")
	t.check(session.state.annual_proposal_slot_counts.is_empty(), "failed draft records no source")
	var enacted := DraftBillState.new()
	enacted.proposals.append(proposal)
	session.enact_bill(enacted)
	t.check_equal(
		session.state.annual_proposal_slot_counts[source], 1,
		"enactment records source with Resource key"
	)
	session.free()


func _test_visit_probability_comes_from_race_state(t: BackendTestContext) -> void:
	var race := t.make_race("visitor")
	var group := t.make_group("visiting group")
	group.decrease_price = true
	var article := t.make_article(race, true, 0.0, 1.0)
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.proposal_negative_magnitude_min = 4
	balance.proposal_negative_magnitude_max = 4
	balance.proposal_positive_magnitude_min = 3
	balance.proposal_positive_magnitude_max = 3
	var session := t.make_session(
		[race], [group], t.make_seats(1, "visit"), [article], balance
	)
	var visits := session.proposal_system.resolve_active_visits(session.context)
	t.check_equal(visits.size(), 1, "visit probability one creates a visit regardless of seat ratio")
	t.check(visits[0].source_group == group, "successful visit chooses the seat's group Resource")
	t.check(visits[0].has_positive_trait(), "active visit receives a positive trait")
	session.state.get_race(race).visit_probability = 0.0
	t.check_equal(
		session.proposal_system.resolve_active_visits(session.context).size(), 0,
		"visit probability zero prevents visits"
	)
	session.free()
