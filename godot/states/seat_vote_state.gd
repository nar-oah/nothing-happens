extends RefCounted
class_name SeatVoteState

enum Position {
	ABSENT,
	OPPOSE,
	ABSTAIN,
	SUPPORT,
}

var seat: SeatState
var score: float = 0.0
var position: Position = Position.ABSTAIN
var breakdown: Dictionary[StringName, float] = {}
var vote_weight: int = 1
var race_support_weight: int = 0
var race_present_weight: int = 0


func add_reason(reason: StringName, amount: float) -> void:
	breakdown[reason] = breakdown.get(reason, 0.0) + amount
	score += amount
