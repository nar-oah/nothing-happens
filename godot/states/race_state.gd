extends RefCounted
class_name RaceState

var definition: RaceDefinition
var political_trust: float = 0.0
var seat_count: int = 0
var expectation_targets: Dictionary[int, int] = {}
var pending_trust_delta: float = 0.0
var expectation_gap_months: Dictionary[int, int] = {}
var resolved_events_this_year: int = 0
var erupted_events_this_year: int = 0
var promises_kept_this_year: int = 0
var promises_broken_this_year: int = 0
var last_year_trust_delta: float = 0.0
var last_year_resolved_events: int = 0
var last_year_erupted_events: int = 0
var last_year_promises_kept: int = 0
var last_year_promises_broken: int = 0


func _init(source_definition: RaceDefinition = null, year: int = 1) -> void:
	definition = source_definition
	if definition == null:
		return
	seat_count = (
		definition.fixed_seat_count
		if definition.fixed_seat_count >= 0
		else definition.initial_seats
	)
	for stance in definition.metric_stances:
		if stance != null and stance.direction != MetricStanceDefinition.Direction.NONE:
			expectation_targets[stance.metric] = stance.target_for_year(year)


func get_id() -> StringName:
	return &"" if definition == null else definition.id


func get_expectation(metric: Metric.Id, fallback: int = 0) -> int:
	return expectation_targets.get(metric, fallback)


func archive_annual_results() -> void:
	last_year_resolved_events = resolved_events_this_year
	last_year_erupted_events = erupted_events_this_year
	last_year_promises_kept = promises_kept_this_year
	last_year_promises_broken = promises_broken_this_year
	resolved_events_this_year = 0
	erupted_events_this_year = 0
	promises_kept_this_year = 0
	promises_broken_this_year = 0
