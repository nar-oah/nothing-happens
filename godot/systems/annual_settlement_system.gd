extends RefCounted
class_name AnnualSettlementSystem


func settle_year(context: RunContext) -> void:
	var state := context.state
	state.last_annual_proposal_slot_counts = state.annual_proposal_slot_counts.duplicate()
	state.last_annual_source_shares = context.parliament_system.get_annual_source_shares(state)
	if not context.race_system.allocate_annual_seats(context):
		push_error("Failed to allocate annual race seats.")
		return
	if not context.parliament_system.initialize_base_groups(context, context.interest_groups):
		push_error("Failed to reallocate annual interest-group base columns.")
		return
	context.parliament_system.apply_annual_coloring(context)
	context.constitution_system.apply_influence_rules(context)
	context.constitution_system.on_year_settlement(context)
	context.race_system.advance_expectations(state, context.balance)
	state.constitution.revision_available = true
	state.petition_used_this_year = 0
	state.annual_proposal_slot_counts.clear()
	for race in state.races:
		race.archive_annual_results()
	state.year_start_metrics = state.metrics.copy()
