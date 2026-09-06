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
	var pure_target := context.proposal_system.calculate_pure_target(context.state.metrics, draft.proposals)
	var projected := calculate_projected_metrics(draft, pure_target, context)
	for seat in context.state.seats:
		var vote := _calculate_seat_vote(seat, draft, pure_target, projected, context, resolve_randomness)
		result.seat_votes.append(vote)
		_count_position(result, vote.position)
	result.passed = result.present_count() > 0 and result.support_count * 2 > result.present_count()
	return result


func set_donation(context: RunContext, seat: SeatState, support_amount: float) -> bool:
	if seat == null or seat.definition == null or seat not in context.state.seats or support_amount <= 0.0:
		return false
	var previous: float = context.state.vote_donations.get(seat.definition, 0.0)
	var additional := support_amount - previous
	if additional > context.state.political_donation_pool:
		return false
	context.state.political_donation_pool -= additional
	context.state.vote_donations[seat.definition] = support_amount
	return true


func get_bribe_cost(context: RunContext, vote: SeatVoteState) -> float:
	if context == null or context.balance == null or vote == null or vote.seat == null or vote.score > 0.0:
		return 0.0
	return maxf(context.balance.support_threshold - vote.score, 0.0)


func can_bribe(context: RunContext, vote: SeatVoteState) -> bool:
	var cost := get_bribe_cost(context, vote)
	return cost > 0.0 and cost <= context.state.political_donation_pool


func bribe_for_support(context: RunContext, draft: DraftBillState, seat: SeatState) -> bool:
	if context == null or context.state == null or seat == null or seat not in context.state.seats:
		return false
	var preview := preview_vote(draft, context)
	for vote in preview.seat_votes:
		if vote.seat != seat:
			continue
		var cost := get_bribe_cost(context, vote)
		if cost <= 0.0:
			return false
		var previous: float = context.state.vote_donations.get(seat.definition, 0.0)
		return set_donation(context, seat, previous + cost)
	return false


func resolve_donation_detection(context: RunContext) -> int:
	var detected := 0
	var probability := context.constitution_system.get_donation_detection_probability(context)
	for seat_definition in context.state.vote_donations:
		var amount: float = context.state.vote_donations[seat_definition]
		if amount <= 0.0 or not context.random_system.chance(probability):
			continue
		detected += 1
		context.collapse_system.increase(context)
	return detected


func clear_donations(state: RunState) -> void:
	state.vote_donations.clear()


func calculate_projected_metrics(
	draft: DraftBillState, pure_target: MetricValues, context: RunContext
) -> MetricValues:
	return context.policy_system.calculate_immediate_result(pure_target, draft.policies)


func _calculate_seat_vote(
	seat: SeatState, draft: DraftBillState, pure_target: MetricValues,
	projected: MetricValues, context: RunContext, resolve_randomness: bool
) -> SeatVoteState:
	var vote := SeatVoteState.new()
	vote.seat = seat
	var race_state := context.state.get_race(seat.race)
	if race_state == null:
		vote.position = SeatVoteState.Position.ABSTAIN
		return vote
	var active_race := race_state.active_definition
	if active_race == null:
		active_race = race_state.definition
	vote.add_reason(&"race_expectation", _race_expectation_score(race_state, projected, context))
	vote.add_reason(&"proposal_source", _group_support_score(seat.actual_group, draft, projected, context))
	vote.add_reason(&"political_donation", context.state.vote_donations.get(seat.definition, 0.0))
	var vote_context := VoteContext.new(context, seat, race_state, draft, pure_target, projected, vote, resolve_randomness)
	context.constitution_system.apply_vote_effects(vote_context)
	active_race.modify_vote(vote_context)
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
	var active := race.active_definition
	if active == null:
		active = race.definition
	var score := 0.0
	for metric in active.get_stance_metrics():
		if not active.is_vote_metric_active(metric, context):
			continue
		var target := context.race_system.get_effective_expectation(race, metric, context)
		var before_gap := maxf(float(target - context.state.metrics.get_value(metric)), 0.0)
		var after_gap := maxf(float(target - projected.get_value(metric)), 0.0)
		if after_gap < before_gap:
			score += context.balance.race_expectation_score
		elif after_gap > before_gap:
			score -= context.balance.race_expectation_score
	return score


func _group_support_score(
	group: InterestGroupDefinition, draft: DraftBillState,
	projected: MetricValues, context: RunContext
) -> float:
	var identity := context.constitution_system.resolve_group_identity(context, group)
	var active := context.constitution_system.get_active_group_definition(context, identity)
	if active == null:
		return 0.0
	if active.race != null:
		var race_state := context.state.get_race(active.race)
		return 0.0 if race_state == null else _race_expectation_score(race_state, projected, context)
	var score := 0.0
	for proposal in draft.proposals:
		if proposal == null:
			continue
		if context.constitution_system.resolve_group_identity(context, proposal.source_group) == identity:
			score += context.balance.proposal_support
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
