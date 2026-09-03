extends ConstitutionEffect
class_name GroupMergeEffect

@export var target_group: InterestGroupDefinition
@export_range(0.0, 1.0, 0.01) var threshold: float = 0.05


func _init() -> void:
	display_name = "利益集团合并"
	timing = Timing.ON_ACTIVATE


func apply(context: RunContext) -> void:
	if context != null and context.constitution_system != null:
		context.constitution_system.merge_groups_below_threshold(context, target_group, threshold)


func get_description() -> String:
	var target_name := "" if target_group == null else target_group.display_name
	return "将影响率低于%s的利益集团并入%s" % [_format_percent(threshold), target_name]
