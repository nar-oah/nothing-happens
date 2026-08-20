extends ConstitutionArticleDefinition
class_name BiyiConstitutionArticleDefinition

@export_range(0.0, 1.0, 0.01) var yin_yang_adjustment_rate: float = 0.0


func apply_runtime(context) -> void:
	super.apply_runtime(context)
	if race == null:
		return
	var race_state = context.state.get_race(race)
	if race_state != null:
		race_state.yin_yang_adjustment_rate = yin_yang_adjustment_rate
