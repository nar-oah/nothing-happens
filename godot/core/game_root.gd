extends Node

@onready var run_session: RunSession = $RunSession


func _ready() -> void:
	print("GameRoot started.")

	run_session.start_new_run()
