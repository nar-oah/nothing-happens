extends NewspaperFrontDefinition
class_name PolicyTriggeredNewspaperFrontDefinition

@export var policy_name_format: String
@export var list_separator: String = "、"
@export var multiple_title: String
@export_multiline var multiple_content: String


func resolve(
	state: RunState,
	_balance: GameBalanceDefinition,
	_previous_collapse: int
) -> Variant:
	if state.newspaper_triggered_policies.is_empty():
		return null
	var names := PackedStringArray()
	for definition in state.newspaper_triggered_policies:
		if definition != null:
			names.append(_t(policy_name_format) % _t(definition.display_name))
	if names.is_empty():
		return null
	if names.size() == 1:
		return make_front(_t(title) % names[0], _t(content) % names[0])
	return make_front(
		_t(multiple_title) % names.size(),
		_t(multiple_content) % _t(list_separator).join(names)
	)
