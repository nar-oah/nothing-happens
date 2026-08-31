extends ConstitutionEffect
class_name InterestGroupVoteModifierEffect

@export var interest_groups: Array[InterestGroupDefinition] = []
@export var support_modifier: float = 0.0


func _init() -> void:
	timing = Timing.BEFORE_SUPPORT_CALCULATION


func get_description() -> String:
	return "受%s影响的席位支持度%s" % [_format_groups(interest_groups), _format_signed_number(support_modifier)]
