extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_permanent_seats_survive_annual_allocation(t)
	_test_anchor_and_zero_max_constraints(t)
	_test_resolved_events_are_the_only_dynamic_race_weight(t)
	_test_annual_group_coloring_and_archives(t)


func _test_permanent_seats_survive_annual_allocation(t: BackendTestContext) -> void:
	var race_a := t.make_race("annual a")
	var race_b := t.make_race("annual b")
	var definitions := t.make_seats(10, "permanent")
	definitions[0].anchor_race = race_a
	definitions[1].anchor_race = race_b
	var session := t.make_session(
		[race_a, race_b], [t.make_group("group")], definitions
	)
	var before: Array[SeatState] = session.state.seats.duplicate()
	for index in range(before.size()):
		before[index].personal_relation = float(index + 1)
	session.state.get_race(race_a).resolved_events_this_year = 4
	session.annual_settlement_system.settle_year(session.context)

	t.check_equal(session.state.seats.size(), definitions.size(), "annual settlement keeps seat count")
	for index in range(before.size()):
		t.check(session.state.seats[index] == before[index], "annual settlement keeps SeatState identity")
		t.check(
			session.state.seats[index].definition == definitions[index],
			"annual settlement keeps SeatDefinition identity"
		)
		t.check_approx(
			session.state.seats[index].personal_relation,
			float(index + 1),
			"annual settlement preserves seat runtime relation"
		)
	session.free()


func _test_anchor_and_zero_max_constraints(t: BackendTestContext) -> void:
	var anchored := t.make_race("anchored")
	var removable := t.make_race("removable")
	var filler := t.make_race("filler")
	var anchored_article := t.make_article(anchored)
	anchored_article.race_max_seat_rate = 0.0
	var removable_article := t.make_article(removable)
	removable_article.race_max_seat_rate = 0.0
	var filler_article := t.make_article(filler)
	var definitions := t.make_seats(5, "anchor")
	definitions[0].anchor_race = anchored
	var session := t.make_session(
		[anchored, removable, filler],
		[t.make_group("group")],
		definitions,
		[anchored_article, removable_article, filler_article]
	)
	t.check_equal(t.count_race_seats(session.state, anchored), 1, "anchor survives max rate zero")
	t.check(session.state.seats[0].race == anchored, "last anchored seat occupies its location")
	t.check_equal(t.count_race_seats(session.state, removable), 0, "unanchored max zero disappears")
	t.check_equal(t.count_race_seats(session.state, filler), 4, "remaining race fills permanent pool")
	t.check(
		session.parliament_system.validate_anchor_invariants(session.state, [anchored, removable, filler]),
		"allocated parliament satisfies anchor invariant"
	)
	session.free()


func _test_resolved_events_are_the_only_dynamic_race_weight(t: BackendTestContext) -> void:
	var race_a := t.make_race("weighted")
	var race_b := t.make_race("neutral")
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.race_seat_base_weight = 1.0
	balance.race_resolved_event_weight = 1.0
	var session := t.make_session(
		[race_a, race_b], [t.make_group("group")], t.make_seats(10, "weights"), [], balance
	)
	t.check_equal(t.count_race_seats(session.state, race_a), 5, "neutral base weights split seats")
	session.state.get_race(race_a).resolved_events_this_year = 4
	t.check_approx(
		session.race_system.get_annual_weight(session.state.get_race(race_a), balance),
		5.0,
		"resolved event count directly raises annual weight"
	)
	session.annual_settlement_system.settle_year(session.context)
	t.check_equal(t.count_race_seats(session.state, race_a), 8, "resolved race gains annual seats")
	t.check_equal(t.count_race_seats(session.state, race_b), 2, "fixed pool adjusts other race share")
	t.check_equal(
		session.state.get_race(race_a).last_year_resolved_events, 4,
		"annual result is archived"
	)
	t.check_equal(
		session.state.get_race(race_a).resolved_events_this_year, 0,
		"annual dynamic counter resets"
	)
	session.annual_settlement_system.settle_year(session.context)
	t.check_equal(t.count_race_seats(session.state, race_a), 5, "no persistent score survives next year")
	t.check_equal(t.count_race_seats(session.state, race_b), 5, "neutral weights restore neutral split")
	session.free()


func _test_annual_group_coloring_and_archives(t: BackendTestContext) -> void:
	var race := t.make_race("coloring")
	var first := t.make_group("first")
	var source := t.make_group("source")
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 0
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.annual_group_coloring_rate = 1.0
	var session := t.make_session(
		[race], [first, source], t.make_seats(4, "coloring"), [], balance
	)
	var proposal := t.make_proposal(source)
	session.parliament_system.record_authorized_proposal_slots(session.state, [proposal, proposal])
	session.parliament_system.apply_annual_coloring(session.context)
	t.check_equal(t.count_group_seats(session.state, source), 4, "coloring rate one uses enacted source")
	session.state.petition_used_this_year = 2
	session.annual_settlement_system.settle_year(session.context)
	t.check_equal(
		session.state.last_annual_proposal_slot_counts[source], 2,
		"annual archive keeps group Resource key"
	)
	t.check_approx(
		session.state.last_annual_source_shares[source], 1.0,
		"annual archive keeps source share"
	)
	t.check(session.state.annual_proposal_slot_counts.is_empty(), "new annual source ledger is empty")
	t.check_equal(session.state.petition_used_this_year, 0, "annual settlement resets petition use")
	t.check(session.state.constitution.revision_available, "annual settlement opens revision window")
	balance.annual_group_coloring_rate = 0.0
	session.parliament_system.apply_annual_coloring(session.context)
	t.check_equal(t.count_group_seats(session.state, first), 2, "zero coloring restores base groups")
	t.check_equal(t.count_group_seats(session.state, source), 2, "base group distribution remains stable")
	session.free()
