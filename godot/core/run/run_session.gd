extends Node
class_name RunSession

@export_group("配置")
@export var balance: GameBalanceDefinition

@export_group("游戏内容")
@export var race_definitions: Array[RaceDefinition] = []
@export var interest_groups: Array[InterestGroupDefinition] = []
@export var seat_definitions: Array[SeatDefinition] = []
@export var constitution_articles: Array[ConstitutionArticleDefinition] = []

var state: RunState
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


func configure_content(
	races: Array[RaceDefinition],
	groups: Array[InterestGroupDefinition],
	seats: Array[SeatDefinition],
	articles: Array[ConstitutionArticleDefinition] = []
) -> void:
	race_definitions = races
	interest_groups = groups
	seat_definitions = seats
	constitution_articles = articles


func start_new_run() -> void:
	if balance == null:
		push_error("RunSession requires GameBalanceDefinition.")
		return
	if race_definitions.is_empty():
		push_error("RunSession requires race definitions.")
		return
	if interest_groups.is_empty():
		push_error("RunSession requires interest group definitions.")
		return
	if seat_definitions.is_empty():
		push_error("RunSession requires seat definitions.")
		return
	state = RunState.new()
	time_system = TimeSystem.new()
	random_system = RandomSystem.new()
	proposal_system = ProposalSystem.new()
	market_system = MarketSystem.new()
	policy_system = PolicySystem.new()
	inflation_system = InflationSystem.new()
	inflation_system.initialize_metrics(state.metrics, balance)
	state.year_start_metrics = (state.metrics.copy())

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
	context.constitution_articles = constitution_articles
	if not race_system.initialize_races(state, race_definitions, balance):
		return
	if not parliament_system.initialize_seats(state, seat_definitions, race_definitions):
		return
	if not constitution_system.initialize(context):
		return
	if not race_system.allocate_seats(context):
		push_error("Failed to allocate initial race seats.")
		return
	if not parliament_system.initialize_base_groups(state, interest_groups):
		return
	constitution_system.apply_influence_rules(context)
	constitution_system.activate_initial_articles(context)

	flow_controller = FlowController.new()
	flow_controller.setup(context)


func advance_month() -> void:
	flow_controller.advance_month()


func enact_bill(draft: DraftBillState) -> void:
	flow_controller.enact_bill(draft)


func submit_draft() -> VoteResultState:
	return flow_controller.submit_draft(state.draft_bill)


func revise_constitution(article: ConstitutionArticleDefinition) -> bool:
	return constitution_system.revise(context, article)


func use_petition() -> bool:
	return parliament_system.use_petition(context)


func accept_proposal_trait(proposal: ProposalInstance) -> bool:
	return proposal_system.resolve_bonus_choice(state, proposal, true)


func convert_proposal_trait_to_donation(proposal: ProposalInstance) -> bool:
	return proposal_system.resolve_bonus_choice(state, proposal, false)
