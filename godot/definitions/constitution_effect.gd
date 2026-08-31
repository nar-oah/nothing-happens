extends Resource
class_name ConstitutionEffect

enum Timing {
	RUNTIME_REBUILD,
	ON_ACTIVATE,
	BEFORE_SEAT_ALLOCATION,
	AFTER_SEAT_ALLOCATION,
	AFTER_GROUP_ALLOCATION,
	BEFORE_DRAFT_SUBMIT,
	BEFORE_SUPPORT_CALCULATION,
}

@export var display_name: String
@export var timing: Timing = Timing.RUNTIME_REBUILD


func apply(_context: RunContext) -> void:
	pass


func get_description() -> String:
	return ""


func _format_races(races: Array[RaceDefinition]) -> String:
	var names := PackedStringArray()
	for race in races:
		if race != null:
			names.append(race.display_name)
	return "、".join(names)


func _format_groups(groups: Array[InterestGroupDefinition]) -> String:
	var names := PackedStringArray()
	for group in groups:
		if group != null:
			names.append(group.display_name)
	return "、".join(names)


func _format_metrics(metrics: Array[Metric.Id]) -> String:
	var names := PackedStringArray()
	for metric in metrics:
		names.append(Metric.display_name(metric))
	return "、".join(names)


func _format_percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)


func _format_signed_percent(value: float) -> String:
	var percent := roundi(value * 100.0)
	return "%+d%%" % percent


func _format_signed_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%+d" % roundi(value)
	return "%+.2f" % value
