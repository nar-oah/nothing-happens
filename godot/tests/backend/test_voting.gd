extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")
const YinYangRuleDefinitionScript = preload("res://definitions/yin_yang_rule_definition.gd")


func run(t: BackendTestContext) -> void:
	_test_fixed_proposal_source_support(t)
	_test_draft_policy_projection_drives_support(t)
	_test_zhushui_support_is_always_99(t)
	_test_donation_pool_spending_and_detection(t)
	_test_nanke_variant_absence_is_submit_only(t)
	_test_strike_effect_locks_absent(t)
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


func _test_draft_policy_projection_drives_support(t: BackendTestContext) -> void:
	var race := t.make_race("projection race")
	race.increase_production = true
	var source := t.make_group("projection source")
	var neutral := t.make_group("projection neutral")
	var condition := MetricCondition.new()
	condition.left_metric = Metric.Id.TAX
	condition.operator = MetricCondition.Operator.GREATER_THAN
	condition.right_metric = Metric.Id.INVESTMENT
	var effect := PolicyEffect.new()
	effect.target_metric = Metric.Id.PRODUCTION
	effect.formula = PolicyEffect.Formula.METRIC_GAP
	effect.source_a = Metric.Id.TAX
	effect.source_b = Metric.Id.INVESTMENT
	var policy := PolicyDefinition.new()
	policy.display_name = "proposal-triggered policy"
	policy.condition = condition
	policy.effects.append(effect)
	var article := t.make_article(race)
	article.policies.append(policy)
	var session := t.make_session(
		[race], [source, neutral], t.make_seats(1, "projection"), [article]
	)
	session.state.seats[0].actual_group = neutral
	session.state.get_race(race).expectation_targets[Metric.Id.PRODUCTION] = 105
	var policy_only := DraftBillState.new()
	policy_only.policies.append(policy)
	var before := session.vote_system.preview_vote(policy_only, session.context)
	t.check_equal(
		t.vote_for_race(before, race).position,
		SeatVoteState.Position.ABSTAIN,
		"policy stays inactive before the proposal creates its condition"
	)
	var proposal := t.make_proposal(source)
	proposal.base_effect.tax = 10
	var draft := DraftBillState.new()
	draft.proposals.append(proposal)
	draft.policies.append(policy)
	var result := session.vote_system.preview_vote(draft, session.context)
	var vote := t.vote_for_race(result, race)
	t.check_approx(
		vote.breakdown[&"race_expectation"],
		session.balance.race_expectation_score,
		"proposal-triggered policy improvement counts toward race support"
	)
	t.check_approx(vote.breakdown[&"proposal_source"], 0.0, "group support does not mask the policy result")
	t.check_equal(vote.position, SeatVoteState.Position.SUPPORT, "policy projection can make the seat support")
	var preview := UiSerializer.new().draft_preview(session)
	t.check_equal(preview["pure_proposal_target"]["tax"], 100, "session draft remains empty in serializer baseline")
	session.state.draft_bill = draft
	preview = UiSerializer.new().draft_preview(session)
	t.check_equal(preview["pure_proposal_target"]["tax"], 110, "UI preview includes the proposal gap")
	t.check_equal(preview["projected_metrics"]["production"], 110, "UI preview applies the triggered policy chain")
	t.check_equal(preview["vote"]["seat_votes"][0]["position"], int(SeatVoteState.Position.SUPPORT), "serialized preview uses the same projected vote")
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
