extends ConstitutionEffect
class_name ModifyInterestGroupEffect

@export var target_groups: Array[InterestGroupDefinition] = []
@export var source_groups: Array[InterestGroupDefinition] = []


func _init() -> void:
	display_name = "利益集团制度状态"


func apply(context: RunContext) -> void:
	if context == null or context.state == null or context.state.constitution == null:
		return
	var count := mini(target_groups.size(), source_groups.size())
	for index in range(count):
		var target := target_groups[index]
		var source := source_groups[index]
		if target != null and source != null:
			context.state.constitution.group_variants[target] = source


func get_description() -> String:
	return "修改利益集团：%s" % _format_groups(target_groups)
