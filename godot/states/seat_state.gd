extends RefCounted
class_name SeatState

var seat_id: int = -1
var race_id: StringName
var base_group_id: StringName
var actual_group_id: StringName
var personal_relation: float = 0.0
var odd_month_relation: float = 0.0
var even_month_relation: float = 0.0
var influence_priority: int = 5


func _init(
	new_seat_id: int = -1,
	new_race_id: StringName = &"",
	new_base_group_id: StringName = &"",
	new_actual_group_id: StringName = &""
) -> void:
	seat_id = new_seat_id
	race_id = new_race_id
	base_group_id = new_base_group_id
	actual_group_id = new_actual_group_id
