extends RefCounted
class_name RunState

var year: int = 1
var month: int = 1
var metrics: MetricValues
var active_bill: ActiveBillState
var proposal_hand: Array[ProposalInstance] = []
var draft_bill: DraftBillState
var seats: Array[SeatState] = []
var races: Array[RaceState] = []
var events: Array[EventState] = []
var constitution: ConstitutionState
var annual_proposal_slot_counts: Dictionary[StringName, int] = {}
var vote_donations: Dictionary[int, float] = {}
var intervention_records: Array[InterventionRecordState] = []
var collapse_level: float = 0.0
var regulation_pressure: float = 0.0
var pending_collapse_delta: float = 0.0
var has_intervened: bool = false
var silent_observation: bool = false
var run_failed: bool = false
var ending_id: StringName


func _init() -> void:
	metrics = MetricValues.new()
	draft_bill = DraftBillState.new()
	constitution = ConstitutionState.new()


func get_race(race_id: StringName) -> RaceState:
	for race in races:
		if race.get_id() == race_id:
			return race
	return null


func absolute_month() -> int:
	return (year - 1) * 12 + month - 1
