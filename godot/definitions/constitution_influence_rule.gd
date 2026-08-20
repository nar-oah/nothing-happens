extends Resource
class_name ConstitutionInfluenceRule

enum Mode {
	MINIMUM,
	MAXIMUM,
	TARGET,
}

@export var race: RaceDefinition
@export var interest_group: InterestGroupDefinition
@export var mode: Mode = Mode.TARGET
@export_range(0.0, 1.0, 0.01) var rate: float = 0.0
