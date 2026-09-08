extends RefCounted
class_name PolicyState

var definition: PolicyDefinition
var delay_months: int = 0
var elapsed_months: int = 0
var triggered: bool = false


func _init(source_definition: PolicyDefinition = null, source_delay_months: int = 0) -> void:
	definition = source_definition
	delay_months = source_delay_months


func copy() -> PolicyState:
	var result := PolicyState.new(definition, delay_months)
	result.elapsed_months = elapsed_months
	result.triggered = triggered
	return result
