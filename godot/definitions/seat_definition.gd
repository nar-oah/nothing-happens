extends Resource
class_name SeatDefinition

@export var display_name: String
@export_multiline var description: String
# Permanent binding: non-null seats never enter ordinary race reallocation.
@export var fixed_race: RaceDefinition
