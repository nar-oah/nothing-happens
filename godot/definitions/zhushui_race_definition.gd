extends RaceDefinition
class_name ZhushuiRaceDefinition


func modify_vote(vote_context) -> void:
	if vote_context == null or vote_context.vote == null:
		return
	vote_context.vote.breakdown[&"zhushui_intrinsic_support"] = 1.0
	vote_context.locked_position = SeatVoteState.Position.SUPPORT
