extends RefCounted
class_name VoteSystem

const DONATION_COST: float = 1.0


func preview_vote(draft: DraftBillState, context: RunContext) -> VoteResultState:
	return calculate_vote(draft, context)


func calculate_vote(
	draft: DraftBillState, context: RunContext, donations: Dictionary = {}
) -> VoteResultState:
	var result := VoteResultState.new()
	if draft == null:
		return result
	var pure_target := context.proposal_system.calculate_pure_target(
		context.state.metrics, draft.proposals
	)
	var projected := calculate_projected_metrics(draft, pure_target, context)
	for seat in context.state.seats:
		result.seat_votes.append(
			_calculate_seat_vote(seat, draft, pure_target, projected, context, donations)
		)
	_count_votes(result, context)
	result.passed = result.present_count() > 0 and result.support_count * 2 > result.present_count()
	return result


func roll_monthly_absences(context: RunContext) -> void:
	if context == null or context.state == null:
		return
	for seat in context.state.seats:
		seat.absent_this_month = false
		var active := _active_race(context, seat)
		if active is NankeRaceDefinition:
			seat.absent_this_month = context.random_system.chance(active.absence_probability)


func get_bribe_cost(context: RunContext, vote: SeatVoteState) -> float:
	if context == null or vote == null or vote.seat == null:
		return 0.0
	return DONATION_COST


func is_bribe_allowed(context: RunContext, vote: SeatVoteState) -> bool:
	return (
		vote != null
		and vote.position != SeatVoteState.Position.SUPPORT
		and vote.position != SeatVoteState.Position.ABSENT
		and _seat_allows_donation(context, vote.seat)
	)


func validate_bribes(
	draft: DraftBillState, context: RunContext, seat_indices: Array[int]
) -> Dictionary:
	if draft == null or context == null or context.state == null:
		return {"ok": false}
	var preview := preview_vote(draft, context)
	var seen: Dictionary[int, bool] = {}
	var donations: Dictionary[SeatState, float] = {}
	var total_cost := 0.0
	for seat_index in seat_indices:
		if seat_index < 0 or seat_index >= preview.seat_votes.size() or seen.has(seat_index):
			return {"ok": false}
		seen[seat_index] = true
		var vote := preview.seat_votes[seat_index]
		if vote.seat != context.state.seats[seat_index] or not is_bribe_allowed(context, vote):
			return {"ok": false}
		var cost := get_bribe_cost(context, vote)
		donations[vote.seat] = cost
		total_cost += cost
	if total_cost > context.state.political_donation_pool:
		return {"ok": false}
	return {"ok": true, "donations": donations, "total_cost": total_cost}


func get_minimum_donation_plan(draft: DraftBillState, context: RunContext) -> Dictionary:
	if (
		draft == null
		or context == null
		or context.state == null
		or context.draft_bill_system == null
		or not context.draft_bill_system.is_ready_to_submit(context, draft)
	):
		return {}
	var preview := preview_vote(draft, context)
	if preview.passed:
		return {"seat_indices": [], "cost": 0.0}
	var options: Array = []
	var peach_votes: Dictionary[RaceState, Array] = {}
	for seat_index in range(preview.seat_votes.size()):
		var vote := preview.seat_votes[seat_index]
		var race_state := context.state.get_race(vote.seat.race)
		if race_state != null and _active_race(context, vote.seat) is PeachRaceDefinition:
			if not peach_votes.has(race_state):
				peach_votes[race_state] = []
			peach_votes[race_state].append([seat_index, vote])
		elif is_bribe_allowed(context, vote):
			options.append([seat_index])
	for race_state in peach_votes:
		var entries: Array = peach_votes[race_state]
		var present_weight := 0
		var support_weight := 0
		var candidates: Array = []
		for entry in entries:
			var vote: SeatVoteState = entry[1]
			if vote.position == SeatVoteState.Position.ABSENT:
				continue
			present_weight += vote.vote_weight
			if vote.position == SeatVoteState.Position.SUPPORT:
				support_weight += vote.vote_weight
			elif is_bribe_allowed(context, vote):
				candidates.append(entry)
		var peach := race_state.active_definition as PeachRaceDefinition
		if peach == null or peach.has_support_majority(support_weight, present_weight):
			continue
		candidates.sort_custom(func(first: Array, second: Array) -> bool:
			var first_vote: SeatVoteState = first[1]
			var second_vote: SeatVoteState = second[1]
			return (
				int(first[0]) < int(second[0])
				if first_vote.vote_weight == second_vote.vote_weight
				else first_vote.vote_weight > second_vote.vote_weight
			)
		)
		var option: Array[int] = []
		var planned_support_weight := support_weight
		for candidate in candidates:
			option.append(int(candidate[0]))
			var candidate_vote: SeatVoteState = candidate[1]
			planned_support_weight += candidate_vote.vote_weight
			if peach.has_support_majority(planned_support_weight, present_weight):
				break
		if peach.has_support_majority(planned_support_weight, present_weight):
			options.append(option)
	var votes_needed := floori(float(preview.present_count()) / 2.0) + 1 - preview.support_count
	if options.size() < votes_needed:
		return {}
	options.sort_custom(func(first: Array, second: Array) -> bool:
		return int(first[0]) < int(second[0]) if first.size() == second.size() else first.size() < second.size()
	)
	var seat_indices: Array[int] = []
	for option_index in range(votes_needed):
		for seat_index in options[option_index]:
			seat_indices.append(int(seat_index))
	seat_indices.sort()
	var cost := float(seat_indices.size()) * DONATION_COST
	if cost > context.state.political_donation_pool:
		return {}
	var validated := validate_bribes(draft, context, seat_indices)
	if not validated["ok"]:
		return {}
	var result := calculate_vote(draft, context, validated["donations"])
	if not result.passed:
		return {}
	return {"seat_indices": seat_indices, "cost": cost}


func resolve_donation_detection(
	context: RunContext, donations: Dictionary[SeatState, float]
) -> int:
	var detected := 0
	var probability := context.constitution_system.get_donation_detection_probability(context)
	for seat in donations:
		if donations[seat] <= 0.0 or not context.random_system.chance(probability):
			continue
		detected += 1
		context.collapse_system.increase(context)
	return detected


func calculate_projected_metrics(
	draft: DraftBillState, pure_target: MetricValues, context: RunContext
) -> MetricValues:
	return context.policy_system.calculate_planned_result(pure_target, draft.policies)


func _calculate_seat_vote(
	seat: SeatState,
	draft: DraftBillState,
	pure_target: MetricValues,
	projected: MetricValues,
	context: RunContext,
	donations: Dictionary
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
	vote.add_reason(
		&"proposal_source", _group_support_score(seat.actual_group, draft, projected, context)
	)
	if _seat_allows_donation(context, seat):
		vote.add_reason(&"political_donation", float(donations.get(seat, 0.0)))
	var vote_context := VoteContext.new(
		context, seat, race_state, draft, pure_target, projected, vote
	)
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
	group: InterestGroupDefinition,
	draft: DraftBillState,
	projected: MetricValues,
	context: RunContext
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


func _count_votes(result: VoteResultState, context: RunContext) -> void:
	var peach_votes: Dictionary[RaceState, Array] = {}
	for vote in result.seat_votes:
		var race_state := context.state.get_race(vote.seat.race)
		var active := _active_race(context, vote.seat)
		if not active is PeachRaceDefinition or race_state == null:
			_count_position(result, vote.position)
			continue
		if not peach_votes.has(race_state):
			peach_votes[race_state] = []
		var race_votes: Array = peach_votes[race_state]
		vote.vote_weight = active.get_vote_weight(race_votes.size())
		race_votes.append(vote)
	for race_state in peach_votes:
		var support_weight := 0
		var present_weight := 0
		var race_votes: Array = peach_votes[race_state]
		for vote in race_votes:
			if vote.position == SeatVoteState.Position.ABSENT:
				continue
			present_weight += vote.vote_weight
			if vote.position == SeatVoteState.Position.SUPPORT:
				support_weight += vote.vote_weight
		for vote in race_votes:
			vote.race_support_weight = support_weight
			vote.race_present_weight = present_weight
		var peach := race_state.active_definition as PeachRaceDefinition
		if present_weight <= 0:
			result.absent_count += 1
		elif peach.has_support_majority(support_weight, present_weight):
			result.support_count += 1
		else:
			result.abstain_count += 1


func _active_race(context: RunContext, seat: SeatState) -> RaceDefinition:
	if context == null or context.state == null or seat == null:
		return null
	var race_state := context.state.get_race(seat.race)
	if race_state == null:
		return null
	return race_state.definition if race_state.active_definition == null else race_state.active_definition


func _seat_allows_donation(context: RunContext, seat: SeatState) -> bool:
	var active := _active_race(context, seat)
	return (
		seat != null
		and seat.race != null
		and seat.race.political_donations_allowed
		and active != null
		and active.political_donations_allowed
	)


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
