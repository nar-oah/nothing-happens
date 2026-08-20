extends RefCounted
class_name RaceState

var definition: RaceDefinition
var expectation_targets: Dictionary[int, int] = {}
var expectation_growth_rate: float = 0.0
var visit_probability: float = 0.0
var resolved_events_this_year: int = 0
var last_year_resolved_events: int = 0
var absence_probability: float = 0.0
var yin_active: bool = true
var yin_yang_adjustment_rate: float = 0.0
var strike_enabled: bool = false
var strike_group: InterestGroupDefinition
var strike_extends_to_group: bool = false


func _init(source_definition: RaceDefinition = null) -> void:
	definition = source_definition


func get_expectation(metric: Metric.Id, fallback: int = 0) -> int:
	return expectation_targets.get(metric, fallback)


func archive_annual_results() -> void:
	last_year_resolved_events = resolved_events_this_year
	resolved_events_this_year = 0
