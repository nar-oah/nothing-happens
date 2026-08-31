extends RefCounted
class_name ConstitutionSystem

const DEFAULT_PARLIAMENT_NAME := "联合议会"


func initialize(context: RunContext) -> bool:
	context.state.constitution = ConstitutionState.new()
	if context.constitution_board != null:
		if not _initialize_from_board(context):
			return false
	else:
		if not _initialize_flat_content(context):
			return false
	refresh_runtime(context)
	return true


func _initialize_from_board(context: RunContext) -> bool:
	var board := context.constitution_board
	if not board.validate():
		return false
	var center := board.get_center_column_index()
	for row in board.get_rows():
		var initial := board.get_article(row, center)
		if initial == null or initial.is_terminal:
			push_error("Every constitution row requires a non-terminal center article.")
			return false
		context.state.constitution.active_articles[row] = initial
	context.constitution_articles = board.get_articles()
	return true


func _initialize_flat_content(context: RunContext) -> bool:
	for definition in context.constitution_articles:
		if definition == null or definition.get_race() == null or not definition.is_initial:
			continue
		var row := definition.row
		if row == null:
			row = ConstitutionRowDefinition.new()
			row.display_name = definition.get_race().display_name
			row.race = definition.get_race()
		context.state.constitution.active_articles[row] = definition
	return not context.state.constitution.active_articles.is_empty()


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


func get_active_effects(
	context: RunContext, timing: int = -1
) -> Array[ConstitutionEffect]:
	var result: Array[ConstitutionEffect] = []
	for article in get_active_articles(context):
		for effect in article.effects:
			if effect == null:
				continue
			if timing < 0 or int(effect.timing) == timing:
				result.append(effect)
	return result


func run_effects(context: RunContext, timing: ConstitutionEffect.Timing) -> void:
	for effect in get_active_effects(context, int(timing)):
		effect.apply(context)


func refresh_runtime(context: RunContext) -> void:
	for race in context.state.races:
		if race != null:
			race.active_definition = race.definition
	context.state.constitution.group_variants.clear()
	context.state.constitution.group_mergers.clear()
	context.state.constitution.local_interest_groups.clear()
	run_effects(context, ConstitutionEffect.Timing.RUNTIME_REBUILD)


func can_revise(context: RunContext, definition: ConstitutionArticleDefinition) -> bool:
	if definition == null or not context.state.constitution.revision_available:
		return false
	if definition.is_terminal:
		var selected_terminal := context.state.constitution.terminal_article
		if selected_terminal != null and selected_terminal != definition:
			return false
	if context.constitution_board == null:
		return definition.can_activate(context)
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
		if context.meta_progression == null or not context.meta_progression.is_column_unlocked(board.columns[target_column]):
			return false
	var current_column := board.get_column_index_for_article(current)
	var center := board.get_center_column_index()
	if current_column < 0 or center < 0:
		return false
	var direction := -1 if target_column < center else 1
	if current_column != center:
		direction = -1 if current_column < center else 1
	if _next_article_outward(board, definition.row, current_column, direction) != definition:
		return false
	return definition.can_activate(context)


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
	var race_snapshot: Dictionary[SeatState, RaceDefinition] = {}
	var fixed_snapshot: Dictionary[SeatState, RaceDefinition] = {}
	var base_snapshot: Dictionary[SeatState, InterestGroupDefinition] = {}
	var annual_snapshot: Dictionary[SeatState, InterestGroupDefinition] = {}
	var actual_snapshot: Dictionary[SeatState, InterestGroupDefinition] = {}
	for seat in context.state.seats:
		race_snapshot[seat] = seat.race
		fixed_snapshot[seat] = seat.fixed_race
		base_snapshot[seat] = seat.base_group
		annual_snapshot[seat] = seat.annual_group
		actual_snapshot[seat] = seat.actual_group
	context.state.constitution.active_articles[row] = definition
	refresh_runtime(context)
	run_effects(context, ConstitutionEffect.Timing.BEFORE_SEAT_ALLOCATION)
	if not context.race_system.reconcile_seat_participation(context):
		context.state.constitution.active_articles[row] = previous
		for seat in context.state.seats:
			seat.race = race_snapshot[seat]
			seat.fixed_race = fixed_snapshot[seat]
			seat.base_group = base_snapshot[seat]
			seat.annual_group = annual_snapshot[seat]
			seat.actual_group = actual_snapshot[seat]
		refresh_runtime(context)
		return false
	context.parliament_system.normalize_groups_after_race_change(context)
	run_effects(context, ConstitutionEffect.Timing.AFTER_SEAT_ALLOCATION)
	run_effects(context, ConstitutionEffect.Timing.AFTER_GROUP_ALLOCATION)
	run_effects(context, ConstitutionEffect.Timing.ON_ACTIVATE)
	context.race_system.rebuild_annual_expectations(context)
	context.state.constitution.revision_available = false
	if definition.is_terminal:
		context.state.constitution.terminal_article = definition
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


func get_active_race_definition(context: RunContext, race: RaceDefinition) -> RaceDefinition:
	var state := null if context == null or context.state == null else context.state.get_race(race)
	return race if state == null or state.active_definition == null else state.active_definition


func resolve_group_identity(
	context: RunContext, group: InterestGroupDefinition
) -> InterestGroupDefinition:
	if context == null or context.state == null:
		return group
	var current := group
	var visited: Dictionary[InterestGroupDefinition, bool] = {}
	while current != null and context.state.constitution.group_mergers.has(current):
		if visited.has(current):
			break
		visited[current] = true
		current = context.state.constitution.group_mergers[current]
	return current


func get_active_group_definition(
	context: RunContext, group: InterestGroupDefinition
) -> InterestGroupDefinition:
	var identity := resolve_group_identity(context, group)
	if identity == null:
		return null
	return context.state.constitution.group_variants.get(identity, identity)


func get_effective_groups(context: RunContext) -> Array[InterestGroupDefinition]:
	var identities: Array[InterestGroupDefinition] = []
	for group in context.interest_groups:
		_append_group_identity(identities, context, group)
	for race in context.race_definitions:
		if race != null:
			_append_group_identity(identities, context, race.fixed_interest_group)
	for local in context.state.constitution.local_interest_groups.values():
		_append_group_identity(identities, context, local)
	return identities


func _append_group_identity(
	result: Array[InterestGroupDefinition], context: RunContext, group: InterestGroupDefinition
) -> void:
	var identity := resolve_group_identity(context, group)
	if identity != null and identity not in result:
		result.append(identity)


func merge_groups_below_threshold(
	context: RunContext, target_group: InterestGroupDefinition, threshold: float
) -> void:
	if target_group == null:
		return
	var target := resolve_group_identity(context, target_group)
	var candidates: Array[InterestGroupDefinition] = []
	for group in context.interest_groups:
		if group != null and group not in candidates:
			candidates.append(group)
	for race in context.race_definitions:
		if race != null and race.fixed_interest_group != null and race.fixed_interest_group not in candidates:
			candidates.append(race.fixed_interest_group)
	for group in candidates:
		var identity := resolve_group_identity(context, group)
		if identity == null or identity == target:
			continue
		if context.parliament_system.get_group_influence_rate(context.state, identity) < threshold:
			context.state.constitution.group_mergers[identity] = target
	for seat in context.state.seats:
		seat.actual_group = resolve_group_identity(context, seat.actual_group)


func race_participates_in_variable_seat_allocation(
	context: RunContext, race: RaceDefinition
) -> bool:
	if race == null or race is ZhushuiRaceDefinition:
		return false
	var result := true
	for effect in get_active_effects(context, int(ConstitutionEffect.Timing.BEFORE_SEAT_ALLOCATION)):
		if effect is RaceSeatEffect and effect.applies_to(race):
			result = effect.participates_in_variable_seat_allocation
	return result


func race_fixed_seat_enabled(context: RunContext, race: RaceDefinition) -> bool:
	var result := true
	for effect in get_active_effects(context, int(ConstitutionEffect.Timing.BEFORE_SEAT_ALLOCATION)):
		if effect is RaceSeatEffect and effect.applies_to(race):
			result = effect.fixed_seat_enabled
	return result


func get_race_seat_constraint(context: RunContext, race: RaceDefinition) -> RaceSeatConstraint:
	if race == null:
		return RaceSeatConstraint.new(0, 0)
	var fixed_count := context.parliament_system.get_fixed_seat_count(context.state, race)
	if not race_participates_in_variable_seat_allocation(context, race):
		return RaceSeatConstraint.new(fixed_count, fixed_count)
	var variable_pool := context.parliament_system.get_variable_seats(context.state).size()
	return RaceSeatConstraint.new(fixed_count, fixed_count + variable_pool)


func get_variable_race_seat_constraint(
	context: RunContext, race: RaceDefinition
) -> RaceSeatConstraint:
	if not race_participates_in_variable_seat_allocation(context, race):
		return RaceSeatConstraint.new(0, 0)
	return RaceSeatConstraint.new(0, context.parliament_system.get_variable_seats(context.state).size())


func get_expectation_growth_multiplier(context: RunContext, race: RaceDefinition) -> float:
	var result := 1.0
	for effect in get_active_effects(context):
		result *= effect.get_expectation_growth_multiplier(race)
	return maxf(result, 0.0)


func get_event_intel_probability_modifier(context: RunContext, race: RaceDefinition) -> float:
	var result := 0.0
	for effect in get_active_effects(context):
		result += effect.get_event_intel_probability_modifier(race)
	return result


func get_donation_detection_probability(context: RunContext) -> float:
	var result := context.balance.donation_detection_probability
	for effect in get_active_effects(context):
		result = effect.override_donation_detection_probability(result)
	return clampf(result, 0.0, 1.0)


func get_parliament_name(context: RunContext) -> String:
	var result := DEFAULT_PARLIAMENT_NAME
	for effect in get_active_effects(context):
		result = effect.override_parliament_name(result)
	return result


func get_petition_limit(context: RunContext) -> int:
	var result := 0
	for effect in get_active_effects(context):
		result += maxi(effect.get_petition_count(context), 0)
	return result


func can_petition_event(context: RunContext, race: RaceDefinition) -> bool:
	for effect in get_active_effects(context):
		if effect.can_petition_event(race):
			return true
	return false


func validate_draft(context: RunContext, draft: DraftBillState, pure_target: MetricValues) -> bool:
	for effect in get_active_effects(context, int(ConstitutionEffect.Timing.BEFORE_DRAFT_SUBMIT)):
		if not effect.validate_draft(context, draft, pure_target):
			return false
	return true


func apply_vote_effects(vote_context: VoteContext) -> void:
	if vote_context == null:
		return
	for effect in get_active_effects(vote_context.run_context, int(ConstitutionEffect.Timing.BEFORE_SUPPORT_CALCULATION)):
		effect.apply_vote(vote_context)
