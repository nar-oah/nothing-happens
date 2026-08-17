extends Resource
class_name EventDefinition

@export var id: StringName
@export var display_name: String
@export var race_id: StringName
@export var requirements: Array[EventRequirementDefinition] = []
@export_range(0.0, 1.0, 0.01) var monthly_spawn_chance: float = 0.03
@export_range(0.0, 1.0, 0.01) var local_issue_chance: float = 0.0
@export_range(0.0, 1.0, 0.01) var worsening_per_month: float = 0.1
@export_range(0.0, 1.0, 0.01) var relief_per_month: float = 0.05
@export_range(0.0, 1.0, 0.01) var relief_streak_bonus: float = 0.01
@export_range(0.0, 1.0, 0.01) var overfulfillment_bonus: float = 0.03
@export_range(1, 12, 1) var crisis_months: int = 3
@export var trust_on_resolve: float = 8.0
@export var trust_on_erupt: float = -12.0
@export var collapse_on_resolve: float = -4.0
@export var collapse_on_erupt: float = 12.0
