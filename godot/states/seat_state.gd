extends RefCounted
class_name SeatState

var definition: SeatDefinition
# Runtime permanent binding. Constitution rules may revoke this for the current term
# without mutating the shared SeatDefinition.
var fixed_race: RaceDefinition
var race: RaceDefinition
var base_group: InterestGroupDefinition
var annual_group: InterestGroupDefinition
var actual_group: InterestGroupDefinition


func _init(
	source_definition: SeatDefinition = null,
	source_race: RaceDefinition = null,
	source_base_group: InterestGroupDefinition = null,
	source_actual_group: InterestGroupDefinition = null
) -> void:
	definition = source_definition
	fixed_race = null if source_definition == null else source_definition.fixed_race
	if source_race != null:
		race = source_race
	else:
		race = fixed_race
	base_group = source_base_group
	annual_group = source_base_group if source_actual_group == null else source_actual_group
	actual_group = annual_group


func is_fixed_seat() -> bool:
	return fixed_race != null
