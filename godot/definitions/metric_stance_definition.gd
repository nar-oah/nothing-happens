extends Resource
class_name MetricStanceDefinition

enum Direction {
	LOWER = -1,
	NONE = 0,
	HIGHER = 1,
}

@export var metric: Metric.Id = Metric.Id.TAX
@export var direction: Direction = Direction.NONE
@export var initial_target: int = 0
@export_range(0, 999, 1) var annual_step: int = 0


func target_for_year(year: int) -> int:
	var elapsed_years := maxi(year - 1, 0)
	return initial_target + direction * annual_step * elapsed_years
