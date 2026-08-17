extends RefCounted
class_name InterventionRecordState

var kind: StringName
var month_index: int = 0
var pressure: float = 0.0


func _init(source_kind: StringName = &"", source_month: int = 0, source_pressure: float = 0.0) -> void:
	kind = source_kind
	month_index = source_month
	pressure = source_pressure
