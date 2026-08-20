extends RefCounted
class_name RaceSeatConstraint

var minimum_count: int = 0
var maximum_count: int = -1


func _init(minimum: int = 0, maximum: int = -1) -> void:
	minimum_count = minimum
	maximum_count = maximum
