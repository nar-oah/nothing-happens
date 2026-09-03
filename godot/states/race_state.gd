extends RefCounted
class_name RaceState

# definition is the canonical identity used by seats, conditions and event ownership.
var definition: RaceDefinition
# active_definition is the current institutional variant used for behavior and presentation.
var active_definition: RaceDefinition
var expectation_targets: Dictionary[int, int] = {}
var resolved_events_this_year: int = 0
var last_year_resolved_events: int = 0


func _init(source_definition: RaceDefinition = null) -> void:
	definition = source_definition
	active_definition = source_definition


func get_expectation(metric: Metric.Id, fallback: int = 0) -> int:
	return expectation_targets.get(metric, fallback)


func archive_annual_results() -> void:
	last_year_resolved_events = resolved_events_this_year
	resolved_events_this_year = 0
