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
	var immediate := context.policy_system.calculate_immediate_result(
		context.state.metrics, draft.policies
	)
	for metric in Metric.all_ids():
		projected.set_value(
			metric,
			(
				projected.get_value(metric)
				+ immediate.get_value(metric)
				- context.state.metrics.get_value(metric)
			)
		)
	for seat in context.state.seats:
		var vote := _calculate_seat_vote(seat, draft, projected, context, resolve_absence)
		result.seat_votes.append(vote)
		_count_position(result, vote.position)
	result.passed = result.present_count() > 0 and result.support_count * 2 > result.present_count()
	return result


func set_donation(context: RunContext, seat_id: int, support_amount: float) -> bool:
	if support_amount <= 0.0:
		return false
	for seat in context.state.seats:
		if seat.seat_id == seat_id:
			context.state.vote_donations[seat_id] = support_amount
			var detection_probability := 0.25
			if context.state.constitution.has_flag(&"transparent_government"):
				detection_probability = 0.65
			elif context.state.constitution.has_flag(&"unregulated_donations"):
				detection_probability = 0.0
			if context.random_system.chance(detection_probability):
				context.state.pending_collapse_delta += 5.0
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
	if race.definition.id == Race.ZHUSHUI:
		vote.add_reason(&"zhushui_governing_seat", 1000.0)
		vote.position = SeatVoteState.Position.SUPPORT
		return vote
	if resolve_absence and _is_absent(seat, race, context):
		vote.position = SeatVoteState.Position.ABSENT
		vote.breakdown[&"special_absence"] = 1.0
		return vote
	var attitude_race := race
	if context.state.constitution.has_flag(&"trust_established"):
		var shared_human := context.state.get_race(Race.HUMAN)
		if shared_human != null:
			attitude_race = shared_human
	vote.add_reason(
		&"race_expectation", _race_expectation_score(attitude_race, projected, context.state)
	)
	var use_human_attitude := (
		context.state.constitution.has_flag(&"free_trade")
		and _is_transport_group(seat.actual_group_id, context.state)
	)
	if use_human_attitude:
		var human_race := context.state.get_race(Race.HUMAN)
		if human_race != null:
			vote.add_reason(
				&"transport_human_attitude",
				_race_expectation_score(human_race, projected, context.state)
			)
	else:
		vote.add_reason(&"group_stance", _group_stance_score(seat.actual_group_id, draft, context))
		vote.add_reason(&"proposal_source", _proposal_source_score(seat.actual_group_id, draft))
	vote.add_reason(
		&"constitution",
		context.constitution_system.get_race_support_modifier(context.state, seat.race_id)
	)
	var relation := seat.personal_relation
	if race.definition.id == Race.BIYI:
		relation += (
			seat.odd_month_relation if context.state.month % 2 == 1 else seat.even_month_relation
		)
	vote.add_reason(&"personal_relation", relation)
	vote.add_reason(&"political_donation", context.state.vote_donations.get(seat.seat_id, 0.0))
	vote.position = _position_from_score(vote.score)
	return vote


func _race_expectation_score(race: RaceState, projected: MetricValues, state: RunState) -> float:
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


func _group_stance_score(group_id: StringName, draft: DraftBillState, context: RunContext) -> float:
	var group := _find_group(group_id, context.interest_groups)
	if group == null:
		return 0.0
	var effect := context.proposal_system.calculate_total_effect(draft.proposals)
	var score := group.base_support_modifier
	for metric in effect.non_zero_metrics():
		var stance := group.get_stance(metric)
		if stance == MetricStanceDefinition.Direction.NONE:
			continue
		score += (
			GROUP_STANCE_SCORE if effect.get_value(metric) * stance > 0 else -GROUP_STANCE_SCORE
		)
	return score


func _proposal_source_score(group_id: StringName, draft: DraftBillState) -> float:
	var score := 0.0
	for proposal in draft.proposals:
		if proposal.source_group_id == group_id:
			score += proposal.political_support
	return score


func _is_absent(seat: SeatState, race: RaceState, context: RunContext) -> bool:
	var nanke := context.state.get_race(Race.NANKE)
	if nanke == null:
		return false
	var is_nanke := race.definition.id == Race.NANKE
	var cooperative := context.state.constitution.has_flag(&"nanke_cooperative")
	var protected := (
		seat.actual_group_id == nanke.definition.special_group_id
		and (
			(is_nanke and not context.state.constitution.has_flag(&"nanke_mutual_aid"))
			or cooperative
		)
	)
	var probability := (
		context.balance.nanke_protected_absence_probability
		if protected
		else context.balance.nanke_normal_absence_probability
	)
	if protected and context.state.metrics.wage < nanke.definition.strike_wage_floor:
		return true
	if not is_nanke and not protected:
		return false
	return context.random_system.chance(probability)


func _is_transport_group(group_id: StringName, state: RunState) -> bool:
	var human := state.get_race(Race.HUMAN)
	return human != null and human.definition.special_group_id == group_id


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
