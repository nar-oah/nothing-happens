extends RefCounted
class_name SeatState

var definition: SeatDefinition
# Runtime copy of SeatDefinition.anchor_race. A non-null value means this physical seat
# is fixed to that race and must never enter ordinary race allocation. Constitution rules
# may revoke the binding for the current term without mutating the shared SeatDefinition.
var fixed_race: RaceDefinition
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
	fixed_race = null if source_definition == null else source_definition.anchor_race
	race = fixed_race if source_race == null and fixed_race != null else source_race
	base_group = source_base_group
	annual_group = source_base_group if source_actual_group == null else source_actual_group
	actual_group = annual_group
