extends UiBridge
class_name NewspaperUiBridge


func _dispatch(message: Dictionary, messages: Array[Dictionary]) -> void:
	if message["type"] == "event.suppress":
		_handle_event_petition(message, messages)
		return
	if message["type"] == "settings.music_volume.set":
		_handle_music_volume_set(message, messages)
		return
	super._dispatch(message, messages)


func _full_state(request_id: Variant = null) -> Dictionary:
	var message := super._full_state(request_id)
	if message.has("payload"):
		message["payload"]["suppression_remaining"] = run_session.parliament_system.get_petition_remaining(run_session.context)
		message["payload"]["music_volume"] = SettingsManager.DEFAULT_MUSIC_VOLUME if settings_manager == null else settings_manager.music_volume
	return message


func _handle_music_volume_set(message: Dictionary, messages: Array[Dictionary]) -> void:
	if message["payload"].size() != 1:
		_append_mutation_error(
			messages,
			{"code": "invalid_payload", "message": "Music volume requires exactly one volume field."},
			message["request_id"]
		)
		return
	var volume := _protocol.read_int(message["payload"], "volume")
	if not volume["ok"]:
		_append_mutation_error(messages, volume["error"], message["request_id"])
		return
	if settings_manager == null:
		_append_mutation_error(
			messages,
			{"code": "settings_not_ready", "message": "SettingsManager is not ready."},
			message["request_id"]
		)
		return
	var result := settings_manager.set_music_volume(volume["value"])
	if not result["ok"]:
		_append_mutation_error(messages, result["error"], message["request_id"])
		return
	messages.append(_full_state(message["request_id"]))


func _handle_event_petition(message: Dictionary, messages: Array[Dictionary]) -> void:
	var index := _protocol.read_int(message["payload"], "event_index")
	if not index["ok"]:
		_append_mutation_error(messages, index["error"], message["request_id"])
		return
	var state := run_session.state
	if index["value"] < 0 or index["value"] >= state.events.size():
		_append_mutation_error(
			messages,
			{"code": "invalid_event_index", "message": "Event index is invalid."},
			message["request_id"]
		)
		return
	var event: EventState = state.events[index["value"]]
	if event == null or not event.is_active() or not event.published:
		_append_mutation_error(
			messages,
			{"code": "event_unavailable", "message": "Event is no longer available for this action."},
			message["request_id"]
		)
		return
	if not run_session.use_petition(event):
		_append_mutation_error(
			messages,
			{"code": "petition_unavailable", "message": "No use is available for this event."},
			message["request_id"]
		)
		return
	event.phase = EventState.Phase.RESOLVED
	for report_index in range(state.month_report_events.size() - 1, -1, -1):
		var report: Variant = state.month_report_events[report_index]
		if report is Dictionary and int(report.get("event_index", -1)) == index["value"]:
			state.month_report_events.remove_at(report_index)
	state_version += 1
	messages.append(_full_state(message["request_id"]))
