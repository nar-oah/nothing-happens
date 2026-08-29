extends RefCounted
class_name RunState

enum RunPhase {
	RUNNING,
	TERM_ENDED,
}

enum TermOutcome {
	NONE,
	COLLAPSE,
	NOTHING_HAPPENS,
}

const NEW_BILL_INDEX: int = -1

var term: int = 1
var year: int = 1
var month: int = 0
var metrics: MetricValues
var year_start_metrics: MetricValues
var month_report_year: int = 0
var month_report_month: int = 0
var month_report_previous_metrics: MetricValues
var month_report_current_metrics: MetricValues
var month_report_events: Array[Dictionary] = []
var active_bill: ActiveBillState
var proposal_hand: Array[ProposalInstance] = []
var proposal_acquisition_order: Array[ProposalInstance] = []
var draft_bill: DraftBillState
var saved_bills: Array[SavedBillState] = []
var editing_saved_bill_index: int = NEW_BILL_INDEX
var seats: Array[SeatState] = []
var races: Array[RaceState] = []
var events: Array[EventState] = []
var constitution: ConstitutionState
var annual_proposal_slot_counts: Dictionary[InterestGroupDefinition, int] = {}
var last_annual_proposal_slot_counts: Dictionary[InterestGroupDefinition, int] = {}
var last_annual_source_shares: Dictionary[InterestGroupDefinition, float] = {}
var vote_donations: Dictionary[SeatDefinition, float] = {}
var political_donation_pool: float = 0.0
var petition_race: RaceDefinition
var petition_limit: int = 0
var petition_used_this_year: int = 0
var donation_detection_probability: float = 0.0
var event_early_reveal_bonus_probability: float = 0.0
var collapse_level: int = 0
var run_phase: RunPhase = RunPhase.RUNNING
var term_outcome: TermOutcome = TermOutcome.NONE
var governing_months: int = 0


func _init() -> void:
	metrics = MetricValues.new()
	year_start_metrics = MetricValues.new()
	draft_bill = DraftBillState.new()
	constitution = ConstitutionState.new()


func get_race(definition: RaceDefinition) -> RaceState:
	for race in races:
		if race.definition == definition:
			return race
	return null


func add_proposal_to_hand(proposal: ProposalInstance) -> void:
	_track_current_hand_order()
	if proposal not in proposal_acquisition_order:
		proposal_acquisition_order.append(proposal)
	if proposal not in proposal_hand:
		proposal_hand.append(proposal)


func take_proposal_from_hand(hand_index: int) -> ProposalInstance:
	if hand_index < 0 or hand_index >= proposal_hand.size():
		return null
	_track_current_hand_order()
	return proposal_hand.pop_at(hand_index)


func reserve_proposal_from_hand(proposal: ProposalInstance) -> bool:
	_track_current_hand_order()
	var hand_index := proposal_hand.find(proposal)
	if hand_index < 0:
		return false
	proposal_hand.remove_at(hand_index)
	return true


func restore_proposal_to_hand(proposal: ProposalInstance) -> void:
	_track_current_hand_order()
	if proposal in proposal_hand:
		return
	var order_index := proposal_acquisition_order.find(proposal)
	if order_index < 0:
		proposal_acquisition_order.append(proposal)
		proposal_hand.append(proposal)
		return
	for next_index in range(order_index + 1, proposal_acquisition_order.size()):
		var hand_index := proposal_hand.find(proposal_acquisition_order[next_index])
		if hand_index >= 0:
			proposal_hand.insert(hand_index, proposal)
			return
	proposal_hand.append(proposal)


func consume_proposals(proposals: Array[ProposalInstance]) -> void:
	_track_current_hand_order()
	for proposal in proposals:
		proposal_hand.erase(proposal)
		proposal_acquisition_order.erase(proposal)


func _track_current_hand_order() -> void:
	for proposal in proposal_hand:
		if proposal not in proposal_acquisition_order:
			proposal_acquisition_order.append(proposal)
