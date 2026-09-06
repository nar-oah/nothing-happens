extends RaceDefinition
class_name BiyiRaceDefinition

@export_group("阴阳半身")
@export var yang_portrait: Texture2D
@export var yang_hover_portrait: Texture2D


func get_portrait(month: int) -> Texture2D:
	if month % 2 == 0 and yang_portrait != null:
		return yang_portrait
	return portrait


func get_hover_portrait(month: int) -> Texture2D:
	if month % 2 == 0 and yang_portrait != null:
		return yang_hover_portrait
	return hover_portrait
