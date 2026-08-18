extends RefCounted


func run(t) -> void:
	_test_collapse_routes(t)


func _test_collapse_routes(t) -> void:
	var system := CollapseSystem.new()

	var silent_state := RunState.new()
	silent_state.collapse_level = 99.0
	silent_state.pending_collapse_delta = 1.0
	system.settle_month(silent_state)
	t.check(silent_state.silent_observation, "no-intervention collapse enters silent observation")
	for i in range(13):
		system.settle_month(silent_state)
	t.check_equal(
		silent_state.ending_id, &"nothing_happens", "silent recovery reaches unique ending"
	)

	var failed_state := RunState.new()
	failed_state.collapse_level = 99.0
	system.record_intervention(failed_state, &"bill_submission", 1.0)
	failed_state.pending_collapse_delta = 1.0
	system.settle_month(failed_state)
	t.check(failed_state.run_failed, "intervened collapse ends the term")

	var interrupted := RunState.new()
	interrupted.collapse_level = 100.0
	interrupted.silent_observation = true
	system.record_intervention(interrupted, &"constitution_revision", 1.0)
	t.check(interrupted.run_failed, "intervention interrupts silent observation immediately")
