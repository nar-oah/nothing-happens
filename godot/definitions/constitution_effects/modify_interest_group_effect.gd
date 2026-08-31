extends ConstitutionEffect
class_name ModifyInterestGroupEffect

@export var target_groups: Array[InterestGroupDefinition] = []
@export var source_groups: Array[InterestGroupDefinition] = []


func get_description() -> String:
	return "修改利益集团：%s" % _format_groups(target_groups)
