extends RaceDefinition
class_name NankeRaceDefinition

@export_range(0.0, 1.0, 0.01) var absence_probability: float = 0.15


func modify_vote(vote_context) -> void:
	if (
		vote_context == null
		or vote_context.vote == null
		or vote_context.seat == null
		or not vote_context.seat.absent_this_month
	):
		return
	vote_context.vote.breakdown[&"nanke_asleep"] = 1.0
	vote_context.locked_position = SeatVoteState.Position.ABSENT
