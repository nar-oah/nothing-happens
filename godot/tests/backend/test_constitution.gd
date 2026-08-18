extends RefCounted


func run(t) -> void:
	_test_constitution_and_special_races(t)
	_test_constitution_revision_threshold(t)


func _test_constitution_and_special_races(t) -> void:
	var yano := t.make_race(Race.YANO)
	var peach := t.make_race(Race.PEACH_BLOSSOM)
	var human := t.make_race(Race.HUMAN)

	var article := ConstitutionArticleDefinition.new()
	article.id = ConstitutionSystem.ARTICLE_FREE_TRADE
	article.axis_id = &"initial"
	article.is_initial = true
	article.flags = [
		ConstitutionSystem.FLAG_FREE_TRADE,
		ConstitutionSystem.FLAG_YANO_RECOGNIZED,
		ConstitutionSystem.FLAG_PEACH_CLOSED,
	]
	article.influence_rules = [
		t.make_group_rule(
			ConstitutionInfluenceRule.Action.LOCALIZE,
			ConstitutionInfluenceRule.Priority.TERMINAL,
			Race.PEACH_BLOSSOM,
			&"",
			0.0,
			&"county"
		),
		t.make_group_rule(
			ConstitutionInfluenceRule.Action.FIX_RACE_TO_GROUP,
			ConstitutionInfluenceRule.Priority.FIXED,
			Race.YANO,
			&"factory"
		),
		t.make_group_rule(
			ConstitutionInfluenceRule.Action.FIX_RACE_TO_GROUP,
			ConstitutionInfluenceRule.Priority.FIXED,
			Race.HUMAN,
			&"transport"
		),
	]

	var races: Array[RaceDefinition] = [yano, peach, human]
	var groups: Array[InterestGroupDefinition] = [
		t.make_group(&"factory", 6, 0),
		t.make_group(&"transport", 6, 1),
		t.make_group(&"minor", 1, 2),
	]
	var articles: Array[ConstitutionArticleDefinition] = [article]
	var session := t.make_session(races, groups, articles, 5)

	t.check_equal(
		session.state.get_race(Race.HUMAN).seat_count, 1, "free trade keeps one human seat"
	)

	var peach_groups: Dictionary[StringName, bool] = {}
	for seat in session.state.seats:
		if seat.race_id == Race.YANO:
			t.check_equal(seat.actual_group_id, &"factory", "recognized yano fixed to factory")
		elif seat.race_id == Race.PEACH_BLOSSOM:
			peach_groups[seat.actual_group_id] = true
		elif seat.race_id == Race.HUMAN:
			t.check_equal(seat.actual_group_id, &"transport", "free-trade human fixed to transport")

	t.check_equal(peach_groups.size(), 2, "closed peach seats get unique local groups")
	t.check_equal(
		session.state.constitution.annual_petition_count, 1, "20 percent transport grants petition"
	)
	t.check(session.constitution_system.use_petition(session.context), "petition can be consumed")
	t.check_equal(session.state.constitution.annual_petition_count, 0, "petition count decreases")
	session.free()


func _test_constitution_revision_threshold(t) -> void:
	var race := t.make_race(&"majority")
	var group := t.make_group(&"group", 1, 0)

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

	var races: Array[RaceDefinition] = [race]
	var groups: Array[InterestGroupDefinition] = [group]
	var articles: Array[ConstitutionArticleDefinition] = [initial, next]
	var session := t.make_session(races, groups, articles)

	t.check(
		session.constitution_system.can_revise(session.state, next),
		"90 percent threshold reads variable race seats"
	)
	t.check(session.revise_constitution(next), "valid one-step constitution revision succeeds")
	t.check(
		not session.state.constitution.revision_available, "revision consumes annual opportunity"
	)
	t.check(session.state.has_intervened, "constitution revision records intervention")
	session.free()
