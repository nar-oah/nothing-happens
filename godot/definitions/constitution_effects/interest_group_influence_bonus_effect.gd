extends ConstitutionEffect
class_name InterestGroupInfluenceBonusEffect

@export var interest_group: InterestGroupDefinition
@export var races: Array[RaceDefinition] = []
@export_range(-1.0, 1.0, 0.01) var bonus_rate: float = 0.0


func _init() -> void:
	display_name = "利益集团影响"
	timing = Timing.AFTER_GROUP_ALLOCATION


func apply(context: RunContext) -> void:
	if context != null and context.parliament_system != null:
		context.parliament_system.apply_influence_bonus(context, self)


func applies_to(race: RaceDefinition) -> bool:
	return _matches_race(races, race)


func get_description() -> String:
	var group_name := "" if interest_group == null else interest_group.display_name
	return "%s对%s的额外影响比例%s" % [group_name, _format_races(races), _format_signed_percent(bonus_rate)]
