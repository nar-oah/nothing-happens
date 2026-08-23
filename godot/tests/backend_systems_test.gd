extends SceneTree

const TestContextScript = preload("res://tests/backend/backend_test_context.gd")
const ParliamentAndProposalTests = preload("res://tests/backend/test_parliament_and_proposals.gd")
const EventTests = preload("res://tests/backend/test_events.gd")
const ConstitutionTests = preload("res://tests/backend/test_constitution.gd")
const ConstitutionInvariantTests = preload("res://tests/backend/test_constitution_invariants.gd")
const VotingTests = preload("res://tests/backend/test_voting.gd")
const AnnualFlowAndBalanceTests = preload("res://tests/backend/test_annual_flow_and_balance.gd")
const CollapseTests = preload("res://tests/backend/test_collapse.gd")
const SavedBillTests = preload("res://tests/backend/test_saved_bills.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var t := TestContextScript.new()
	var suites := [
		ParliamentAndProposalTests.new(),
		EventTests.new(),
		ConstitutionTests.new(),
		ConstitutionInvariantTests.new(),
		VotingTests.new(),
		AnnualFlowAndBalanceTests.new(),
		CollapseTests.new(),
		SavedBillTests.new(),
	]
	for suite in suites:
		suite.run(t)
	if t.failures == 0:
		print("BACKEND TESTS PASSED: %s assertions" % t.assertions)
	else:
		push_error("BACKEND TESTS FAILED: %s of %s assertions" % [t.failures, t.assertions])
	quit(t.failures)
