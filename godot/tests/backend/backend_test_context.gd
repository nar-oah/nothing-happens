extends RefCounted

var failures: int = 0
var assertions: int = 0


func check(condition: bool, message: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAILED: %s" % message)


func check_equal(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s (actual=%s expected=%s)" % [message, actual, expected])


func make_session(
	races: Array[RaceDefinition],
	groups: Array[InterestGroupDefinition],
	articles: Array[ConstitutionArticleDefinition] = [],
	variable_seat_count: int = 20
) -> RunSession:
	var session := RunSession.new()
	session.balance = GameBalanceDefinition.new()
	session.balance.variable_seat_count = variable_seat_count
	session.configure_content(races, groups, articles)
	session.automatic_draw_count = 0
	session.start_new_run()
	return session


func make_race(id: StringName) -> RaceDefinition:
	var result := RaceDefinition.new()
	result.id = id
	result.display_name = String(id)
	return result


func make_group(id: StringName, weight: int, order: int) -> InterestGroupDefinition:
	var result := InterestGroupDefinition.new()
	result.id = id
	result.display_name = String(id)
	result.base_column_weight = weight
	result.fixed_sort_order = order

	var proposal := ProposalDefinition.new()
	proposal.id = StringName("%s_proposal" % id)
	proposal.source_group_id = id
	proposal.affects_price = true
	result.proposal_definition = proposal
	return result


func make_stance(
	metric: Metric.Id, direction: MetricStanceDefinition.Direction
) -> MetricStanceDefinition:
	var result := MetricStanceDefinition.new()
	result.metric = metric
	result.direction = direction
	return result


func make_proposal(group_id: StringName) -> ProposalInstance:
	var result := ProposalInstance.new()
	result.definition_id = StringName("%s_card" % group_id)
	result.source_group_id = group_id
	return result


func make_group_rule(
	action: int,
	priority: int,
	race_id: StringName,
	target_group_id: StringName = &"",
	rate: float = 0.0,
	local_prefix: StringName = &"local"
) -> ConstitutionInfluenceRule:
	var rule := ConstitutionInfluenceRule.new()
	rule.action = action as ConstitutionInfluenceRule.Action
	rule.priority = priority as ConstitutionInfluenceRule.Priority
	rule.race_id = race_id
	rule.target_group_id = target_group_id
	rule.rate = rate
	rule.local_group_prefix = local_prefix
	return rule


func vote_for_race(
	result: VoteResultState, state: RunState, race_id: StringName
) -> SeatVoteState.Position:
	for vote in result.seat_votes:
		for seat in state.seats:
			if seat.seat_id == vote.seat_id and seat.race_id == race_id:
				return vote.position
	return SeatVoteState.Position.ABSTAIN
