extends Resource
class_name SeatDefinition

@export var display_name: String
# Historical field name retained for serialized resources. Semantically this is a fixed
# race binding, not a preference: the seat is removed from ordinary race allocation and
# always belongs to this race unless a constitution explicitly revokes the runtime binding.
@export var anchor_race: RaceDefinition
