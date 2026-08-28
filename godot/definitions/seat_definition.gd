extends Resource
class_name SeatDefinition

@export var display_name: String
@export_multiline var description: String
# Opening anchor: this seat starts the term assigned to the race, but remains part of the
# ordinary variable-seat pool unless fixed_race is also set.
@export var anchor_race: RaceDefinition
# Permanent binding: non-null seats never enter ordinary race reallocation. In the formal
# opening content this is used only by the Zhushui executive seat.
@export var fixed_race: RaceDefinition
