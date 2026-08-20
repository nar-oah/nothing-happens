extends Resource
class_name ConstitutionArticleDefinition

@export var display_name: String
@export var race: RaceDefinition
@export var is_initial: bool = false
@export var prerequisite: ConstitutionArticleDefinition
@export var seat_condition: ConstitutionSeatCondition

@export_group("席位约束")
@export_range(0.0, 1.0, 0.01) var race_min_seat_rate: float = 0.0
@export_range(0.0, 1.0, 0.01) var race_max_seat_rate: float = 1.0

@export_group("种族运行参数")
@export_range(0.0, 1.0, 0.01) var expectation_growth_rate: float = 0.0
@export_range(0.0, 1.0, 0.01) var visit_probability: float = 0.0

@export_group("内容")
@export var policies: Array[PolicyDefinition] = []
@export var influence_rules: Array[ConstitutionInfluenceRule] = []


func can_activate(context) -> bool:
	if prerequisite != null and not context.state.constitution.was_clicked(prerequisite):
		return false
	return seat_condition == null or seat_condition.is_met(context)


func apply_runtime(context) -> void:
	if race == null:
		return
	var race_state = context.state.get_race(race)
	if race_state == null:
		return
	race_state.expectation_growth_rate = expectation_growth_rate
	race_state.visit_probability = visit_probability


func on_activate(_context) -> void:
	pass


func on_deactivate(_context) -> void:
	pass


func on_month_start(_context) -> void:
	pass


func on_year_settlement(_context) -> void:
	pass


func modify_vote(_vote_context) -> void:
	pass
