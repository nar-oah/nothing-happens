extends Node2D

signal parliament_requested


func _ready() -> void:
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()


func _update_layout() -> void:
	var size := get_viewport_rect().size
	$LeftAnchor.position = Vector2(0, size.y)
	$CenterAnchor.position = Vector2(size.x / 2.0, size.y)
	$RightAnchor.position = size


func _on_door_clicked() -> void:
	parliament_requested.emit()
