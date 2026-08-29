extends RefCounted
class_name ProposalSystem


func calculate_total_effect(proposals: Array[ProposalInstance]) -> MetricVector:
	var total := MetricVector.new()
	for proposal in proposals:
		total.add(proposal.get_total_effect())
	return total


func are_gameplay_equivalent(first: ProposalInstance, second: ProposalInstance) -> bool:
	if first == null or second == null:
		return first == second
	if (
		first.source_group != second.source_group
		or not _metric_vectors_equal(first.base_effect, second.base_effect)
		or first.lag_months != second.lag_months
	):
		return false
	var first_has_positive := first.has_positive_trait()
	if first_has_positive != second.has_positive_trait():
		return false
	if not first_has_positive:
		return true
	if not _metric_vectors_equal(first.positive_effect, second.positive_effect):
		return false
	var first_pending := first.is_bonus_choice_pending()
	if first_pending != second.is_bonus_choice_pending():
		return false
	if first_pending:
		return is_equal_approx(first.donation_offer, second.donation_offer)
	return first.positive_trait_accepted == second.positive_trait_accepted


func match_equivalent_proposals(
	required: Array[ProposalInstance], available: Array[ProposalInstance]
) -> Array[ProposalInstance]:
	var result: Array[ProposalInstance] = []
	var used_instances: Dictionary[int, bool] = {}
	for required_proposal in required:
		var matched_proposal: ProposalInstance
		for candidate in available:
			if candidate == null or used_instances.has(candidate.get_instance_id()):
				continue
			if are_gameplay_equivalent(required_proposal, candidate):
				matched_proposal = candidate
				used_instances[candidate.get_instance_id()] = true
				break
		result.append(matched_proposal)
	return result


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
	var consumption := float(bill.start_values.consumption)
	var production := float(bill.start_values.production)
	var employment := float(bill.start_values.employment)
	var investment := float(bill.start_values.investment)

	for active_proposal in bill.proposals:
		var effect := active_proposal.proposal.get_total_effect()
		var progress := active_proposal.get_digestion_progress()

		tax += effect.tax * progress
		consumption += effect.consumption * progress
		production += effect.production * progress
		employment += effect.employment * progress
		investment += effect.investment * progress

	var result := MetricValues.new()

	result.tax = roundi(tax)
	result.consumption = roundi(consumption)
	result.production = roundi(production)
	result.employment = roundi(employment)
	result.investment = roundi(investment)

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
	proposal.lag_months = random_system.random_int(
		balance.proposal_lag_months_min, balance.proposal_lag_months_max
	)
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
	proposal.positive_effect.set_value(metric, magnitude)
	proposal.donation_offer = float(absi(magnitude)) * balance.donation_per_positive_point
	proposal.bonus_choice_resolved = false
	proposal.positive_trait_accepted = false


func resolve_bonus_choice(
	state: RunState, proposal: ProposalInstance, accept_trait: bool
) -> bool:
	if (
		proposal == null
		or proposal not in state.proposal_hand
		or proposal.bonus_choice_resolved
		or not proposal.has_positive_trait()
	):
		return false
	proposal.bonus_choice_resolved = true
	proposal.positive_trait_accepted = accept_trait
	if not accept_trait:
		proposal.positive_effect = MetricVector.new()
		state.political_donation_pool += proposal.donation_offer
	return true


func add_to_hand(state: RunState, proposal: ProposalInstance) -> void:
	if proposal == null:
		push_error("Cannot add null proposal to hand.")
		return
	state.add_proposal_to_hand(proposal)


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
	result.donation_offer = 0.0
	result.bonus_choice_resolved = true
	result.positive_trait_accepted = true
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
		result.positive_effect.set_value(metric, upgraded)
		result.donation_offer = float(upgraded) * balance.donation_per_positive_point
		result.bonus_choice_resolved = selected_positive.bonus_choice_resolved
		result.positive_trait_accepted = selected_positive.positive_trait_accepted
	state.consume_proposals(mothers)
	state.add_proposal_to_hand(result)
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
		if mother.is_bonus_choice_pending():
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


func _metric_vectors_equal(first: MetricVector, second: MetricVector) -> bool:
	if first == null or second == null:
		return first == second
	for metric in Metric.all_ids():
		if first.get_value(metric) != second.get_value(metric):
			return false
	return true
