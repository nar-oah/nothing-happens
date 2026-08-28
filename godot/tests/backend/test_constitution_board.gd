extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_board_navigation_unlocks_and_terminal_mutex(t)
	_test_column_unlock_ipc_stays_in_month_zero(t)
	_test_formal_opening_uses_five_anchors_and_twenty_random_seats(t)
	_test_variable_seat_denominators(t)
	_test_group_coloring_bias_and_hard_rule_layers(t)


func _test_board_navigation_unlocks_and_terminal_mutex(t: BackendTestContext) -> void:
	var zhushui := ZhushuiRaceDefinition.new()
	zhushui.display_name = "驻岁"
	var race_a := t.make_race("axis a")
	var race_b := t.make_race("axis b")
	var group := t.make_group("board group")
	var row_a := _make_row(&"a", "甲轴", race_a, 0)
	var row_b := _make_row(&"b", "乙轴", race_b, 1)
	var regulator := _make_row(&"regulator", "监管", zhushui, 2, true, true)
	var far_left := _make_column(&"far_left", "异制", 24)
	var left := _make_column(&"left", "偏制", 12)
	var center := _make_column(&"center", "常制", 0)
	var right := _make_column(&"right", "新制", 12)
	var far_right := _make_column(&"far_right", "极制", 24)
	var a_terminal := _add_article(far_left, row_a, "甲终局", true)
	var regulator_left := _add_article(far_left, regulator, "透明政府")
	var a_left := _add_article(left, row_a, "甲偏制")
	var a_center := _add_article(center, row_a, "甲常制")
	var b_center := _add_article(center, row_b, "乙常制")
	var regulator_center := _add_article(center, regulator, "哲人王")
	var b_terminal := _add_article(right, row_b, "乙终局", true)
	var regulator_right := _add_article(far_right, regulator, "锦衣卫")
	var board := _make_board([far_left, left, center, right, far_right])
	var seats: Array[SeatDefinition] = [
		t.make_seat("久视", zhushui),
		t.make_seat("甲锚", race_a),
		t.make_seat("乙锚", race_b),
	]
	for index in range(4):
		seats.append(t.make_seat("board_%s" % index))
	var races: Array[RaceDefinition] = [zhushui, race_a, race_b]
	var groups: Array[InterestGroupDefinition] = [group]
	var session := _make_board_session(t, races, groups, seats, board)

	t.check(
		session.state.constitution.get_active_article_for_row(row_a) == a_center,
		"board starts the first axis at its center article"
	)
	t.check(
		session.state.constitution.get_active_article_for_row(row_b) == b_center,
		"board starts the second axis at its center article"
	)
	t.check(
		session.state.constitution.get_active_article_for_row(regulator) == regulator_center,
		"regulator starts at its center article"
	)

	session.meta_progression.available_governing_months = 48
	t.check(
		not session.unlock_constitution_column(far_left),
		"an outer column cannot unlock before its inward neighbor"
	)
	t.check(session.unlock_constitution_column(left), "the inward left column unlocks first")
	t.check_equal(
		session.meta_progression.available_governing_months,
		36,
		"column unlock consumes its governing-month cost"
	)
	t.check(session.unlock_constitution_column(far_left), "the outer left column unlocks after its inward neighbor")
	t.check(session.unlock_constitution_column(right), "the inward right column unlocks independently")
	t.check_equal(
		session.meta_progression.available_governing_months,
		0,
		"unlocks consume the shared meta-progression budget"
	)
	t.check(
		not session.meta_progression.is_column_unlocked(far_right),
		"the far-right column remains locked"
	)

	t.check(
		not session.constitution_system.can_revise(session.context, a_terminal),
		"a normal axis cannot skip its nearer non-empty article"
	)
	t.check(
		session.constitution_system.can_revise(session.context, a_left),
		"the next outward article is eligible"
	)
	t.check(session.revise_constitution(a_left), "the first outward revision succeeds")
	session.state.constitution.revision_available = true
	t.check(
		not session.constitution_system.can_revise(session.context, a_center),
		"a normal axis cannot retreat toward the center"
	)
	t.check(
		session.constitution_system.can_revise(session.context, a_terminal),
		"the same axis can continue outward after the nearer article"
	)
	t.check(
		session.constitution_system.can_revise(session.context, b_terminal),
		"another terminal remains eligible before any terminal is selected"
	)
	t.check(session.revise_constitution(a_terminal), "the first race terminal revision succeeds")
	t.check(
		session.state.constitution.terminal_article == a_terminal,
		"the first race terminal becomes the term terminal"
	)
	session.state.constitution.revision_available = true
	t.check(
		not session.constitution_system.can_revise(session.context, b_terminal),
		"a selected race terminal locks the other race terminals"
	)
	t.check(
		session.constitution_system.can_revise(session.context, regulator_right),
		"free-navigation regulator can jump directly to a locked outer column"
	)
	t.check(session.revise_constitution(regulator_right), "regulator revision remains available after a race terminal")
	t.check(
		session.state.constitution.terminal_article == a_terminal,
		"regulator revision does not replace the race terminal"
	)
	session.state.constitution.revision_available = true
	t.check(
		session.constitution_system.can_revise(session.context, regulator_left),
		"regulator can later jump across the center to another state"
	)

	var dto := UiSerializer.new().constitution(session)
	t.check_equal(dto["center_column_index"], 2, "board DTO preserves the center column")
	t.check_equal(dto["columns"].size(), 5, "board DTO serializes every column including locked ones")
	t.check_equal(dto["rows"].size(), 3, "board DTO serializes every row")
	t.check_equal(
		dto["terminal_article_index"],
		session.constitution_articles.find(a_terminal),
		"board DTO exposes the selected terminal article"
	)
	t.check(
		not dto["columns"][4]["unlocked"],
		"board DTO preserves the locked far-right column"
	)
	var regulator_right_index := session.constitution_articles.find(regulator_right)
	t.check_equal(
		dto["articles"][regulator_right_index]["column_index"],
		4,
		"article DTO keeps its real board column coordinate"
	)
	t.check_equal(
		dto["articles"][regulator_right_index]["row_index"],
		2,
		"article DTO keeps its real board row coordinate"
	)
	session.free()


func _test_column_unlock_ipc_stays_in_month_zero(t: BackendTestContext) -> void:
	var zhushui := ZhushuiRaceDefinition.new()
	zhushui.display_name = "驻岁"
	var race := t.make_race("ipc axis")
	var race_b := t.make_race("ipc companion")
	var group := t.make_group("ipc group")
	var row := _make_row(&"ipc_axis", "IPC轴", race, 0)
	var row_b := _make_row(&"ipc_companion", "陪测轴", race_b, 1)
	var regulator := _make_row(&"ipc_regulator", "监管", zhushui, 2, true, true)
	var center := _make_column(&"center", "常制", 0)
	var right := _make_column(&"right", "新制", 12)
	_add_article(center, row, "常制")
	_add_article(center, row_b, "陪测常制")
	_add_article(center, regulator, "哲人王")
	_add_article(right, row, "新制")
	var board := _make_board([center, right])
	var races: Array[RaceDefinition] = [zhushui, race, race_b]
	var groups: Array[InterestGroupDefinition] = [group]
	var seats: Array[SeatDefinition] = [t.make_seat("久视", zhushui)]
	for index in range(4):
		seats.append(t.make_seat("ipc_%s" % index))
	var session := _make_board_session(t, races, groups, seats, board)
	session.meta_progression.available_governing_months = 12
	var bridge := UiBridge.new()
	bridge.setup(session)
	var messages := bridge.receive_ipc_message(
		_message("constitution.column.unlock", {"state_version": 0, "column_index": 1})
	)
	var full: Dictionary = messages[messages.size() - 1]
	t.check_equal(full["type"], "state.full", "column unlock returns an authoritative full state")
	t.check_equal(full["payload"]["state_version"], 1, "column unlock advances state version")
	t.check_equal(full["payload"]["month"], 0, "column unlock does not consume constitution month zero")
	t.check(
		full["payload"]["constitution"]["revision_available"],
		"column unlock does not consume the annual constitution revision"
	)
	t.check_equal(
		full["payload"]["constitution"]["available_governing_months"],
		0,
		"column unlock syncs the remaining meta-progression budget"
	)
	t.check(
		full["payload"]["constitution"]["columns"][1]["unlocked"],
		"column unlock syncs the new unlocked state"
	)
	bridge.free()
	session.free()


func _test_formal_opening_uses_five_anchors_and_twenty_random_seats(t: BackendTestContext) -> void:
	var zhushui := ZhushuiRaceDefinition.new()
	zhushui.display_name = "驻岁"
	var human := t.make_race("人类")
	var nanke := t.make_race("南柯")
	var biyi := t.make_race("比翼")
	var yano := t.make_race("偃偶")
	var peach := t.make_race("桃花妖")
	var races: Array[RaceDefinition] = [zhushui, human, nanke, biyi, yano, peach]
	var rows: Array[ConstitutionRowDefinition] = []
	for index in range(races.size()):
		rows.append(_make_row(StringName("opening_%s" % index), races[index].display_name, races[index], index))
	var center := _make_column(&"center", "常制", 0)
	for row in rows:
		_add_article(center, row, "%s常制" % row.display_name)
	var board := _make_board([center])
	var seats: Array[SeatDefinition] = [
		t.make_seat("久视", zhushui),
		t.make_seat("会同", human),
		t.make_seat("槐安", nanke),
		t.make_seat("连理", biyi),
		t.make_seat("桃源", peach),
	]
	for index in range(20):
		seats.append(t.make_seat("random_%s" % index))
	var groups: Array[InterestGroupDefinition] = [t.make_group("opening group")]
	var session := _make_board_session(t, races, groups, seats, board)

	t.check_equal(session.state.seats.size(), 25, "formal opening keeps the permanent 25-seat parliament")
	t.check_equal(
		session.parliament_system.get_variable_seats(session.state).size(),
		24,
		"only the Zhushui executive seat is excluded from the variable-seat pool"
	)
	t.check_equal(
		session.parliament_system.get_race_seat_count(session.state, zhushui),
		1,
		"Zhushui owns exactly its single permanent anchor"
	)
	var anchor_races: Array[RaceDefinition] = [zhushui, human, nanke, biyi, peach]
	for index in range(anchor_races.size()):
		t.check(
			session.state.seats[index].race == anchor_races[index],
			"every formal anchor remains assigned to its owning race"
		)
	var random_count := 0
	for seat in session.state.seats:
		if seat.definition.anchor_race != null:
			continue
		random_count += 1
		t.check(seat.race != null, "every random opening seat receives a race")
		t.check(not (seat.race is ZhushuiRaceDefinition), "random opening seats never expand Zhushui")
	t.check_equal(random_count, 20, "formal opening contains exactly twenty random seats")
	var non_zhushui_total := 0
	for race in [human, nanke, biyi, yano, peach]:
		non_zhushui_total += session.parliament_system.get_race_seat_count(session.state, race)
	t.check_equal(non_zhushui_total, 24, "five non-Zhushui races fill every variable seat")
	session.free()


func _test_variable_seat_denominators(t: BackendTestContext) -> void:
	var zhushui := ZhushuiRaceDefinition.new()
	zhushui.display_name = "驻岁"
	var race_a := t.make_race("ratio a")
	var race_b := t.make_race("ratio b")
	var group_a := t.make_group("ratio group a")
	var group_b := t.make_group("ratio group b")
	var row_z := _make_row(&"ratio_z", "监管", zhushui, 0, true, true)
	var row_a := _make_row(&"ratio_a", "甲轴", race_a, 1)
	var row_b := _make_row(&"ratio_b", "乙轴", race_b, 2)
	var center := _make_column(&"center", "常制", 0)
	_add_article(center, row_z, "哲人王")
	var article_a := _add_article(center, row_a, "甲常制")
	article_a.race_min_seat_rate = 0.5
	_add_article(center, row_b, "乙常制")
	var board := _make_board([center])
	var seats: Array[SeatDefinition] = [t.make_seat("久视", zhushui)]
	for index in range(24):
		seats.append(t.make_seat("ratio_%s" % index))
	var races: Array[RaceDefinition] = [zhushui, race_a, race_b]
	var groups: Array[InterestGroupDefinition] = [group_a, group_b]
	var session := _make_board_session(t, races, groups, seats, board)
	var target_counts: Dictionary[RaceDefinition, int] = {}
	target_counts[zhushui] = 1
	target_counts[race_a] = 12
	target_counts[race_b] = 12
	t.check(
		session.parliament_system.assign_race_distribution(session.state, races, target_counts),
		"ratio fixture can assign one fixed and twenty-four variable seats"
	)
	var constraint := session.constitution_system.get_race_seat_constraint(session.context, race_a)
	t.check_equal(constraint.minimum_count, 12, "a 50% constitution threshold is twelve of twenty-four seats")
	t.check_approx(
		session.parliament_system.get_race_seat_rate(session.state, race_a),
		0.5,
		"race seat rate excludes the Zhushui executive seat from its denominator"
	)
	var variable := session.parliament_system.get_variable_seats(session.state)
	for index in range(variable.size()):
		variable[index].actual_group = group_a if index < 12 else group_b
	t.check_approx(
		session.parliament_system.get_group_influence_rate(session.state, group_a),
		0.5,
		"global group influence uses the same twenty-four-seat denominator"
	)
	var race_condition := ConstitutionSeatCondition.new()
	race_condition.race = race_a
	race_condition.required_rate = 0.5
	t.check(race_condition.is_met(session.context), "race threshold accepts exactly fifty percent")
	race_condition.required_rate = 0.51
	t.check(not race_condition.is_met(session.context), "race threshold rejects values above the exact share")
	var group_condition := ConstitutionSeatCondition.new()
	group_condition.interest_group = group_a
	group_condition.required_rate = 0.5
	t.check(group_condition.is_met(session.context), "group threshold accepts exactly fifty percent")
	group_condition.required_rate = 0.51
	t.check(not group_condition.is_met(session.context), "group threshold rejects values above the exact share")
	session.free()


func _test_group_coloring_bias_and_hard_rule_layers(t: BackendTestContext) -> void:
	var zhushui := ZhushuiRaceDefinition.new()
	zhushui.display_name = "驻岁"
	var race_a := t.make_race("layer a")
	var race_b := t.make_race("layer b")
	var source := t.make_group("annual source")
	var biased := t.make_group("constitution bias")
	var hard := t.make_group("hard override")
	var row_z := _make_row(&"layer_z", "监管", zhushui, 0, true, true)
	var row_a := _make_row(&"layer_a", "甲轴", race_a, 1)
	var row_b := _make_row(&"layer_b", "乙轴", race_b, 2)
	var center := _make_column(&"center", "常制", 0)
	_add_article(center, row_z, "哲人王")
	var article_a := _add_article(center, row_a, "甲常制")
	_add_article(center, row_b, "乙常制")
	var bias := ConstitutionGroupBiasDefinition.new()
	bias.interest_group = biased
	bias.probability = 1.0
	article_a.group_biases.append(bias)
	article_a.influence_rules.append(
		t.make_rule(ConstitutionInfluenceRule.Mode.TARGET, hard, 0.5, race_a)
	)
	var board := _make_board([center])
	var seats: Array[SeatDefinition] = [t.make_seat("久视", zhushui)]
	for index in range(12):
		seats.append(t.make_seat("layer_%s" % index))
	var races: Array[RaceDefinition] = [zhushui, race_a, race_b]
	var groups: Array[InterestGroupDefinition] = [source, biased, hard]
	var session := _make_board_session(t, races, groups, seats, board)
	var target_counts: Dictionary[RaceDefinition, int] = {}
	target_counts[zhushui] = 1
	target_counts[race_a] = 6
	target_counts[race_b] = 6
	t.check(
		session.parliament_system.assign_race_distribution(session.state, races, target_counts),
		"layer fixture assigns a stable six-seat row per test race"
	)
	t.check(
		session.parliament_system.initialize_base_groups(session.context, groups),
		"layer fixture rebuilds base columns after the forced race distribution"
	)
	session.balance.annual_group_coloring_rate = 1.0
	var proposal := t.make_proposal(source)
	session.parliament_system.record_authorized_proposal_slots(session.state, [proposal])
	session.parliament_system.apply_annual_coloring(session.context)
	for seat in session.parliament_system.get_race_seats(session.state, race_a):
		t.check(seat.annual_group == biased, "constitution probability bias overwrites annual source coloring on its race")
		t.check(seat.actual_group == biased, "actual influence initially follows the biased annual layer")
	for seat in session.parliament_system.get_race_seats(session.state, race_b):
		t.check(seat.annual_group == source, "unbiased races retain the annual proposal-source coloring")
	session.constitution_system.apply_influence_rules(session.context)
	t.check_equal(
		session.parliament_system.get_group_influence_count(session.state, hard, race_a),
		3,
		"hard constitution rule applies after coloring and bias"
	)
	for seat in session.parliament_system.get_race_seats(session.state, race_a):
		t.check(seat.annual_group == biased, "hard rules do not destroy the underlying annual influence layer")
	session.free()


func _make_board_session(
	t: BackendTestContext,
	races: Array[RaceDefinition],
	groups: Array[InterestGroupDefinition],
	seats: Array[SeatDefinition],
	board: ConstitutionBoardDefinition
) -> RunSession:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.event_early_reveal_probability_per_seat = 0.0
	var session := RunSession.new()
	session.balance = balance
	var legacy_articles: Array[ConstitutionArticleDefinition] = []
	session.configure_content(traces, groups, seats, legacy_articles, board)
	session.start_new_run()
	return session


func _make_row(
	id: StringName,
	display_name: String,
	race: RaceDefinition,
	display_order: int,
	free_navigation: bool = false,
	ignores_column_unlocks: bool = false
) -> ConstitutionRowDefinition:
	var row := ConstitutionRowDefinition.new()
	row.id = id
	row.display_name = display_name
	row.race = race
	row.display_order = display_order
	row.free_navigation = free_navigation
	row.ignores_column_unlocks = ignores_column_unlocks
	return row


func _make_column(
	id: StringName, display_name: String, unlock_cost_months: int
) -> ConstitutionColumnDefinition:
	var column := ConstitutionColumnDefinition.new()
	column.id = id
	column.display_name = display_name
	column.unlock_cost_months = unlock_cost_months
	return column


func _add_article(
	column: ConstitutionColumnDefinition,
	row: ConstitutionRowDefinition,
	display_name: String,
	is_terminal: bool = false
) -> ConstitutionArticleDefinition:
	var article := ConstitutionArticleDefinition.new()
	article.display_name = display_name
	article.row = row
	article.race = row.race
	article.is_terminal = is_terminal
	column.articles.append(article)
	return article


func _make_board(raw_columns: Array) -> ConstitutionBoardDefinition:
	var board := ConstitutionBoardDefinition.new()
	for column in raw_columns:
		board.columns.append(column)
	return board


func _message(message_type: String, payload: Dictionary) -> String:
	return JSON.stringify({"type": message_type, "request_id": "board-test", "payload": payload})
