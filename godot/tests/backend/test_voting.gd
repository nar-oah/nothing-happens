extends RefCounted


func run(t) -> void:
	_test_special_voting_rules(t)


func _test_special_voting_rules(t) -> void:
	var zhushui := t.make_race(Race.ZHUSHUI)
	var nanke := t.make_race(Race.NANKE)
	nanke.increase_wage = true
	var biyi := t.make_race(Race.BIYI)

	var labor_article := ConstitutionArticleDefinition.new()
	labor_article.id = &"union"
	labor_article.axis_id = &"labor"
	labor_article.is_initial = true
	labor_article.influence_rules = [
		t.make_group_rule(
			ConstitutionInfluenceRule.Action.GROUP_MINIMUM,
			ConstitutionInfluenceRule.Priority.LIMIT,
			Race.NANKE,
			&"union",
			0.5
		)
	]

	var races: Array[RaceDefinition] = [zhushui, nanke, biyi]
	var groups: Array[InterestGroupDefinition] = [t.make_group(&"union", 1, 0)]
	var articles: Array[ConstitutionArticleDefinition] = [labor_article]
	var session := t.make_session(races, groups, articles)

	var strike_proposal := t.make_proposal(&"union")
	strike_proposal.base_effect.wage = -10
	session.state.draft_bill.proposals.append(strike_proposal)

	for seat in session.state.seats:
		if seat.race_id == Race.BIYI:
			seat.odd_month_relation = 10.0
			seat.even_month_relation = -10.0

	var actual := session.vote_system.calculate_vote(
		session.state.draft_bill, session.context, true
	)
	t.check_equal(
		t.vote_for_race(actual, session.state, Race.ZHUSHUI),
		SeatVoteState.Position.SUPPORT,
		"zhushui always supports"
	)
	t.check_equal(
		t.vote_for_race(actual, session.state, Race.NANKE),
		SeatVoteState.Position.OPPOSE,
		"nanke strike counts as opposition"
	)
	t.check_equal(
		t.vote_for_race(actual, session.state, Race.BIYI),
		SeatVoteState.Position.SUPPORT,
		"odd-month biyi half uses own relation"
	)

	session.state.month = 2
	var even_vote := session.vote_system.calculate_vote(
		session.state.draft_bill, session.context, false
	)
	t.check_equal(
		t.vote_for_race(even_vote, session.state, Race.BIYI),
		SeatVoteState.Position.OPPOSE,
		"even-month biyi half replaces attitude"
	)
	session.free()
