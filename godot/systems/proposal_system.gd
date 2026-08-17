extends RefCounted
class_name ProposalSystem

const DEV_DRAW_BASE_WEIGHT: float = 1.0
const DEV_DRAW_REVERSE_FACTOR: float = 3.0
const DEV_DRAW_MIN_WEIGHT: float = 0.5
const DEV_DRAW_MAX_WEIGHT: float = 2.0
const DEV_DIGESTION_SPEED_MIN: float = 0.8
const DEV_DIGESTION_SPEED_MAX: float = 1.2


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
	return proposal


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
