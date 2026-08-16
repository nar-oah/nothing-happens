extends RefCounted
class_name FlowController

var context: RunContext


func setup(run_context: RunContext) -> void:
	context = run_context


func advance_month() -> void:
	context.market_system.settle_month(context)
	context.policy_system.resolve_policy_chain(context.state)
	context.time_system.advance_month(context.state)
