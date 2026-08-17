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
var flow_controller: FlowController


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

	context = RunContext.new()
	context.setup(
		state,
		time_system,
		random_system,
		proposal_system,
		market_system,
		policy_system,
		inflation_system,
		parliament_system
	)

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
