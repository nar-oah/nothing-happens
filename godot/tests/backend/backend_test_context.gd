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


func check_approx(actual: float, expected: float, message: String) -> void:
	check(
		is_equal_approx(actual, expected),
		"%s (actual=%s expected=%s)" % [message, actual, expected]
	)


func make_session(
	races: Array[RaceDefinition],
	groups: Array[InterestGroupDefinition],
	seats: Array[SeatDefinition],
	articles: Array[ConstitutionArticleDefinition] = [],
	supplied_balance: GameBalanceDefinition = null
) -> RunSession:
	var session := RunSession.new()
	var configured_balance: GameBalanceDefinition = supplied_balance
	if configured_balance == null:
		configured_balance = GameBalanceDefinition.new()
		configured_balance.automatic_draw_count = 0
		configured_balance.event_spawn_count_min = 0
		configured_balance.event_spawn_count_max = 0
		configured_balance.event_early_reveal_probability_per_seat = 0.0
		configured_balance.market_noise_ratio = 0.0
	session.balance = configured_balance
	var complete_articles: Array[ConstitutionArticleDefinition] = articles.duplicate()
	for race in races:
		var has_initial := false
		for article in complete_articles:
			if article != null and article.race == race and article.is_initial:
				has_initial = true
				break
		if not has_initial:
			complete_articles.append(make_article(race))
	session.configure_content(races, groups, seats, complete_articles)
	session.start_new_run()
	return session


func make_race(display_name: String) -> RaceDefinition:
	var result := RaceDefinition.new()
	result.display_name = display_name
	return result


func make_group(display_name: String, weight: int = 1) -> InterestGroupDefinition:
	var result := InterestGroupDefinition.new()
	result.display_name = display_name
	result.base_column_weight = weight
	return result


func make_seat(display_name: String, anchor: RaceDefinition = null) -> SeatDefinition:
	var result := SeatDefinition.new()
	result.display_name = display_name
	result.anchor_race = anchor
	return result


func make_seats(count: int, prefix: String = "seat") -> Array[SeatDefinition]:
	var result: Array[SeatDefinition] = []
	for index in range(count):
		result.append(make_seat("%s_%s" % [prefix, index]))
	return result


func make_article(
	race: RaceDefinition,
	is_initial: bool = true,
	growth_rate: float = 0.0,
	visit_probability: float = 0.0
) -> ConstitutionArticleDefinition:
	var result := ConstitutionArticleDefinition.new()
	result.display_name = "%s article" % race.display_name
	result.race = race
	result.is_initial = is_initial
	result.expectation_growth_rate = growth_rate
	result.visit_probability = visit_probability
	return result


func make_proposal(group: InterestGroupDefinition) -> ProposalInstance:
	var result := ProposalInstance.new()
	result.source_group = group
	return result


func make_rule(
	mode: ConstitutionInfluenceRule.Mode,
	group: InterestGroupDefinition,
	rate: float,
	race: RaceDefinition = null
) -> ConstitutionInfluenceRule:
	var result := ConstitutionInfluenceRule.new()
	result.mode = mode
	result.interest_group = group
	result.rate = rate
	result.race = race
	return result


func vote_for_race(
	result: VoteResultState, race: RaceDefinition
) -> SeatVoteState:
	for vote in result.seat_votes:
		if vote.seat != null and vote.seat.race == race:
			return vote
	return null


func count_race_seats(state: RunState, race: RaceDefinition) -> int:
	var result := 0
	for seat in state.seats:
		if seat.race == race:
			result += 1
	return result


func count_group_seats(
	state: RunState, group: InterestGroupDefinition, race: RaceDefinition = null
) -> int:
	var result := 0
	for seat in state.seats:
		if seat.actual_group == group and (race == null or seat.race == race):
			result += 1
	return result
