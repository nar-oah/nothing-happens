extends RefCounted
class_name SeatState

var definition: SeatDefinition
var race: RaceDefinition
var base_group: InterestGroupDefinition
var annual_group: InterestGroupDefinition
var actual_group: InterestGroupDefinition
var personal_relation: float = 0.0
var odd_month_relation: float = 0.0
var even_month_relation: float = 0.0


func _init(
	source_definition: SeatDefinition = null,
	source_race: RaceDefinition = null,
	source_base_group: InterestGroupDefinition = null,
	source_actual_group: InterestGroupDefinition = null
) -> void:
	definition = source_definition
	race = source_race
	base_group = source_base_group
	annual_group = source_base_group if source_actual_group == null else source_actual_group
	actual_group = annual_group
