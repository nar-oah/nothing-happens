extends Node2D

signal parliament_requested


func _on_door_clicked() -> void:
	parliament_requested.emit()
