extends RefCounted
class_name VoteSystem

const RACE_EXPECTATION_SCORE: float = 6.0
const GROUP_STANCE_SCORE: float = 4.0
const SUPPORT_THRESHOLD: float = 1.0


func preview_vote(draft: DraftBillState, context: RunContext) -> VoteResultState:
	return calculate_vote(draft, context, false)


func calculate_vote(
	draft: DraftBillState, context: RunContext, resolve_absence: bool = true
) -> VoteResultState:
	var result := VoteResultState.new()
	if draft == null:
		return result
	var projected := context.proposal_system.calculate_pure_target(
		context.state.metrics, draft.proposals
	)
	for seat in context.state.seats:
		var vote := _calculate_seat_vote(seat, draft, projected, context, resolve_absence)
		result.seat_votes.append(vote)
		_count_position(result, vote.position)
	result.passed = result.present_count() > 0 and result.support_count * 2 > result.present_count()
	return result


func set_donation(state: RunState, seat_id: int, support_amount: float) -> bool:
	if support_amount <= 0.0:
		return false
	for seat in state.seats:
		if seat.seat_id == seat_id:
			state.vote_donations[seat_id] = support_amount
			return true
	return false


func clear_donations(state: RunState) -> void:
	state.vote_donations.clear()


func _calculate_seat_vote(
	seat: SeatState,
	draft: DraftBillState,
	projected: MetricValues,
	context: RunContext,
	resolve_absence: bool
) -> SeatVoteState:
	var vote := SeatVoteState.new()
	vote.seat_id = seat.seat_id
	var race := context.state.get_race(seat.race_id)
	if race == null or race.definition == null:
		vote.position = SeatVoteState.Position.ABSTAIN
		return vote
	if race.definition.special_mechanism == RaceDefinition.SpecialMechanism.ZHUSHUI:
		vote.add_reason(&"zhushui_governing_seat", 1000.0)
		vote.position = SeatVoteState.Position.SUPPORT
		return vote
	if resolve_absence and _is_absent(seat, race, context):
		vote.position = SeatVoteState.Position.ABSENT
		vote.breakdown[&"special_absence"] = 1.0
		return vote
	vote.add_reason(&"race_expectation", _race_expectation_score(race, projected, context.state))
	var use_human_attitude := (
		context.state.constitution.has_flag(&"free_trade")
		and _is_transport_group(seat.actual_group_id, context.state)
	)
	if use_human_attitude:
		var human_race := _find_special_race(context.state, RaceDefinition.SpecialMechanism.HUMAN)
		if human_race != null:
			vote.add_reason(
				&"transport_human_attitude",
				_race_expectation_score(human_race, projected, context.state)
			)
	else:
		vote.add_reason(
			&"group_stance", _group_stance_score(seat.actual_group_id, draft, context)
		)
		vote.add_reason(
			&"proposal_source", _proposal_source_score(seat.actual_group_id, draft)
		)
	vote.add_reason(
		&"constitution",
		context.constitution_system.get_race_support_modifier(context.state, seat.race_id)
	)
	vote.add_reason(&"personal_relation", seat.personal_relation)
	vote.add_reason(&"political_donation", context.state.vote_donations.get(seat.seat_id, 0.0))
	vote.position = _position_from_score(vote.score)
	return vote


func _race_expectation_score(
	race: RaceState, projected: MetricValues, state: RunState
) -> float:
	var score := 0.0
	for stance in race.definition.get_stances(state.month):
		if stance == null or stance.direction == MetricStanceDefinition.Direction.NONE:
			continue
		var target := race.get_expectation(stance.metric, stance.initial_target)
		var before_distance := absf(float(state.metrics.get_value(stance.metric) - target))
		var after_distance := absf(float(projected.get_value(stance.metric) - target))
		if after_distance < before_distance:
			score += RACE_EXPECTATION_SCORE
		elif after_distance > before_distance:
			score -= RACE_EXPECTATION_SCORE
	return score


func _group_stance_score(
	group_id: StringName, draft: DraftBillState, context: RunContext
) -> float:
	var group := _find_group(group_id, context.interest_groups)
	if group == null:
		return 0.0
	var effect := context.proposal_system.calculate_total_effect(draft.proposals)
	var score := group.base_support_modifier
	for metric in effect.non_zero_metrics():
		var stance := group.get_stance(metric)
		if stance == MetricStanceDefinition.Direction.NONE:
			continue
		score += GROUP_STANCE_SCORE if effect.get_value(metric) * stance > 0 else -GROUP_STANCE_SCORE
	return score


func _proposal_source_score(group_id: StringName, draft: DraftBillState) -> float:
	var score := 0.0
	for proposal in draft.proposals:
		if proposal.source_group_id == group_id:
			score += proposal.political_support
	return score


func _is_absent(seat: SeatState, race: RaceState, context: RunContext) -> bool:
	if race.definition.special_mechanism != RaceDefinition.SpecialMechanism.NANKE:
		return false
	var protected := (
		seat.actual_group_id == race.definition.special_group_id
		and not context.state.constitution.has_flag(&"nanke_mutual_aid")
	)
	var probability := (
		race.definition.protected_absence_probability
		if protected
		else race.definition.normal_absence_probability
	)
	return context.random_system.chance(probability)


func _is_transport_group(group_id: StringName, state: RunState) -> bool:
	var human := _find_special_race(state, RaceDefinition.SpecialMechanism.HUMAN)
	return human != null and human.definition.special_group_id == group_id


func _find_special_race(state: RunState, mechanism: RaceDefinition.SpecialMechanism) -> RaceState:
	for race in state.races:
		if race.definition != null and race.definition.special_mechanism == mechanism:
			return race
	return null


func _find_group(
	group_id: StringName, groups: Array[InterestGroupDefinition]
) -> InterestGroupDefinition:
	for group in groups:
		if group != null and group.id == group_id:
			return group
	return null


func _position_from_score(score: float) -> SeatVoteState.Position:
	if score >= SUPPORT_THRESHOLD:
		return SeatVoteState.Position.SUPPORT
	if score <= -SUPPORT_THRESHOLD:
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
