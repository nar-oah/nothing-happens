extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_three_seat_condition_scopes(t)
	_test_direct_prerequisite_and_clicked_history(t)
	_test_policy_union_and_resource_deduplication(t)
	_test_influence_rule_modes(t)
	_test_revision_preserves_annual_group_layer(t)
	_test_local_autonomy_runtime_resources(t)
	_test_human_petition_runtime_and_anchor_safety(t)


func _test_three_seat_condition_scopes(t: BackendTestContext) -> void:
	var race_a := t.make_race("race a")
	var race_b := t.make_race("race b")
	var group_a := t.make_group("group a")
	var group_b := t.make_group("group b")
	var session := t.make_session(
		[race_a, race_b], [group_a, group_b], t.make_seats(4, "conditions")
	)
	for index in range(4):
		var seat := session.state.seats[index]
		seat.race = race_a if index < 2 else race_b
		seat.base_group = group_a if index % 2 == 0 else group_b
		seat.actual_group = seat.base_group

	var race_condition := ConstitutionSeatCondition.new()
	race_condition.race = race_a
	race_condition.required_rate = 0.5
	t.check(race_condition.is_met(session.context), "race condition uses all permanent seats")
	race_condition.required_rate = 0.51
	t.check(not race_condition.is_met(session.context), "race condition rejects rate above share")

	var global_group := ConstitutionSeatCondition.new()
	global_group.interest_group = group_a
	global_group.required_rate = 0.5
	t.check(global_group.is_met(session.context), "global group rate uses influenceable seats")
	global_group.required_rate = 0.51
	t.check(not global_group.is_met(session.context), "global group boundary is exact")

	var scoped_group := ConstitutionSeatCondition.new()
	scoped_group.race = race_a
	scoped_group.interest_group = group_a
	scoped_group.required_rate = 0.5
	t.check(scoped_group.is_met(session.context), "scoped group rate uses that race's seats")
	scoped_group.required_rate = 0.51
	t.check(not scoped_group.is_met(session.context), "scoped group rate rejects excess threshold")
	session.free()


func _test_direct_prerequisite_and_clicked_history(t: BackendTestContext) -> void:
	var race := t.make_race("history")
	var initial := t.make_article(race)
	initial.display_name = "initial"
	var next := t.make_article(race, false)
	next.display_name = "next"
	next.prerequisite = initial
	var sibling := t.make_article(race, false)
	sibling.display_name = "sibling"
	sibling.prerequisite = initial
	var session := t.make_session(
		[race], [t.make_group("group")], t.make_seats(2, "history"),
		[initial, next, sibling]
	)
	t.check(session.state.constitution.was_clicked(initial), "initial Resource enters clicked history")
	t.check(session.constitution_system.can_revise(session.context, next), "direct prerequisite permits revision")
	t.check(session.revise_constitution(next), "revision activates the selected Resource")
	t.check(
		session.state.constitution.get_active_article(race) == next,
		"active article is keyed by race Resource"
	)
	t.check(session.state.constitution.was_clicked(next), "revision records clicked Resource")
	session.state.constitution.revision_available = true
	t.check(
		session.constitution_system.can_revise(session.context, sibling),
		"inactive prerequisite remains valid because it was clicked"
	)
	var locked := t.make_article(race, false)
	locked.prerequisite = ConstitutionArticleDefinition.new()
	t.check(
		not session.constitution_system.can_revise(session.context, locked),
		"an unclicked prerequisite Resource remains locked"
	)
	session.free()


func _test_policy_union_and_resource_deduplication(t: BackendTestContext) -> void:
	var race_a := t.make_race("policy a")
	var race_b := t.make_race("policy b")
	var shared := PolicyDefinition.new()
	shared.display_name = "same"
	var distinct_same_name := PolicyDefinition.new()
	distinct_same_name.display_name = "same"
	var unavailable := PolicyDefinition.new()
	unavailable.display_name = "unavailable"
	var article_a := t.make_article(race_a)
	article_a.policies = [shared, distinct_same_name]
	var article_b := t.make_article(race_b)
	article_b.policies = [shared]
	var session := t.make_session(
		[race_a, race_b], [t.make_group("group")], t.make_seats(2, "policies"),
		[article_a, article_b]
	)
	var available := session.constitution_system.get_available_policies(session.context)
	t.check_equal(available.size(), 2, "active article policies form a Resource identity union")
	t.check(shared in available and distinct_same_name in available, "same names remain distinct Resources")
	t.check(
		session.draft_bill_system.add_available_policy(session.context, shared),
		"available policy enters draft"
	)
	t.check(
		not session.draft_bill_system.add_available_policy(session.context, shared),
		"the same policy Resource cannot duplicate"
	)
	t.check(
		session.draft_bill_system.add_available_policy(session.context, distinct_same_name),
		"different same-name policy Resource is allowed"
	)
	t.check(
		not session.draft_bill_system.add_available_policy(session.context, unavailable),
		"policy outside active articles is unavailable"
	)
	session.free()


func _test_influence_rule_modes(t: BackendTestContext) -> void:
	var race_a := t.make_race("influence a")
	var race_b := t.make_race("influence b")
	var base := t.make_group("base")
	var target := t.make_group("target")
	var article_a := t.make_article(race_a)
	var article_b := t.make_article(race_b)
	var session := t.make_session(
		[race_a, race_b], [base, target], t.make_seats(6, "influence"),
		[article_a, article_b]
	)
	for seat in session.state.seats:
		seat.base_group = base
		seat.actual_group = base

	article_a.influence_rules = [
		t.make_rule(ConstitutionInfluenceRule.Mode.TARGET, target, 0.5, race_a)
	]
	session.constitution_system.apply_influence_rules(session.context)
	t.check_equal(t.count_group_seats(session.state, target, race_a), 2, "scoped target rounds to rate")
	t.check_equal(t.count_group_seats(session.state, target, race_b), 0, "scoped target leaves other race")

	article_a.influence_rules = [
		t.make_rule(ConstitutionInfluenceRule.Mode.MAXIMUM, target, 0.0, race_a)
	]
	session.constitution_system.apply_influence_rules(session.context)
	t.check_equal(t.count_group_seats(session.state, target, race_a), 0, "maximum removes excess influence")

	article_a.influence_rules = [
		t.make_rule(ConstitutionInfluenceRule.Mode.MINIMUM, target, 0.5)
	]
	session.constitution_system.apply_influence_rules(session.context)
	t.check_equal(t.count_group_seats(session.state, target), 3, "global minimum raises total influence")

	article_a.influence_rules = []
	article_b.influence_rules = [
		t.make_rule(ConstitutionInfluenceRule.Mode.TARGET, target, 1.0, race_b)
	]
	session.constitution_system.apply_influence_rules(session.context)
	t.check_equal(t.count_group_seats(session.state, target, race_b), 3, "race target can reach one hundred percent")
	session.free()


func _test_local_autonomy_runtime_resources(t: BackendTestContext) -> void:
	var race := t.make_race("local race")
	var other_race := t.make_race("other race")
	var base_group := t.make_group("base")
	var rule_group := t.make_group("ordinary rule")
	var article := LocalAutonomyConstitutionArticleDefinition.new()
	article.display_name = "local autonomy"
	article.race = race
	article.is_initial = true
	article.influence_rules = [
		t.make_rule(ConstitutionInfluenceRule.Mode.TARGET, rule_group, 1.0)
	]
	var replacement := t.make_article(race, false)
	replacement.display_name = "centralized"
	var other_initial := t.make_article(other_race)
	var other_next := t.make_article(other_race, false)
	var definitions := t.make_seats(4, "location")
	var session := t.make_session(
		[race, other_race], [base_group, rule_group], definitions,
		[article, replacement, other_initial, other_next]
	)
	var locals := session.state.constitution.local_interest_groups
	t.check_equal(locals.size(), definitions.size(), "one runtime local group per SeatDefinition")
	var remembered: Dictionary[SeatDefinition, InterestGroupDefinition] = locals.duplicate()
	var unique: Dictionary[InterestGroupDefinition, bool] = {}
	for definition in definitions:
		var group: InterestGroupDefinition = locals[definition]
		unique[group] = true
		t.check_equal(group.display_name, definition.display_name, "local name comes from location")
		t.check(group.decrease_tax, "local group only cares about lower tax")
		t.check(
			not group.decrease_price
			and not group.decrease_wage
			and not group.decrease_employment
			and not group.decrease_trade,
			"other local stances remain false"
		)
	t.check_equal(unique.size(), definitions.size(), "each location owns a unique Resource")
	article.on_activate(session.context)
	for definition in definitions:
		t.check(
			session.state.constitution.local_interest_groups[definition] == remembered[definition],
			"repeated activation preserves runtime Resource identity"
		)
	for seat in session.state.seats:
		t.check(
			seat.actual_group == remembered[seat.definition],
			"special local overlay wins over ordinary influence rules at startup"
		)
	session.annual_settlement_system.settle_year(session.context)
	for seat in session.state.seats:
		t.check(
			seat.actual_group == remembered[seat.definition],
			"special local overlay keeps the same precedence at annual settlement"
		)
	t.check(session.revise_constitution(other_next), "another race can revise while local autonomy stays active")
	for seat in session.state.seats:
		t.check(
			seat.actual_group == remembered[seat.definition],
			"unrelated revision preserves the active local overlay"
		)
	session.state.constitution.revision_available = true
	t.check(session.revise_constitution(replacement), "local autonomy can be deactivated")
	var effective := session.constitution_system.get_effective_groups(session.context)
	for seat in session.state.seats:
		t.check(
			seat.actual_group == seat.annual_group,
			"deactivation restores the underlying annual group"
		)
		t.check(
			not effective.has(remembered[seat.definition]),
			"inactive historical local groups do not leak into effective content"
		)
	session.free()


func _test_revision_preserves_annual_group_layer(t: BackendTestContext) -> void:
	var race_a := t.make_race("merger race")
	var race_b := t.make_race("revised race")
	var weak := t.make_group("weak")
	var strong := t.make_group("strong")
	var article_a := t.make_article(race_a)
	var article_b := t.make_article(race_b)
	var next_b := t.make_article(race_b, false)
	var session := t.make_session(
		[race_a, race_b], [weak, strong], t.make_seats(4, "annual layer"),
		[article_a, article_b, next_b]
	)
	for seat in session.state.seats:
		seat.annual_group = weak
		seat.actual_group = strong
	session.state.constitution.group_mergers[weak] = strong
	t.check(session.revise_constitution(next_b), "unrelated article revision succeeds")
	for seat in session.state.seats:
		t.check(seat.annual_group == weak, "revision preserves raw annual coloring")
		t.check(seat.actual_group == strong, "revision reapplies active merger to annual coloring")
	session.free()


func _test_human_petition_runtime_and_anchor_safety(t: BackendTestContext) -> void:
	var human := t.make_race("human")
	var donor := t.make_race("anchored donor")
	var filler := t.make_race("filler")
	var human_article := HumanConstitutionArticleDefinition.new()
	human_article.display_name = "petition constitution"
	human_article.race = human
	human_article.is_initial = true
	human_article.petition_limit = 2
	human_article.race_max_seat_rate = 0.75
	var donor_article := t.make_article(donor)
	var filler_article := t.make_article(filler)
	var definitions := t.make_seats(4, "petition")
	definitions[0].anchor_race = donor
	var session := t.make_session(
		[human, donor, filler], [t.make_group("group")], definitions,
		[human_article, donor_article, filler_article]
	)
	t.check_equal(session.state.petition_limit, 2, "petition limit comes from active Human article")
	t.check(session.state.petition_race == human, "petition race is a direct Resource")
	t.check_equal(t.count_race_seats(session.state, human), 2, "fixture starts below petition max")
	t.check_equal(t.count_race_seats(session.state, donor), 1, "donor starts at anchor minimum")
	t.check(session.use_petition(), "petition immediately reassigns a legal seat")
	t.check_equal(t.count_race_seats(session.state, human), 3, "petition changes the current parliament")
	t.check_equal(session.state.petition_used_this_year, 1, "State records annual petition usage")
	t.check(session.state.seats[0].race == donor, "petition does not steal another race's anchor")
	t.check(not session.use_petition(), "petition fails when target is at active max")
	t.check_equal(session.state.petition_used_this_year, 1, "failed petition consumes no use")

	var next := HumanConstitutionArticleDefinition.new()
	next.display_name = "expanded petition"
	next.race = human
	next.prerequisite = human_article
	next.petition_limit = 3
	next.race_max_seat_rate = 1.0
	session.context.constitution_articles.append(next)
	session.state.constitution.revision_available = true
	t.check(session.revise_constitution(next), "Human constitution can change midyear")
	t.check_equal(session.state.petition_limit, 3, "new article refreshes petition limit")
	t.check_equal(session.state.petition_used_this_year, 1, "midyear revision does not reset usage")
	session.free()
