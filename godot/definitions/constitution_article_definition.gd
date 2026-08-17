extends Resource
class_name ConstitutionArticleDefinition

enum ThresholdKind {
	NONE,
	RACE_SEAT_RATE,
	GROUP_INFLUENCE_RATE,
}

@export var id: StringName
@export var display_name: String
@export var axis_id: StringName
@export var direction: int = 0
@export_range(0, 3, 1) var level: int = 0
@export var is_initial: bool = false
@export var is_terminal: bool = false
@export var is_regulation: bool = false
@export var prerequisite_id: StringName
@export var threshold_kind: ThresholdKind = ThresholdKind.NONE
@export var threshold_target_id: StringName
@export_range(0.0, 1.0, 0.01) var threshold_rate: float = 0.0
@export var flags: Array[StringName] = []
@export var support_race_id: StringName
@export var base_support_modifier: float = 0.0
@export var influence_rules: Array[ConstitutionInfluenceRule] = []
@export var unlocked_policies: Array[PolicyDefinition] = []
