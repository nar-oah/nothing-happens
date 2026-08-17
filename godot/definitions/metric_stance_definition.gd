extends Resource
class_name MetricStanceDefinition

enum Direction {
	LOWER = -1,
	NONE = 0,
	HIGHER = 1,
}

@export var metric: Metric.Id = Metric.Id.TAX
@export var direction: Direction = Direction.NONE
