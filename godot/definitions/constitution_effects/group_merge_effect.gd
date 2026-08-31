extends ConstitutionEffect
class_name GroupMergeEffect

@export var target_group: InterestGroupDefinition
@export_range(0.0, 1.0, 0.01) var threshold: float = 0.05


func _init() -> void:
	timing = Timing.ON_ACTIVATE


func get_description() -> String:
	var target_name := "" if target_group == null else target_group.display_name
	return "将影响率低于%s的利益集团并入%s" % [_format_percent(threshold), target_name]
