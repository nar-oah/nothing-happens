extends RefCounted
class_name VoteSystem


func preview_vote(draft: DraftBillState, context: RunContext) -> VoteResultState:
	return calculate_vote(draft, context, false)


func calculate_vote(
	draft: DraftBillState, context: RunContext, resolve_randomness: bool = true
) -> VoteResultState:
	var result := VoteResultState.new()
	if draft == null:
		return result
	var projected := _calculate_projected_metrics(draft, context)
	for seat in context.state.seats:
		var vote := _calculate_seat_vote(
			seat, draft, projected, context, resolve_randomness
		)
		result.seat_votes.append(vote)
		_count_position(result, vote.position)
	result.passed = result.present_count() > 0 and result.support_count * 2 > result.present_count()
	return result


func set_donation(context: RunContext, seat: SeatState, support_amount: float) -> bool:
	if (
		seat == null
		or seat.definition == null
		or seat not in context.state.seats
		or support_amount <= 0.0
	):
		return false
	var previous: float = context.state.vote_donations.get(seat.definition, 0.0)
	var additional := support_amount - previous
	if additional > context.state.political_donation_pool:
		return false
	context.state.political_donation_pool -= additional
	context.state.vote_donations[seat.definition] = support_amount
	if additional > 0.0 and context.random_system.chance(
		context.state.donation_detection_probability
	):
		context.state.pending_collapse_delta += context.balance.donation_detection_collapse
	return true


func clear_donations(state: RunState) -> void:
	state.vote_donations.clear()


func _calculate_projected_metrics(
	draft: DraftBillState, context: RunContext
) -> MetricValues:
	var projected := context.proposal_system.calculate_pure_target(
		context.state.metrics, draft.proposals
	)
	var immediate := context.policy_system.calculate_immediate_result(
		context.state.metrics, draft.policies
	)
	for metric in Metric.all_ids():
		projected.set_value(
			metric,
			projected.get_value(metric)
			+ immediate.get_value(metric)
			- context.state.metrics.get_value(metric)
		)
	return projected


func _calculate_seat_vote(
	seat: SeatState,
	draft: DraftBillState,
	projected: MetricValues,
	context: RunContext,
	resolve_randomness: bool
) -> SeatVoteState:
	var vote := SeatVoteState.new()
	vote.seat = seat
	var race := context.state.get_race(seat.race)
	if race == null or race.definition == null:
		vote.position = SeatVoteState.Position.ABSTAIN
		return vote
	vote.add_reason(
		&"race_expectation", _race_expectation_score(race, projected, context)
	)
	vote.add_reason(
		&"group_stance", _group_stance_score(seat.actual_group, draft, context)
	)
	vote.add_reason(
		&"proposal_source", _proposal_source_score(seat.actual_group, draft, context.balance)
	)
	vote.add_reason(&"personal_relation", seat.personal_relation)
	vote.add_reason(
		&"political_donation", context.state.vote_donations.get(seat.definition, 0.0)
	)
	var vote_context := VoteContext.new(
		context, seat, race, draft, projected, vote, resolve_randomness
	)
	race.definition.modify_vote(vote_context)
	context.constitution_system.modify_vote(vote_context)
	if vote_context.locked_position >= 0:
		vote.position = vote_context.locked_position as SeatVoteState.Position
	elif vote_context.position_override >= 0:
		vote.position = vote_context.position_override as SeatVoteState.Position
	else:
		vote.position = _position_from_score(vote.score, context.balance.support_threshold)
	return vote


func _race_expectation_score(
	race: RaceState, projected: MetricValues, context: RunContext
) -> float:
	var score := 0.0
	for metric in race.definition.get_stance_metrics():
		if not race.definition.is_vote_metric_active(metric, context):
			continue
		var target := context.race_system.get_effective_expectation(race, metric, context)
		var before_distance := absf(float(context.state.metrics.get_value(metric) - target))
		var after_distance := absf(float(projected.get_value(metric) - target))
		if after_distance < before_distance:
			score += context.balance.race_expectation_score
		elif after_distance > before_distance:
			score -= context.balance.race_expectation_score
	return score


func _group_stance_score(
	group: InterestGroupDefinition, draft: DraftBillState, context: RunContext
) -> float:
	if group == null:
		return 0.0
	var effect := context.proposal_system.calculate_total_effect(draft.proposals)
	var score := 0.0
	for metric in effect.non_zero_metrics():
		var stance := group.get_stance(metric)
		if stance == Metric.Direction.NONE:
			continue
		score += (
			context.balance.group_stance_score
			if effect.get_value(metric) * int(stance) > 0
			else -context.balance.group_stance_score
		)
	return score


func _proposal_source_score(
	group: InterestGroupDefinition,
	draft: DraftBillState,
	balance: GameBalanceDefinition
) -> float:
	if group == null:
		return 0.0
	var score := 0.0
	for proposal in draft.proposals:
		if proposal.source_group == group:
			score += balance.proposal_support
	return score


func _position_from_score(score: float, threshold: float) -> SeatVoteState.Position:
	if score >= threshold:
		return SeatVoteState.Position.SUPPORT
	if score <= -threshold:
		return SeatVoteState.Position.OPPOSE
	return SeatVoteState.Position.ABSTAIN


func _count_position(result: VoteResultState, position: SeatVoteState.Position) -> void:
	match position:
		SeatVoteState.Position.SUPPORT:
			result.support_count += 1
		SeatVoteState.Position.OPPOSE:
			result.oppose_count += 1
		SeatVoteState.Position.ABSTAIN:
			result.abstain_count += 1
		SeatVoteState.Position.ABSENT:
			result.absent_count += 1
