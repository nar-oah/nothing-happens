extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")
const Board = preload("res://data/constitutions/constitution_board.tres")
const TransparentGovernment = preload("res://data/constitutions/透明政府.tres")


func run(t: BackendTestContext) -> void:
	_test_conditions_and_policy_union(t)
	_test_formal_board_policy_pool_and_tiers(t)
	_test_requirement_descriptions(t)
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


func _test_formal_board_policy_pool_and_tiers(t: BackendTestContext) -> void:
	var system := ConstitutionSystem.new()
	var context := RunContext.new()
	context.state = RunState.new()
	context.constitution_board = Board
	context.constitution_system = system
	var center := Board.get_center_column_index()
	var expected_by_article := {
		"外藩": 0.5,
		"朝贡": 0.75,
		"自由贸易": 1.0,
		"内附": 0.75,
		"行省": 1.5,
		"包容": 0.5,
		"汉化": 0.75,
		"比翼化": 0.75,
		"国有化": 1.0,
		"法团": 1.5,
		"有限": 0.5,
		"承认": 0.75,
		"否决": 0.75,
		"托拉斯": 1.5,
		"自治": 0.5,
		"开放": 0.75,
		"封闭": 0.75,
		"地区自治": 1.5,
		"工会": 0.5,
		"互助": 0.75,
		"合作社": 0.75,
		"理想国": 1.5,
		"哲人王": 0.5,
		"有限监管": 0.5,
		"言论自由": 0.5,
		"透明政府": 0.5,
		"锦衣卫": 0.5,
	}
	var terminal_names: Array[String] = []
	for article in Board.get_articles():
		t.check_equal(article.policies.size(), 1, "%s provides exactly one policy" % article.display_name)
		if article.is_terminal:
			terminal_names.append(article.display_name)
		if article.policies.is_empty() or article.policies[0] == null:
			continue
		var policy := article.policies[0]
		t.check(policy.effects.size() >= 2, "%s keeps its tier-scaled gap effect" % policy.display_name)
		if policy.effects.size() < 2 or policy.effects[1] == null:
			continue
		t.check(expected_by_article.has(article.display_name), "%s has an explicit route-depth policy tier" % article.display_name)
		if not expected_by_article.has(article.display_name):
			continue
		var expected: float = expected_by_article[article.display_name]
		t.check_approx(policy.effects[1].multiplier, expected, "%s main gap multiplier follows route depth and regulation exceptions" % policy.display_name)
	terminal_names.sort()
	var expected_terminal_names: Array[String] = ["地区自治", "托拉斯", "法团", "理想国", "行省"]
	expected_terminal_names.sort()
	t.check_equal(terminal_names, expected_terminal_names, "only the five actual 90% articles carry the terminal marker")
	for row in Board.get_rows():
		context.state.constitution.active_articles[row] = Board.get_article(row, center)
	var available := system.get_available_policies(context)
	t.check_equal(available.size(), 6, "the six opening constitution rows expose at most six policies")
	var draft_system := DraftBillSystem.new()
	for policy in available:
		t.check(draft_system.add_available_policy(context, policy), "all six available policies can enter one bill")
	t.check_equal(context.state.draft_bill.policies.size(), 6, "one bill keeps all six available policies without a policy cap")
	t.check(not TransparentGovernment.is_terminal, "the outer regulation article remains non-terminal")
	t.check_approx(TransparentGovernment.policies[0].effects[1].multiplier, 0.5, "all regulation policies stay at the base multiplier")


func _test_requirement_descriptions(t: BackendTestContext) -> void:
	var race := t.make_race("人类")
	var race_condition := ConstitutionSeatCondition.new()
	race_condition.race = race
	race_condition.required_rate = 0.505
	var operators := ["不低于", "不高于", "高于", "低于"]
	for comparison in range(operators.size()):
		race_condition.comparison = comparison
		t.check_equal(race_condition.get_description(), "种族：人类\n席位占比：%s50.5%%" % operators[comparison], "race requirement describes its comparison and exact percentage")
	var group_a := t.make_group("甲集团")
	var group_b := t.make_group("乙集团")
	var group_condition := ConstitutionSeatCondition.new()
	group_condition.interest_groups = [group_a, group_b, group_a]
	group_condition.interest_group = group_a
	group_condition.required_rate = 0.25
	t.check_equal(group_condition.get_description(), "范围：全议会\n利益集团：甲集团、乙集团\n各集团影响力占比：不低于25%\n满足方式：全部满足", "group requirements describe separate influence thresholds and deduplicate group references")
	group_condition.race = race
	group_condition.match_mode = ConstitutionSeatCondition.MatchMode.ANY
	t.check_equal(group_condition.get_description(), "范围：人类\n利益集团：甲集团、乙集团\n各集团影响力占比：不低于25%\n满足方式：任一满足", "group requirements describe race scope and any matching")
	var article := ConstitutionArticleDefinition.new()
	t.check_equal(article.get_requirement_description(), "无", "articles without activation conditions show no requirements")
	article.conditions = [race_condition]
	article.seat_condition = group_condition
	t.check_equal(article.get_requirement_description(), "须同时满足：\n%s\n\n%s" % [race_condition.get_description(), group_condition.get_description()], "article requirements combine all activation conditions")
	article.conditions.append(group_condition)
	t.check_equal(article.get_requirement_description(), "须同时满足：\n%s\n\n%s" % [race_condition.get_description(), group_condition.get_description()], "legacy seat conditions already in the condition array appear once")


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
