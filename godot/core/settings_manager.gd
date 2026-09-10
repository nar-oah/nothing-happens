extends Node
class_name SettingsManager

const LANGUAGES: Array[String] = ["zh_CN", "en"]
const DISPLAY_MODES: Array[String] = ["windowed", "fullscreen"]
const MUSIC_VOLUME_MIN: int = 0
const MUSIC_VOLUME_MAX: int = 100
const DEFAULT_MUSIC_VOLUME: int = 100

var settings_path: String = "user://settings.cfg"
var language: String = "zh_CN"
var display_mode: String = "windowed"
var music_volume: int = DEFAULT_MUSIC_VOLUME


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	language = "zh_CN"
	display_mode = "windowed"
	music_volume = DEFAULT_MUSIC_VOLUME
	if config.load(settings_path) == OK:
		var saved_language: Variant = config.get_value("settings", "language", language)
		var saved_mode: Variant = config.get_value("settings", "display_mode", display_mode)
		var saved_music_volume: Variant = config.get_value("settings", "music_volume", music_volume)
		if saved_language is String and saved_language in LANGUAGES:
			language = saved_language
		if saved_mode is String and saved_mode in DISPLAY_MODES:
			display_mode = saved_mode
		if saved_music_volume is int and saved_music_volume >= MUSIC_VOLUME_MIN and saved_music_volume <= MUSIC_VOLUME_MAX:
			music_volume = saved_music_volume
	TranslationServer.set_locale(language)
	_apply_display_mode()
	_apply_music_volume()


func set_language(value: String) -> Dictionary:
	if value not in LANGUAGES:
		return {"ok": false, "error": {"code": "invalid_language", "message": "Unsupported language."}}
	var result := _save(value, display_mode, music_volume)
	if result["ok"]:
		language = value
		TranslationServer.set_locale(language)
	return result


func set_display_mode(value: String) -> Dictionary:
	if value not in DISPLAY_MODES:
		return {"ok": false, "error": {"code": "invalid_display_mode", "message": "Unsupported display mode."}}
	var result := _save(language, value, music_volume)
	if result["ok"]:
		display_mode = value
		_apply_display_mode()
	return result


func set_music_volume(value: int) -> Dictionary:
	if value < MUSIC_VOLUME_MIN or value > MUSIC_VOLUME_MAX:
		return {"ok": false, "error": {"code": "invalid_music_volume", "message": "Music volume must be between 0 and 100."}}
	var result := _save(language, display_mode, value)
	if result["ok"]:
		music_volume = value
		_apply_music_volume()
	return result


func _save(next_language: String, next_mode: String, next_music_volume: int) -> Dictionary:
	var config := ConfigFile.new()
	config.set_value("settings", "language", next_language)
	config.set_value("settings", "display_mode", next_mode)
	config.set_value("settings", "music_volume", next_music_volume)
	var temporary_path := settings_path + ".tmp"
	if config.save(temporary_path) != OK or DirAccess.rename_absolute(temporary_path, settings_path) != OK:
		return {"ok": false, "error": {"code": "settings_write_failed", "message": "Unable to save settings."}}
	return {"ok": true}


func _apply_display_mode() -> void:
	if is_inside_tree():
		get_tree().root.mode = Window.MODE_FULLSCREEN if display_mode == "fullscreen" else Window.MODE_WINDOWED


func _apply_music_volume() -> void:
	if not is_inside_tree():
		return
	var audio_director := get_node_or_null("/root/AudioDirector")
	if audio_director != null and audio_director.has_method(&"set_music_volume"):
		audio_director.call(&"set_music_volume", music_volume)
