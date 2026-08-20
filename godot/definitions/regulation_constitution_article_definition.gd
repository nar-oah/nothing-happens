extends ConstitutionArticleDefinition
class_name RegulationConstitutionArticleDefinition

@export_range(0.0, 1.0, 0.01) var donation_detection_probability: float = 0.25
@export_range(0.0, 1.0, 0.01) var event_early_reveal_bonus_probability: float = 0.0


func apply_runtime(context) -> void:
	super.apply_runtime(context)
	context.state.donation_detection_probability = donation_detection_probability
	context.state.event_early_reveal_bonus_probability += event_early_reveal_bonus_probability
