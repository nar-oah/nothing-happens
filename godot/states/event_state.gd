extends RefCounted
class_name EventState

enum Phase {
	WORSENING,
	PAUSED,
	RELIEVING,
	RESOLVED,
	FAILED,
}

var race: RaceDefinition
var metric: Metric.Id = Metric.Id.TAX
var baseline_value: int = 0
var full_target: int = 0
var growth_progress: float = 0.0
var satisfaction_rate: float = 0.0
var known: bool = false
var public_window_entered: bool = false
var phase: Phase = Phase.WORSENING
var months_alive: int = 0


func _init(
	source_race: RaceDefinition = null,
	source_metric: Metric.Id = Metric.Id.TAX,
	source_baseline: int = 0,
	source_target: int = 0
) -> void:
	race = source_race
	metric = source_metric
	baseline_value = source_baseline
	full_target = source_target


func is_active() -> bool:
	return phase != Phase.RESOLVED and phase != Phase.FAILED
