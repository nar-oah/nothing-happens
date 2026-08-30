extends Node
class_name RunSession

@export_group("配置")
@export var balance: GameBalanceDefinition
@export var constitution_board: ConstitutionBoardDefinition = preload("res://data/constitutions/constitution_board.tres")

@export_group("游戏内容")
@export var race_definitions: Array[RaceDefinition] = []
@export var interest_groups: Array[InterestGroupDefinition] = []
@export var seat_definitions: Array[SeatDefinition] = []
# Without a board this stores legacy flat content. With a board it is refreshed from
# ConstitutionBoardDefinition so serializers and external callers share one article order.
@export var constitution_articles: Array[ConstitutionArticleDefinition] = []

var state: RunState
var meta_progression := MetaProgressionState.new()
var context: RunContext
var time_system: TimeSystem
var random_system: RandomSystem
var proposal_system: ProposalSystem
var market_system: MarketSystem
var policy_system: PolicySystem
var inflation_system: InflationSystem
var parliament_system: ParliamentSystem
var race_system: RaceSystem
var draft_bill_system: DraftBillSystem
var vote_system: VoteSystem
var event_system: EventSystem
var constitution_system: ConstitutionSystem
var collapse_system: CollapseSystem
var annual_settlement_system: AnnualSettlementSystem
var flow_controller: FlowController
var newspaper_front_resolvers: Array[Callable] = []
var term_report: Dictionary = {}
var _last_awarded_term: int = 0
var _previous_newspaper_collapse: int = 0


func configure_content(
	races: Array[RaceDefinition],
	groups: Array[InterestGroupDefinition],
	seats: Array[SeatDefinition],
	articles: Array[ConstitutionArticleDefinition] = [],
	board: ConstitutionBoardDefinition = null
) -> void:
	race_definitions = races
	interest_groups = groups
	seat_definitions = seats
	# configure_content is an explicit content override. Passing no board intentionally
	# selects the legacy flat-article path instead of retaining the exported default board.
	constitution_board = board
	constitution_articles = board.get_articles() if board != null else articles


func start_new_run() -> void:
	term_report.clear()
	_last_awarded_term = 0
	_start_term(1)


func _start_term(term_number: int) -> bool:
	if balance == null:
		push_error("RunSession requires GameBalanceDefinition.")
		return false
	if race_definitions.is_empty():
		push_error("RunSession requires race definitions.")
		return false
	if interest_groups.is_empty():
		push_error("RunSession requires interest group definitions.")
		return false
	if seat_definitions.is_empty():
		push_error("RunSession requires seat definitions.")
		return false
	if constitution_board != null:
		constitution_articles = constitution_board.get_articles()
	state = RunState.new()
	state.term = maxi(term_number, 1)
	time_system = TimeSystem.new()
	random_system = RandomSystem.new()
	proposal_system = ProposalSystem.new()
	market_system = MarketSystem.new()
	policy_system = PolicySystem.new()
	inflation_system = InflationSystem.new()
	inflation_system.initialize_metrics(state.metrics, balance)
	state.year_start_metrics = state.metrics.copy()
	parliament_system = ParliamentSystem.new()
	race_system = RaceSystem.new()
	draft_bill_system = DraftBillSystem.new()
	vote_system = VoteSystem.new()
	event_system = EventSystem.new()
	constitution_system = ConstitutionSystem.new()
	collapse_system = CollapseSystem.new()
	annual_settlement_system = AnnualSettlementSystem.new()
	context = RunContext.new()
	context.setup(
		state,
		balance,
		time_system,
		random_system,
		proposal_system,
		market_system,
		policy_system,
		inflation_system,
		parliament_system,
		race_system,
		draft_bill_system,
		vote_system,
		event_system,
		constitution_system,
		collapse_system,
		annual_settlement_system
	)
	context.race_definitions = race_definitions
	context.interest_groups = interest_groups
	context.seat_definitions = seat_definitions
	context.constitution_board = constitution_board
	context.constitution_articles = constitution_articles
	context.meta_progression = meta_progression
	if not race_system.initialize_races(state, race_definitions, balance):
		return false
	if not parliament_system.initialize_seats(state, seat_definitions, race_definitions):
		return false
	if not constitution_system.initialize(context):
		return false
	var allocated := (
		race_system.allocate_opening_seats(context)
		if constitution_board != null
		else race_system.allocate_annual_seats(context)
	)
	if not allocated:
		push_error("Failed to allocate opening race seats.")
		return false
	for race in race_definitions:
		if not race_system.enforce_constitution_constraints(context, race):
			push_error("Failed to apply opening constitution seat constraints.")
			return false
	if not parliament_system.initialize_base_groups(context, interest_groups):
		return false
	constitution_system.apply_influence_rules(context)
	constitution_system.activate_initial_articles(context)
	# First-year expectations use the same constitution-driven month-0 formula as later years.
	race_system.rebuild_annual_expectations(context)
	flow_controller = FlowController.new()
	flow_controller.setup(context)
	_previous_newspaper_collapse = state.collapse_level
	_configure_newspaper_front_resolvers()
	return true


func advance_month() -> bool:
	var advanced := (
		true
		if state.run_phase == RunState.RunPhase.TERM_ENDED
		else flow_controller.advance_month()
	)
	if not advanced:
		return false
	if state.run_phase != RunState.RunPhase.TERM_ENDED:
		_resolve_newspaper_front(state)
	return (
		_settle_and_start_next_term()
		if state.run_phase == RunState.RunPhase.TERM_ENDED
		else true
	)


func start_next_term() -> bool:
	if state == null or state.run_phase != RunState.RunPhase.TERM_ENDED:
		return false
	return _settle_and_start_next_term()


func clear_term_report() -> void:
	term_report.clear()


func _settle_and_start_next_term() -> bool:
	var ended_state := state
	var previous_governing_months := meta_progression.available_governing_months
	if _last_awarded_term != ended_state.term:
		var elapsed_months := maxi((ended_state.year - 1) * 12 + ended_state.month, 0)
		meta_progression.add_governing_months(elapsed_months)
		_last_awarded_term = ended_state.term
	term_report = {
		"outcome": ended_state.term_outcome,
		"previous_governing_months": previous_governing_months,
		"current_governing_months": meta_progression.available_governing_months,
	}
	return _start_term(ended_state.term + 1)


func unlock_constitution_column(column: ConstitutionColumnDefinition) -> bool:
	return meta_progression.unlock_column(constitution_board, column)


func enact_bill(draft: DraftBillState) -> void:
	flow_controller.enact_bill(draft)


func submit_draft() -> VoteResultState:
	return flow_controller.submit_draft(state.draft_bill)


func start_new_bill(title: String = "") -> void:
	draft_bill_system.start_new_bill(state, title)


func edit_saved_bill(saved_index: int) -> bool:
	return draft_bill_system.load_saved_bill_for_editing(context, saved_index)


func cancel_bill_editing() -> void:
	draft_bill_system.cancel_editing(state)


func revise_constitution(article: ConstitutionArticleDefinition) -> bool:
	return constitution_system.revise(context, article)


func use_petition() -> bool:
	return parliament_system.use_petition(context)


func accept_proposal_trait(proposal: ProposalInstance) -> bool:
	return proposal_system.resolve_bonus_choice(state, proposal, true)


func convert_proposal_trait_to_donation(proposal: ProposalInstance) -> bool:
	return proposal_system.resolve_bonus_choice(state, proposal, false)


func _configure_newspaper_front_resolvers() -> void:
	newspaper_front_resolvers.clear()
	newspaper_front_resolvers.append(Callable(self, "_resolve_no_event_front"))
	newspaper_front_resolvers.append(Callable(self, "_resolve_term_start_front"))
	newspaper_front_resolvers.append(Callable(self, "_resolve_bill_passed_front"))
	newspaper_front_resolvers.append(Callable(self, "_resolve_policy_triggered_front"))
	newspaper_front_resolvers.append(Callable(self, "_resolve_collapse_50_front"))
	newspaper_front_resolvers.append(Callable(self, "_resolve_collapse_80_front"))
	newspaper_front_resolvers.append(Callable(self, "_resolve_collapse_90_front"))


func _resolve_newspaper_front(current_state: RunState) -> void:
	current_state.newspaper_front.clear()
	for resolver in newspaper_front_resolvers:
		var result: Variant = resolver.call(current_state)
		if result is Dictionary and not result.is_empty():
			current_state.newspaper_front = result.duplicate(true)
	current_state.newspaper_pending_bill = null
	current_state.newspaper_triggered_policies.clear()
	_previous_newspaper_collapse = current_state.collapse_level


func _resolve_no_event_front(current_state: RunState) -> Variant:
	if not current_state.month_report_events.is_empty():
		return null
	return _newspaper_front(
		"无事发生？",
		"本月没有任何种族事件达到公开门槛。报馆未能找到足以占据头版的危机，只得提醒读者：没有消息，或许正是最值得警惕的消息。"
	)


func _resolve_term_start_front(current_state: RunState) -> Variant:
	if current_state.year != 1 or current_state.month != 1:
		return null
	return _newspaper_front(
		"第%d次入主会同" % current_state.term,
		"新一任联合政府开议。各族在彼此之间挑了一圈，最终还是把会同的印信交到驻岁案前；至少在谁也不肯让步的时候，长生者看起来还算能等。"
	)


func _resolve_bill_passed_front(current_state: RunState) -> Variant:
	var bill := current_state.newspaper_pending_bill
	if bill == null:
		return null
	var bill_name := "新法案" if bill.title.strip_edges().is_empty() else "《%s》" % bill.title.strip_edges()
	var reductions := _expected_monthly_bill_reductions(bill)
	var reduction_text := (
		"按所含提案的形成速度估算，五项公共指标平均每月没有净下降"
		if reductions.is_empty()
		else "按所含提案的形成速度估算，平均每月预计减少：%s" % "、".join(reductions)
	)
	return _newspaper_front(
		"%s获议会通过" % bill_name,
		"新法已经生效。%s；实际月度路径仍可能短暂偏离。" % reduction_text
	)


func _resolve_policy_triggered_front(current_state: RunState) -> Variant:
	if current_state.newspaper_triggered_policies.is_empty():
		return null
	var names := PackedStringArray()
	for definition in current_state.newspaper_triggered_policies:
		if definition != null:
			names.append("《%s》" % definition.display_name)
	if names.is_empty():
		return null
	if names.size() == 1:
		return _newspaper_front(
			"%s触发　授权即时生效" % names[0],
			"本月账簿关系满足既定条件，%s随即执行。其影响已经记入当前市场状态；若由此带动其它政策条件，同月连锁也已一并结算。" % names[0]
		)
	return _newspaper_front(
		"%d项政策相继触发" % names.size(),
		"本月市场关系连续触及既定条款，%s即时生效。各项影响与由此产生的连锁变化，均已记入本期账簿。" % "、".join(names)
	)


func _resolve_collapse_50_front(current_state: RunState) -> Variant:
	if not _crossed_collapse_threshold(current_state, 50):
		return null
	return _newspaper_front(
		"危机预期过半　议会警告声渐密",
		"各族对全面崩溃的共同预期已经越过半数。报馆、议员与来访者开始反复引用彼此的警告；但截至目前，仍没有证据能够证明一场全面灾难已经发生。"
	)


func _resolve_collapse_80_front(current_state: RunState) -> Variant:
	if not _crossed_collapse_threshold(current_state, 80):
		return null
	return _newspaper_front(
		"八成相信危机将至　会同难闻别声",
		"崩溃预期已经越过八成。原本彼此矛盾的警告开始汇成同一种结论：必须立刻做些什么。至于灾难本身，仍没有一项账簿记录能够单独证实它。"
	)


func _resolve_collapse_90_front(current_state: RunState) -> Variant:
	if not _crossed_collapse_threshold(current_state, 90):
		return null
	return _newspaper_front(
		"九成危言同指一处　已经没有时间了",
		"崩溃预期越过九成，会同几乎无人再讨论危机是否会来，只争论它将在何时到来。越是缺少确定证据，新的期限、推算和补救方案反而越快出现。"
	)


func _crossed_collapse_threshold(current_state: RunState, percent: int) -> bool:
	if balance == null or balance.max_collapse <= 0:
		return false
	var threshold := ceili(float(balance.max_collapse) * float(percent) / 100.0)
	return _previous_newspaper_collapse < threshold and current_state.collapse_level >= threshold


func _expected_monthly_bill_reductions(bill: ActiveBillState) -> PackedStringArray:
	var totals: Dictionary = {}
	for metric in Metric.all_ids():
		totals[metric] = 0.0
	for active_proposal in bill.proposals:
		if active_proposal == null or active_proposal.proposal == null:
			continue
		var proposal := active_proposal.proposal
		var effect := proposal.get_total_effect()
		var lag := maxi(proposal.lag_months, 1)
		for metric in Metric.all_ids():
			totals[metric] = float(totals[metric]) + float(effect.get_value(metric)) / float(lag)
	var reductions := PackedStringArray()
	for metric in Metric.all_ids():
		var delta := float(totals[metric])
		if delta >= -0.05:
			continue
		reductions.append("%s约%s" % [Metric.display_name(metric), _format_front_number(absf(delta))])
	return reductions


func _format_front_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return "%.1f" % value


func _newspaper_front(title: String, content: String) -> Dictionary:
	return {"title": title, "content": content}
