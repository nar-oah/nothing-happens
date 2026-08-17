extends Resource
class_name RaceDefinition

@export var id: StringName
@export var display_name: String
@export_range(0, 999, 1) var minimum_seats: int = 1
@export_range(0, 999, 1) var initial_seats: int = 4
@export_range(0, 999, 1) var maximum_seats: int = 8
@export_range(-1, 999, 1) var fixed_seat_count: int = -1
@export var metric_stances: Array[MetricStanceDefinition] = []
@export var odd_month_stances: Array[MetricStanceDefinition] = []
@export var even_month_stances: Array[MetricStanceDefinition] = []
@export var special_group_id: StringName
@export var local_group_prefix: StringName = &"local"
@export var strike_wage_floor: int = -999999


func get_stances(month: int) -> Array[MetricStanceDefinition]:
	if id != Race.BIYI:
		return metric_stances
	var alternate := odd_month_stances if month % 2 == 1 else even_month_stances
	return metric_stances if alternate.is_empty() else alternate
