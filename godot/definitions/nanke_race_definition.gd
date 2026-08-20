extends RaceDefinition
class_name NankeRaceDefinition


func modify_vote(vote_context) -> void:
	if (
		vote_context == null
		or vote_context.vote == null
		or vote_context.race_state == null
		or not vote_context.resolve_randomness
	):
		return
	var probability: float = vote_context.race_state.absence_probability
	if not vote_context.run_context.random_system.chance(probability):
		return
	vote_context.vote.breakdown[&"nanke_asleep"] = 1.0
	vote_context.position_override = SeatVoteState.Position.ABSENT
