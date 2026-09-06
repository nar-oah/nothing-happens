extends Node
class_name SettingsManager

const LANGUAGES: Array[String] = ["zh_CN", "en"]
const DISPLAY_MODES: Array[String] = ["windowed", "fullscreen"]

var settings_path: String = "user://settings.cfg"
var language: String = "zh_CN"
var display_mode: String = "windowed"


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	language = "zh_CN"
	display_mode = "windowed"
	if config.load(settings_path) == OK:
		var saved_language: Variant = config.get_value("settings", "language", language)
		var saved_mode: Variant = config.get_value("settings", "display_mode", display_mode)
		if saved_language is String and saved_language in LANGUAGES:
			language = saved_language
		if saved_mode is String and saved_mode in DISPLAY_MODES:
			display_mode = saved_mode
	TranslationServer.set_locale(language)
	_apply_display_mode()


func set_language(value: String) -> Dictionary:
	if value not in LANGUAGES:
		return {"ok": false, "error": {"code": "invalid_language", "message": "Unsupported language."}}
	var result := _save(value, display_mode)
	if result["ok"]:
		language = value
		TranslationServer.set_locale(language)
	return result


func set_display_mode(value: String) -> Dictionary:
	if value not in DISPLAY_MODES:
		return {"ok": false, "error": {"code": "invalid_display_mode", "message": "Unsupported display mode."}}
	var result := _save(language, value)
	if result["ok"]:
		display_mode = value
		_apply_display_mode()
	return result


func _save(next_language: String, next_mode: String) -> Dictionary:
	var config := ConfigFile.new()
	config.set_value("settings", "language", next_language)
	config.set_value("settings", "display_mode", next_mode)
	var temporary_path := settings_path + ".tmp"
	if config.save(temporary_path) != OK or DirAccess.rename_absolute(temporary_path, settings_path) != OK:
		return {"ok": false, "error": {"code": "settings_write_failed", "message": "Unable to save settings."}}
	return {"ok": true}


func _apply_display_mode() -> void:
	if is_inside_tree():
		get_tree().root.mode = Window.MODE_FULLSCREEN if display_mode == "fullscreen" else Window.MODE_WINDOWED
