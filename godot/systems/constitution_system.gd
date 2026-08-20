extends RefCounted
class_name ConstitutionSystem


func initialize(context: RunContext) -> void:
	context.state.constitution = ConstitutionState.new()
	for race in context.race_definitions:
		var initial: ConstitutionArticleDefinition
		for definition in context.constitution_articles:
			if definition == null or definition.race != race or not definition.is_initial:
				continue
			if initial != null:
				push_error("A race can have at most one initial constitution article.")
				continue
			initial = definition
		if initial != null:
			context.state.constitution.active_articles[race] = initial
			context.state.constitution.clicked_articles[initial] = true
	refresh_runtime(context)


func activate_initial_articles(context: RunContext) -> void:
	for article in get_active_articles(context):
		article.on_activate(context)


func can_revise(context: RunContext, definition: ConstitutionArticleDefinition) -> bool:
	if (
		definition == null
		or definition.race == null
		or not context.state.constitution.revision_available
		or definition.race not in context.race_definitions
		or context.state.constitution.get_active_article(definition.race) == definition
	):
		return false
	return definition.can_activate(context)


func revise(context: RunContext, definition: ConstitutionArticleDefinition) -> bool:
	if not can_revise(context, definition):
		return false
	var previous := context.state.constitution.get_active_article(definition.race)
	context.state.constitution.active_articles[definition.race] = definition
	refresh_runtime(context)
	if not context.race_system.allocate_seats(context):
		if previous == null:
			context.state.constitution.active_articles.erase(definition.race)
		else:
			context.state.constitution.active_articles[definition.race] = previous
		refresh_runtime(context)
		return false
	context.state.constitution.clicked_articles[definition] = true
	context.state.constitution.revision_available = false
	context.collapse_system.record_intervention(
		context, &"constitution_revision", context.balance.constitution_revision_pressure
	)
	definition.on_activate(context)
	apply_influence_rules(context)
	return true


func refresh_runtime(context: RunContext) -> void:
	var state := context.state
	state.petition_race = null
	state.petition_limit = 0
	state.donation_detection_probability = context.balance.donation_detection_probability
	state.event_early_reveal_bonus_probability = 0.0
	state.constitution.group_mergers.clear()
	for race in state.races:
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
	for race in context.race_definitions:
		var article := context.state.constitution.get_active_article(race)
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


func get_effective_groups(context: RunContext) -> Array[InterestGroupDefinition]:
	var result: Array[InterestGroupDefinition] = []
	for group in context.interest_groups:
		_append_effective_group(result, context.state, group)
	for seat in context.state.seats:
		var local: InterestGroupDefinition = context.state.constitution.local_interest_groups.get(
			seat.definition
		)
		_append_effective_group(result, context.state, local)
	return result


func on_month_start(context: RunContext) -> void:
	for article in get_active_articles(context):
		article.on_month_start(context)


func on_year_settlement(context: RunContext) -> void:
	for article in get_active_articles(context):
		article.on_year_settlement(context)


func modify_vote(vote_context: VoteContext) -> void:
	if vote_context == null or vote_context.race_state == null:
		return
	var article := vote_context.run_context.state.constitution.get_active_article(
		vote_context.race_state.definition
	)
	if article != null:
		article.modify_vote(vote_context)


func get_race_seat_constraint(
	context: RunContext, race: RaceDefinition
) -> RaceSeatConstraint:
	var pool := context.state.seats.size()
	var article := context.state.constitution.get_active_article(race)
	var minimum := 0 if article == null else ceili(article.race_min_seat_rate * pool)
	var maximum := pool if article == null else floori(article.race_max_seat_rate * pool)
	if _has_anchor(context, race):
		minimum = maxi(minimum, 1)
		maximum = maxi(maximum, 1)
	return RaceSeatConstraint.new(minimum, maximum)


func get_race_seat_constraints(
	context: RunContext
) -> Dictionary[RaceDefinition, RaceSeatConstraint]:
	var result: Dictionary[RaceDefinition, RaceSeatConstraint] = {}
	for race in context.race_definitions:
		result[race] = get_race_seat_constraint(context, race)
	return result


func apply_influence_rules(context: RunContext) -> void:
	for article in get_active_articles(context):
		for rule in article.influence_rules:
			if rule != null and rule.interest_group != null:
				_apply_influence_rule(context, rule)


func _apply_influence_rule(context: RunContext, rule: ConstitutionInfluenceRule) -> void:
	var eligible := context.parliament_system.get_influenceable_seats(
		context.state, rule.race
	)
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
	if seat.base_group != null and seat.base_group != excluded:
		return seat.base_group
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


func _resolve_merger(
	state: RunState, group: InterestGroupDefinition
) -> InterestGroupDefinition:
	var current := group
	var visited: Dictionary[InterestGroupDefinition, bool] = {}
	while current != null and state.constitution.group_mergers.has(current):
		if visited.has(current):
			break
		visited[current] = true
		current = state.constitution.group_mergers[current]
	return current


func _has_anchor(context: RunContext, race: RaceDefinition) -> bool:
	for definition in context.seat_definitions:
		if definition.anchor_race == race:
			return true
	return false
