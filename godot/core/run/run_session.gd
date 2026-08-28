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
var _last_awarded_term: int = 0


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
	return true


func advance_month() -> bool:
	var advanced := flow_controller.advance_month()
	if advanced and state.run_phase == RunState.RunPhase.TERM_ENDED and _last_awarded_term != state.term:
		meta_progression.add_governing_months(state.governing_months)
		_last_awarded_term = state.term
	return advanced


func start_next_term() -> bool:
	if state == null or state.run_phase != RunState.RunPhase.TERM_ENDED:
		return false
	return _start_term(state.term + 1)


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
