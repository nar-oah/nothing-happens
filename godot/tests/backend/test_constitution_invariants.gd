extends RefCounted


func run(t) -> void:
	_test_group_threshold_excludes_zhushui(t)
	_test_pending_group_target_capacity_excludes_zhushui(t)
	_test_province_does_not_rebuild_race_rows(t)


func _test_group_threshold_excludes_zhushui(t) -> void:
	var zhushui := t.make_race(Race.ZHUSHUI)
	var human := t.make_race(Race.HUMAN)

	var initial := ConstitutionArticleDefinition.new()
	initial.id = &"center"
	initial.axis_id = &"group_axis"
	initial.is_initial = true

	var next := ConstitutionArticleDefinition.new()
	next.id = &"group_threshold"
	next.axis_id = &"group_axis"
	next.level = 1
	next.prerequisite_id = &"center"
	next.threshold_kind = ConstitutionArticleDefinition.ThresholdKind.GROUP_INFLUENCE_RATE
	next.threshold_target_id = &"target"
	next.threshold_rate = 1.0

	var races: Array[RaceDefinition] = [zhushui, human]
	var groups: Array[InterestGroupDefinition] = [t.make_group(&"target", 1, 0)]
	var articles: Array[ConstitutionArticleDefinition] = [initial, next]
	var session := t.make_session(races, groups, articles, 4)

	t.check(
		session.constitution_system.can_revise(session.state, next),
		"group influence threshold excludes fixed Zhushui governing seat"
	)
	session.free()


func _test_pending_group_target_capacity_excludes_zhushui(t) -> void:
	var zhushui := t.make_race(Race.ZHUSHUI)
	var human := t.make_race(Race.HUMAN)
	var races: Array[RaceDefinition] = [zhushui, human]
	var groups: Array[InterestGroupDefinition] = [t.make_group(&"base", 1, 0)]
	var session := t.make_session(races, groups, [], 4)

	var accepted := session.constitution_system.add_next_year_group_target(
		session.state, &"new_group", 5
	)
	t.check(not accepted, "pending group target capacity excludes fixed Zhushui governing seat")
	session.free()


func _test_province_does_not_rebuild_race_rows(t) -> void:
	var yano := t.make_race(Race.YANO)
	var human := t.make_race(Race.HUMAN)

	var initial := ConstitutionArticleDefinition.new()
	initial.id = &"center"
	initial.axis_id = &"foreign"
	initial.is_initial = true

	var province := ConstitutionArticleDefinition.new()
	province.id = ConstitutionSystem.ARTICLE_PROVINCE
	province.axis_id = &"foreign"
	province.level = 1
	province.prerequisite_id = &"center"

	var races: Array[RaceDefinition] = [yano, human]
	var groups: Array[InterestGroupDefinition] = [
		t.make_group(&"a", 1, 0),
		t.make_group(&"b", 1, 1),
	]
	var articles: Array[ConstitutionArticleDefinition] = [initial, province]
	var session := t.make_session(races, groups, articles, 4)

	var marked_seat: SeatState = null
	for seat in session.state.seats:
		if seat.race_id == Race.YANO:
			marked_seat = seat
			break

	t.check(marked_seat != null, "province preservation test has a Yano seat")
	if marked_seat == null:
		session.free()
		return

	marked_seat.actual_group_id = &"marker"
	marked_seat.personal_relation = 7.0
	var yano_count_before := session.state.get_race(Race.YANO).seat_count
	var human_count_before := session.state.get_race(Race.HUMAN).seat_count

	t.check(session.revise_constitution(province), "province revision succeeds")
	t.check_equal(
		session.state.get_race(Race.YANO).seat_count,
		yano_count_before,
		"province preserves Yano seat count"
	)
	t.check_equal(
		session.state.get_race(Race.HUMAN).seat_count,
		human_count_before,
		"province preserves Human seat count"
	)

	var preserved := false
	for seat in session.state.seats:
		if (
			seat.race_id == Race.YANO
			and seat.actual_group_id == &"marker"
			and is_equal_approx(seat.personal_relation, 7.0)
		):
			preserved = true
			break

	t.check(
		preserved, "province does not rebuild parliament rows when seat constraints are unchanged"
	)
	session.free()
