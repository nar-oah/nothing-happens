extends RefCounted
class_name PolicyState

var definition: PolicyDefinition
var triggered: bool = false


func _init(source_definition: PolicyDefinition) -> void:
	definition = source_definition
