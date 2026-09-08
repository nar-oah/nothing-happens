extends Resource
class_name NewspaperFrontDefinition

@export var title: String
@export_multiline var content: String


func resolve(
	_state: RunState,
	_balance: GameBalanceDefinition,
	_previous_collapse: int
) -> Variant:
	return null


func make_front(resolved_title: String = "", resolved_content: String = "") -> Dictionary:
	return {
		"title": _t(title) if resolved_title.is_empty() else resolved_title,
		"content": _t(content) if resolved_content.is_empty() else resolved_content,
	}


func _t(text: String) -> String:
	return text if text.is_empty() else str(TranslationServer.translate(text))
