extends RefCounted
class_name UiProtocol

const COMMAND_TYPES: Array[String] = [
	"ui.ready",
	"ui.input_regions",
	"ui.mode.set",
	"ui.newspaper.close",
	"draft.proposal.add",
	"draft.proposal.remove",
	"draft.policy.add",
	"draft.policy.remove",
	"draft.title.set",
	"bill.new",
	"bill.edit",
	"bill.submit",
	"proposal.merge",
	"proposal.bonus.resolve",
	"month.advance",
	"constitution.revise",
]

const GAMEPLAY_MUTATIONS: Array[String] = [
	"draft.proposal.add",
	"draft.proposal.remove",
	"draft.policy.add",
	"draft.policy.remove",
	"draft.title.set",
	"bill.new",
	"bill.edit",
	"bill.submit",
	"proposal.merge",
	"proposal.bonus.resolve",
	"month.advance",
	"constitution.revise",
]

const UI_MODES: Array[String] = ["office", "dialogue", "parliament", "constitution"]


func decode(raw_message: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(raw_message) != OK:
		return _failure("malformed_json", "IPC message must be valid JSON.")
	var decoded: Variant = JSON.parse_string(raw_message)
	if not decoded is Dictionary:
		return _failure("malformed_json", "IPC message must be a JSON object.")
	var message: Dictionary = decoded
	var message_type: Variant = message.get("type")
	if not message_type is String or message_type.is_empty():
		return _failure("missing_type", "IPC message requires a non-empty type.")
	if message_type not in COMMAND_TYPES:
		return _failure("unknown_type", "Unknown IPC message type: %s" % message_type)
	var request_id: Variant = message.get("request_id")
	if request_id != null and not request_id is String:
		return _failure("invalid_request_id", "request_id must be a string.")
	if not message.has("payload"):
		return _failure("missing_payload", "IPC message requires a payload object.")
	var payload: Variant = message["payload"]
	if not payload is Dictionary:
		return _failure("invalid_payload", "payload must be an object.")
	return {
		"ok": true,
		"message": {
			"type": message_type,
			"request_id": request_id,
			"payload": payload,
		},
	}


func encode(message_type: String, payload: Dictionary, request_id: Variant = null) -> String:
	var message := {"type": message_type, "payload": payload}
	if request_id != null:
		message["request_id"] = request_id
	return JSON.stringify(message)


func is_gameplay_mutation(message_type: String) -> bool:
	return message_type in GAMEPLAY_MUTATIONS


func read_int(payload: Dictionary, key: String) -> Dictionary:
	if not payload.has(key):
		return _failure("missing_field", "payload.%s is required." % key)
	var value: Variant = payload[key]
	if value is int:
		return {"ok": true, "value": value}
	if value is float and is_equal_approx(value, roundf(value)):
		return {"ok": true, "value": int(value)}
	return _failure("invalid_field", "payload.%s must be an integer." % key)


func _failure(code: String, detail: String) -> Dictionary:
	return {"ok": false, "error": {"code": code, "message": detail}}
