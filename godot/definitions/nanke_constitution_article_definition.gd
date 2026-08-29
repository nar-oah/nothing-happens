extends ConstitutionArticleDefinition
class_name NankeConstitutionArticleDefinition

@export_range(0.0, 1.0, 0.01) var absence_probability: float = 0.15
@export var strike_enabled: bool = false
@export var strike_group: InterestGroupDefinition
@export var strike_extends_to_group: bool = false


func apply_runtime(context) -> void:
	super.apply_runtime(context)
	var target_race := get_race()
	if target_race == null:
		return
	var race_state = context.state.get_race(target_race)
	if race_state == null:
		return
	race_state.absence_probability = absence_probability
	race_state.strike_enabled = strike_enabled
	race_state.strike_group = strike_group
	race_state.strike_extends_to_group = strike_extends_to_group


func modify_vote(vote_context) -> void:
	if vote_context == null or vote_context.vote == null or vote_context.seat == null or vote_context.projected_metrics == null:
		return
	var target_race := get_race()
	if target_race == null:
		return
	var nanke_state = vote_context.run_context.state.get_race(target_race)
	if nanke_state == null or not nanke_state.strike_enabled:
		return
	if nanke_state.strike_group == null or vote_context.seat.actual_group != nanke_state.strike_group:
		return
	if not nanke_state.strike_extends_to_group and vote_context.seat.race != target_race:
		return
	var projected_production: int = vote_context.projected_metrics.get_value(Metric.Id.PRODUCTION)
	var year_start_production: int = vote_context.run_context.state.year_start_metrics.get_value(Metric.Id.PRODUCTION)
	if projected_production >= year_start_production:
		return
	vote_context.vote.breakdown[&"nanke_strike"] = 1.0
	vote_context.position_override = SeatVoteState.Position.OPPOSE
