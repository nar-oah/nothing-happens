extends Resource
class_name SimpleDialogueDefinition

@export_multiline var initial_text: String = ""

@export_group("选项")
@export var left_option: String = ""
@export var right_option: String = ""
@export_multiline var left_content: String = ""
@export_multiline var right_content: String = ""


func has_options() -> bool:
	return not left_option.is_empty() and not right_option.is_empty()
