extends RefCounted
class_name ConstitutionSystem


func initialize(context: RunContext) -> bool:
	context.state.constitution = ConstitutionState.new()
	if context.constitution_board != null:
		return _initialize_from_board(context)
	return _initialize_legacy(context)


func _initialize_from_board(context: RunContext) -> bool:
	var board := context.constitution_board
	if not board.validate():
		return false
	var center := board.get_center_column_index()
	for row in board.get_rows():
		var initial := board.get_article(row, center)
		if initial == null:
			push_error("Every constitution row requires a center article.")
			return false
		if initial.get_race() != row.race:
			push_error("Constitution row race must match its center article race.")
			return false
		if initial.is_terminal:
			push_error("A center constitution article cannot be terminal.")
			return false
		context.state.constitution.active_articles[row] = initial
	context.constitution_articles = board.get_articles()
	refresh_runtime(context)
	return true


func _initialize_legacy(context: RunContext) -> bool:
	var seen: Dictionary[ConstitutionArticleDefinition, bool] = {}
	for definition in context.constitution_articles:
		if definition == null or seen.has(definition) or definition.get_race() == null:
			push_error("Constitution articles must be unique Resources owned by a content race.")
			return false
		seen[definition] = true
	for race in context.race_definitions:
		var initial: ConstitutionArticleDefinition
		for definition in context.constitution_articles:
			if definition.get_race() != race or not definition.is_initial:
				continue
			if initial != null:
				push_error("A race can have at most one legacy initial constitution article.")
				return false
			initial = definition
		if initial == null:
			continue
		var row := initial.row
		if row == null:
			row = ConstitutionRowDefinition.new()
			row.id = StringName("legacy_%s" % race.display_name)
			row.display_name = race.display_name
			row.race = race
		context.state.constitution.active_articles[row] = initial
	refresh_runtime(context)
	return true


func activate_initial_articles(context: RunContext) -> void:
	for article in get_active_articles(context):
		article.on_activate(context)


func can_revise(context: RunContext, definition: ConstitutionArticleDefinition) -> bool:
	if definition == null or not context.state.constitution.revision_available:
		return false
	if definition.is_terminal:
		var selected_terminal := context.state.constitution.terminal_article
		if selected_terminal != null and selected_terminal != definition:
			return false
	if context.constitution_board == null:
		return _can_revise_legacy(context, definition)
	if context.state.month != 0 or definition.row == null:
		return false
	var board := context.constitution_board
	var target_column := board.get_column_index_for_article(definition)
	if target_column < 0:
		return false
	var current := context.state.constitution.get_active_article_for_row(definition.row)
	if current == null or current == definition:
		return false
	if definition.row.free_navigation:
		return definition.can_activate(context)
	if not definition.row.ignores_column_unlocks:
		if context.meta_progression == null:
			return false
		if not context.meta_progression.is_column_unlocked(board.columns[target_column]):
			return false
	var current_column := board.get_column_index_for_article(current)
	var center := board.get_center_column_index()
	if current_column < 0 or center < 0:
		return false
	var expected: ConstitutionArticleDefinition
	if current_column == center:
		if target_column < center:
			expected = _next_article_outward(board, definition.row, current_column, -1)
		elif target_column > center:
			expected = _next_article_outward(board, definition.row, current_column, 1)
	else:
		var direction := -1 if current_column < center else 1
		expected = _next_article_outward(board, definition.row, current_column, direction)
	if expected != definition:
		return false
	return definition.can_activate(context)


func _can_revise_legacy(context: RunContext, definition: ConstitutionArticleDefinition) -> bool:
	var race := definition.get_race()
	if race == null or race not in context.race_definitions or definition not in context.constitution_articles:
		return false
	return context.state.constitution.get_active_article(race) != definition and definition.can_activate(context)


func revise(context: RunContext, definition: ConstitutionArticleDefinition) -> bool:
	if not can_revise(context, definition):
		return false
	var row := definition.row
	if row == null:
		for candidate in context.state.constitution.active_articles:
			if candidate.race == definition.get_race():
				row = candidate
				break
	if row == null:
		return false
	var previous := context.state.constitution.get_active_article_for_row(row)
	var target_race := definition.get_race()
	var race_snapshot: Dictionary[SeatState, RaceDefinition] = {}
	var fixed_snapshot: Dictionary[SeatState, RaceDefinition] = {}
	for seat in context.state.seats:
		race_snapshot[seat] = seat.race
		fixed_snapshot[seat] = seat.fixed_race
	context.state.constitution.active_articles[row] = definition
	if target_race != null and definition.revoke_fixed_seat:
		context.parliament_system.revoke_fixed_seat(context, target_race)
	if target_race != null and not context.race_system.enforce_constitution_constraints(context, target_race):
		context.state.constitution.active_articles[row] = previous
		for seat in context.state.seats:
			seat.race = race_snapshot.get(seat)
			seat.fixed_race = fixed_snapshot.get(seat)
		refresh_runtime(context)
		return false
	if previous != null:
		previous.on_deactivate(context)
	_restore_constitution_base_groups(context)
	apply_influence_rules(context)
	refresh_runtime(context)
	# A month-0 revision changes this year's expectation formula but not its baseline.
	context.race_system.rebuild_annual_expectations(context)
	context.state.constitution.revision_available = false
	if definition.is_terminal:
		context.state.constitution.terminal_article = definition
	definition.on_activate(context)
	return true


func _next_article_outward(
	board: ConstitutionBoardDefinition,
	row: ConstitutionRowDefinition,
	from_column: int,
	direction: int
) -> ConstitutionArticleDefinition:
	var index := from_column + direction
	while index >= 0 and index < board.columns.size():
		var article := board.get_article(row, index)
		if article != null:
			return article
		index += direction
	return null


func refresh_runtime(context: RunContext) -> void:
	var state := context.state
	state.petition_race = null
	state.petition_limit = 0
	state.donation_detection_probability = context.balance.donation_detection_probability
	state.event_early_reveal_bonus_probability = 0.0
	for race in state.races:
		# Formal Board content always supplies an active article for every race row. Zero is a
		# real growth rate, so there is deliberately no fallback to GameBalanceDefinition.
		race.expectation_growth_rate = 0.0
		race.visit_probability = 0.0
		race.absence_probability = context.balance.normal_absence_probability
		race.yin_yang_adjustment_rate = 0.0
		race.strike_enabled = false
		race.strike_group = null
		race.strike_extends_to_group = false
	for article in get_active_articles(context):
		article.apply_runtime(context)


func get_active_articles(context: RunContext) -> Array[ConstitutionArticleDefinition]:
	var result: Array[ConstitutionArticleDefinition] = []
	if context.constitution_board != null:
		for row in context.constitution_board.get_rows():
			var article := context.state.constitution.get_active_article_for_row(row)
			if article != null:
				result.append(article)
		return result
	for row in context.state.constitution.active_articles:
		var article: ConstitutionArticleDefinition = context.state.constitution.active_articles[row]
		if article != null:
			result.append(article)
	return result


func get_available_policies(context: RunContext) -> Array[PolicyDefinition]:
	var result: Array[PolicyDefinition] = []
	for article in get_active_articles(context):
		for policy in article.policies:
			if policy != null and policy not in result:
				result.append(policy)
	return result


func get_available_policy(context: RunContext, display_name: String) -> PolicyDefinition:
	for policy in get_available_policies(context):
		if policy.display_name == display_name:
			return policy
	return null


func get_effective_groups(context: RunContext) -> Array[InterestGroupDefinition]:
	var result: Array[InterestGroupDefinition] = []
	for group in context.interest_groups:
		_append_effective_group(result, context.state, group)
	for race in context.race_definitions:
		if race != null:
			_append_effective_group(result, context.state, race.fixed_interest_group)
	for seat in context.state.seats:
		_append_effective_group(result, context.state, seat.base_group)
		_append_effective_group(result, context.state, seat.annual_group)
		_append_effective_group(result, context.state, seat.actual_group)
	return result


func on_month_start(context: RunContext) -> void:
	for article in get_active_articles(context):
		article.on_month_start(context)


func on_year_settlement(context: RunContext) -> void:
	for article in get_active_articles(context):
		article.on_year_settlement(context)


func modify_vote(vote_context: VoteContext) -> void:
	if vote_context == null:
		return
	for article in get_active_articles(vote_context.run_context):
		article.modify_vote(vote_context)


func race_participates_in_variable_seat_allocation(
	context: RunContext, race: RaceDefinition
) -> bool:
	if race == null:
		return false
	var article := context.state.constitution.get_active_article(race)
	return true if article == null else article.participates_in_variable_seat_allocation


func get_race_seat_constraint(context: RunContext, race: RaceDefinition) -> RaceSeatConstraint:
	if race == null:
		return RaceSeatConstraint.new(0, 0)
	var fixed_count := context.parliament_system.get_fixed_seat_count(context.state, race)
	if not race_participates_in_variable_seat_allocation(context, race):
		return RaceSeatConstraint.new(fixed_count, fixed_count)
	var total := context.state.seats.size()
	var article := context.state.constitution.get_active_article(race)
	var minimum := fixed_count
	var maximum := total
	if article != null:
		minimum = maxi(ceili(article.race_min_seat_rate * total), fixed_count)
		maximum = maxi(floori(article.race_max_seat_rate * total), fixed_count)
	return RaceSeatConstraint.new(minimum, maximum)


func get_variable_race_seat_constraint(
	context: RunContext, race: RaceDefinition
) -> RaceSeatConstraint:
	if not race_participates_in_variable_seat_allocation(context, race):
		return RaceSeatConstraint.new(0, 0)
	var final_constraint := get_race_seat_constraint(context, race)
	var fixed_count := context.parliament_system.get_fixed_seat_count(context.state, race)
	var variable_pool := context.parliament_system.get_variable_seats(context.state).size()
	var minimum := maxi(final_constraint.minimum_count - fixed_count, 0)
	var maximum := (
		variable_pool
		if final_constraint.maximum_count < 0
		else maxi(final_constraint.maximum_count - fixed_count, 0)
	)
	return RaceSeatConstraint.new(minimum, mini(maximum, variable_pool))


func get_race_seat_constraints(context: RunContext) -> Dictionary[RaceDefinition, RaceSeatConstraint]:
	var result: Dictionary[RaceDefinition, RaceSeatConstraint] = {}
	for race in context.race_definitions:
		result[race] = get_race_seat_constraint(context, race)
	return result


func get_group_biases_for_race(
	context: RunContext, race: RaceDefinition
) -> Array[ConstitutionGroupBiasDefinition]:
	var article := context.state.constitution.get_active_article(race)
	return [] if article == null else article.group_biases


func apply_influence_rules(context: RunContext) -> void:
	for article in get_active_articles(context):
		for rule in article.influence_rules:
			if rule != null and rule.interest_group != null:
				_apply_influence_rule(context, rule)


func _apply_influence_rule(context: RunContext, rule: ConstitutionInfluenceRule) -> void:
	var eligible := context.parliament_system.get_influenceable_seats(context.state, rule.race)
	if eligible.is_empty():
		return
	var desired := 0
	match rule.mode:
		ConstitutionInfluenceRule.Mode.MINIMUM:
			desired = ceili(rule.rate * eligible.size())
		ConstitutionInfluenceRule.Mode.MAXIMUM:
			desired = floori(rule.rate * eligible.size())
		ConstitutionInfluenceRule.Mode.TARGET:
			desired = roundi(rule.rate * eligible.size())
	var current: Array[SeatState] = []
	for seat in eligible:
		if seat.actual_group == rule.interest_group:
			current.append(seat)
	if rule.mode == ConstitutionInfluenceRule.Mode.MINIMUM and current.size() >= desired:
		return
	if rule.mode == ConstitutionInfluenceRule.Mode.MAXIMUM and current.size() <= desired:
		return
	var difference := desired - current.size()
	if difference > 0:
		for seat in eligible:
			if difference <= 0:
				break
			if seat.actual_group == rule.interest_group:
				continue
			seat.actual_group = rule.interest_group
			difference -= 1
	elif difference < 0:
		for seat in current:
			if difference >= 0:
				break
			seat.actual_group = _fallback_group(context, seat, rule.interest_group)
			difference += 1


func _fallback_group(
	context: RunContext,
	seat: SeatState,
	excluded: InterestGroupDefinition
) -> InterestGroupDefinition:
	if seat.race != null and seat.race.fixed_interest_group != null:
		return _resolve_merger(context.state, seat.race.fixed_interest_group)
	var underlying := seat.annual_group
	if underlying == null:
		underlying = seat.base_group
	var base := _resolve_merger(context.state, underlying)
	if base != null and base != excluded:
		return base
	for group in get_effective_groups(context):
		if group != excluded:
			return group
	return null


func _append_effective_group(
	result: Array[InterestGroupDefinition],
	state: RunState,
	group: InterestGroupDefinition
) -> void:
	var effective := _resolve_merger(state, group)
	if effective != null and effective not in result:
		result.append(effective)


func _resolve_merger(state: RunState, group: InterestGroupDefinition) -> InterestGroupDefinition:
	var current := group
	var visited: Dictionary[InterestGroupDefinition, bool] = {}
	while current != null and state.constitution.group_mergers.has(current):
		if visited.has(current):
			break
		visited[current] = true
		current = state.constitution.group_mergers[current]
	return current


func _restore_constitution_base_groups(context: RunContext) -> void:
	for seat in context.state.seats:
		if seat.race == null or seat.race is ZhushuiRaceDefinition:
			seat.actual_group = null
			continue
		if seat.race.fixed_interest_group != null:
			seat.base_group = seat.race.fixed_interest_group
			seat.annual_group = seat.race.fixed_interest_group
			seat.actual_group = _resolve_merger(context.state, seat.race.fixed_interest_group)
			continue
		var underlying := seat.annual_group
		if underlying == null:
			underlying = seat.base_group
		seat.actual_group = _resolve_merger(context.state, underlying)
