extends ConstitutionEffect
class_name DonationDetectionEffect

@export_range(0.0, 1.0, 0.01) var probability: float = 0.0


func _init() -> void:
	display_name = "政治献金侦查"


func override_donation_detection_probability(_current: float) -> float:
	return probability


func get_description() -> String:
	return "政治献金被发现概率为%s" % _format_percent(probability)
