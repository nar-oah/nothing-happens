extends RefCounted
class_name VoteResultState

var passed: bool = false
var submitted: bool = false
var support_count: int = 0
var oppose_count: int = 0
var abstain_count: int = 0
var absent_count: int = 0
var seat_votes: Array[SeatVoteState] = []


func present_count() -> int:
	return support_count + oppose_count + abstain_count
