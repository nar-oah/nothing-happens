extends Resource
class_name InterestGroupDefinition

const STRONG_COLUMN_WEIGHT: int = 6
const STANDARD_COLUMN_WEIGHT: int = 3
const LOCAL_COLUMN_WEIGHT: int = 1

@export var id: StringName
@export var display_name: String
@export_range(1, 999, 1) var base_column_weight: int = STANDARD_COLUMN_WEIGHT
@export var fixed_sort_order: int = 0
@export var proposal_definition: ProposalDefinition
@export var metric_stances: Array[MetricStanceDefinition] = []
@export var base_support_modifier: float = 0.0


func get_stance(metric: Metric.Id) -> int:
	for stance in metric_stances:
		if stance != null and stance.metric == metric:
			return stance.direction
	return MetricStanceDefinition.Direction.NONE
