extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


class TrackingRaceDefinition:
	extends RaceDefinition
	var month_calls: int = 0

	func on_month_start(context, _race_state) -> void:
		month_calls += 1
		context.state.petition_limit = 7


class TrackingArticleDefinition:
	extends ConstitutionArticleDefinition
	var month_calls: int = 0
	var observed_race_value: int = -1

	func on_month_start(context) -> void:
		month_calls += 1
		observed_race_value = context.state.petition_limit
		context.state.petition_limit = 8


class FlowCallLog:
	extends RefCounted
	var entries: Array[StringName] = []

	func record(entry: StringName) -> void:
		entries.append(entry)


class FlowRaceDefinition:
	extends RaceDefinition
	var call_log: FlowCallLog

	func _init(source_log: FlowCallLog = null) -> void:
		call_log = source_log

	func on_month_start(_context, _race_state) -> void:
		call_log.record(&"race")


class FlowArticleDefinition:
	extends ConstitutionArticleDefinition
	var call_log: FlowCallLog

	func _init(source_log: FlowCallLog = null) -> void:
		call_log = source_log

	func on_month_start(_context) -> void:
		call_log.record(&"article")


class FlowMarketSystem:
	extends MarketSystem
	var call_log: FlowCallLog

	func _init(source_log: FlowCallLog = null) -> void:
		call_log = source_log

	func settle_month(_context: RunContext) -> void:
		call_log.record(&"market")


class FlowPolicySystem:
	extends PolicySystem
	var call_log: FlowCallLog

	func _init(source_log: FlowCallLog = null) -> void:
		call_log = source_log

	func resolve_policy_chain(_state: RunState) -> void:
		call_log.record(&"policy")


class FlowEventSystem:
	extends EventSystem
	var call_log: FlowCallLog

	func _init(source_log: FlowCallLog = null) -> void:
		call_log = source_log

	func try_generate_month(_context: RunContext) -> Array[EventState]:
		call_log.record(&"event_generate")
		var result: Array[EventState] = []
		return result

	func settle_month(_context: RunContext) -> void:
		call_log.record(&"event_settle")

	func update_information(_context: RunContext) -> void:
		call_log.record(&"event_information")


class FlowCollapseSystem:
	extends CollapseSystem
	var call_log: FlowCallLog

	func _init(source_log: FlowCallLog = null) -> void:
		call_log = source_log

	func settle_month(_context: RunContext) -> void:
		call_log.record(&"collapse")

	func recover_annual(context: RunContext) -> void:
		call_log.record(&"collapse_recovery")
		super.recover_annual(context)


class FlowProposalSystem:
	extends ProposalSystem
	var call_log: FlowCallLog

	func _init(source_log: FlowCallLog = null) -> void:
		call_log = source_log

	func draw_automatic_proposals(_context: RunContext) -> void:
		call_log.record(&"proposal_draw")

	func resolve_active_visits(_context: RunContext) -> Array[ProposalInstance]:
		call_log.record(&"proposal_visit")
		var result: Array[ProposalInstance] = []
		return result


class FlowAnnualSettlementSystem:
	extends AnnualSettlementSystem
	var call_log: FlowCallLog

	func _init(source_log: FlowCallLog = null) -> void:
		call_log = source_log

	func settle_year(_context: RunContext) -> void:
		call_log.record(&"annual")


class FlowTimeSystem:
	extends TimeSystem
	var call_log: FlowCallLog

	func _init(source_log: FlowCallLog = null) -> void:
		call_log = source_log

	func advance_month(state: RunState) -> void:
		call_log.record(&"time")
		super.advance_month(state)


func run(t: BackendTestContext) -> void:
	_test_recursive_expectation_growth(t)
	_test_zero_growth_still_allows_gap_event(t)
	_test_biyi_adjustment_is_proportional(t)
	_test_month_hook_order(t)
	_test_complete_month_flow_order(t)
	_test_balance_controls_automatic_draw_count(t)


func _test_recursive_expectation_growth(t: BackendTestContext) -> void:
	var higher := t.make_race("higher")
	higher.increase_trade = true
	var higher_article := t.make_article(higher, true, 0.10)
	var higher_session := t.make_session(
		[higher], [t.make_group("group")], t.make_seats(1, "higher"), [higher_article]
	)
	var higher_state := higher_session.state.get_race(higher)
	t.check_equal(higher_state.get_expectation(Metric.Id.TRADE), 100, "first year starts at initial value")
	higher_session.annual_settlement_system.settle_year(higher_session.context)
	t.check_equal(higher_state.get_expectation(Metric.Id.TRADE), 110, "higher target grows from prior value")
	higher_session.annual_settlement_system.settle_year(higher_session.context)
	t.check_equal(higher_state.get_expectation(Metric.Id.TRADE), 121, "higher target compounds recursively")
	higher_session.free()

	var lower := t.make_race("lower")
	lower.decrease_tax = true
	var lower_article := t.make_article(lower, true, 0.10)
	var lower_session := t.make_session(
		[lower], [t.make_group("group")], t.make_seats(1, "lower"), [lower_article]
	)
	var lower_state := lower_session.state.get_race(lower)
	lower_session.annual_settlement_system.settle_year(lower_session.context)
	t.check_equal(lower_state.get_expectation(Metric.Id.TAX), 90, "lower target shrinks from prior value")
	lower_session.annual_settlement_system.settle_year(lower_session.context)
	t.check_equal(lower_state.get_expectation(Metric.Id.TAX), 81, "lower target compounds recursively")
	lower_session.free()

	var balance := GameBalanceDefinition.new()
	balance.proposal_magnitude_growth_per_year = 0.10
	t.check_approx(
		InflationSystem.new().get_proposal_magnitude_multiplier(3, balance),
		1.21,
		"proposal era magnitude uses independent compound growth"
	)


func _test_zero_growth_still_allows_gap_event(t: BackendTestContext) -> void:
	var race := t.make_race("stable expectation")
	race.increase_wage = true
	var article := t.make_article(race, true, 0.0)
	var session := t.make_session(
		[race], [t.make_group("group")], t.make_seats(1, "stable"), [article]
	)
	var race_state := session.state.get_race(race)
	session.race_system.advance_expectations(session.state)
	t.check_equal(race_state.get_expectation(Metric.Id.WAGE), 100, "zero growth preserves target")
	session.state.metrics.wage = 50
	var event := session.event_system.spawn_event(session.context, race, Metric.Id.WAGE)
	t.check(event != null, "real metric regression still creates an event at zero growth")
	session.free()


func _test_biyi_adjustment_is_proportional(t: BackendTestContext) -> void:
	var race := BiyiRaceDefinition.new()
	race.display_name = "biyi"
	race.decrease_tax = true
	race.yin_tax = true
	var article := BiyiConstitutionArticleDefinition.new()
	article.display_name = "yin yang"
	article.race = race
	article.is_initial = true
	article.yin_yang_adjustment_rate = 0.10
	var session := t.make_session(
		[race], [t.make_group("group")], t.make_seats(1, "biyi"), [article]
	)
	var race_state := session.state.get_race(race)
	race_state.expectation_targets[Metric.Id.TAX] = 200
	session.state.month = 1
	t.check_equal(
		session.race_system.get_effective_expectation(race_state, Metric.Id.TAX, session.context),
		180,
		"yin month adjusts ten percent of current target"
	)
	t.check(race.is_vote_metric_active(Metric.Id.TAX, session.context), "yin metric is active in yin month")
	session.state.month = 2
	t.check_equal(
		session.race_system.get_effective_expectation(race_state, Metric.Id.TAX, session.context),
		220,
		"yang month reverses the proportional adjustment"
	)
	t.check(not race.is_vote_metric_active(Metric.Id.TAX, session.context), "yin metric is inactive in yang month")
	session.free()


func _test_month_hook_order(t: BackendTestContext) -> void:
	var race := TrackingRaceDefinition.new()
	race.display_name = "tracking"
	var article := TrackingArticleDefinition.new()
	article.display_name = "tracking article"
	article.race = race
	article.is_initial = true
	var session := t.make_session(
		[race], [t.make_group("group")], t.make_seats(1, "hooks"), [article]
	)
	session.state.month = 1
	session.advance_month()
	t.check_equal(race.month_calls, 1, "FlowController invokes race month hook")
	t.check_equal(article.month_calls, 1, "FlowController invokes article month hook")
	t.check_equal(article.observed_race_value, 7, "race hook runs before article hook")
	t.check_equal(session.state.petition_limit, 8, "article hook result remains in runtime state")
	t.check_equal(session.state.month, 2, "month advances after lifecycle and systems")
	session.free()


func _test_complete_month_flow_order(t: BackendTestContext) -> void:
	var call_log := FlowCallLog.new()
	var race := FlowRaceDefinition.new(call_log)
	race.display_name = "flow race"
	var article := FlowArticleDefinition.new(call_log)
	article.display_name = "flow article"
	article.race = race
	article.is_initial = true
	var session := t.make_session(
		[race], [t.make_group("flow group")], t.make_seats(1, "flow"), [article]
	)
	session.context.market_system = FlowMarketSystem.new(call_log)
	session.context.policy_system = FlowPolicySystem.new(call_log)
	session.context.event_system = FlowEventSystem.new(call_log)
	session.context.collapse_system = FlowCollapseSystem.new(call_log)
	session.context.proposal_system = FlowProposalSystem.new(call_log)
	session.context.annual_settlement_system = FlowAnnualSettlementSystem.new(call_log)
	session.context.time_system = FlowTimeSystem.new(call_log)
	session.state.month = 12
	session.advance_month()
	var expected: Array[StringName] = [
		&"race",
		&"article",
		&"market",
		&"policy",
		&"event_generate",
		&"event_settle",
		&"event_information",
		&"collapse",
		&"proposal_draw",
		&"proposal_visit",
		&"annual",
		&"time",
		&"collapse_recovery",
	]
	t.check_equal(call_log.entries, expected, "monthly flow order is stable through annual settlement")
	session.free()


func _test_balance_controls_automatic_draw_count(t: BackendTestContext) -> void:
	var race := t.make_race("draw")
	var group := t.make_group("draw group")
	group.decrease_price = true
	var balance := GameBalanceDefinition.new()
	balance.automatic_draw_count = 2
	balance.event_spawn_count_min = 0
	balance.event_spawn_count_max = 0
	balance.proposal_negative_magnitude_min = 3
	balance.proposal_negative_magnitude_max = 3
	var session := t.make_session(
		[race], [group], t.make_seats(1, "draw"), [], balance
	)
	t.check_equal(session.state.proposal_hand.size(), 0, "month zero defers the automatic opening draw")
	session.advance_month()
	t.check_equal(session.state.proposal_hand.size(), 2, "automatic opening draw count comes from balance")
	for proposal in session.state.proposal_hand:
		t.check(proposal.source_group == group, "automatic proposal keeps group Resource")
		t.check_equal(proposal.base_effect.price, 3, "configured proposal magnitude is applied")
	session.free()
