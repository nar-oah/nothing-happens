extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")
const YinYangRuleDefinitionScript = preload("res://definitions/yin_yang_rule_definition.gd")


func run(t: BackendTestContext) -> void:
	_test_fixed_proposal_source_support(t)
	_test_planned_policy_projection_drives_support(t)
	_test_zhushui_support_is_always_99(t)
	_test_submit_donations_are_one_shot(t)
	_test_absent_and_non_bribable_seats_reject_donations(t)
	_test_nanke_monthly_absence_is_stable(t)
	_test_strike_effect_locks_absent(t)
	_test_peach_weighted_race_vote(t)
	_test_parliament_visual_only_hides_absent(t)
	_test_global_yin_yang_rule(t)
	_test_biyi_portrait_switch(t)


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


func _test_planned_policy_projection_drives_support(t: BackendTestContext) -> void:
	var race := t.make_race("projection race")
	race.increase_production = true
	var source := t.make_group("projection source")
	var neutral := t.make_group("projection neutral")
	var effect := PolicyEffect.new()
	effect.target_metric = Metric.Id.PRODUCTION
	effect.formula = PolicyEffect.Formula.METRIC_GAP
	effect.source_a = Metric.Id.TAX
	effect.source_b = Metric.Id.INVESTMENT
	var policy := PolicyDefinition.new()
	policy.display_name = "future policy"
	policy.effects.append(effect)
	var article := t.make_article(race)
	article.policies.append(policy)
	var session := t.make_session(
		[race], [source, neutral], t.make_seats(1, "projection"), [article]
	)
	session.state.seats[0].actual_group = neutral
	session.state.get_race(race).expectation_targets[Metric.Id.PRODUCTION] = 105
	var policy_only := DraftBillState.new()
	policy_only.policies.append(PolicyState.new(policy, 0))
	var before := session.vote_system.preview_vote(policy_only, session.context)
	t.check_equal(
		t.vote_for_race(before, race).position,
		SeatVoteState.Position.ABSTAIN,
		"a policy with no calculated effect does not affect the vote projection"
	)
	var proposal := t.make_proposal(source)
	proposal.base_effect.tax = 10
	var draft := DraftBillState.new()
	draft.proposals.append(proposal)
	draft.policies.append(PolicyState.new(policy, 1))
	var result := session.vote_system.preview_vote(draft, session.context)
	var vote := t.vote_for_race(result, race)
	t.check_approx(
		vote.breakdown[&"race_expectation"],
		session.balance.race_expectation_score,
		"the planned policy improvement counts toward race support"
	)
	t.check_approx(vote.breakdown[&"proposal_source"], 0.0, "group support does not mask the policy result")
	t.check_equal(vote.position, SeatVoteState.Position.SUPPORT, "the planned policy projection can make the seat support")
	var preview := UiSerializer.new().draft_preview(session)
	t.check_equal(preview["pure_proposal_target"]["tax"], 100, "session draft remains empty in serializer baseline")
	session.state.draft_bill = draft
	preview = UiSerializer.new().draft_preview(session)
	t.check_equal(preview["pure_proposal_target"]["tax"], 110, "UI preview includes the proposal gap")
	t.check_equal(preview["projected_metrics"]["production"], 110, "UI preview applies policies at their planned delays")
	t.check_equal(preview["vote"]["seat_votes"][0]["position"], int(SeatVoteState.Position.SUPPORT), "serialized preview uses the same planned projection")
	session.free()


func _test_zhushui_support_is_always_99(t: BackendTestContext) -> void:
	var race := ZhushuiRaceDefinition.new()
	race.display_name = "zhushui"
	var group := t.make_group("opposition")
	var article := t.make_article(race)
	var modifier := InterestGroupVoteModifierEffect.new()
	modifier.interest_groups = [group]
	modifier.support_modifier = -250.0
	article.effects.append(modifier)
	var session := t.make_session([race], [group], [t.make_seat("zhushui", race)], [article])
	var seat := session.state.seats[0]
	seat.actual_group = group
	var result := session.vote_system.preview_vote(session.state.draft_bill, session.context)
	var vote := t.vote_for_race(result, race)
	t.check(vote.breakdown.has(&"constitution_group_modifier"), "Zhushui keeps prior vote effects")
	t.check_equal(vote.score, 99.0, "Zhushui final support score is exactly 99")
	t.check_equal(vote.position, SeatVoteState.Position.SUPPORT, "Zhushui remains locked to support")
	var preview := UiSerializer.new().draft_preview(session)
	t.check_equal(
		preview["vote"]["seat_votes"][0]["score"],
		99.0,
		"serialized Zhushui preview support stays exactly 99"
	)
	session.free()


func _test_submit_donations_are_one_shot(t: BackendTestContext) -> void:
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
	session.state.political_donation_pool = 10.0
	session.balance.proposal_support = 0.0
	session.state.draft_bill.proposals.append(t.make_proposal(group))
	var preview := session.vote_system.preview_vote(session.state.draft_bill, session.context)
	t.check_approx(preview.seat_votes[0].score, 0.0, "ordinary preview excludes unsent donations")
	t.check(session.vote_system.is_bribe_allowed(session.context, preview.seat_votes[0]), "ordinary abstaining seat can receive a donation")
	t.check_approx(session.vote_system.get_bribe_cost(session.context, preview.seat_votes[0]), 1.0, "bribe cost reaches the support threshold")
	var plan := session.vote_system.validate_bribes(session.state.draft_bill, session.context, [0, 1])
	t.check(plan["ok"], "valid one-shot donations pass submission validation")
	t.check_approx(session.state.political_donation_pool, 10.0, "preview and validation never charge the pool")
	var rejected := session.submit_draft([0, 0])
	t.check(not rejected.submitted, "submit rejects duplicate bribed seat indices")
	t.check_approx(session.state.political_donation_pool, 10.0, "rejected donation payload is atomic")
	var result := session.submit_draft([0, 1])
	t.check(result.submitted and result.passed, "submitted donations temporarily secure both votes")
	t.check_approx(result.seat_votes[0].breakdown[&"political_donation"], 1.0, "submitted vote records its temporary donation reason")
	t.check_approx(session.state.political_donation_pool, 8.0, "only bill submission charges donations")
	t.check_equal(session.state.collapse_level, 6, "each detected donation adds collapse")
	session.free()


func _test_absent_and_non_bribable_seats_reject_donations(t: BackendTestContext) -> void:
	var nanke := NankeRaceDefinition.new()
	nanke.display_name = "absent"
	nanke.absence_probability = 1.0
	var group := t.make_group("group")
	var absent_session := t.make_session([nanke], [group], t.make_seats(1, "absent"))
	t.check(absent_session.advance_month(), "first operable month initializes absence")
	var absent_vote := absent_session.vote_system.preview_vote(
		DraftBillState.new(), absent_session.context
	).seat_votes[0]
	t.check_equal(absent_vote.position, SeatVoteState.Position.ABSENT, "monthly Nanke absence serializes as ABSENT")
	t.check(not absent_session.vote_system.is_bribe_allowed(absent_session.context, absent_vote), "ABSENT cannot receive a donation")
	var absent_payload := UiSerializer.new().vote_result(
		absent_session.vote_system.preview_vote(DraftBillState.new(), absent_session.context),
		absent_session
	)
	t.check_equal(absent_payload["seat_votes"][0]["position"], int(SeatVoteState.Position.ABSENT), "Nanke serializes through the unified ABSENT position")
	absent_session.free()
	var configured_yanou: RaceDefinition = load("res://data/races/偃偶.tres")
	t.check(not configured_yanou.political_donations_allowed, "configured Yanou race disables political donations")
	var yanou := t.make_race("non-bribable")
	yanou.political_donations_allowed = false
	var yanou_session := t.make_session([yanou], [group], t.make_seats(1, "yanou"))
	var yanou_vote := yanou_session.vote_system.preview_vote(
		DraftBillState.new(), yanou_session.context
	).seat_votes[0]
	t.check(not yanou_session.vote_system.is_bribe_allowed(yanou_session.context, yanou_vote), "authoritative Yanou rule rejects donations")
	t.check(not yanou_session.vote_system.validate_bribes(DraftBillState.new(), yanou_session.context, [0])["ok"], "illegal donation payload is rejected")
	yanou_session.free()


func _test_nanke_monthly_absence_is_stable(t: BackendTestContext) -> void:
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
	t.check(session.advance_month(), "Nanke first operable month starts")
	t.check(session.state.seats[0].absent_this_month, "active Nanke variant rolls absence once at month start")
	var rng_before := session.random_system.rng.state
	var preview := session.vote_system.preview_vote(DraftBillState.new(), session.context)
	t.check_equal(t.vote_for_race(preview, canonical).position, SeatVoteState.Position.ABSENT, "preview uses fixed monthly absence")
	var second_preview := session.vote_system.preview_vote(DraftBillState.new(), session.context)
	t.check_equal(t.vote_for_race(second_preview, canonical).position, SeatVoteState.Position.ABSENT, "repeated preview keeps the same absence")
	t.check_equal(session.random_system.rng.state, rng_before, "preview consumes no RNG")
	session.state.draft_bill.proposals.append(t.make_proposal(session.interest_groups[0]))
	var actual := session.submit_draft()
	t.check(actual.submitted, "an absent Nanke vote can be formally submitted")
	t.check_equal(t.vote_for_race(actual, canonical).position, SeatVoteState.Position.ABSENT, "submit reuses fixed monthly absence")
	t.check_equal(session.random_system.rng.state, rng_before, "formal submit does not reroll Nanke absence")
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
	var serialized := UiSerializer.new().vote_result(result, session)
	t.check_equal(serialized["seat_votes"][0]["position"], int(SeatVoteState.Position.ABSENT), "strike serializes through the unified ABSENT position")
	t.check(not serialized["seat_votes"][0]["bribe_allowed"], "strike absence is not bribable in the preview DTO")
	session.free()


func _test_peach_weighted_race_vote(t: BackendTestContext) -> void:
	for maximum in [2, 4, 8]:
		var definition := PeachRaceDefinition.new()
		definition.max_elder_weight = int(maximum)
		var expected: Array[int] = []
		var current: int = int(maximum)
		for _index in range(5):
			expected.append(current)
			current = maxi(ceili(float(current) / 2.0), 1)
		var actual: Array[int] = []
		for index in range(5):
			actual.append(definition.get_vote_weight(index))
		t.check_equal(actual, expected, "Peach max %s halves elder weights with a floor of one" % maximum)
	var peach := PeachRaceDefinition.new()
	peach.display_name = "peach"
	peach.max_elder_weight = 2
	var supporter := t.make_group("supporter")
	var neutral := t.make_group("neutral")
	var absent_group := t.make_group("striker")
	absent_group.decrease_employment = true
	var article := t.make_article(peach)
	var strike := StrikeEffect.new()
	strike.interest_group = absent_group
	strike.races = [peach]
	strike.metric = Metric.Id.EMPLOYMENT
	article.effects.append(strike)
	var session := t.make_session(
		[peach], [supporter, neutral, absent_group], t.make_seats(3, "peach"), [article]
	)
	session.state.seats[0].actual_group = supporter
	session.state.seats[1].actual_group = neutral
	session.state.seats[2].actual_group = neutral
	var proposal := t.make_proposal(supporter)
	proposal.base_effect.employment = -1
	var draft := DraftBillState.new()
	draft.proposals.append(proposal)
	var tied := session.vote_system.preview_vote(draft, session.context)
	t.check_equal(tied.seat_votes[0].vote_weight, 2, "first Peach seat receives maximum elder weight")
	t.check_equal(tied.seat_votes[1].vote_weight, 1, "second Peach seat receives halved weight")
	t.check_equal(tied.seat_votes[0].race_support_weight, 2, "Peach support numerator sums supporting weights")
	t.check_equal(tied.seat_votes[0].race_present_weight, 4, "all present Peach weights form the denominator")
	t.check(not tied.passed, "exactly half of Peach weight does not pass the race vote")
	session.state.seats[2].actual_group = absent_group
	var reduced := session.vote_system.preview_vote(draft, session.context)
	t.check_equal(reduced.seat_votes[2].position, SeatVoteState.Position.ABSENT, "striking Peach seat uses ABSENT")
	t.check_equal(reduced.seat_votes[0].race_present_weight, 3, "absent Peach weight leaves the denominator")
	t.check(reduced.passed, "support strictly over half of present Peach weight passes the race vote")
	t.check_equal(reduced.support_count, 1, "Peach consensus contributes one final race vote")
	var serialized := UiSerializer.new().vote_result(reduced, session)
	t.check_equal(serialized["seat_votes"][0]["vote_weight"], 2, "serializer exposes Peach seat weight")
	t.check_equal(serialized["seat_votes"][0]["race_support_weight"], 2, "serializer exposes Peach support weight")
	t.check_equal(serialized["seat_votes"][0]["race_present_weight"], 3, "serializer exposes Peach present weight")
	session.free()


func _test_parliament_visual_only_hides_absent(t: BackendTestContext) -> void:
	var scene: PackedScene = load("res://worlds/parliament_seat.tscn")
	var seat: ParliamentSeat = scene.instantiate()
	Engine.get_main_loop().root.add_child(seat)
	seat.set_preview_position(SeatVoteState.Position.ABSENT)
	t.check(not seat.visual.visible, "ABSENT preview hides the parliament portrait")
	t.check(seat.visible and seat.ui_anchor.visible, "ABSENT preview keeps the seat and UI anchor visible")
	seat.set_preview_position(SeatVoteState.Position.ABSTAIN)
	t.check(seat.visual.visible, "a present preview restores the parliament portrait")
	seat.free()


func _test_global_yin_yang_rule(t: BackendTestContext) -> void:
	var race := RaceDefinition.new()
	race.display_name = "yin-yang"
	race.yin_yang_enabled = true
	race.increase_tax = true
	race.increase_production = true
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	var rule := YinYangRuleDefinitionScript.new()
	rule.yin_tax = true
	rule.yin_consumption = true
	rule.yin_production = false
	rule.yin_employment = false
	rule.yin_investment = false
	balance.yin_yang_rule = rule
	balance.yin_yang_adjustment_rate = 0.10
	var session := t.make_session([race], [t.make_group("group")], t.make_seats(1, "yin-yang"), [], balance)
	session.state.month = 1
	t.check(race.is_vote_metric_active(Metric.Id.TAX, session.context), "yin month activates yin metrics")
	t.check(not race.is_vote_metric_active(Metric.Id.PRODUCTION, session.context), "yin month deactivates yang metrics")
	t.check_equal(race.get_effective_expectation(100, Metric.Id.TAX, session.context, null), 110, "yin metric tightens in yin month")
	t.check_equal(race.get_effective_expectation(100, Metric.Id.PRODUCTION, session.context, null), 90, "yang metric relaxes in yin month")
	session.state.month = 2
	t.check(not race.is_vote_metric_active(Metric.Id.TAX, session.context), "yang month deactivates yin metrics")
	t.check(race.is_vote_metric_active(Metric.Id.PRODUCTION, session.context), "yang month activates yang metrics")
	t.check_equal(race.get_effective_expectation(100, Metric.Id.TAX, session.context, null), 90, "yin metric relaxes in yang month")
	t.check_equal(race.get_effective_expectation(100, Metric.Id.PRODUCTION, session.context, null), 110, "yang metric tightens in yang month")
	session.free()


func _test_biyi_portrait_switch(t: BackendTestContext) -> void:
	var race := BiyiRaceDefinition.new()
	var yin := ImageTexture.new()
	var yang := ImageTexture.new()
	race.portrait = yin
	race.yang_portrait = yang
	t.check(race.get_portrait(1) == yin, "Biyi uses yin portrait in odd months")
	t.check(race.get_portrait(2) == yang, "Biyi uses yang portrait in even months")
	race.yang_portrait = null
	t.check(race.get_portrait(2) == yin, "Biyi falls back to base portrait when yang portrait is missing")
