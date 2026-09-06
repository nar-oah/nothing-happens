extends SceneTree

const TestContextScript = preload("res://tests/backend/backend_test_context.gd")
const ParliamentAndProposalTests = preload("res://tests/backend/test_parliament_and_proposals.gd")
const EventTests = preload("res://tests/backend/test_events.gd")
const ConstitutionTests = preload("res://tests/backend/test_constitution.gd")
const ConstitutionBoardTests = preload("res://tests/backend/test_constitution_board.gd")
const ContentResourceTests = preload("res://tests/backend/test_content_resources.gd")
const ConstitutionInvariantTests = preload("res://tests/backend/test_constitution_invariants.gd")
const VotingTests = preload("res://tests/backend/test_voting.gd")
const AnnualFlowAndBalanceTests = preload("res://tests/backend/test_annual_flow_and_balance.gd")
const CollapseTests = preload("res://tests/backend/test_collapse.gd")
const SavedBillTests = preload("res://tests/backend/test_saved_bills.gd")
const UiIntegrationTests = preload("res://tests/backend/test_ui_integration.gd")
const TransitionFlowTests = preload("res://tests/backend/test_transition_flow.gd")
const SaveGameTests = preload("res://tests/backend/test_save_game.gd")
const SettingsTests = preload("res://tests/backend/test_settings.gd")


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
		ConstitutionBoardTests.new(),
		ContentResourceTests.new(),
		ConstitutionInvariantTests.new(),
		VotingTests.new(),
		AnnualFlowAndBalanceTests.new(),
		CollapseTests.new(),
		SavedBillTests.new(),
		UiIntegrationTests.new(),
		TransitionFlowTests.new(),
		SaveGameTests.new(),
		SettingsTests.new(),
	]
	for suite in suites:
		suite.run(t)
	TranslationServer.set_locale(previous_locale)
	if t.failures == 0:
		print("BACKEND TESTS PASSED: %s assertions" % t.assertions)
	else:
		push_error("BACKEND TESTS FAILED: %s of %s assertions" % [t.failures, t.assertions])
	quit(t.failures)
