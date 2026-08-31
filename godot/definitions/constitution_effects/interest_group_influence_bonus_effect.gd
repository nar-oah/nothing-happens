extends ConstitutionEffect
class_name InterestGroupInfluenceBonusEffect

@export var interest_group: InterestGroupDefinition
@export var races: Array[RaceDefinition] = []
@export_range(-1.0, 1.0, 0.01) var bonus_rate: float = 0.0


func _init() -> void:
	timing = Timing.AFTER_GROUP_ALLOCATION


func get_description() -> String:
	var group_name := "" if interest_group == null else interest_group.display_name
	return "%s对%s的额外影响比例%s" % [group_name, _format_races(races), _format_signed_percent(bonus_rate)]
