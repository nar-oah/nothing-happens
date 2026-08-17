extends Resource
class_name ConstitutionInfluenceRule

enum Priority {
	TERMINAL,
	MERGER,
	FIXED,
	LIMIT,
	TARGET,
}

enum Action {
	REMOVE_GROUP,
	MERGE_GROUP,
	LOCALIZE,
	FIX_RACE_TO_GROUP,
	GROUP_MINIMUM,
	GROUP_MAXIMUM,
	GROUP_TARGET,
}

@export var priority: Priority = Priority.FIXED
@export var action: Action = Action.FIX_RACE_TO_GROUP
@export var race_id: StringName
@export var source_group_id: StringName
@export var target_group_id: StringName
@export_range(0.0, 1.0, 0.01) var rate: float = 0.0
@export var local_group_prefix: StringName = &"local"
