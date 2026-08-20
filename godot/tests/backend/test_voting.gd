extends RefCounted


func run(t) -> void:
	_test_fixed_proposal_source_support(t)
	_test_donation_pool_spending_and_detection(t)
	_test_zhushui_intrinsic_support(t)
	_test_nanke_absence_is_submit_only(t)
	_test_nanke_constitution_strike_hook(t)
	_test_biyi_relation_switch(t)


func _test_fixed_proposal_source_support(t) -> void:
	var race := t.make_race("neutral")
	var group := t.make_group("source")
	var session := t.make_session([race], [group], t.make_seats(1, "support"))
	session.state.year = 8
	session.state.draft_bill.proposals = [t.make_proposal(group), t.make_proposal(group)]
	var result := session.vote_system.preview_vote(session.state.draft_bill, session.context)
	var vote := t.vote_for_race(result, race)
	t.check(vote != null, "vote maps directly to SeatState race Resource")
	t.check_approx(vote.breakdown[&"proposal_source"], 2.0, "each source proposal grants fixed support one")
	t.check_equal(vote.position, SeatVoteState.Position.SUPPORT, "two source cards cross support threshold")
	t.check_approx(session.balance.proposal_support, 1.0, "default proposal support is one")
	session.free()


func _test_donation_pool_spending_and_detection(t) -> void:
	var race := t.make_race("donation")
	var group := t.make_group("group")
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.donation_detection_probability = 0.0
	balance.donation_detection_collapse = 7.0
	var session := t.make_session(
		[race], [group], t.make_seats(1, "donation"), [], balance
	)
	var seat := session.state.seats[0]
	session.state.political_donation_pool = 5.0
	t.check(session.vote_system.set_donation(session.context, seat, 3.0), "donation spends available pool")
	t.check_approx(session.state.political_donation_pool, 2.0, "successful allocation deducts pool")
	t.check_approx(session.state.vote_donations[seat.definition], 3.0, "allocation key is SeatDefinition")
	t.check(
		not session.vote_system.set_donation(session.context, seat, 6.0),
		"allocation cannot exceed remaining pool"
	)
	t.check_approx(session.state.political_donation_pool, 2.0, "failed overspend changes no pool")
	t.check_approx(session.state.vote_donations[seat.definition], 3.0, "failed overspend keeps allocation")
	var preview := session.vote_system.preview_vote(DraftBillState.new(), session.context)
	t.check_equal(
		t.vote_for_race(preview, race).position,
		SeatVoteState.Position.SUPPORT,
		"allocated donation contributes to vote score"
	)
	session.state.donation_detection_probability = 1.0
	t.check(session.vote_system.set_donation(session.context, seat, 4.0), "allocation can be increased")
	t.check_approx(session.state.political_donation_pool, 1.0, "only incremental donation is charged")
	t.check_approx(session.state.pending_collapse_delta, 7.0, "certain detection adds configured collapse")
	session.vote_system.clear_donations(session.state)
	t.check(session.state.vote_donations.is_empty(), "vote completion clears allocations")
	session.free()


func _test_zhushui_intrinsic_support(t) -> void:
	var race := ZhushuiRaceDefinition.new()
	race.display_name = "zhushui"
	var session := t.make_session(
		[race], [t.make_group("group")], t.make_seats(1, "zhushui")
	)
	var result := session.vote_system.preview_vote(DraftBillState.new(), session.context)
	var vote := t.vote_for_race(result, race)
	t.check_equal(vote.position, SeatVoteState.Position.SUPPORT, "Zhushui subclass always supports")
	t.check(vote.breakdown.has(&"zhushui_intrinsic_support"), "intrinsic subclass adds its reason")
	session.free()


func _test_nanke_absence_is_submit_only(t) -> void:
	var race := NankeRaceDefinition.new()
	race.display_name = "nanke"
	var article := NankeConstitutionArticleDefinition.new()
	article.display_name = "sleep"
	article.race = race
	article.is_initial = true
	article.absence_probability = 1.0
	var session := t.make_session(
		[race], [t.make_group("group")], t.make_seats(1, "nanke"), [article]
	)
	var rng_before := session.random_system.rng.state
	var first_preview := session.vote_system.preview_vote(DraftBillState.new(), session.context)
	var second_preview := session.vote_system.preview_vote(DraftBillState.new(), session.context)
	t.check_equal(
		t.vote_for_race(first_preview, race).position,
		SeatVoteState.Position.ABSTAIN,
		"preview does not resolve Nanke absence"
	)
	t.check_equal(
		t.vote_for_race(second_preview, race).position,
		SeatVoteState.Position.ABSTAIN,
		"repeated preview is deterministic"
	)
	t.check_equal(session.random_system.rng.state, rng_before, "preview consumes no RNG")
	var actual := session.vote_system.calculate_vote(DraftBillState.new(), session.context, true)
	t.check_equal(
		t.vote_for_race(actual, race).position,
		SeatVoteState.Position.ABSENT,
		"submit resolves certain Nanke absence"
	)
	session.free()


func _test_nanke_constitution_strike_hook(t) -> void:
	var race := NankeRaceDefinition.new()
	race.display_name = "nanke workers"
	race.increase_wage = true
	var union := t.make_group("union")
	union.decrease_wage = true
	var article := NankeConstitutionArticleDefinition.new()
	article.display_name = "strike constitution"
	article.race = race
	article.is_initial = true
	article.absence_probability = 0.0
	article.strike_enabled = true
	article.strike_group = union
	var session := t.make_session(
		[race], [union], t.make_seats(1, "strike"), [article]
	)
	var proposal := t.make_proposal(union)
	proposal.base_effect.wage = -10
	var draft := DraftBillState.new()
	draft.proposals.append(proposal)
	var result := session.vote_system.preview_vote(draft, session.context)
	var vote := t.vote_for_race(result, race)
	t.check_equal(vote.position, SeatVoteState.Position.OPPOSE, "article subclass overrides strike vote")
	t.check(vote.breakdown.has(&"nanke_strike"), "article hook records strike reason")
	session.free()


func _test_biyi_relation_switch(t) -> void:
	var race := BiyiRaceDefinition.new()
	race.display_name = "biyi"
	var article := BiyiConstitutionArticleDefinition.new()
	article.display_name = "biyi article"
	article.race = race
	article.is_initial = true
	var session := t.make_session(
		[race], [t.make_group("group")], t.make_seats(1, "biyi"), [article]
	)
	var seat := session.state.seats[0]
	seat.odd_month_relation = 2.0
	seat.even_month_relation = -2.0
	session.state.month = 1
	var odd := session.vote_system.preview_vote(DraftBillState.new(), session.context)
	t.check_equal(t.vote_for_race(odd, race).position, SeatVoteState.Position.SUPPORT, "odd half supports")
	t.check_approx(
		t.vote_for_race(odd, race).breakdown[&"biyi_half_relation"], 2.0,
		"odd half supplies odd relation"
	)
	session.state.month = 2
	var even := session.vote_system.preview_vote(DraftBillState.new(), session.context)
	t.check_equal(t.vote_for_race(even, race).position, SeatVoteState.Position.OPPOSE, "even half opposes")
	t.check_approx(
		t.vote_for_race(even, race).breakdown[&"biyi_half_relation"], -2.0,
		"even half supplies even relation"
	)
	session.free()
