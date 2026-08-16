extends Node
class_name RunSession

var state: RunState
var time_system: TimeSystem
var flow_controller: FlowController


func start_new_run() -> void:
	state = RunState.new()

	time_system = TimeSystem.new()

	flow_controller = FlowController.new()
	flow_controller.setup(state, time_system)

	print("Run started.")
	print_current_date()


func advance_month() -> void:
	flow_controller.advance_month()
	print_current_date()


func print_current_date() -> void:
	print("Year: ", state.year, ", Month: ", state.month)
