extends RefCounted
class_name AnnualSettlementSystem


func settle_year(context: RunContext) -> void:
	var state := context.state
	state.last_annual_proposal_slot_counts = state.annual_proposal_slot_counts.duplicate()
	state.last_annual_source_shares = context.parliament_system.get_annual_source_shares(state)
	context.constitution_system.run_effects(context, ConstitutionEffect.Timing.BEFORE_SEAT_ALLOCATION)
	if not context.race_system.allocate_annual_seats(context):
		push_error("Failed to allocate annual race seats.")
		return
	context.constitution_system.run_effects(context, ConstitutionEffect.Timing.AFTER_SEAT_ALLOCATION)
	if not context.parliament_system.initialize_base_groups(context, context.interest_groups):
		push_error("Failed to reallocate annual interest-group base columns.")
		return
	context.parliament_system.apply_annual_coloring(context)
	context.constitution_system.run_effects(context, ConstitutionEffect.Timing.AFTER_GROUP_ALLOCATION)
	context.collapse_system.recover_annual(context)
	state.year_start_metrics = state.metrics.copy()
	context.race_system.rebuild_annual_expectations(context)
	state.constitution.revision_available = true
	state.petition_used_this_year = 0
	state.annual_proposal_slot_counts.clear()
	for race in state.races:
		race.archive_annual_results()
