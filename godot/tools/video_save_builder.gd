extends Node

const OUTPUT_DIR := "user://video_saves"
const Balance = preload("res://data/config/game_balance.tres")
const Board = preload("res://data/constitutions/constitution_board.tres")


func _ready() -> void:
	if DirAccess.make_dir_recursive_absolute(OUTPUT_DIR) != OK:
		push_error("Failed to create video save directory: %s" % OUTPUT_DIR)
		get_tree().quit()
		return
	var session := _make_session()
	session.random_system.set_seed(0x23456789abcdef)
	var state := session.state
	state.term = 9
	state.year = 9
	state.month = 9
	state.political_donation_pool = 99
	var slot_id := "manual_900001"
	_write(session, slot_id)
	var restored := _make_session()
	var result := restored.load_save(slot_id)
	if result["ok"] != true:
		push_error("Failed to restore video save: result.ok is false")
	elif restored.state.term != 9:
		push_error("Failed to restore video save: state.term is %s, expected 9" % restored.state.term)
	elif restored.state.year != 9:
		push_error("Failed to restore video save: state.year is %s, expected 9" % restored.state.year)
	elif restored.state.month != 9:
		push_error("Failed to restore video save: state.month is %s, expected 9" % restored.state.month)
	elif restored.state.political_donation_pool != 99:
		push_error("Failed to restore video save: state.political_donation_pool is %s, expected 99" % restored.state.political_donation_pool)
	else:
		print("VIDEO SAVE BUILD OK")
	session.free()
	restored.free()
	get_tree().quit()


func _make_session() -> RunSession:
	var session := RunSession.new()
	session.balance = Balance
	session.save_directory = OUTPUT_DIR
	session.autosave_enabled = false
	var races: Array[RaceDefinition] = []
	var groups: Array[InterestGroupDefinition] = []
	var seats: Array[SeatDefinition] = []
	races.assign(_resources("res://data/races"))
	groups.assign(_resources("res://data/interest_groups"))
	seats.assign(_resources("res://data/seats"))
	session.configure_content(races, groups, seats, [], Board)
	session.start_new_run()
	return session


func _write(session: RunSession, slot_id: String) -> void:
	var result := RunSaveStore.write_save(session, slot_id)
	var path := session.save_directory.path_join(slot_id + ".json")
	if result["ok"]:
		print("Generated video save: %s" % path)
	else:
		push_error("Failed to generate video save: %s" % result["error"]["message"])


func _resources(directory: String) -> Array[Resource]:
	var result: Array[Resource] = []
	var files := DirAccess.get_files_at(directory)
	files.sort()
	for filename in files:
		if filename.ends_with(".tres"):
			result.append(load(directory.path_join(filename)))
	return result
