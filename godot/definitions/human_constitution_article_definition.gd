extends ConstitutionArticleDefinition
class_name HumanConstitutionArticleDefinition

@export_range(0, 999, 1) var petition_limit: int = 0


func apply_runtime(context) -> void:
	super.apply_runtime(context)
	context.state.petition_race = race
	context.state.petition_limit = petition_limit
