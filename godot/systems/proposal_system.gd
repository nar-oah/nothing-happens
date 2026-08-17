extends RefCounted
class_name ProposalSystem

const DEV_DRAW_BASE_WEIGHT: float = 1.0
const DEV_DRAW_REVERSE_FACTOR: float = 3.0
const DEV_DRAW_MIN_WEIGHT: float = 0.5
const DEV_DRAW_MAX_WEIGHT: float = 2.0
const DEV_DIGESTION_SPEED_MIN: float = 0.8
const DEV_DIGESTION_SPEED_MAX: float = 1.2
const DEV_POSITIVE_MAGNITUDE_MIN: int = 5
const DEV_POSITIVE_MAGNITUDE_MAX: int = 8
const DEV_VISIT_BASE_PROBABILITY: float = 0.05
const DEV_VISIT_REVERSE_FACTOR: float = 0.3
const DEV_VISIT_MIN_PROBABILITY: float = 0.02
const DEV_VISIT_MAX_PROBABILITY: float = 0.18
const MERGE_CONVERSION_RATIO: float = 0.5
const MERGE_UPGRADE_EXPONENT: float = 1.0


func calculate_total_effect(proposals: Array[ProposalInstance]) -> MetricVector:
	var total := MetricVector.new()
	for proposal in proposals:
		total.add(proposal.get_total_effect())
	return total


func calculate_pure_target(
	start_values: MetricValues, proposals: Array[ProposalInstance]
) -> MetricValues:
	var target := start_values.copy()
	var total_effect := calculate_total_effect(proposals)
	target.apply_delta(total_effect)
	return target


func create_active_states(proposals: Array[ProposalInstance]) -> Array[ActiveProposalState]:
	var result: Array[ActiveProposalState] = []
	for proposal in proposals:
		var active_copy := proposal.copy()
		result.append(ActiveProposalState.new(active_copy))
	return result


func calculate_digested_anchor(bill: ActiveBillState) -> MetricValues:
	var tax := float(bill.start_values.tax)
	var price := float(bill.start_values.price)
	var wage := float(bill.start_values.wage)
	var employment := float(bill.start_values.employment)
	var trade := float(bill.start_values.trade)

	for active_proposal in bill.proposals:
		var effect := active_proposal.proposal.get_total_effect()
		var progress := clampf(active_proposal.digestion_progress, 0.0, 1.0)

		tax += effect.tax * progress
		price += effect.price * progress
		wage += effect.wage * progress
		employment += effect.employment * progress
		trade += effect.trade * progress

	var result := MetricValues.new()

	result.tax = roundi(tax)
	result.price = roundi(price)
	result.wage = roundi(wage)
	result.employment = roundi(employment)
	result.trade = roundi(trade)

	return result


func generate_automatic_proposal(
	definition: ProposalDefinition,
	state: RunState,
	inflation_system: InflationSystem,
	random_system: RandomSystem
) -> ProposalInstance:
	var proposal := ProposalInstance.new()
	proposal.definition_id = definition.id
	proposal.source_group_id = definition.source_group_id
	proposal.base_effect = inflation_system.generate_negative_effect(
		definition, state.year, random_system
	)
	proposal.digestion_speed = random_system.random_float(
		DEV_DIGESTION_SPEED_MIN, DEV_DIGESTION_SPEED_MAX
	)
	proposal.political_support = definition.political_support
	proposal.collapse_impact = definition.collapse_impact
	return proposal


func add_positive_trait(
	proposal: ProposalInstance,
	year: int,
	inflation_system: InflationSystem,
	random_system: RandomSystem
) -> void:
	if proposal == null:
		return
	proposal.positive_effect = MetricVector.new()
	var metric := Metric.all_ids()[random_system.random_int(0, Metric.all_ids().size() - 1)]
	var base_magnitude := random_system.random_int(
		DEV_POSITIVE_MAGNITUDE_MIN, DEV_POSITIVE_MAGNITUDE_MAX
	)
	var magnitude := maxi(1, roundi(base_magnitude * inflation_system.get_era_multiplier(year)))
	proposal.positive_effect.set_value(metric, magnitude * Metric.favorable_sign(metric))


func add_to_hand(state: RunState, proposal: ProposalInstance) -> void:
	if proposal == null:
		push_error("Cannot add null proposal to hand.")
		return
	state.proposal_hand.append(proposal)


func calculate_automatic_draw_weight(current_influence: float, baseline_influence: float) -> float:
	return clampf(
		DEV_DRAW_BASE_WEIGHT + DEV_DRAW_REVERSE_FACTOR * (baseline_influence - current_influence),
		DEV_DRAW_MIN_WEIGHT,
		DEV_DRAW_MAX_WEIGHT
	)


func calculate_visit_probability(current_influence: float, baseline_influence: float) -> float:
	return clampf(
		DEV_VISIT_BASE_PROBABILITY
		+ DEV_VISIT_REVERSE_FACTOR * (baseline_influence - current_influence),
		DEV_VISIT_MIN_PROBABILITY,
		DEV_VISIT_MAX_PROBABILITY
	)


func choose_automatic_source(
	groups: Array[InterestGroupDefinition], context: RunContext
) -> InterestGroupDefinition:
	var candidates: Array[InterestGroupDefinition] = []
	for group in groups:
		if group == null:
			continue
		if group.proposal_definition == null:
			continue
		candidates.append(group)
	if candidates.is_empty():
		return null
	var baseline_influence := 1.0 / float(candidates.size())
	var weights: Array[float] = []
	for group in candidates:
		var current_influence := context.parliament_system.get_group_influence_rate(
			context.state, group.id
		)
		weights.append(calculate_automatic_draw_weight(current_influence, baseline_influence))
	var selected_index := context.random_system.weighted_index(weights)
	if selected_index < 0:
		return null
	return candidates[selected_index]


func draw_automatic_proposal(
	groups: Array[InterestGroupDefinition], context: RunContext
) -> ProposalInstance:
	var source := choose_automatic_source(groups, context)
	if source == null:
		return null
	return generate_automatic_proposal(
		source.proposal_definition, context.state, context.inflation_system, context.random_system
	)


func draw_automatic_proposals(
	groups: Array[InterestGroupDefinition], count: int, context: RunContext
) -> void:
	for i in range(maxi(count, 0)):
		var proposal := draw_automatic_proposal(groups, context)
		if proposal == null:
			continue
		add_to_hand(context.state, proposal)


func resolve_active_visits(
	groups: Array[InterestGroupDefinition], context: RunContext
) -> Array[ProposalInstance]:
	var result: Array[ProposalInstance] = []
	var candidates: Array[InterestGroupDefinition] = []
	for group in groups:
		if group != null and group.proposal_definition != null:
			candidates.append(group)
	if candidates.is_empty():
		return result
	var baseline_influence := 1.0 / float(candidates.size())
	for group in candidates:
		var influence := context.parliament_system.get_group_influence_rate(
			context.state, group.id
		)
		var probability := calculate_visit_probability(influence, baseline_influence)
		if not context.random_system.chance(probability):
			continue
		var proposal := generate_automatic_proposal(
			group.proposal_definition,
			context.state,
			context.inflation_system,
			context.random_system
		)
		add_positive_trait(
			proposal,
			context.state.year,
			context.inflation_system,
			context.random_system
		)
		add_to_hand(context.state, proposal)
		result.append(proposal)
	return result


func merge_three(
	state: RunState,
	mothers: Array[ProposalInstance],
	negative_base: ProposalInstance,
	selected_positive: ProposalInstance = null
) -> ProposalInstance:
	if not _can_merge(state, mothers, negative_base, selected_positive):
		return null
	var result := negative_base.copy()
	result.positive_effect = MetricVector.new()
	if selected_positive != null:
		var metric_value := selected_positive.get_positive_metric()
		var metric: Metric.Id = metric_value
		var selected_magnitude := absi(selected_positive.positive_effect.get_value(metric))
		var discarded_magnitude := 0
		for mother in mothers:
			if mother == selected_positive or not mother.has_positive_trait():
				continue
			var discarded_metric: Metric.Id = mother.get_positive_metric()
			discarded_magnitude += absi(mother.positive_effect.get_value(discarded_metric))
		var converted := float(discarded_magnitude) * MERGE_CONVERSION_RATIO
		var upgraded := maxi(1, roundi(pow(float(selected_magnitude) + converted, MERGE_UPGRADE_EXPONENT)))
		result.positive_effect.set_value(metric, upgraded * Metric.favorable_sign(metric))
	for mother in mothers:
		state.proposal_hand.erase(mother)
	state.proposal_hand.append(result)
	return result


func _can_merge(
	state: RunState,
	mothers: Array[ProposalInstance],
	negative_base: ProposalInstance,
	selected_positive: ProposalInstance
) -> bool:
	if mothers.size() != 3 or negative_base == null or negative_base not in mothers:
		return false
	if mothers[0] == null:
		return false
	var seen: Dictionary[int, bool] = {}
	var group_id: StringName = mothers[0].source_group_id
	for mother in mothers:
		if mother == null or mother not in state.proposal_hand:
			return false
		if mother.source_group_id != group_id or seen.has(mother.get_instance_id()):
			return false
		seen[mother.get_instance_id()] = true
	if selected_positive == null:
		for mother in mothers:
			if mother.has_positive_trait():
				return false
		return true
	return selected_positive in mothers and selected_positive.has_positive_trait()
