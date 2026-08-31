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
	var variable_text := "参加" if participates_in_variable_seat_allocation else "不参加"
	var fixed_text := "保留" if fixed_seat_enabled else "取消"
	return "%s%s可变席位分配，%s固定席位" % [_format_races(races), variable_text, fixed_text]
