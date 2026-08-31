extends ConstitutionEffect
class_name PetitionEffect

@export var count_races: Array[RaceDefinition] = []
@export var event_races: Array[RaceDefinition] = []
@export_range(0, 999, 1) var fixed_count: int = 0
@export_range(0.0, 1.0, 0.01) var seat_ratio: float = 0.0


func get_description() -> String:
	var count_text := str(fixed_count)
	if seat_ratio > 0.0:
		var race_text := _format_races(count_races)
		var ratio_text := _format_percent(seat_ratio)
		count_text = "%d + ceil(%s席位数 × %s)" % [fixed_count, race_text, ratio_text]
	return "每年可奏请%s次；可处理%s事件" % [count_text, _format_races(event_races)]
