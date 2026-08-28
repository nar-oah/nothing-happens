extends Resource
class_name ConstitutionArticleDefinition

@export var display_name: String
@export var row: ConstitutionRowDefinition
@export var is_terminal: bool = false

# Legacy serialized fields are kept only so existing .tres files remain loadable while
# their topology is migrated to ConstitutionBoardDefinition. Runtime navigation no longer
# reads is_initial or prerequisite.
@export var race: RaceDefinition
@export var is_initial: bool = false
@export var prerequisite: ConstitutionArticleDefinition
@export var seat_condition: ConstitutionSeatCondition
@export var conditions: Array[ConstitutionCondition] = []

@export_group("席位规则")
@export_range(0.0, 1.0, 0.01) var race_min_seat_rate: float = 0.0
@export_range(0.0, 1.0, 0.01) var race_max_seat_rate: float = 1.0
# When false, this race receives zero seats from the ordinary variable-seat pool. Any
# currently active fixed race seats are still kept, so this one rule supports Zhushui,
# Free Trade humans and Limited Yano without race-specific allocation branches.
@export var participates_in_variable_seat_allocation: bool = true
# A constitution may revoke this race's runtime fixed-seat binding. The physical seat is
# not deleted; it simply returns to the ordinary variable pool for the rest of the term.
@export var revoke_fixed_seat: bool = false

@export_group("种族运行参数")
@export_range(-1.0, 1.0, 0.01) var expectation_growth_rate: float = 0.10
@export_range(0.0, 1.0, 0.01) var visit_probability: float = 0.0

@export_group("内容")
@export var policies: Array[PolicyDefinition] = []
@export var group_biases: Array[ConstitutionGroupBiasDefinition] = []
@export var influence_rules: Array[ConstitutionInfluenceRule] = []


func get_race() -> RaceDefinition:
	if row != null and row.race != null:
		return row.race
	return race


func can_activate(context: RunContext) -> bool:
	for condition in conditions:
		if condition != null and not condition.is_met(context):
			return false
	return seat_condition == null or seat_condition.is_met(context)


func apply_runtime(context: RunContext) -> void:
	var target_race := get_race()
	if target_race == null:
		return
	var race_state := context.state.get_race(target_race)
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
