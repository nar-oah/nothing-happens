extends RefCounted
class_name EventState

enum RequirementKind {
	METRIC,
	INTEREST_GROUP_PROPOSALS,
}

enum Phase {
	WORSENING,
	PAUSED,
	RELIEVING,
	RESOLVED,
	FAILED,
}

var race: RaceDefinition
var requirement_kind: int = RequirementKind.METRIC
var metric: Metric.Id = Metric.Id.TAX
var interest_group: InterestGroupDefinition
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
	source_target: int = 0,
	source_requirement_kind: int = RequirementKind.METRIC,
	source_interest_group: InterestGroupDefinition = null
) -> void:
	race = source_race
	metric = source_metric
	baseline_value = source_baseline
	full_target = source_target
	requirement_kind = source_requirement_kind
	interest_group = source_interest_group


func is_active() -> bool:
	return phase != Phase.RESOLVED and phase != Phase.FAILED
