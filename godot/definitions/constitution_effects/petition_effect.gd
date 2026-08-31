extends ConstitutionEffect
class_name PetitionEffect

@export var count_races: Array[RaceDefinition] = []
@export var event_races: Array[RaceDefinition] = []
@export_range(0, 999, 1) var fixed_count: int = 0
@export_range(0.0, 1.0, 0.01) var seat_ratio: float = 0.0


func _init() -> void:
	display_name = "奏请"


func get_petition_count(context: RunContext) -> int:
	if context == null or context.state == null:
		return fixed_count
	var seat_count := 0
	for seat in context.state.seats:
		if seat != null and _matches_race(count_races, seat.race):
			seat_count += 1
	return fixed_count + ceili(float(seat_count) * seat_ratio)


func can_petition_event(race: RaceDefinition) -> bool:
	return _matches_race(event_races, race)


func get_description() -> String:
	var count_text := str(fixed_count)
	if seat_ratio > 0.0:
		count_text = "%d + ceil(%s席位数 × %s)" % [fixed_count, _format_races(count_races), _format_percent(seat_ratio)]
	return "每年可奏请%s次；可处理%s事件" % [count_text, _format_races(event_races)]
