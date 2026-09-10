extends SceneTree

const TestContextScript = preload("res://tests/backend/backend_test_context.gd")
const ParliamentAndProposalTests = preload("res://tests/backend/test_parliament_and_proposals.gd")
const EventTests = preload("res://tests/backend/test_events.gd")
const ConstitutionTests = preload("res://tests/backend/test_constitution.gd")
const ConstitutionRequirementSerializationTests = preload("res://tests/backend/test_constitution_requirement_serialization.gd")
const VotingTests = preload("res://tests/backend/test_voting.gd")
const CollapseTests = preload("res://tests/backend/test_collapse.gd")
const PolicySchedulingTests = preload("res://tests/backend/test_policy_scheduling.gd")
const TransitionFlowTests = preload("res://tests/backend/test_transition_flow.gd")
const SaveGameTests = preload("res://tests/backend/test_save_game.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var previous_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("zh_CN")
	var t := TestContextScript.new()
	t.check_equal(
		ProjectSettings.get_setting("internationalization/locale/fallback"),
		"zh_CN",
		"localization fallback uses the Chinese source language"
	)
	t.check_equal(
		str(TranslationServer.translate("无")),
		"无",
		"Chinese locale keeps untranslated source-language text"
	)
	var suites := [
		ParliamentAndProposalTests.new(),
		EventTests.new(),
		ConstitutionTests.new(),
		ConstitutionRequirementSerializationTests.new(),
		VotingTests.new(),
		CollapseTests.new(),
		PolicySchedulingTests.new(),
		TransitionFlowTests.new(),
		SaveGameTests.new(),
	]
	for suite in suites:
		suite.run(t)
	TranslationServer.set_locale(previous_locale)
	if t.failures == 0:
		print("BACKEND TESTS PASSED: %s assertions" % t.assertions)
	else:
		push_error("BACKEND TESTS FAILED: %s of %s assertions" % [t.failures, t.assertions])
	quit(t.failures)
