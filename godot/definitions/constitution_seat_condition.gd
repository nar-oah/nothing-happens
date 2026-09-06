extends ConstitutionCondition
class_name ConstitutionSeatCondition

enum Comparison {
	AT_LEAST,
	AT_MOST,
	GREATER_THAN,
	LESS_THAN,
}

enum MatchMode {
	ALL,
	ANY,
}

@export var race: RaceDefinition
@export var interest_groups: Array[InterestGroupDefinition] = []
@export var interest_group: InterestGroupDefinition
@export var comparison: Comparison = Comparison.AT_LEAST
@export var match_mode: MatchMode = MatchMode.ALL
@export_range(0.0, 1.0, 0.01) var required_rate: float = 0.0


func is_met(context: RunContext) -> bool:
	if context == null or context.state == null:
		return false
	var groups := _get_groups()
	if groups.is_empty():
		if race == null:
			return false
		return _compare(context.parliament_system.get_race_seat_rate(context.state, race))
	var matched := 0
	for group in groups:
		var rate := context.parliament_system.get_group_influence_rate(
			context.state, group, race
		)
		if _compare(rate):
			matched += 1
	if match_mode == MatchMode.ANY:
		return matched > 0
	return matched == groups.size()


func get_description() -> String:
	var comparison_text: String = [_t("不低于"), _t("不高于"), _t("高于"), _t("低于")][comparison]
	var threshold := "%s%s%%" % [comparison_text, String.num(required_rate * 100.0, 2).trim_suffix(".0")]
	var groups := _get_groups()
	if groups.is_empty():
		if race == null:
			return _t("未指定种族或利益集团，无法满足")
		return _t("种族：%s\n席位占比：%s") % [_t(race.display_name), threshold]
	var names := PackedStringArray()
	for group in groups:
		names.append(_t(group.display_name))
	return _t("范围：%s\n利益集团：%s\n各集团影响力占比：%s\n满足方式：%s") % [
		_t("全议会") if race == null else _t(race.display_name),
		_t("、").join(names),
		threshold,
		_t("任一满足") if match_mode == MatchMode.ANY else _t("全部满足"),
	]


func _get_groups() -> Array[InterestGroupDefinition]:
	var result: Array[InterestGroupDefinition] = []
	for group in interest_groups:
		if group != null and group not in result:
			result.append(group)
	if interest_group != null and interest_group not in result:
		result.append(interest_group)
	return result


func _compare(rate: float) -> bool:
	match comparison:
		Comparison.AT_MOST:
			return rate <= required_rate
		Comparison.GREATER_THAN:
			return rate > required_rate
		Comparison.LESS_THAN:
			return rate < required_rate
		_:
			return rate >= required_rate


func _t(text: String) -> String:
	return text if text.is_empty() else str(TranslationServer.translate(text))
