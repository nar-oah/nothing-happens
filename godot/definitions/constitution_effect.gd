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


func apply_vote(_vote_context: VoteContext) -> void:
	pass


func validate_draft(
	_context: RunContext, _draft: DraftBillState, _pure_target: MetricValues
) -> bool:
	return true


func get_expectation_growth_multiplier(_race: RaceDefinition) -> float:
	return 1.0


func get_event_intel_probability_modifier(_race: RaceDefinition) -> float:
	return 0.0


func override_donation_detection_probability(current: float) -> float:
	return current


func override_parliament_name(current: String) -> String:
	return current


func get_petition_count(_context: RunContext) -> int:
	return 0


func can_petition_event(_race: RaceDefinition) -> bool:
	return false


func get_description() -> String:
	return ""


func _matches_race(races: Array[RaceDefinition], race: RaceDefinition) -> bool:
	return race != null and (races.is_empty() or race in races)


func _matches_group(
	groups: Array[InterestGroupDefinition], group: InterestGroupDefinition
) -> bool:
	return group != null and (groups.is_empty() or group in groups)


func _format_races(races: Array[RaceDefinition]) -> String:
	if races.is_empty():
		return _t("全部种族")
	var names := PackedStringArray()
	for race in races:
		if race != null:
			names.append(_t(race.display_name))
	return _t("、").join(names)


func _format_groups(groups: Array[InterestGroupDefinition]) -> String:
	if groups.is_empty():
		return _t("全部利益集团")
	var names := PackedStringArray()
	for group in groups:
		if group != null:
			names.append(_t(group.display_name))
	return _t("、").join(names)


func _format_metrics(metrics: Array[Metric.Id]) -> String:
	var names := PackedStringArray()
	for metric in metrics:
		names.append(_t(Metric.display_name(metric)))
	return _t("、").join(names)


func _format_percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)


func _format_signed_percent(value: float) -> String:
	var percent := roundi(value * 100.0)
	return "%+d%%" % percent


func _format_signed_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%+d" % roundi(value)
	return "%+.2f" % value


func _t(text: String) -> String:
	if text.is_empty():
		return text
	return str(TranslationServer.translate(text))
