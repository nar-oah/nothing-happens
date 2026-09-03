extends ConstitutionEffect
class_name GovernmentDisplayEffect

@export var parliament_name: String


func _init() -> void:
	display_name = "政府称谓"


func override_parliament_name(current: String) -> String:
	return current if parliament_name.strip_edges().is_empty() else parliament_name


func get_description() -> String:
	return "议会名称改为%s" % parliament_name
