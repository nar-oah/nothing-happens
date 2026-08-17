extends RefCounted
class_name AnnualSettlementSystem


func settle_year(context: RunContext) -> void:
	context.state.last_annual_proposal_slot_counts = (
		context.state.annual_proposal_slot_counts.duplicate()
	)
	context.state.last_annual_source_shares = context.parliament_system.get_annual_source_shares(
		context.state
	)
	context.political_trust_system.settle_annual_trust(context.state)
	if not context.race_system.allocate_seats(
		context.state, context.balance, context.constitution_system, context.random_system
	):
		push_error("Failed to allocate annual race seats.")
		return
	var groups := context.constitution_system.get_effective_groups(
		context.state, context.interest_groups
	)
	context.parliament_system.rebuild_all_rows(context.state, groups)
	context.parliament_system.apply_annual_coloring(context.state, groups, context.random_system)
	context.constitution_system.apply_annual_influence_rules(context)
	context.state.constitution.revision_available = true
	context.race_system.advance_era_expectations(context.state)
	context.state.annual_proposal_slot_counts.clear()
	for race in context.state.races:
		race.archive_annual_results()
