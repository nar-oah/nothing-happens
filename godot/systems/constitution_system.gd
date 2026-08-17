extends RefCounted
class_name ConstitutionSystem

const FLAG_FREE_TRADE: StringName = &"free_trade"
const FLAG_YANO_RECOGNIZED: StringName = &"yano_recognized"
const FLAG_PEACH_CLOSED: StringName = &"peach_closed"
const MERGER_STRONG_RATE: float = 0.5
const MERGER_WEAK_RATE: float = 0.05


func initialize(
	state: RunState, definitions: Array[ConstitutionArticleDefinition]
) -> void:
	state.constitution = ConstitutionState.new()
	for definition in definitions:
		if definition != null and definition.is_initial:
			state.constitution.active_articles[definition.axis_id] = definition
			if definition.is_terminal:
				state.constitution.terminal_article_id = definition.id


func can_revise(
	state: RunState, definition: ConstitutionArticleDefinition
) -> bool:
	if definition == null or not state.constitution.revision_available:
		return false
	if definition.is_regulation:
		return true
	if definition.is_terminal and state.constitution.terminal_article_id != &"":
		return false
	var current := state.constitution.get_active_article(definition.axis_id)
	if current == null:
		return definition.level <= 1 and _threshold_met(state, definition)
	if current.is_terminal:
		return false
	if definition.level != current.level + 1:
		return false
	if current.direction != 0 and definition.direction != current.direction:
		return false
	if definition.prerequisite_id != &"" and definition.prerequisite_id != current.id:
		return false
	return _threshold_met(state, definition)


func revise(context: RunContext, definition: ConstitutionArticleDefinition) -> bool:
	if not can_revise(context.state, definition):
		return false
	var had_free_trade := context.state.constitution.has_flag(FLAG_FREE_TRADE)
	context.state.constitution.active_articles[definition.axis_id] = definition
	context.state.constitution.revision_available = false
	if definition.is_terminal:
		context.state.constitution.terminal_article_id = definition.id
	context.collapse_system.record_intervention(
		context.state, &"constitution_revision", 3.0
	)
	_rebuild_article_affected_row(context, definition)
	apply_annual_influence_rules(context)
	if not had_free_trade and context.state.constitution.has_flag(FLAG_FREE_TRADE):
		apply_free_trade_mergers(context.state)
		apply_special_fixed_relations(context.state)
		update_petition_count(context.state)
	return true


func get_race_support_modifier(state: RunState, race_id: StringName) -> float:
	var result := 0.0
	for article in state.constitution.active_articles.values():
		if article != null and article.support_race_id == race_id:
			result += article.base_support_modifier
	return result


func get_unlocked_policies(state: RunState) -> Array[PolicyDefinition]:
	var result: Array[PolicyDefinition] = []
	var seen: Dictionary[StringName, bool] = {}
	for article in state.constitution.active_articles.values():
		if article == null:
			continue
		for policy in article.unlocked_policies:
			if policy != null and not seen.has(policy.id):
				seen[policy.id] = true
				result.append(policy)
	return result


func apply_annual_seat_corrections(state: RunState) -> void:
	for article in state.constitution.active_articles.values():
		if article == null or article.seat_race_id == &"":
			continue
		var race := state.get_race(article.seat_race_id)
		if race == null:
			continue
		if article.fixed_seat_count >= 0:
			race.seat_count = article.fixed_seat_count
		else:
			if article.seat_minimum >= 0:
				race.seat_count = maxi(race.seat_count, article.seat_minimum)
			if article.seat_maximum >= 0:
				race.seat_count = mini(race.seat_count, article.seat_maximum)
	for race in state.races:
		if (
			race.definition != null
			and race.definition.special_mechanism == RaceDefinition.SpecialMechanism.HUMAN
			and state.constitution.has_flag(FLAG_FREE_TRADE)
		):
			race.seat_count = 1


func get_effective_groups(
	state: RunState, groups: Array[InterestGroupDefinition]
) -> Array[InterestGroupDefinition]:
	var removed: Dictionary[StringName, bool] = {}
	var mergers := state.constitution.group_mergers.duplicate()
	for rule in state.constitution.get_influence_rules():
		if rule == null or rule.priority != ConstitutionInfluenceRule.Priority.TERMINAL:
			continue
		if rule.action == ConstitutionInfluenceRule.Action.REMOVE_GROUP:
			removed[rule.source_group_id] = true
		elif rule.action == ConstitutionInfluenceRule.Action.MERGE_GROUP:
			mergers[rule.source_group_id] = rule.target_group_id
	var by_id: Dictionary[StringName, InterestGroupDefinition] = {}
	for source in groups:
		if source == null or removed.has(source.id):
			continue
		var target_id := _resolve_merger(source.id, mergers)
		if removed.has(target_id):
			continue
		if not by_id.has(target_id):
			var clone := _clone_group(source)
			clone.id = target_id
			clone.base_column_weight = 0
			by_id[target_id] = clone
		by_id[target_id].base_column_weight += source.base_column_weight
	var result: Array[InterestGroupDefinition] = []
	for group in by_id.values():
		result.append(group)
	result.sort_custom(func(a: InterestGroupDefinition, b: InterestGroupDefinition) -> bool:
		return a.fixed_sort_order < b.fixed_sort_order
	)
	return result


func apply_annual_influence_rules(context: RunContext) -> void:
	var rules := context.state.constitution.get_influence_rules()
	for priority in range(ConstitutionInfluenceRule.Priority.TARGET + 1):
		for rule in rules:
			if rule != null and rule.priority == priority:
				_apply_rule(context.state, rule)
		if priority == ConstitutionInfluenceRule.Priority.MERGER:
			apply_free_trade_mergers(context.state)
		if priority == ConstitutionInfluenceRule.Priority.FIXED:
			apply_special_fixed_relations(context.state)
	if context.state.constitution.has_flag(FLAG_FREE_TRADE):
		_apply_pending_targets(context.state)
	update_petition_count(context.state)


func apply_free_trade_mergers(state: RunState) -> void:
	if not state.constitution.has_flag(FLAG_FREE_TRADE) or state.seats.is_empty():
		return
	var counts: Dictionary[StringName, int] = {}
	for seat in state.seats:
		counts[seat.actual_group_id] = counts.get(seat.actual_group_id, 0) + 1
	var strongest: StringName
	var strongest_rate := 0.0
	for group_id in counts:
		var rate := float(counts[group_id]) / float(state.seats.size())
		if rate > MERGER_STRONG_RATE and rate > strongest_rate:
			strongest = group_id
			strongest_rate = rate
	if strongest == &"":
		return
	for group_id in counts:
		var rate := float(counts[group_id]) / float(state.seats.size())
		if group_id == strongest or rate >= MERGER_WEAK_RATE:
			continue
		state.constitution.group_mergers[group_id] = strongest
		for seat in state.seats:
			if seat.actual_group_id == group_id and seat.influence_priority >= 1:
				seat.actual_group_id = strongest
				seat.influence_priority = 1


func apply_special_fixed_relations(state: RunState) -> void:
	for race in state.races:
		if race.definition == null:
			continue
		var mechanism := race.definition.special_mechanism
		if mechanism == RaceDefinition.SpecialMechanism.YANO and state.constitution.has_flag(FLAG_YANO_RECOGNIZED):
			_fix_race(state, race.get_id(), race.definition.special_group_id, 2)
		elif mechanism == RaceDefinition.SpecialMechanism.PEACH_BLOSSOM and state.constitution.has_flag(FLAG_PEACH_CLOSED):
			_localize_race(state, race.get_id(), race.definition.local_group_prefix, 0)
		elif mechanism == RaceDefinition.SpecialMechanism.HUMAN and state.constitution.has_flag(FLAG_FREE_TRADE):
			_fix_race(state, race.get_id(), race.definition.special_group_id, 2)


func update_petition_count(state: RunState) -> void:
	state.constitution.annual_petition_count = 0
	if not state.constitution.has_flag(FLAG_FREE_TRADE):
		return
	var human := _find_special_race(state, RaceDefinition.SpecialMechanism.HUMAN)
	if human == null:
		return
	var group_id := human.definition.special_group_id
	var count := 0
	for seat in state.seats:
		if seat.actual_group_id == group_id:
			count += 1
	var rate := 0.0 if state.seats.is_empty() else float(count) / float(state.seats.size())
	if rate >= 0.9:
		state.constitution.annual_petition_count = 3
	elif rate >= 0.5:
		state.constitution.annual_petition_count = 2
	elif rate >= 0.2:
		state.constitution.annual_petition_count = 1


func add_next_year_group_target(
	state: RunState, group_id: StringName, additional_seats: int
) -> bool:
	if additional_seats <= 0:
		return false
	var free_capacity := 0
	for seat in state.seats:
		if seat.influence_priority >= 4 and seat.actual_group_id != group_id:
			free_capacity += 1
	if free_capacity < additional_seats:
		return false
	state.constitution.pending_group_seat_targets[group_id] = (
		state.constitution.pending_group_seat_targets.get(group_id, 0) + additional_seats
	)
	return true


func _threshold_met(state: RunState, definition: ConstitutionArticleDefinition) -> bool:
	match definition.threshold_kind:
		ConstitutionArticleDefinition.ThresholdKind.NONE:
			return true
		ConstitutionArticleDefinition.ThresholdKind.RACE_SEAT_RATE:
			if state.seats.is_empty():
				return false
			var count := 0
			for seat in state.seats:
				if seat.race_id == definition.threshold_target_id:
					count += 1
			return float(count) / float(state.seats.size()) >= definition.threshold_rate
		ConstitutionArticleDefinition.ThresholdKind.GROUP_INFLUENCE_RATE:
			if state.seats.is_empty():
				return false
			var count := 0
			for seat in state.seats:
				if seat.actual_group_id == definition.threshold_target_id:
					count += 1
			return float(count) / float(state.seats.size()) >= definition.threshold_rate
	return false


func _apply_rule(state: RunState, rule: ConstitutionInfluenceRule) -> void:
	match rule.action:
		ConstitutionInfluenceRule.Action.REMOVE_GROUP:
			_replace_group(state, rule.source_group_id, rule.target_group_id, rule.priority)
		ConstitutionInfluenceRule.Action.MERGE_GROUP:
			state.constitution.group_mergers[rule.source_group_id] = rule.target_group_id
			_replace_group(state, rule.source_group_id, rule.target_group_id, rule.priority)
		ConstitutionInfluenceRule.Action.LOCALIZE:
			_localize_race(state, rule.race_id, rule.local_group_prefix, rule.priority)
		ConstitutionInfluenceRule.Action.FIX_RACE_TO_GROUP:
			_fix_race(state, rule.race_id, rule.target_group_id, rule.priority)
		ConstitutionInfluenceRule.Action.GROUP_MINIMUM:
			_apply_group_limit(state, rule, true)
		ConstitutionInfluenceRule.Action.GROUP_MAXIMUM:
			_apply_group_limit(state, rule, false)
		ConstitutionInfluenceRule.Action.GROUP_TARGET:
			_apply_group_target(state, rule.target_group_id, ceili(rule.rate * _eligible_seats(state, rule.race_id).size()), rule.race_id)


func _apply_group_limit(
	state: RunState, rule: ConstitutionInfluenceRule, is_minimum: bool
) -> void:
	var eligible := _eligible_seats(state, rule.race_id)
	var target_count := ceili(rule.rate * eligible.size()) if is_minimum else floori(rule.rate * eligible.size())
	var current: Array[SeatState] = []
	for seat in eligible:
		if seat.actual_group_id == rule.target_group_id:
			current.append(seat)
	if is_minimum:
		var needed := target_count - current.size()
		for seat in eligible:
			if needed <= 0:
				break
			if seat.actual_group_id != rule.target_group_id and seat.influence_priority >= rule.priority:
				seat.actual_group_id = rule.target_group_id
				seat.influence_priority = rule.priority
				needed -= 1
	else:
		var excess := current.size() - target_count
		for seat in current:
			if excess <= 0:
				break
			if seat.influence_priority < rule.priority:
				continue
			seat.actual_group_id = _fallback_group(state, seat, rule.target_group_id)
			seat.influence_priority = rule.priority
			excess -= 1


func _apply_group_target(
	state: RunState, group_id: StringName, target_count: int, race_id: StringName = &""
) -> void:
	var eligible := _eligible_seats(state, race_id)
	var current := 0
	for seat in eligible:
		if seat.actual_group_id == group_id:
			current += 1
	var needed := target_count - current
	for seat in eligible:
		if needed <= 0:
			break
		if seat.actual_group_id != group_id and seat.influence_priority >= 4:
			seat.actual_group_id = group_id
			seat.influence_priority = 4
			needed -= 1


func _apply_pending_targets(state: RunState) -> void:
	for group_id in state.constitution.pending_group_seat_targets:
		var current := 0
		for seat in state.seats:
			if seat.actual_group_id == group_id:
				current += 1
		var additional: int = state.constitution.pending_group_seat_targets[group_id]
		_apply_group_target(state, group_id, current + additional)
	state.constitution.pending_group_seat_targets.clear()


func _replace_group(
	state: RunState, source: StringName, target: StringName, priority: int
) -> void:
	for seat in state.seats:
		if seat.actual_group_id == source and seat.influence_priority >= priority:
			seat.actual_group_id = seat.base_group_id if target == &"" else target
			seat.influence_priority = priority


func _fix_race(state: RunState, race_id: StringName, group_id: StringName, priority: int) -> void:
	for seat in state.seats:
		if seat.race_id == race_id and seat.influence_priority >= priority:
			seat.actual_group_id = group_id
			seat.influence_priority = priority


func _localize_race(
	state: RunState, race_id: StringName, prefix: StringName, priority: int
) -> void:
	var index := 1
	for seat in state.seats:
		if (race_id == &"" or seat.race_id == race_id) and seat.influence_priority >= priority:
			var local_id := StringName("%s_%s" % [prefix, index])
			seat.base_group_id = local_id
			seat.actual_group_id = local_id
			seat.influence_priority = priority
			index += 1


func _eligible_seats(state: RunState, race_id: StringName) -> Array[SeatState]:
	var result: Array[SeatState] = []
	for seat in state.seats:
		if race_id == &"" or seat.race_id == race_id:
			result.append(seat)
	return result


func _fallback_group(state: RunState, seat: SeatState, excluded: StringName) -> StringName:
	if seat.base_group_id != excluded:
		return seat.base_group_id
	for candidate in state.seats:
		if candidate.base_group_id != excluded:
			return candidate.base_group_id
	return &""


func _resolve_merger(
	group_id: StringName, mergers: Dictionary[StringName, StringName]
) -> StringName:
	var current := group_id
	var visited: Dictionary[StringName, bool] = {}
	while mergers.has(current) and not visited.has(current):
		visited[current] = true
		current = mergers[current]
	return current


func _clone_group(source: InterestGroupDefinition) -> InterestGroupDefinition:
	var result := InterestGroupDefinition.new()
	result.id = source.id
	result.display_name = source.display_name
	result.base_column_weight = source.base_column_weight
	result.fixed_sort_order = source.fixed_sort_order
	result.proposal_definition = source.proposal_definition
	result.metric_stances = source.metric_stances
	result.base_support_modifier = source.base_support_modifier
	return result


func _find_special_race(state: RunState, mechanism: RaceDefinition.SpecialMechanism) -> RaceState:
	for race in state.races:
		if race.definition != null and race.definition.special_mechanism == mechanism:
			return race
	return null


func _rebuild_article_affected_row(
	context: RunContext, article: ConstitutionArticleDefinition
) -> void:
	if article.seat_race_id == &"":
		return
	var race := context.state.get_race(article.seat_race_id)
	if race == null:
		return
	apply_annual_seat_corrections(context.state)
	var groups := get_effective_groups(context.state, context.interest_groups)
	context.parliament_system.replace_race_row(context.state, race, groups)
