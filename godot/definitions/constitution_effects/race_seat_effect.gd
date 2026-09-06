extends ConstitutionEffect
class_name RaceSeatEffect

@export var races: Array[RaceDefinition] = []
@export var participates_in_variable_seat_allocation: bool = true
@export var fixed_seat_enabled: bool = true


func _init() -> void:
	display_name = "种族席位"
	timing = Timing.BEFORE_SEAT_ALLOCATION


func apply(context: RunContext) -> void:
	if context != null and context.parliament_system != null:
		context.parliament_system.apply_race_seat_effect(context, self)


func applies_to(race: RaceDefinition) -> bool:
	return _matches_race(races, race)


func get_description() -> String:
	var template: String
	if participates_in_variable_seat_allocation:
		template = "%s参加可变席位分配，保留固定席位" if fixed_seat_enabled else "%s参加可变席位分配，取消固定席位"
	else:
		template = "%s不参加可变席位分配，保留固定席位" if fixed_seat_enabled else "%s不参加可变席位分配，取消固定席位"
	return _t(template) % _format_races(races)
