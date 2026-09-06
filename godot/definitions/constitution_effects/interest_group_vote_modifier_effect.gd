extends ConstitutionEffect
class_name InterestGroupVoteModifierEffect

@export var interest_groups: Array[InterestGroupDefinition] = []
@export var support_modifier: float = 0.0


func _init() -> void:
	display_name = "利益集团投票修正"
	timing = Timing.BEFORE_SUPPORT_CALCULATION


func apply_vote(vote_context: VoteContext) -> void:
	if vote_context == null or vote_context.vote == null or vote_context.seat == null:
		return
	var context := vote_context.run_context
	if context == null or context.constitution_system == null:
		return
	var group := context.constitution_system.resolve_group_identity(context, vote_context.seat.actual_group)
	var matched := false
	for candidate in interest_groups:
		if context.constitution_system.resolve_group_identity(context, candidate) == group:
			matched = true
			break
	if interest_groups.is_empty():
		matched = group != null
	if matched and not is_zero_approx(support_modifier):
		vote_context.vote.add_reason(&"constitution_group_modifier", support_modifier)


func get_description() -> String:
	return _t("受%s影响的席位支持度%s") % [_format_groups(interest_groups), _format_signed_number(support_modifier)]
