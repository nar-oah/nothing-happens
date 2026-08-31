extends RefCounted
class_name VoteContext

var run_context: RunContext
var seat: SeatState
var race_state: RaceState
var draft: DraftBillState
var pure_proposal_target: MetricValues
var projected_metrics: MetricValues
var vote: SeatVoteState
var resolve_randomness: bool = false
var position_override: int = -1
var locked_position: int = -1


func _init(
	source_run_context: RunContext = null,
	source_seat: SeatState = null,
	source_race_state: RaceState = null,
	source_draft: DraftBillState = null,
	source_pure_target: MetricValues = null,
	source_projected: MetricValues = null,
	source_vote: SeatVoteState = null,
	should_resolve_randomness: bool = false
) -> void:
	run_context = source_run_context
	seat = source_seat
	race_state = source_race_state
	draft = source_draft
	pure_proposal_target = source_pure_target
	projected_metrics = source_projected
	vote = source_vote
	resolve_randomness = should_resolve_randomness
