extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_board_navigation_and_effect_serialization(t)
	_test_race_seat_effect_controls_variable_participation(t)
	_test_influence_bonus_runs_after_group_allocation(t)


func _test_board_navigation_and_effect_serialization(t: BackendTestContext) -> void:
	var race := t.make_race("board race")
	var companion := t.make_race("companion")
	var group := t.make_group("board group")
	var row := _make_row("制度轴", race, 0)
	var companion_row := _make_row("陪测轴", companion, 1)
	var center := _make_column("常制", 0)
	var right := _make_column("新制", 12)
	var center_article := _add_article(center, row, "常制")
	_add_article(center, companion_row, "陪测常制")
	var right_article := _add_article(right, row, "新制")
	_add_article(right, companion_row, "陪测新制")
	var effect := EventIntelProbabilityEffect.new()
	effect.races = [race]
	effect.probability_modifier = 0.25
	right_article.effects.append(effect)
	var board := _make_board([center, right])
	var session := _make_board_session([race, companion], [group], t.make_seats(6, "board"), board)
	t.check(session.state.constitution.get_active_article_for_row(row) == center_article, "board starts at center article")
	session.meta_progression.available_governing_months = 12
	t.check(session.unlock_constitution_column(right), "adjacent constitution column unlocks")
	t.check(session.constitution_system.can_revise(session.context, right_article), "unlocked outward article is eligible")
	t.check(session.revise_constitution(right_article), "board revision succeeds")
	t.check_approx(session.constitution_system.get_event_intel_probability_modifier(session.context, race), 0.25, "revised article exposes its effect")
	var dto := UiSerializer.new().constitution(session)
	var article_index := session.constitution_articles.find(right_article)
	t.check_equal(dto["articles"][article_index]["effects"].size(), 1, "article DTO serializes effects")
	t.check_equal(dto["articles"][article_index]["effects"][0]["display_name"], "事件情报", "effect DTO exposes display name")
	session.free()


func _test_race_seat_effect_controls_variable_participation(t: BackendTestContext) -> void:
	var excluded := t.make_race("excluded")
	var active := t.make_race("active")
	var group := t.make_group("seat group")
	var excluded_article := t.make_article(excluded)
	var seat_effect := RaceSeatEffect.new()
	seat_effect.races = [excluded]
	seat_effect.participates_in_variable_seat_allocation = false
	seat_effect.fixed_seat_enabled = true
	excluded_article.effects.append(seat_effect)
	var session := t.make_session([excluded, active], [group], t.make_seats(8, "seat"), [excluded_article, t.make_article(active)])
	t.check_equal(session.parliament_system.get_race_seat_count(session.state, excluded), 0, "excluded race receives no variable seats")
	var constraint := session.constitution_system.get_variable_race_seat_constraint(session.context, excluded)
	t.check_equal(constraint.minimum_count, 0, "excluded race variable minimum is zero")
	t.check_equal(constraint.maximum_count, 0, "excluded race variable maximum is zero")
	session.free()


func _test_influence_bonus_runs_after_group_allocation(t: BackendTestContext) -> void:
	var race := t.make_race("influence race")
	var other := t.make_race("other race")
	var target := t.make_group("target")
	var fallback := t.make_group("fallback")
	var article := t.make_article(race)
	var effect := InterestGroupInfluenceBonusEffect.new()
	effect.interest_group = target
	effect.races = [race]
	effect.bonus_rate = 1.0
	article.effects.append(effect)
	var session := t.make_session([race, other], [target, fallback], t.make_seats(8, "influence"), [article, t.make_article(other)])
	var race_seats := session.parliament_system.get_race_seats(session.state, race)
	for seat in race_seats:
		t.check(seat.actual_group == target, "100% influence bonus converts every targeted race seat")
	session.free()


func _make_board_session(races: Array[RaceDefinition], groups: Array[InterestGroupDefinition], seats: Array[SeatDefinition], board: ConstitutionBoardDefinition) -> RunSession:
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.event_early_reveal_probability_per_seat = 0.0
	var session := RunSession.new()
	session.balance = balance
	var articles: Array[ConstitutionArticleDefinition] = []
	session.configure_content(races, groups, seats, articles, board)
	session.start_new_run()
	return session


func _make_row(display_name: String, race: RaceDefinition, display_order: int) -> ConstitutionRowDefinition:
	var row := ConstitutionRowDefinition.new()
	row.display_name = display_name
	row.race = race
	row.display_order = display_order
	return row


func _make_column(display_name: String, unlock_cost_months: int) -> ConstitutionColumnDefinition:
	var column := ConstitutionColumnDefinition.new()
	column.display_name = display_name
	column.unlock_cost_months = unlock_cost_months
	return column


func _add_article(column: ConstitutionColumnDefinition, row: ConstitutionRowDefinition, display_name: String) -> ConstitutionArticleDefinition:
	var article := ConstitutionArticleDefinition.new()
	article.display_name = display_name
	article.row = row
	article.race = row.race
	column.articles.append(article)
	return article


func _make_board(raw_columns: Array) -> ConstitutionBoardDefinition:
	var board := ConstitutionBoardDefinition.new()
	for column in raw_columns:
		board.columns.append(column)
	return board
