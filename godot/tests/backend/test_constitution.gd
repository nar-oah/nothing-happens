extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_conditions_and_policy_union(t)
	_test_race_and_group_variants(t)
	_test_local_interest_groups(t)
	_test_group_merge_preserves_canonical_identity(t)
	_test_petition_is_capacity_not_seat_reassignment(t)


func _test_conditions_and_policy_union(t: BackendTestContext) -> void:
	var race_a := t.make_race("race a")
	var race_b := t.make_race("race b")
	var group_a := t.make_group("group a")
	var group_b := t.make_group("group b")
	var shared := PolicyDefinition.new()
	shared.display_name = "shared"
	var distinct := PolicyDefinition.new()
	distinct.display_name = "distinct"
	var article_a := t.make_article(race_a)
	article_a.policies = [shared, distinct]
	var article_b := t.make_article(race_b)
	article_b.policies = [shared]
	var session := t.make_session([race_a, race_b], [group_a, group_b], t.make_seats(4, "conditions"), [article_a, article_b])
	var available := session.constitution_system.get_available_policies(session.context)
	t.check_equal(available.size(), 2, "active articles expose a deduplicated policy Resource union")
	for index in range(session.state.seats.size()):
		var seat := session.state.seats[index]
		seat.race = race_a if index < 2 else race_b
		seat.actual_group = group_a if index % 2 == 0 else group_b
	var race_condition := ConstitutionSeatCondition.new()
	race_condition.race = race_a
	race_condition.required_rate = 0.5
	t.check(race_condition.is_met(session.context), "race condition uses current variable seat share")
	var group_condition := ConstitutionSeatCondition.new()
	group_condition.interest_group = group_a
	group_condition.required_rate = 0.5
	t.check(group_condition.is_met(session.context), "group condition uses current influence share")
	session.free()


func _test_race_and_group_variants(t: BackendTestContext) -> void:
	var race := t.make_race("canonical race")
	var race_variant := t.make_race("variant race")
	race_variant.description = "variant description"
	var group := t.make_group("canonical group")
	var group_variant := t.make_group("variant group")
	var article := t.make_article(race)
	var race_effect := ModifyRaceEffect.new()
	race_effect.target_races = [race]
	race_effect.source_races = [race_variant]
	var group_effect := ModifyInterestGroupEffect.new()
	group_effect.target_groups = [group]
	group_effect.source_groups = [group_variant]
	article.effects = [race_effect, group_effect]
	var session := t.make_session([race], [group], t.make_seats(3, "variant"), [article])
	var race_state := session.state.get_race(race)
	t.check(race_state.definition == race, "race canonical identity remains stable")
	t.check(race_state.active_definition == race_variant, "ModifyRaceEffect selects active race variant")
	t.check(session.constitution_system.get_active_group_definition(session.context, group) == group_variant, "ModifyInterestGroupEffect selects active group variant")
	var dto := UiSerializer.new().full_state(session, "office", "office", 0)
	t.check_equal(dto["races"][0]["display_name"], "variant race", "UI serializes active race variant")
	t.check_equal(dto["interest_groups"][0]["display_name"], "variant group", "UI serializes active group variant")
	session.free()


func _test_local_interest_groups(t: BackendTestContext) -> void:
	var race := t.make_race("local race")
	var group := t.make_group("base group")
	var article := t.make_article(race)
	var local_effect := LocalInterestGroupEffect.new()
	local_effect.races = [race]
	local_effect.decrease_metric = Metric.Id.TAX
	article.effects.append(local_effect)
	var seats := t.make_seats(3, "local")
	for definition in seats:
		definition.description = "%s description" % definition.display_name
	var session := t.make_session([race], [group], seats, [article])
	t.check_equal(session.state.constitution.local_interest_groups.size(), seats.size(), "local effect creates one group per seat definition")
	var unique: Dictionary[InterestGroupDefinition, bool] = {}
	for seat in session.state.seats:
		var local := seat.actual_group
		unique[local] = true
		t.check(local == session.state.constitution.local_interest_groups[seat.definition], "seat uses its own local group")
		t.check(local.decrease_tax, "local group stance follows effect metric")
		t.check_equal(local.description, seat.definition.description, "local group inherits location description")
	t.check_equal(unique.size(), seats.size(), "local groups are unique Resources")
	session.free()


func _test_group_merge_preserves_canonical_identity(t: BackendTestContext) -> void:
	var race := t.make_race("merge race")
	var target := t.make_group("target")
	var weak := t.make_group("weak")
	var article := t.make_article(race)
	var session := t.make_session([race], [target, weak], t.make_seats(10, "merge"), [article])
	for index in range(session.state.seats.size()):
		session.state.seats[index].actual_group = target if index < 9 else weak
	var merge := GroupMergeEffect.new()
	merge.target_group = target
	merge.threshold = 0.2
	merge.apply(session.context)
	t.check(session.constitution_system.resolve_group_identity(session.context, weak) == target, "weak canonical group resolves to merger target")
	t.check(session.context.interest_groups.has(weak), "merge does not delete canonical content Resource")
	for seat in session.state.seats:
		t.check(seat.actual_group == target, "merge rewrites current effective seat influence")
	session.free()


func _test_petition_is_capacity_not_seat_reassignment(t: BackendTestContext) -> void:
	var human := t.make_race("human")
	var other := t.make_race("other")
	var group := t.make_group("petition group")
	var article := t.make_article(human)
	var petition := PetitionEffect.new()
	petition.count_races = []
	petition.event_races = []
	petition.seat_ratio = 0.5
	article.effects.append(petition)
	var session := t.make_session([human, other], [group], t.make_seats(5, "petition"), [article, t.make_article(other)])
	var before: Array[RaceDefinition] = []
	for seat in session.state.seats:
		before.append(seat.race)
	t.check_equal(session.constitution_system.get_petition_limit(session.context), 3, "petition uses ceil(total seats × ratio)")
	t.check(session.use_petition(), "petition consumes available annual capacity")
	t.check_equal(session.state.petition_used_this_year, 1, "petition usage is persisted separately from capacity")
	for index in range(session.state.seats.size()):
		t.check(session.state.seats[index].race == before[index], "petition never reassigns parliament seats")
	session.free()
