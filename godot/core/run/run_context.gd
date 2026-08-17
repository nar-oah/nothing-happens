extends RefCounted
class_name RunContext

var state: RunState
var balance: GameBalanceDefinition
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
var race_definitions: Array[RaceDefinition] = []
var interest_groups: Array[InterestGroupDefinition] = []
var event_definitions: Array[EventDefinition] = []
var constitution_articles: Array[ConstitutionArticleDefinition] = []
var automatic_draw_count: int = 3


func setup(
	run_state: RunState,
	run_balance: GameBalanceDefinition,
	run_time_system: TimeSystem,
	run_random_system: RandomSystem,
	run_proposal_system: ProposalSystem,
	run_market_system: MarketSystem,
	run_policy_system: PolicySystem,
	run_inflation_system: InflationSystem,
	run_parliament_system: ParliamentSystem,
	run_race_system: RaceSystem,
	run_political_trust_system: PoliticalTrustSystem,
	run_draft_bill_system: DraftBillSystem,
	run_vote_system: VoteSystem,
	run_event_system: EventSystem,
	run_constitution_system: ConstitutionSystem,
	run_collapse_system: CollapseSystem,
	run_annual_settlement_system: AnnualSettlementSystem
) -> void:
	state = run_state
	balance = run_balance
	time_system = run_time_system
	random_system = run_random_system
	proposal_system = run_proposal_system
	market_system = run_market_system
	policy_system = run_policy_system
	inflation_system = run_inflation_system
	parliament_system = run_parliament_system
	race_system = run_race_system
	political_trust_system = run_political_trust_system
	draft_bill_system = run_draft_bill_system
	vote_system = run_vote_system
	event_system = run_event_system
	constitution_system = run_constitution_system
	collapse_system = run_collapse_system
	annual_settlement_system = run_annual_settlement_system
