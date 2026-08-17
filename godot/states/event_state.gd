extends RefCounted
class_name EventState

enum Phase {
	WORSENING,
	PAUSED,
	RELIEVING,
	RESOLVED,
	ERUPTED,
}

var definition: EventDefinition
var baseline: MetricValues
var base_intensity: float = 0.5
var effective_intensity: float = 0.5
var satisfaction_rate: float = 0.0
var relief_streak: int = 0
var crisis_progress: int = 0
var known: bool = false
var published: bool = false
var phase: Phase = Phase.WORSENING
var months_alive: int = 0


func _init(source_definition: EventDefinition = null, source_baseline: MetricValues = null) -> void:
	definition = source_definition
	baseline = MetricValues.new() if source_baseline == null else source_baseline.copy()


func is_active() -> bool:
	return phase != Phase.RESOLVED and phase != Phase.ERUPTED
