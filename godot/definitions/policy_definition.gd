extends Resource
class_name PolicyDefinition

@export var id: StringName
@export var display_name: String
@export var condition: MetricCondition
@export var effects: Array[PolicyEffect] = []
@export var collapse_impact: float = 0.0
