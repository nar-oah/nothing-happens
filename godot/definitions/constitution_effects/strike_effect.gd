extends ConstitutionEffect
class_name StrikeEffect

@export var interest_group: InterestGroupDefinition
@export var races: Array[RaceDefinition] = []
@export var metric: Metric.Id = Metric.Id.EMPLOYMENT


func _init() -> void:
	display_name = "罢工"
	timing = Timing.BEFORE_SUPPORT_CALCULATION


func apply_vote(vote_context: VoteContext) -> void:
	if vote_context == null or vote_context.vote == null or vote_context.seat == null:
		return
	if not _matches_race(races, vote_context.seat.race):
		return
	var context := vote_context.run_context
	if context == null or context.constitution_system == null or vote_context.pure_proposal_target == null:
		return
	var seat_group := context.constitution_system.resolve_group_identity(context, vote_context.seat.actual_group)
	var required_group := context.constitution_system.resolve_group_identity(context, interest_group)
	if required_group == null or seat_group != required_group:
		return
	if vote_context.pure_proposal_target.get_value(metric) >= context.state.year_start_metrics.get_value(metric):
		return
	vote_context.vote.breakdown[&"constitution_strike"] = 1.0
	vote_context.locked_position = SeatVoteState.Position.ABSENT


func get_description() -> String:
	var group_name := "" if interest_group == null else _t(interest_group.display_name)
	return _t("受%s影响的%s在草案使%s低于年初值时缺席表决") % [group_name, _format_races(races), _t(Metric.display_name(metric))]
