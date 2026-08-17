extends RefCounted
class_name AnnualSettlementSystem


func settle_year(context: RunContext) -> void:
	context.political_trust_system.settle_annual_trust(context.state)
	context.race_system.recalculate_all_seat_counts(context.state)
	context.constitution_system.apply_annual_seat_corrections(context.state)
	var groups := context.constitution_system.get_effective_groups(
		context.state, context.interest_groups
	)
	context.parliament_system.rebuild_all_rows(context.state, groups)
	context.parliament_system.apply_annual_coloring(
		context.state, groups, context.random_system
	)
	context.constitution_system.apply_annual_influence_rules(context)
	context.state.constitution.revision_available = true
	context.race_system.advance_era_expectations(context.state)
	context.state.annual_proposal_slot_counts.clear()
	for race in context.state.races:
		race.reset_annual_results()
