extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_fixed_proposal_source_support(t)
	_test_donation_pool_spending_and_detection(t)
	_test_zhushui_intrinsic_support(t)
	_test_nanke_absence_is_submit_only(t)
	_test_nanke_constitution_strike_hook(t)
	_test_biyi_relation_switch(t)


func _test_fixed_proposal_source_support(t: BackendTestContext) -> void:
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


func _test_donation_pool_spending_and_detection(t: BackendTestContext) -> void:
	var race := t.make_race("donation")
	var group := t.make_group("group")
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.collapse_step = 3
	balance.donation_detection_probability = 1.0
	var session := t.make_session(
		[race], [group], t.make_seats(2, "donation"), [], balance
	)
	var first_seat := session.state.seats[0]
	var second_seat := session.state.seats[1]
	session.state.political_donation_pool = 10.0
	var rng_before_edit := session.random_system.rng.state
	t.check(session.vote_system.set_donation(session.context, first_seat, 3.0), "donation spends available pool")
	t.check(session.vote_system.set_donation(session.context, first_seat, 4.0), "donation draft can be edited")
	t.check(session.vote_system.set_donation(session.context, second_seat, 2.0), "a second donation can be drafted")
	t.check_equal(session.random_system.rng.state, rng_before_edit, "editing donation values performs no detection")
	t.check_equal(session.state.collapse_level, 0, "editing donation values adds no collapse")
	t.check(not session.state.has_submitted_bill, "editing donations is not a bill submission")
	t.check_approx(session.state.political_donation_pool, 4.0, "only final donation increments are charged")
	t.check_approx(session.state.vote_donations[first_seat.definition], 4.0, "allocation key is SeatDefinition")
	t.check(
		not session.vote_system.set_donation(session.context, first_seat, 20.0),
		"allocation cannot exceed remaining pool"
	)
	t.check_approx(session.state.political_donation_pool, 4.0, "failed overspend changes no pool")
	t.check_approx(session.state.vote_donations[first_seat.definition], 4.0, "failed overspend keeps allocation")
	var draft := DraftBillState.new()
	draft.proposals.append(t.make_proposal(group))
	var preview := session.vote_system.preview_vote(draft, session.context)
	t.check_equal(
		t.vote_for_race(preview, race).position,
		SeatVoteState.Position.SUPPORT,
		"allocated donation contributes to vote score"
	)
	session.state.draft_bill = draft
	var result := session.submit_draft()
	t.check(result.submitted, "non-empty draft is formally submitted")
	t.check_equal(session.state.collapse_level, 6, "submission detects each final donation with shared steps")
	t.check_equal(typeof(session.state.collapse_level), TYPE_INT, "donation collapse remains int")
	t.check(session.state.vote_donations.is_empty(), "vote completion clears final allocations")
	session.free()


func _test_zhushui_intrinsic_support(t: BackendTestContext) -> void:
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


func _test_nanke_absence_is_submit_only(t: BackendTestContext) -> void:
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


func _test_nanke_constitution_strike_hook(t: BackendTestContext) -> void:
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


func _test_biyi_relation_switch(t: BackendTestContext) -> void:
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
