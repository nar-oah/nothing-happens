extends Node
class_name UiBridge

signal outgoing_message(message: Dictionary)

var run_session: RunSession
var scene_manager: Node
var cef_texture: Control
var state_version: int = 0
var ui_mode: String = "office"
var world_scene: String = "office"

var _protocol := UiProtocol.new()
var _serializer := UiSerializer.new()


func setup(session: RunSession, manager: Node = null, texture: Control = null) -> void:
	run_session = session
	scene_manager = manager
	set_cef_texture(texture)
	if (
		run_session != null
		and run_session.state != null
		and run_session.state.run_phase == RunState.RunPhase.RUNNING
		and run_session.state.month == 0
	):
		set_ui_mode("constitution", false)
	else:
		_refresh_dialogue_mode()


func set_cef_texture(texture: Control) -> void:
	if cef_texture != null and cef_texture.has_signal("ipc_message"):
		var callback := Callable(self, "_on_ipc_message")
		if cef_texture.is_connected("ipc_message", callback):
			cef_texture.disconnect("ipc_message", callback)
	cef_texture = texture
	if cef_texture != null and cef_texture.has_signal("ipc_message"):
		var callback := Callable(self, "_on_ipc_message")
		if not cef_texture.is_connected("ipc_message", callback):
			cef_texture.connect("ipc_message", callback)


func receive_ipc_message(raw_message: String) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	var decoded := _protocol.decode(raw_message)
	if not decoded["ok"]:
		messages.append(_envelope("command.error", decoded["error"]))
		_send_all(messages)
		return messages
	var message: Dictionary = decoded["message"]
	if run_session == null or run_session.state == null:
		messages.append(
			_envelope(
				"command.error",
				{"code": "session_not_ready", "message": "RunSession is not ready."},
				message["request_id"]
			)
		)
		_send_all(messages)
		return messages
	if _protocol.is_gameplay_mutation(message["type"]):
		var version := _protocol.read_int(message["payload"], "state_version")
		if not version["ok"]:
			_append_mutation_error(messages, version["error"], message["request_id"])
			_send_all(messages)
			return messages
		if version["value"] != state_version:
			_append_mutation_error(
				messages,
				{
					"code": "stale_state",
					"message": "Expected state_version %s, received %s."
					% [state_version, version["value"]],
				},
				message["request_id"]
			)
			_send_all(messages)
			return messages
	_dispatch(message, messages)
	_send_all(messages)
	return messages


func send_full_state(request_id: Variant = null) -> void:
	if run_session == null or run_session.state == null:
		return
	_refresh_dialogue_mode()
	_send_message(_full_state(request_id))


func set_ui_mode(mode: String, send_sync: bool = true) -> bool:
	if mode not in UiProtocol.UI_MODES:
		return false
	if (
		run_session != null
		and run_session.state != null
		and run_session.state.run_phase == RunState.RunPhase.RUNNING
		and _serializer.pending_dialogue(run_session.state) != null
	):
		mode = "dialogue"
	ui_mode = mode
	world_scene = "parliament" if mode in ["parliament", "constitution"] else "office"
	if scene_manager != null:
		var method := "show_parliament" if world_scene == "parliament" else "show_office"
		if scene_manager.has_method(method):
			scene_manager.call(method)
	if send_sync:
		send_full_state()
	return true


func handle_world_interaction(action: StringName, payload: Dictionary) -> void:
	if action != &"ui.mode.set":
		return
	var mode: Variant = payload.get("mode")
	if mode is String:
		set_ui_mode(mode)


func _on_ipc_message(raw_message: String) -> void:
	receive_ipc_message(raw_message)


func _dispatch(message: Dictionary, messages: Array[Dictionary]) -> void:
	var message_type: String = message["type"]
	match message_type:
		"ui.ready":
			_refresh_dialogue_mode()
			messages.append(_full_state(message["request_id"]))
		"ui.input_regions":
			_handle_input_regions(message, messages)
		"ui.mode.set":
			_handle_mode_set(message, messages)
		"ui.newspaper.close":
			_handle_newspaper_close(message, messages)
		"draft.proposal.add":
			_handle_draft_proposal_add(message, messages)
		"draft.proposal.remove":
			_handle_draft_proposal_remove(message, messages)
		"draft.policy.add":
			_handle_draft_policy_add(message, messages)
		"draft.policy.remove":
			_handle_draft_policy_remove(message, messages)
		"draft.title.set":
			_handle_draft_title(message, messages)
		"bill.new":
			run_session.start_new_bill()
			_finish_draft_mutation(messages, message["request_id"])
		"bill.edit":
			_handle_bill_edit(message, messages)
		"bill.submit":
			_handle_bill_submit(message, messages)
		"proposal.merge":
			_handle_proposal_merge(message, messages)
		"proposal.bonus.resolve":
			_handle_bonus_resolve(message, messages)
		"month.advance":
			if _advance_month_and_refresh_mode():
				state_version += 1
			messages.append(_full_state(message["request_id"]))
		"term.next":
			_handle_term_next(message, messages)
		"constitution.revise":
			_handle_constitution_revise(message, messages)
		"constitution.column.unlock":
			_handle_constitution_column_unlock(message, messages)


func _handle_input_regions(message: Dictionary, messages: Array[Dictionary]) -> void:
	var raw_regions: Variant = message["payload"].get("regions")
	if not raw_regions is Array:
		messages.append(_error("invalid_field", "payload.regions must be an array.", message["request_id"]))
		return
	var regions: Array[Dictionary] = []
	for raw_region in raw_regions:
		if not raw_region is Dictionary or not _is_region(raw_region):
			messages.append(
				_error(
					"invalid_field",
					"Every input region requires normalized x, y, width and height.",
					message["request_id"]
				)
			)
			return
		regions.append(raw_region)
	if cef_texture != null and cef_texture.has_method("set_blocker_regions"):
		cef_texture.call("set_blocker_regions", regions)


func _handle_mode_set(message: Dictionary, messages: Array[Dictionary]) -> void:
	var mode: Variant = message["payload"].get("mode")
	if not mode is String or mode not in UiProtocol.UI_MODES:
		messages.append(_error("invalid_mode", "Unsupported UI mode.", message["request_id"]))
		messages.append(_full_state(message["request_id"]))
		return
	set_ui_mode(mode, false)
	messages.append(_full_state(message["request_id"]))


func _handle_newspaper_close(message: Dictionary, messages: Array[Dictionary]) -> void:
	run_session.clear_term_report()
	_refresh_dialogue_mode()
	set_ui_mode(ui_mode, false)
	messages.append(_full_state(message["request_id"]))


func _handle_draft_proposal_add(message: Dictionary, messages: Array[Dictionary]) -> void:
	var index := _protocol.read_int(message["payload"], "hand_index")
	if not index["ok"]:
		_append_mutation_error(messages, index["error"], message["request_id"])
		return
	if not run_session.draft_bill_system.move_proposal_from_hand(run_session.state, index["value"]):
		_append_mutation_error(
			messages,
			{"code": "invalid_hand_index", "message": "Proposal cannot enter the draft."},
			message["request_id"]
		)
		return
	_finish_draft_mutation(messages, message["request_id"])


func _handle_draft_proposal_remove(message: Dictionary, messages: Array[Dictionary]) -> void:
	var index := _protocol.read_int(message["payload"], "draft_index")
	if not index["ok"]:
		_append_mutation_error(messages, index["error"], message["request_id"])
		return
	if not run_session.draft_bill_system.return_proposal_to_hand(run_session.state, index["value"]):
		_append_mutation_error(
			messages,
			{"code": "invalid_draft_index", "message": "Draft proposal index is invalid."},
			message["request_id"]
		)
		return
	_finish_draft_mutation(messages, message["request_id"])


func _handle_draft_policy_add(message: Dictionary, messages: Array[Dictionary]) -> void:
	var display_name: Variant = message["payload"].get("display_name")
	if not display_name is String or display_name.is_empty():
		_append_mutation_error(
			messages,
			{"code": "invalid_field", "message": "payload.display_name is required."},
			message["request_id"]
		)
		return
	if not run_session.draft_bill_system.add_available_policy_by_name(run_session.context, display_name):
		_append_mutation_error(
			messages,
			{
				"code": "unavailable_policy",
				"message": "Policy is unavailable or already in the draft.",
			},
			message["request_id"]
		)
		return
	_finish_draft_mutation(messages, message["request_id"])


func _handle_draft_policy_remove(message: Dictionary, messages: Array[Dictionary]) -> void:
	var index := _protocol.read_int(message["payload"], "draft_index")
	if not index["ok"]:
		_append_mutation_error(messages, index["error"], message["request_id"])
		return
	if not run_session.draft_bill_system.remove_policy(run_session.state, index["value"]):
		_append_mutation_error(
			messages,
			{"code": "invalid_draft_index", "message": "Draft policy index is invalid."},
			message["request_id"]
		)
		return
	_finish_draft_mutation(messages, message["request_id"])


func _handle_draft_title(message: Dictionary, messages: Array[Dictionary]) -> void:
	var title: Variant = message["payload"].get("title")
	if not title is String:
		_append_mutation_error(
			messages,
			{"code": "invalid_field", "message": "payload.title must be a string."},
			message["request_id"]
		)
		return
	run_session.state.draft_bill.title = title
	_finish_draft_mutation(messages, message["request_id"])


func _handle_bill_edit(message: Dictionary, messages: Array[Dictionary]) -> void:
	var index := _protocol.read_int(message["payload"], "saved_bill_index")
	if not index["ok"]:
		_append_mutation_error(messages, index["error"], message["request_id"])
		return
	if not run_session.edit_saved_bill(index["value"]):
		_append_mutation_error(
			messages,
			{"code": "invalid_saved_bill_index", "message": "Saved bill index is invalid."},
			message["request_id"]
		)
		return
	_finish_draft_mutation(messages, message["request_id"])


func _handle_bill_submit(message: Dictionary, messages: Array[Dictionary]) -> void:
	var result := run_session.submit_draft()
	if not result.submitted:
		_append_mutation_error(
			messages,
			{"code": "draft_not_ready", "message": "The current draft cannot be submitted."},
			message["request_id"]
		)
		return
	var vote_payload := _serializer.vote_result(result, run_session.state)
	_advance_month_and_refresh_mode()
	state_version += 1
	var payload := {
		"state_version": state_version,
		"submitted": result.submitted,
		"passed": result.passed,
		"vote": vote_payload,
		"saved_bills": _serialize_bills(),
		"proposal_hand": _serialize_hand(),
		"draft_bill": _serializer.bill(run_session.state.draft_bill),
		"editing_saved_bill_index": _editing_index(),
		"active_bill": _serializer.active_bill(run_session.state.active_bill),
		"status": _serializer.game_status(run_session),
		"draft_preview": _serializer.draft_preview(run_session),
		"pending_dialogue": _serializer.pending_dialogue(run_session.state),
		"ui_mode": ui_mode,
		"world_scene": world_scene,
	}
	messages.append(_envelope("bill.result", payload))
	messages.append(_full_state(message["request_id"]))


func _handle_proposal_merge(message: Dictionary, messages: Array[Dictionary]) -> void:
	var payload: Dictionary = message["payload"]
	var raw_indices: Variant = payload.get("hand_indices")
	if not raw_indices is Array or raw_indices.size() != 3:
		_append_mutation_error(
			messages,
			{"code": "invalid_merge_refs", "message": "Merge requires exactly three hand indices."},
			message["request_id"]
		)
		return
	var hand_indices: Array[int] = []
	for raw_index in raw_indices:
		var parsed_index: Variant = _int_value(raw_index)
		if parsed_index == null:
			_append_mutation_error(
				messages,
				{"code": "invalid_merge_refs", "message": "Merge indices must be integers."},
				message["request_id"]
			)
			return
		hand_indices.append(parsed_index)
	var negative_index := _protocol.read_int(payload, "negative_base_index")
	if not negative_index["ok"]:
		_append_mutation_error(messages, negative_index["error"], message["request_id"])
		return
	var selected_index: Variant = null
	if payload.get("selected_positive_index") != null:
		selected_index = _int_value(payload.get("selected_positive_index"))
		if selected_index == null:
			_append_mutation_error(
				messages,
				{"code": "invalid_merge_refs", "message": "Positive index must be an integer or null."},
				message["request_id"]
			)
			return
	var state := run_session.state
	var all_indices: Array = hand_indices.duplicate()
	all_indices.append(negative_index["value"])
	if selected_index != null:
		all_indices.append(selected_index)
	for index in all_indices:
		if index < 0 or index >= state.proposal_hand.size():
			_append_mutation_error(
				messages,
				{"code": "invalid_hand_index", "message": "A merge hand index is stale."},
				message["request_id"]
			)
			return
	var mothers: Array[ProposalInstance] = []
	for index in hand_indices:
		mothers.append(state.proposal_hand[index])
	var negative_base: ProposalInstance = state.proposal_hand[negative_index["value"]]
	var selected_positive: ProposalInstance = null if selected_index == null else state.proposal_hand[selected_index]
	var merged := run_session.proposal_system.merge_three(
		state, mothers, negative_base, run_session.balance, selected_positive
	)
	if merged == null:
		_append_mutation_error(
			messages,
			{"code": "merge_rejected", "message": "Proposal merge validation failed."},
			message["request_id"]
		)
		return
	state_version += 1
	var result := {"kind": "merge", "proposal": _serializer.proposal(merged)}
	messages.append(_envelope("proposal.sync", _proposal_sync(result), message["request_id"]))


func _handle_bonus_resolve(message: Dictionary, messages: Array[Dictionary]) -> void:
	var payload: Dictionary = message["payload"]
	var index := _protocol.read_int(payload, "hand_index")
	var accept_trait: Variant = payload.get("accept_trait")
	if not index["ok"]:
		_append_mutation_error(messages, index["error"], message["request_id"])
		return
	if not accept_trait is bool:
		_append_mutation_error(
			messages,
			{"code": "invalid_field", "message": "payload.accept_trait must be boolean."},
			message["request_id"]
		)
		return
	if index["value"] < 0 or index["value"] >= run_session.state.proposal_hand.size():
		_append_mutation_error(
			messages,
			{"code": "invalid_hand_index", "message": "Proposal hand index is invalid."},
			message["request_id"]
		)
		return
	var current := run_session.state.proposal_hand[index["value"]]
	var resolved := (
		run_session.accept_proposal_trait(current)
		if accept_trait
		else run_session.convert_proposal_trait_to_donation(current)
	)
	if not resolved:
		_append_mutation_error(
			messages,
			{"code": "bonus_choice_rejected", "message": "Proposal has no pending bonus choice."},
			message["request_id"]
		)
		return
	state_version += 1
	_refresh_dialogue_mode()
	var result := {
		"kind": "bonus_choice",
		"hand_index": index["value"],
		"accept_trait": accept_trait,
		"proposal": _serializer.proposal(current),
	}
	messages.append(_envelope("proposal.sync", _proposal_sync(result), message["request_id"]))


func _handle_constitution_revise(message: Dictionary, messages: Array[Dictionary]) -> void:
	var index := _protocol.read_int(message["payload"], "article_index")
	if not index["ok"]:
		_append_mutation_error(messages, index["error"], message["request_id"])
		return
	if index["value"] < 0 or index["value"] >= run_session.constitution_articles.size():
		_append_mutation_error(
			messages,
			{"code": "invalid_article_index", "message": "Constitution article index is invalid."},
			message["request_id"]
		)
		return
	if not run_session.revise_constitution(run_session.constitution_articles[index["value"]]):
		_append_mutation_error(
			messages,
			{"code": "revision_rejected", "message": "Constitution revision is not eligible."},
			message["request_id"]
		)
		return
	_advance_month_and_refresh_mode()
	state_version += 1
	messages.append(_full_state(message["request_id"]))


func _handle_constitution_column_unlock(message: Dictionary, messages: Array[Dictionary]) -> void:
	if (
		run_session.constitution_board == null
		or run_session.state.run_phase != RunState.RunPhase.RUNNING
		or run_session.state.month != 0
	):
		_append_mutation_error(
			messages,
			{"code": "unlock_unavailable", "message": "Constitution columns can only be unlocked in month zero."},
			message["request_id"]
		)
		return
	var index := _protocol.read_int(message["payload"], "column_index")
	if not index["ok"]:
		_append_mutation_error(messages, index["error"], message["request_id"])
		return
	if index["value"] < 0 or index["value"] >= run_session.constitution_board.columns.size():
		_append_mutation_error(
			messages,
			{"code": "invalid_column_index", "message": "Constitution column index is invalid."},
			message["request_id"]
		)
		return
	var column := run_session.constitution_board.columns[index["value"]]
	if not run_session.unlock_constitution_column(column):
		_append_mutation_error(
			messages,
			{"code": "unlock_rejected", "message": "Constitution column cannot be unlocked yet."},
			message["request_id"]
		)
		return
	state_version += 1
	messages.append(_full_state(message["request_id"]))


func _handle_term_next(message: Dictionary, messages: Array[Dictionary]) -> void:
	if not run_session.start_next_term():
		_append_mutation_error(
			messages,
			{"code": "term_not_ended", "message": "The current term has not ended."},
			message["request_id"]
		)
		return
	state_version += 1
	set_ui_mode("constitution", false)
	messages.append(_full_state(message["request_id"]))


func _advance_month_and_refresh_mode() -> bool:
	if not run_session.advance_month():
		return false
	if run_session.state.run_phase == RunState.RunPhase.TERM_ENDED:
		return true
	if run_session.state.month == 0:
		set_ui_mode("constitution", false)
		return true
	_refresh_dialogue_mode()
	if ui_mode != "dialogue":
		set_ui_mode("office", false)
	return true


func _finish_draft_mutation(messages: Array[Dictionary], request_id: Variant) -> void:
	state_version += 1
	var payload := {
		"state_version": state_version,
		"proposal_hand": _serialize_hand(),
		"draft_bill": _serializer.bill(run_session.state.draft_bill),
		"editing_saved_bill_index": _editing_index(),
		"draft_preview": _serializer.draft_preview(run_session),
	}
	messages.append(_envelope("draft.sync", payload, request_id))


func _proposal_sync(result: Dictionary) -> Dictionary:
	return {
		"state_version": state_version,
		"proposal_hand": _serialize_hand(),
		"result": result,
		"political_donation_pool": run_session.state.political_donation_pool,
		"pending_dialogue": _serializer.pending_dialogue(run_session.state),
		"ui_mode": ui_mode,
		"world_scene": world_scene,
	}


func _append_mutation_error(
	messages: Array[Dictionary], error_value: Dictionary, request_id: Variant
) -> void:
	messages.append(_error(error_value["code"], error_value["message"], request_id, true))
	messages.append(_full_state(request_id))


func _refresh_dialogue_mode() -> void:
	if run_session == null or run_session.state == null:
		return
	if run_session.state.run_phase == RunState.RunPhase.TERM_ENDED:
		return
	var has_pending := _serializer.pending_dialogue(run_session.state) != null
	if has_pending:
		set_ui_mode("dialogue", false)
	elif ui_mode == "dialogue":
		set_ui_mode("office", false)


func _full_state(request_id: Variant = null) -> Dictionary:
	return _envelope(
		"state.full",
		_serializer.full_state(run_session, ui_mode, world_scene, state_version),
		request_id
	)


func _error(
	code: String,
	detail: String,
	request_id: Variant = null,
	recover_full_state: bool = false
) -> Dictionary:
	return _envelope(
		"command.error",
		{
			"code": code,
			"message": detail,
			"state_version": state_version,
			"recover_full_state": recover_full_state,
		},
		request_id
	)


func _envelope(message_type: String, payload: Dictionary, request_id: Variant = null) -> Dictionary:
	var message := {"type": message_type, "payload": payload}
	if request_id != null:
		message["request_id"] = request_id
	return message


func _send_all(messages: Array[Dictionary]) -> void:
	for message in messages:
		_send_message(message)


func _send_message(message: Dictionary) -> void:
	outgoing_message.emit(message)
	if cef_texture != null and cef_texture.has_method("send_ipc_message"):
		cef_texture.call("send_ipc_message", JSON.stringify(message))


func _serialize_hand() -> Array:
	var result: Array = []
	for current in run_session.state.proposal_hand:
		result.append(_serializer.proposal(current))
	return result


func _serialize_bills() -> Array:
	var result: Array = []
	for current in run_session.state.saved_bills:
		result.append(_serializer.bill(current))
	return result


func _editing_index() -> Variant:
	return (
		null
		if run_session.state.editing_saved_bill_index == RunState.NEW_BILL_INDEX
		else run_session.state.editing_saved_bill_index
	)


func _int_value(value: Variant) -> Variant:
	if value is int:
		return value
	if value is float and is_equal_approx(value, roundf(value)):
		return int(value)
	return null


func _is_region(region: Dictionary) -> bool:
	for key in ["x", "y", "width", "height"]:
		if not region.has(key) or not region[key] is float and not region[key] is int:
			return false
	var x := float(region["x"])
	var y := float(region["y"])
	var width := float(region["width"])
	var height := float(region["height"])
	return (
		x >= 0.0
		and y >= 0.0
		and width >= 0.0
		and height >= 0.0
		and x + width <= 1.000001
		and y + height <= 1.000001
	)
