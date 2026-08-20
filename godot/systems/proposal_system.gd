extends RefCounted
class_name ProposalSystem


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


func generate_proposal(
	source_group: InterestGroupDefinition,
	state: RunState,
	inflation_system: InflationSystem,
	balance: GameBalanceDefinition,
	random_system: RandomSystem
) -> ProposalInstance:
	if source_group == null or source_group.get_stance_metrics().is_empty():
		return null
	var proposal := ProposalInstance.new()
	proposal.source_group = source_group
	proposal.base_effect = inflation_system.generate_negative_effect(
		source_group, state.year, balance, random_system
	)
	proposal.digestion_speed = random_system.random_float(
		balance.proposal_digestion_speed_min, balance.proposal_digestion_speed_max
	)
	proposal.collapse_impact = balance.proposal_collapse_impact
	return proposal


func add_positive_trait(
	proposal: ProposalInstance,
	year: int,
	inflation_system: InflationSystem,
	balance: GameBalanceDefinition,
	random_system: RandomSystem
) -> void:
	if proposal == null:
		return
	proposal.positive_effect = MetricVector.new()
	var metrics := Metric.all_ids()
	var metric := metrics[random_system.random_int(0, metrics.size() - 1)]
	var base_magnitude := random_system.random_int(
		balance.proposal_positive_magnitude_min, balance.proposal_positive_magnitude_max
	)
	var magnitude := roundi(
		float(base_magnitude)
		* inflation_system.get_proposal_magnitude_multiplier(year, balance)
	)
	proposal.positive_effect.set_value(metric, magnitude * Metric.favorable_sign(metric))
	proposal.donation_offer = float(absi(magnitude)) * balance.donation_per_positive_point
	proposal.bonus_choice_resolved = false


func resolve_bonus_choice(
	state: RunState, proposal: ProposalInstance, accept_trait: bool
) -> bool:
	if proposal == null or proposal.bonus_choice_resolved or not proposal.has_positive_trait():
		return false
	proposal.bonus_choice_resolved = true
	if not accept_trait:
		proposal.positive_effect = MetricVector.new()
		state.political_donation_pool += proposal.donation_offer
	return true


func add_to_hand(state: RunState, proposal: ProposalInstance) -> void:
	if proposal == null:
		push_error("Cannot add null proposal to hand.")
		return
	state.proposal_hand.append(proposal)


func calculate_automatic_draw_weight(
	current_influence: float,
	baseline_influence: float,
	balance: GameBalanceDefinition
) -> float:
	return clampf(
		(
			balance.proposal_draw_base_weight
			+ balance.proposal_draw_reverse_factor * (baseline_influence - current_influence)
		),
		balance.proposal_draw_min_weight,
		balance.proposal_draw_max_weight
	)


func choose_automatic_source(context: RunContext) -> InterestGroupDefinition:
	var candidates: Array[InterestGroupDefinition] = []
	for group in context.constitution_system.get_effective_groups(context):
		if group == null or group.get_stance_metrics().is_empty():
			continue
		candidates.append(group)
	if candidates.is_empty():
		return null
	var baseline_influence := 1.0 / float(candidates.size())
	var weights: Array[float] = []
	for group in candidates:
		var current_influence := context.parliament_system.get_group_influence_rate(
			context.state, group
		)
		weights.append(
			calculate_automatic_draw_weight(current_influence, baseline_influence, context.balance)
		)
	var selected_index := context.random_system.weighted_index(weights)
	if selected_index < 0:
		return null
	return candidates[selected_index]


func draw_automatic_proposal(context: RunContext) -> ProposalInstance:
	var source := choose_automatic_source(context)
	if source == null:
		return null
	return generate_proposal(
		source,
		context.state,
		context.inflation_system,
		context.balance,
		context.random_system
	)


func draw_automatic_proposals(context: RunContext) -> void:
	for index in range(context.balance.automatic_draw_count):
		var proposal := draw_automatic_proposal(context)
		if proposal == null:
			continue
		add_to_hand(context.state, proposal)


func resolve_active_visits(context: RunContext) -> Array[ProposalInstance]:
	var result: Array[ProposalInstance] = []
	for race_definition in context.race_definitions:
		var seats := context.parliament_system.get_race_seats(
			context.state, race_definition
		)
		if seats.is_empty():
			continue
		var race_state := context.state.get_race(race_definition)
		if race_state == null or not context.random_system.chance(race_state.visit_probability):
			continue
		var source := _choose_visit_source(seats, context.random_system)
		if source == null:
			continue
		var proposal := generate_proposal(
			source,
			context.state,
			context.inflation_system,
			context.balance,
			context.random_system
		)
		add_positive_trait(
			proposal,
			context.state.year,
			context.inflation_system,
			context.balance,
			context.random_system
		)
		add_to_hand(context.state, proposal)
		result.append(proposal)
	return result


func _choose_visit_source(
	seats: Array[SeatState], random_system: RandomSystem
) -> InterestGroupDefinition:
	var candidates: Array[InterestGroupDefinition] = []
	var counts: Dictionary[InterestGroupDefinition, int] = {}
	for seat in seats:
		var group := seat.actual_group
		if group == null or group.get_stance_metrics().is_empty():
			continue
		if not counts.has(group):
			candidates.append(group)
			counts[group] = 0
		counts[group] += 1
	var weights: Array[float] = []
	for group in candidates:
		weights.append(float(counts[group]))
	var selected_index := random_system.weighted_index(weights)
	return null if selected_index < 0 else candidates[selected_index]


func merge_three(
	state: RunState,
	mothers: Array[ProposalInstance],
	negative_base: ProposalInstance,
	balance: GameBalanceDefinition,
	selected_positive: ProposalInstance = null
) -> ProposalInstance:
	if not _can_merge(state, mothers, negative_base, selected_positive):
		return null
	var result := negative_base.copy()
	result.positive_effect = MetricVector.new()
	if selected_positive != null:
		var metric_value := selected_positive.get_positive_metric()
		var metric := metric_value as Metric.Id
		var selected_magnitude := absi(selected_positive.positive_effect.get_value(metric))
		var discarded_magnitude := 0
		for mother in mothers:
			if mother == selected_positive or not mother.has_positive_trait():
				continue
			var discarded_metric := mother.get_positive_metric() as Metric.Id
			discarded_magnitude += absi(mother.positive_effect.get_value(discarded_metric))
		var converted := float(discarded_magnitude) * balance.merge_conversion_ratio
		var upgraded := roundi(
			pow(float(selected_magnitude) + converted, balance.merge_upgrade_exponent)
		)
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
	var source_group := mothers[0].source_group
	if source_group == null:
		return false
	for mother in mothers:
		if mother == null or mother not in state.proposal_hand:
			return false
		if mother.source_group != source_group or seen.has(mother.get_instance_id()):
			return false
		seen[mother.get_instance_id()] = true
	if selected_positive == null:
		for mother in mothers:
			if mother.has_positive_trait():
				return false
		return true
	return selected_positive in mothers and selected_positive.has_positive_trait()
