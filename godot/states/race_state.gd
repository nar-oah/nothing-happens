extends RefCounted
class_name RaceState

var definition: RaceDefinition
var political_trust: float = 50.0
var seat_count: int = 0
var expectation_targets: Dictionary[int, int] = {}
var pending_trust_delta: float = 0.0
var expectation_gap_months: Dictionary[int, int] = {}
var resolved_events_this_year: int = 0
var erupted_events_this_year: int = 0
var promises_kept_this_year: int = 0
var promises_broken_this_year: int = 0


func _init(source_definition: RaceDefinition = null, year: int = 1) -> void:
	definition = source_definition
	if definition == null:
		return
	political_trust = definition.initial_political_trust
	seat_count = definition.fixed_seat_count if definition.fixed_seat_count >= 0 else definition.initial_seats
	for stance in definition.metric_stances:
		if stance != null and stance.direction != MetricStanceDefinition.Direction.NONE:
			expectation_targets[stance.metric] = stance.target_for_year(year)


func get_id() -> StringName:
	return &"" if definition == null else definition.id


func get_expectation(metric: Metric.Id, fallback: int = 0) -> int:
	return expectation_targets.get(metric, fallback)


func reset_annual_results() -> void:
	resolved_events_this_year = 0
	erupted_events_this_year = 0
	promises_kept_this_year = 0
	promises_broken_this_year = 0
