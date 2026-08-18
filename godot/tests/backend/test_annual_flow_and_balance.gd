extends RefCounted


func run(t) -> void:
	_test_annual_settlement(t)
	_test_flow_reaches_new_year(t)
	_test_era_expectations(t)
	_test_yin_yang_expectations(t)


func _test_annual_settlement(t) -> void:
	var race := t.make_race(&"annual")
	race.increase_trade = true
	var groups: Array[InterestGroupDefinition] = [
		t.make_group(&"a", 1, 0),
		t.make_group(&"b", 1, 1),
	]
	var races: Array[RaceDefinition] = [race]
	var session := t.make_session(races, groups, [], 8)

	var race_state := session.state.get_race(&"annual")
	race_state.pending_trust_delta = 50.0

	var proposal := t.make_proposal(&"b")
	var proposals: Array[ProposalInstance] = [proposal]
	session.parliament_system.record_authorized_proposal_slots(session.state, proposals)
	session.annual_settlement_system.settle_year(session.context)

	t.check_equal(race_state.political_trust, 100.0, "annual trust is applied first")
	t.check_equal(race_state.seat_count, 8, "new trust determines annual row size")
	t.check_equal(session.state.seats.size(), 8, "whole parliament rebuilt with new rows")
	t.check_equal(race_state.get_expectation(Metric.Id.TRADE), 110, "era expectation tightens last")
	t.check_equal(
		session.state.last_annual_proposal_slot_counts[&"b"], 1, "annual slot ledger retained"
	)
	t.check_equal(
		session.state.last_annual_source_shares[&"b"], 1.0, "annual source share retained"
	)
	t.check(
		session.state.annual_proposal_slot_counts.is_empty(), "new year slot ledger starts empty"
	)
	t.check(session.state.constitution.revision_available, "one annual revision window opens")
	session.free()


func _test_flow_reaches_new_year(t) -> void:
	var race := t.make_race(&"flow")
	race.increase_wage = true
	var races: Array[RaceDefinition] = [race]
	var groups: Array[InterestGroupDefinition] = [t.make_group(&"group", 1, 0)]
	var session := t.make_session(races, groups, [], 4)

	session.state.month = 12
	var race_state := session.state.get_race(&"flow")
	race_state.pending_trust_delta = 50.0
	session.advance_month()

	t.check_equal(session.state.year, 2, "December flow enters next year")
	t.check_equal(session.state.month, 1, "new year starts at first month")
	t.check_equal(race_state.seat_count, 4, "flow runs trust and seats before new year")
	t.check_equal(
		race_state.get_expectation(Metric.Id.WAGE), 110, "flow tightens expectation before new year"
	)
	session.free()


func _test_era_expectations(t) -> void:
	var balance := GameBalanceDefinition.new()
	var inflation := InflationSystem.new()

	t.check_equal(
		inflation.get_expectation_target(MetricStanceDefinition.Direction.HIGHER, 1, balance),
		100,
		"year one higher expectation starts at baseline"
	)
	t.check_equal(
		inflation.get_expectation_target(MetricStanceDefinition.Direction.LOWER, 1, balance),
		100,
		"year one lower expectation starts at baseline"
	)
	t.check_equal(
		inflation.get_expectation_target(MetricStanceDefinition.Direction.HIGHER, 2, balance),
		110,
		"year two higher expectation tightens upward"
	)
	t.check_equal(
		inflation.get_expectation_target(MetricStanceDefinition.Direction.LOWER, 2, balance),
		90,
		"year two lower expectation tightens downward"
	)


func _test_yin_yang_expectations(t) -> void:
	var biyi := t.make_race(Race.BIYI)
	biyi.decrease_tax = true
	biyi.decrease_price = true
	biyi.increase_wage = true
	biyi.decrease_trade = true

	var article := ConstitutionArticleDefinition.new()
	article.id = &"inclusive_culture"
	article.axis_id = &"culture"
	article.is_initial = true
	article.flags = [ConstitutionSystem.FLAG_YIN_YANG_BIYI_ONLY]

	var races: Array[RaceDefinition] = [biyi]
	var groups: Array[InterestGroupDefinition] = [t.make_group(&"group", 1, 0)]
	var articles: Array[ConstitutionArticleDefinition] = [article]
	var session := t.make_session(races, groups, articles)
	var race := session.state.get_race(Race.BIYI)

	t.check_equal(
		race.get_expectation(Metric.Id.TAX), 100, "annual base target is not mutated by month"
	)

	session.state.month = 1
	t.check_equal(
		session.race_system.get_effective_expectation(race, Metric.Id.TAX, session.context),
		90,
		"yin month tightens lower tax expectation"
	)
	t.check_equal(
		session.race_system.get_effective_expectation(race, Metric.Id.WAGE, session.context),
		90,
		"yin month relaxes yang wage expectation"
	)

	session.state.month = 2
	t.check_equal(
		session.race_system.get_effective_expectation(race, Metric.Id.TAX, session.context),
		110,
		"yang month relaxes yin tax expectation"
	)
	t.check_equal(
		session.race_system.get_effective_expectation(race, Metric.Id.WAGE, session.context),
		110,
		"yang month tightens yang wage expectation"
	)
	session.free()
