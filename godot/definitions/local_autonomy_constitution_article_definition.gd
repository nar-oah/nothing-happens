extends ConstitutionArticleDefinition
class_name LocalAutonomyConstitutionArticleDefinition

@export_range(1, 999, 1) var local_group_base_column_weight: int = 1


func apply_runtime(context) -> void:
	super.apply_runtime(context)
	_apply_local_groups(context)


func on_activate(context) -> void:
	_apply_local_groups(context)


func on_year_settlement(context) -> void:
	_apply_local_groups(context)


func _apply_local_groups(context) -> void:
	for seat_definition in context.seat_definitions:
		if seat_definition == null:
			continue
		if context.state.constitution.local_interest_groups.has(seat_definition):
			continue
		var group := InterestGroupDefinition.new()
		group.display_name = seat_definition.display_name
		group.description = seat_definition.description
		group.base_column_weight = local_group_base_column_weight
		group.decrease_tax = true
		context.state.constitution.local_interest_groups[seat_definition] = group
	for seat in context.state.seats:
		var local: InterestGroupDefinition = (
			context.state.constitution.local_interest_groups.get(seat.definition)
		)
		if local != null:
			seat.actual_group = local
