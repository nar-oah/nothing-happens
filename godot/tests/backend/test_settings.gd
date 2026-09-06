extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")
const Fixture = preload("res://tests/backend/save_test_fixture.gd")


class QuitBridge extends UiBridge:
	var quit_calls: int = 0
	var save_at_quit: Dictionary = {}

	func _quit_application() -> void:
		quit_calls += 1
		save_at_quit = RunSaveStore.read_save(run_session.save_directory, RunSaveStore.AUTO_SLOT)


func run(t: BackendTestContext) -> void:
	var previous_locale := TranslationServer.get_locale()
	var main_window: Window = Engine.get_main_loop().root
	var previous_mode := main_window.mode
	_test_persistence(t)
	_test_settings_commands(t)
	_test_settings_write_failure(t)
	_test_quit_autosave(t)
	TranslationServer.set_locale(previous_locale)
	main_window.mode = previous_mode


func _test_persistence(t: BackendTestContext) -> void:
	var directory := _directory("persistence")
	DirAccess.make_dir_recursive_absolute(directory)
	var settings := SettingsManager.new()
	t.check_equal(settings.settings_path, "user://settings.cfg", "settings use a dedicated user config file")
	settings.settings_path = directory.path_join("settings.cfg")
	Engine.get_main_loop().root.add_child(settings)
	t.check_equal(settings.language, "zh_CN", "missing settings default to Chinese")
	t.check_equal(settings.display_mode, "windowed", "missing settings default to windowed")
	t.check(settings.set_language("en")["ok"], "English setting persists")
	t.check_equal(TranslationServer.get_locale(), "en", "language applies to TranslationServer immediately")
	t.check(settings.set_display_mode("fullscreen")["ok"], "fullscreen setting persists")
	var config := ConfigFile.new()
	t.check_equal(config.load(settings.settings_path), OK, "settings are readable immediately after mutation")
	t.check_equal(config.get_value("settings", "language"), "en", "changing display preserves saved language")
	t.check_equal(config.get_value("settings", "display_mode"), "fullscreen", "config contains current display mode")
	if DisplayServer.get_name() != "headless":
		t.check_equal(settings.get_tree().root.mode, Window.MODE_FULLSCREEN, "display changes the main Window mode")
	settings.free()
	var restarted := SettingsManager.new()
	restarted.settings_path = directory.path_join("settings.cfg")
	Engine.get_main_loop().root.add_child(restarted)
	t.check_equal(restarted.language, "en", "a fresh manager restores saved language on startup")
	t.check_equal(restarted.display_mode, "fullscreen", "a fresh manager restores saved display mode on startup")
	t.check(restarted.set_language("zh_CN")["ok"], "language can switch back to Chinese")
	t.check_equal(TranslationServer.get_locale(), "zh_CN", "Chinese locale applies immediately")
	t.check(restarted.set_display_mode("windowed")["ok"], "display can switch back to windowed")
	t.check_equal(restarted.get_tree().root.mode, Window.MODE_WINDOWED, "windowed mode applies to the main Window")
	config.set_value("settings", "language", "unsupported")
	config.set_value("settings", "display_mode", 2)
	config.save(restarted.settings_path)
	restarted.load_settings()
	t.check_equal(restarted.language, "zh_CN", "unsupported saved language falls back to Chinese")
	t.check_equal(restarted.display_mode, "windowed", "invalid saved display type falls back to windowed")
	restarted.free()
	Fixture.clean(directory)


func _test_settings_commands(t: BackendTestContext) -> void:
	var directory := _directory("commands")
	var session := Fixture.make_session(directory)
	var settings := SettingsManager.new()
	settings.settings_path = directory.path_join("settings.cfg")
	var bridge := UiBridge.new()
	bridge.setup(session, null, null, settings)
	bridge.state_version = 7
	var before := _snapshot(session)
	var automatic_before := FileAccess.get_file_as_string(directory.path_join("auto.json"))
	var protocol := UiProtocol.new()
	for command in ["settings.language.set", "settings.display.set", "app.quit"]:
		t.check(not protocol.is_gameplay_mutation(command), "%s is not a gameplay mutation" % command)
	var messages := bridge.receive_ipc_message(_message("settings.language.set", {"language": "en"}))
	t.check_equal(messages[0]["type"], "state.full", "language command works without state_version and returns full state")
	t.check_equal(messages[0]["request_id"], "settings-test", "settings sync preserves request id")
	t.check_equal(messages[0]["payload"]["language"], "en", "language sync uses SettingsManager state")
	messages = bridge.receive_ipc_message(_message("settings.display.set", {"mode": "fullscreen"}))
	t.check_equal(messages[0]["payload"]["display_mode"], "fullscreen", "display command works without state_version and syncs mode")
	t.check_equal(messages[0]["payload"]["state_version"], 7, "settings sync preserves the current gameplay version")
	for value in [null, 1, true, {}, [], "unsupported"]:
		for command in ["settings.language.set", "settings.display.set"]:
			var field := "language" if command == "settings.language.set" else "mode"
			var payload := {} if value == null else {field: value}
			messages = bridge.receive_ipc_message(_message(command, payload))
			t.check_equal(messages[0]["type"], "command.error", "invalid settings payload returns command.error")
			t.check_equal(messages[0]["payload"]["code"], "invalid_language" if field == "language" else "invalid_display_mode", "invalid settings enum has a specific error code")
			t.check_equal(messages.back()["payload"]["language"], "en", "rejected settings preserve authoritative language")
			t.check_equal(messages.back()["payload"]["display_mode"], "fullscreen", "rejected settings preserve authoritative display mode")
	for command in ["settings.language.set", "settings.display.set"]:
		for extra_field in ["state_version", "unexpected"]:
			var payload := {"language": "zh_CN"} if command == "settings.language.set" else {"mode": "windowed"}
			payload[extra_field] = 7
			messages = bridge.receive_ipc_message(_message(command, payload))
			t.check_equal(messages[0]["payload"]["code"], "invalid_payload", "settings reject state_version and extra payload fields")
	t.check_equal(bridge.state_version, 7, "accepted and rejected settings commands never increase state_version")
	t.check(_snapshot(session) == before, "settings do not change the persisted run graph or RNG")
	t.check_equal(FileAccess.get_file_as_string(directory.path_join("auto.json")), automatic_before, "settings commands leave the automatic game save untouched")
	var manual := session.create_manual_save()
	t.check(manual["ok"], "manual save succeeds after settings changes")
	var saved := RunSaveStore.read_save(directory, manual["slot_id"])
	var saved_text := JSON.stringify(saved["snapshot"], "", true, true)
	t.check_equal(saved_text, before, "a game save after settings changes contains the same run snapshot")
	t.check(not saved_text.contains('"language"') and not saved_text.contains('"display_mode"'), "settings fields never enter a term save")
	messages = bridge.receive_ipc_message(_message("saves.load", {"slot_id": manual["slot_id"], "state_version": 7}))
	t.check_equal(messages.back()["payload"]["language"], "en", "loading a term keeps application language")
	t.check_equal(messages.back()["payload"]["display_mode"], "fullscreen", "loading a term keeps application display mode")
	bridge.free()
	settings.free()
	session.free()
	Fixture.clean(directory)


func _test_settings_write_failure(t: BackendTestContext) -> void:
	var directory := _directory("write_failure")
	var session := Fixture.make_session(directory)
	var settings := SettingsManager.new()
	settings.settings_path = directory.path_join("settings.cfg")
	t.check(settings.set_language("en")["ok"], "write failure fixture saves an original settings file")
	var original_config := FileAccess.get_file_as_string(settings.settings_path)
	DirAccess.make_dir_absolute(settings.settings_path + ".tmp")
	var bridge := UiBridge.new()
	bridge.setup(session, null, null, settings)
	for command in ["settings.language.set", "settings.display.set"]:
		var payload := {"language": "zh_CN"} if command == "settings.language.set" else {"mode": "fullscreen"}
		var messages := bridge.receive_ipc_message(_message(command, payload))
		t.check_equal(messages[0]["payload"]["code"], "settings_write_failed", "settings write failure returns command.error")
		t.check_equal(messages.back()["payload"]["language"], "en", "failed settings write does not change language")
		t.check_equal(messages.back()["payload"]["display_mode"], "windowed", "failed settings write does not change display")
	t.check_equal(TranslationServer.get_locale(), "en", "failed write does not apply a new locale")
	t.check_equal(bridge.state_version, 0, "failed settings persistence does not change state_version")
	t.check_equal(FileAccess.get_file_as_string(settings.settings_path), original_config, "failed settings writes preserve the previous config")
	DirAccess.remove_absolute(settings.settings_path + ".tmp")
	bridge.free()
	settings.free()
	session.free()
	Fixture.clean(directory)


func _test_quit_autosave(t: BackendTestContext) -> void:
	var directory := _directory("quit")
	var session := Fixture.make_session(directory)
	var manual := session.create_manual_save()
	var manual_path := directory.path_join(manual["slot_id"] + ".json")
	var manual_before := FileAccess.get_file_as_string(manual_path)
	Fixture.populate(session)
	var expected := _snapshot(session)
	var bridge := QuitBridge.new()
	bridge.setup(session)
	bridge.state_version = 4
	var messages := bridge.receive_ipc_message(_message("app.quit", {"state_version": 4}))
	t.check_equal(messages[0]["payload"]["code"], "invalid_payload", "quit only accepts an empty payload")
	t.check_equal(bridge.quit_calls, 0, "invalid quit payload does not quit")
	var automatic_before := FileAccess.get_file_as_string(directory.path_join("auto.json"))
	var blocked_path := directory.path_join("auto.json.tmp")
	DirAccess.make_dir_absolute(blocked_path)
	messages = bridge.receive_ipc_message(_message("app.quit", {}))
	t.check_equal(messages[0]["type"], "command.error", "failed quit autosave returns the existing error envelope")
	t.check_equal(messages[0]["payload"]["code"], "save_write_failed", "failed quit reports the save system error code")
	t.check_equal(messages[0]["request_id"], "settings-test", "failed quit error preserves request id")
	t.check_equal(messages.back()["type"], "state.full", "failed quit resyncs the active game UI")
	t.check_equal(bridge.quit_calls, 0, "autosave failure prevents application quit")
	t.check_equal(FileAccess.get_file_as_string(directory.path_join("auto.json")), automatic_before, "failed quit preserves the previous automatic save")
	t.check_equal(bridge.state_version, 4, "failed quit does not change state_version")
	DirAccess.remove_absolute(blocked_path)
	messages = bridge.receive_ipc_message(_message("app.quit", {}))
	t.check(messages.is_empty(), "successful quit requires no gameplay response")
	t.check_equal(bridge.quit_calls, 1, "successful autosave allows application quit")
	t.check(bridge.save_at_quit["ok"], "the automatic slot is readable before quit is invoked")
	t.check_equal(JSON.stringify(bridge.save_at_quit["snapshot"], "", true, true), expected, "quit writes the complete current term before exiting")
	t.check_equal(bridge.save_at_quit["slot"]["term"], 3, "quit uses the automatic slot for the current term")
	t.check_equal(FileAccess.get_file_as_string(manual_path), manual_before, "quit never overwrites a manual save")
	t.check_equal(bridge.state_version, 4, "successful quit does not increase state_version")
	t.check_equal(_snapshot(session), expected, "quit leaves the current run and RNG unchanged")
	bridge.free()
	session.free()
	Fixture.clean(directory)


func _snapshot(session: RunSession) -> String:
	return JSON.stringify(RunSnapshot.capture(session), "", true, true)


func _directory(label: String) -> String:
	return "user://test_settings_%s_%s_%s" % [label, OS.get_process_id(), Time.get_ticks_usec()]


func _message(message_type: String, payload: Dictionary) -> String:
	return JSON.stringify({"type": message_type, "request_id": "settings-test", "payload": payload})
