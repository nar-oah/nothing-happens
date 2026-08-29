extends Resource
class_name ConstitutionRowDefinition

@export var display_name: String
@export var race: RaceDefinition
@export_range(0, 999, 1) var display_order: int = 0
@export var ignores_column_unlocks: bool = false
@export var free_navigation: bool = false
