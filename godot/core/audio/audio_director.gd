extends Node

const BGM := preload("res://assets/audio/bgm.mp3")
const DIALOGUE_SFX := preload("res://assets/audio/dialogue.ogg")
const DOOR_SFX := preload("res://assets/audio/door.ogg")
const OTHER_SFX := preload("res://assets/audio/other.ogg")
const TYPEWRITER_ANXIETY := preload("res://assets/audio/typewriter_anxiety.ogg")
const PARLIAMENT_MURMUR := preload("res://assets/audio/parliament_murmur.ogg")

const TYPEWRITER_INTERVALS := {
	1: Vector2(22.0, 34.0),
	2: Vector2(11.0, 20.0),
	3: Vector2(5.0, 11.0),
}
const MURMUR_VOLUMES := {
	1: -31.0,
	2: -24.0,
	3: -18.0,
}

var _world_scene: String = "office"
var _anxiety_stage: int = 0
var _music_player: AudioStreamPlayer
var _typewriter_player: AudioStreamPlayer
var _murmur_player: AudioStreamPlayer
var _typewriter_timer: Timer
var _interaction_players: Array[AudioStreamPlayer] = []
var _interaction_index: int = 0


func _ready() -> void:
	_music_player = _make_player("Music", -10.0)
	_typewriter_player = _make_player("TypewriterAnxiety", -13.0)
	_murmur_player = _make_player("ParliamentMurmur", -80.0)
	for index in range(4):
		_interaction_players.append(_make_player("Interaction%d" % index, 0.0))

	_typewriter_timer = Timer.new()
	_typewriter_timer.name = "TypewriterTimer"
	_typewriter_timer.one_shot = true
	_typewriter_timer.timeout.connect(_on_typewriter_timer_timeout)
	add_child(_typewriter_timer)

	_set_loop(BGM, true)
	_set_loop(PARLIAMENT_MURMUR, true)
	_music_player.stream = BGM
	_music_player.play()
	_murmur_player.stream = PARLIAMENT_MURMUR
	_typewriter_player.stream = TYPEWRITER_ANXIETY
	_refresh_anxiety()


func set_world_scene(scene_name: String) -> void:
	if scene_name == _world_scene:
		return
	_world_scene = scene_name
	_refresh_anxiety()


func set_collapse(collapse_level: int, max_collapse: int) -> void:
	var next_stage := _stage_for(collapse_level, max_collapse)
	if next_stage == _anxiety_stage:
		return
	_anxiety_stage = next_stage
	_refresh_anxiety()


func play_dialogue() -> void:
	_play_interaction(DIALOGUE_SFX, -2.0)


func play_door() -> void:
	_play_interaction(DOOR_SFX, -1.0)


func play_other() -> void:
	_play_interaction(OTHER_SFX, -3.0)


func _stage_for(collapse_level: int, max_collapse: int) -> int:
	if max_collapse <= 0:
		return 0
	var ratio := float(collapse_level) / float(max_collapse)
	if ratio >= 0.9:
		return 3
	if ratio >= 0.8:
		return 2
	if ratio >= 0.5:
		return 1
	return 0


func _refresh_anxiety() -> void:
	if _world_scene == "office" and _anxiety_stage > 0:
		_stop_murmur()
		_schedule_typewriter()
		return
	if _world_scene == "parliament" and _anxiety_stage > 0:
		_stop_typewriter()
		_murmur_player.volume_db = MURMUR_VOLUMES.get(_anxiety_stage, -31.0)
		if not _murmur_player.playing:
			_murmur_player.play()
		return
	_stop_typewriter()
	_stop_murmur()


func _schedule_typewriter() -> void:
	if _world_scene != "office" or _anxiety_stage <= 0:
		_typewriter_timer.stop()
		return
	if not _typewriter_timer.is_stopped():
		return
	var interval: Vector2 = TYPEWRITER_INTERVALS.get(_anxiety_stage, Vector2(22.0, 34.0))
	_typewriter_timer.start(randf_range(interval.x, interval.y))


func _on_typewriter_timer_timeout() -> void:
	if _world_scene != "office" or _anxiety_stage <= 0:
		return
	_typewriter_player.pitch_scale = randf_range(0.96, 1.04)
	_typewriter_player.volume_db = -15.0 + float(_anxiety_stage - 1) * 1.5
	_typewriter_player.play()
	_schedule_typewriter()


func _stop_typewriter() -> void:
	_typewriter_timer.stop()
	_typewriter_player.stop()


func _stop_murmur() -> void:
	_murmur_player.stop()
	_murmur_player.volume_db = -80.0


func _play_interaction(stream: AudioStream, volume_db: float) -> void:
	if _interaction_players.is_empty():
		return
	var player := _interaction_players[_interaction_index]
	_interaction_index = (_interaction_index + 1) % _interaction_players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0
	player.play()


func _make_player(player_name: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.volume_db = volume_db
	add_child(player)
	return player


func _set_loop(stream: AudioStream, enabled: bool) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = enabled
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = enabled
