extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_fixed_proposal_source_support(t)
	_test_donation_pool_spending_and_detection(t)
	_test_nanke_variant_absence_is_submit_only(t)
	_test_strike_effect_locks_absent(t)
	_test_biyi_variant_relation_switch(t)


func _test_fixed_proposal_source_support(t: BackendTestContext) -> void:
	var race := t.make_race("neutral")
	var group := t.make_group("source")
	var session := t.make_session([race], [group], t.make_seats(1, "support"))
	session.state.draft_bill.proposals = [t.make_proposal(group), t.make_proposal(group)]
	var result := session.vote_system.preview_vote(session.state.draft_bill, session.context)
	var vote := t.vote_for_race(result, race)
	t.check(vote != null, "vote maps directly to canonical race Resource")
	t.check_approx(vote.breakdown[&"proposal_source"], 2.0, "each source proposal grants fixed support")
	t.check_equal(vote.position, SeatVoteState.Position.SUPPORT, "two source cards cross support threshold")
	session.free()


func _test_donation_pool_spending_and_detection(t: BackendTestContext) -> void:
	var race := t.make_race("donation")
	var group := t.make_group("group")
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.collapse_step = 3
	balance.donation_detection_probability = 0.0
	var article := t.make_article(race)
	var detection := DonationDetectionEffect.new()
	detection.probability = 1.0
	article.effects.append(detection)
	var session := t.make_session([race], [group], t.make_seats(2, "donation"), [article], balance)
	var first_seat := session.state.seats[0]
	var second_seat := session.state.seats[1]
	session.state.political_donation_pool = 10.0
	t.check(session.vote_system.set_donation(session.context, first_seat, 4.0), "donation spends pool")
	t.check(session.vote_system.set_donation(session.context, second_seat, 2.0), "second donation spends pool")
	t.check_approx(session.state.political_donation_pool, 4.0, "only allocated donations are charged")
	var detected := session.vote_system.resolve_donation_detection(session.context)
	t.check_equal(detected, 2, "DonationDetectionEffect overrides detection probability")
	t.check_equal(session.state.collapse_level, 6, "each detected donation adds collapse")
	session.free()


func _test_nanke_variant_absence_is_submit_only(t: BackendTestContext) -> void:
	var canonical := NankeRaceDefinition.new()
	canonical.display_name = "nanke"
	var sleeping := NankeRaceDefinition.new()
	sleeping.display_name = "nanke sleeping"
	sleeping.absence_probability = 1.0
	var article := t.make_article(canonical)
	var modify := ModifyRaceEffect.new()
	modify.target_races = [canonical]
	modify.source_races = [sleeping]
	article.effects.append(modify)
	var session := t.make_session([canonical], [t.make_group("group")], t.make_seats(1, "nanke"), [article])
	t.check(session.state.get_race(canonical).active_definition == sleeping, "Nanke constitution selects active race variant")
	var rng_before := session.random_system.rng.state
	var preview := session.vote_system.preview_vote(DraftBillState.new(), session.context)
	t.check_equal(t.vote_for_race(preview, canonical).position, SeatVoteState.Position.ABSTAIN, "preview does not resolve random absence")
	t.check_equal(session.random_system.rng.state, rng_before, "preview consumes no RNG")
	var actual := session.vote_system.calculate_vote(DraftBillState.new(), session.context, true)
	t.check_equal(t.vote_for_race(actual, canonical).position, SeatVoteState.Position.ABSENT, "submit resolves variant absence")
	session.free()


func _test_strike_effect_locks_absent(t: BackendTestContext) -> void:
	var race := NankeRaceDefinition.new()
	race.display_name = "workers"
	var union := t.make_group("union")
	union.decrease_employment = true
	var article := t.make_article(race)
	var strike := StrikeEffect.new()
	strike.interest_group = union
	strike.races = [race]
	strike.metric = Metric.Id.EMPLOYMENT
	article.effects.append(strike)
	var session := t.make_session([race], [union], t.make_seats(1, "strike"), [article])
	var proposal := t.make_proposal(union)
	proposal.base_effect.employment = -10
	var draft := DraftBillState.new()
	draft.proposals.append(proposal)
	var result := session.vote_system.preview_vote(draft, session.context)
	var vote := t.vote_for_race(result, race)
	t.check_equal(vote.position, SeatVoteState.Position.ABSENT, "strike locks affected seat to absent")
	t.check(vote.breakdown.has(&"constitution_strike"), "strike effect records constitution reason")
	session.free()


func _test_biyi_variant_relation_switch(t: BackendTestContext) -> void:
	var canonical := BiyiRaceDefinition.new()
	canonical.display_name = "biyi"
	var yin_yang := BiyiRaceDefinition.new()
	yin_yang.display_name = "biyi yin-yang"
	yin_yang.yin_yang_enabled = true
	var article := t.make_article(canonical)
	var modify := ModifyRaceEffect.new()
	modify.target_races = [canonical]
	modify.source_races = [yin_yang]
	article.effects.append(modify)
	var session := t.make_session([canonical], [t.make_group("group")], t.make_seats(1, "biyi"), [article])
	var seat := session.state.seats[0]
	seat.odd_month_relation = 2.0
	seat.even_month_relation = -2.0
	session.state.month = 1
	var odd := session.vote_system.preview_vote(DraftBillState.new(), session.context)
	t.check_equal(t.vote_for_race(odd, canonical).position, SeatVoteState.Position.SUPPORT, "active Biyi variant uses odd relation")
	session.state.month = 2
	var even := session.vote_system.preview_vote(DraftBillState.new(), session.context)
	t.check_equal(t.vote_for_race(even, canonical).position, SeatVoteState.Position.OPPOSE, "active Biyi variant uses even relation")
	session.free()
