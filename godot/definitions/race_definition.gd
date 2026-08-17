extends Resource
class_name RaceDefinition

enum SpecialMechanism {
	NONE,
	ZHUSHUI,
	NANKE,
	BIYI,
	YANO,
	PEACH_BLOSSOM,
	HUMAN,
}

@export var id: StringName
@export var display_name: String
@export var special_mechanism: SpecialMechanism = SpecialMechanism.NONE
@export_range(0.0, 100.0, 0.5) var initial_political_trust: float = 50.0
@export_range(0, 999, 1) var minimum_seats: int = 1
@export_range(0, 999, 1) var initial_seats: int = 4
@export_range(0, 999, 1) var maximum_seats: int = 8
@export_range(-1, 999, 1) var fixed_seat_count: int = -1
@export var metric_stances: Array[MetricStanceDefinition] = []
@export var odd_month_stances: Array[MetricStanceDefinition] = []
@export var even_month_stances: Array[MetricStanceDefinition] = []
@export var special_group_id: StringName
@export var local_group_prefix: StringName = &"local"
@export_range(0.0, 1.0, 0.01) var normal_absence_probability: float = 0.15
@export_range(0.0, 1.0, 0.01) var protected_absence_probability: float = 0.03
@export var strike_wage_floor: int = -999999


func get_stances(month: int) -> Array[MetricStanceDefinition]:
	if special_mechanism != SpecialMechanism.BIYI:
		return metric_stances
	var alternate := odd_month_stances if month % 2 == 1 else even_month_stances
	return metric_stances if alternate.is_empty() else alternate
