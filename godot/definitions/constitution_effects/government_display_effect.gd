extends ConstitutionEffect
class_name GovernmentDisplayEffect

@export var parliament_name: String


func get_description() -> String:
	return "议会名称改为%s" % parliament_name
