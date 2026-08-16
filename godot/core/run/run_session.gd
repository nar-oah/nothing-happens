extends Node
class_name RunSession

var state: RunState


func start_new_run() -> void:
	state = RunState.new()

	print("Run started.")
	print("Year: ", state.year)
	print("Month: ", state.month)
