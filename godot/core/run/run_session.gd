extends Node
class_name RunSession

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
var political_trust_system: PoliticalTrustSystem
var draft_bill_system: DraftBillSystem
var vote_system: VoteSystem
var event_system: EventSystem
var constitution_system: ConstitutionSystem
var collapse_system: CollapseSystem
var annual_settlement_system: AnnualSettlementSystem
var flow_controller: FlowController
var race_definitions: Array[RaceDefinition] = []
var interest_groups: Array[InterestGroupDefinition] = []
var event_definitions: Array[EventDefinition] = []
var constitution_articles: Array[ConstitutionArticleDefinition] = []
var automatic_draw_count: int = 3


func configure_content(
	races: Array[RaceDefinition],
	groups: Array[InterestGroupDefinition],
	events: Array[EventDefinition] = [],
	articles: Array[ConstitutionArticleDefinition] = []
) -> void:
	race_definitions = races
	interest_groups = groups
	event_definitions = events
	constitution_articles = articles


func start_new_run() -> void:
	state = RunState.new()
	time_system = TimeSystem.new()
	random_system = RandomSystem.new()
	random_system.set_seed(12345)
	proposal_system = ProposalSystem.new()
	market_system = MarketSystem.new()
	policy_system = PolicySystem.new()
	inflation_system = InflationSystem.new()
	parliament_system = ParliamentSystem.new()
	race_system = RaceSystem.new()
	political_trust_system = PoliticalTrustSystem.new()
	draft_bill_system = DraftBillSystem.new()
	vote_system = VoteSystem.new()
	event_system = EventSystem.new()
	constitution_system = ConstitutionSystem.new()
	collapse_system = CollapseSystem.new()
	annual_settlement_system = AnnualSettlementSystem.new()

	context = RunContext.new()
	context.setup(
		state,
		time_system,
		random_system,
		proposal_system,
		market_system,
		policy_system,
		inflation_system,
		parliament_system,
		race_system,
		political_trust_system,
		draft_bill_system,
		vote_system,
		event_system,
		constitution_system,
		collapse_system,
		annual_settlement_system
	)
	context.race_definitions = race_definitions
	context.interest_groups = interest_groups
	context.event_definitions = event_definitions
	context.constitution_articles = constitution_articles
	context.automatic_draw_count = automatic_draw_count
	constitution_system.initialize(state, constitution_articles)
	race_system.initialize_races(state, race_definitions)
	race_system.recalculate_all_seat_counts(state)
	constitution_system.apply_annual_seat_corrections(state)
	var groups := constitution_system.get_effective_groups(state, interest_groups)
	parliament_system.rebuild_all_rows(state, groups)
	constitution_system.apply_special_fixed_relations(state)
	constitution_system.update_petition_count(state)

	flow_controller = FlowController.new()
	flow_controller.setup(context)

	print("Run started.")
	print_current_date()


func advance_month() -> void:
	flow_controller.advance_month()
	print_current_date()


func print_current_date() -> void:
	print("Year: ", state.year, ", Month: ", state.month)


func enact_bill(draft: DraftBillState) -> void:
	flow_controller.enact_bill(draft)


func submit_draft() -> VoteResultState:
	return flow_controller.submit_draft(state.draft_bill)


func revise_constitution(article: ConstitutionArticleDefinition) -> bool:
	return constitution_system.revise(context, article)
