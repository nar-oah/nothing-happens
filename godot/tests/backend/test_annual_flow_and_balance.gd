extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_expectation_growth_effect_modifies_active_race_growth(t)
	_test_annual_settlement_reapplies_group_effects(t)
	_test_annual_settlement_resets_yearly_runtime_state(t)


func _test_expectation_growth_effect_modifies_active_race_growth(t: BackendTestContext) -> void:
	var race := t.make_race("growth")
	race.increase_tax = true
	race.expectation_growth_rate = 0.2
	var article := t.make_article(race)
	var growth := ExpectationGrowthEffect.new()
	growth.races = [race]
	growth.growth_modifier = -0.5
	article.effects.append(growth)
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.initial_metric_value = 100
	var session := t.make_session([race], [t.make_group("group")], t.make_seats(2, "growth"), [article], balance)
	session.state.year_start_metrics.tax = 100
	session.race_system.rebuild_annual_expectations(session.context)
	t.check_equal(session.state.get_race(race).get_expectation(Metric.Id.TAX, 0), 110, "-50% growth modifier scales 20% intrinsic growth to 10%")
	growth.growth_modifier = -1.0
	session.race_system.rebuild_annual_expectations(session.context)
	t.check_equal(session.state.get_race(race).get_expectation(Metric.Id.TAX, 0), 100, "-100% growth modifier cleanly disables growth")
	session.free()


func _test_annual_settlement_reapplies_group_effects(t: BackendTestContext) -> void:
	var race := t.make_race("annual local")
	var group := t.make_group("base")
	var article := t.make_article(race)
	var local := LocalInterestGroupEffect.new()
	local.races = [race]
	local.decrease_metric = Metric.Id.TAX
	article.effects.append(local)
	var session := t.make_session([race], [group], t.make_seats(4, "annual-local"), [article])
	var before: Dictionary[SeatDefinition, InterestGroupDefinition] = session.state.constitution.local_interest_groups.duplicate()
	session.annual_settlement_system.settle_year(session.context)
	for seat in session.state.seats:
		t.check(seat.actual_group == session.state.constitution.local_interest_groups[seat.definition], "annual group allocation reapplies local interest-group effect")
		t.check(seat.actual_group == before[seat.definition], "annual settlement preserves runtime local Resource identity")
	session.free()


func _test_annual_settlement_resets_yearly_runtime_state(t: BackendTestContext) -> void:
	var race := t.make_race("annual state")
	var group := t.make_group("group")
	var article := t.make_article(race)
	var petition := PetitionEffect.new()
	petition.fixed_count = 2
	article.effects.append(petition)
	var session := t.make_session([race], [group], t.make_seats(2, "annual-state"), [article])
	t.check(session.use_petition(), "petition capacity is available before settlement")
	session.state.constitution.revision_available = false
	session.state.annual_proposal_slot_counts[group] = 3
	session.annual_settlement_system.settle_year(session.context)
	t.check_equal(session.state.petition_used_this_year, 0, "annual settlement resets petition usage")
	t.check(session.state.constitution.revision_available, "annual settlement restores constitution revision")
	t.check(session.state.annual_proposal_slot_counts.is_empty(), "annual settlement clears current proposal source counters")
	t.check_equal(session.state.last_annual_proposal_slot_counts.get(group, 0), 3, "annual settlement archives proposal source counters")
	session.free()
