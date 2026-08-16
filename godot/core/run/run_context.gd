extends RefCounted
class_name RunContext

var state: RunState
var time_system: TimeSystem
var random_system: RandomSystem
var proposal_system: ProposalSystem
var market_system: MarketSystem
var policy_system: PolicySystem


func setup(
	run_state: RunState,
	run_time_system: TimeSystem,
	run_random_system: RandomSystem,
	run_proposal_system: ProposalSystem,
	run_market_system: MarketSystem,
	run_policy_system: PolicySystem
) -> void:
	state = run_state
	time_system = run_time_system
	random_system = run_random_system
	proposal_system = run_proposal_system
	market_system = run_market_system
	policy_system = run_policy_system
