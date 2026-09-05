extends RefCounted
class_name RunSnapshot

const VERSION: int = 1
const STATE_TYPES: Dictionary = {
	"RunState": preload("res://core/run/run_state.gd"),
	"MetaProgressionState": preload("res://states/meta_progression_state.gd"),
	"MetricValues": preload("res://core/metrics/metric_values.gd"),
	"MetricVector": preload("res://core/metrics/metric_vector.gd"),
	"ProposalInstance": preload("res://states/proposal_instance.gd"),
	"ActiveProposalState": preload("res://states/active_proposal_state.gd"),
	"ActiveBillState": preload("res://states/active_bill_state.gd"),
	"DraftBillState": preload("res://states/draft_bill_state.gd"),
	"SavedBillState": preload("res://states/saved_bill_state.gd"),
	"PolicyState": preload("res://states/policy_state.gd"),
	"EventState": preload("res://states/event_state.gd"),
	"OfficeVisitState": preload("res://states/office_visit_state.gd"),
	"SeatState": preload("res://states/seat_state.gd"),
	"RaceState": preload("res://states/race_state.gd"),
	"ConstitutionState": preload("res://states/constitution_state.gd"),
	"InterestGroupDefinition": preload("res://definitions/interest_group_definition.gd"),
}
const SESSION_FIELDS: Array[String] = [
	"term_report", "_last_awarded_term", "_previous_newspaper_collapse",
]

var _objects: Array = []
var _object_ids: Dictionary = {}
var _error: String = ""


static func capture(session: RunSession) -> Dictionary:
	if session.state == null or session.random_system == null:
		return {}
	var codec := RunSnapshot.new()
	var session_data: Dictionary = {}
	for field in SESSION_FIELDS:
		session_data[field] = session.get(field)
	var snapshot := {
		"version": VERSION,
		"state": codec._encode(session.state),
		"meta_progression": codec._encode(session.meta_progression),
		"rng_state": str(session.random_system.rng.state),
		"session": codec._encode(session_data),
		"objects": codec._objects,
	}
	if not codec._error.is_empty():
		push_warning(codec._error)
		return {}
	return snapshot


static func decode(snapshot: Dictionary) -> Dictionary:
	var codec := RunSnapshot.new()
	return codec._decode_snapshot(snapshot)


func _encode(value: Variant) -> Variant:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING:
			return value
		TYPE_FLOAT:
			if is_finite(value):
				return value
		TYPE_INT:
			return {"integer": str(value)}
		TYPE_STRING_NAME:
			return {"string_name": str(value)}
		TYPE_ARRAY:
			var items: Array = []
			for item in value:
				items.append(_encode(item))
			return items
		TYPE_DICTIONARY:
			var entries: Array = []
			for key in value:
				entries.append([_encode(key), _encode(value[key])])
			return {"entries": entries}
		TYPE_OBJECT:
			return _encode_object(value)
	_error = "Unsupported snapshot value type: %s" % type_string(typeof(value))
	return null


func _encode_object(value: Object) -> Variant:
	# Seat-local groups are generated state; file-backed definitions remain UID references.
	if value is Resource and not (value is InterestGroupDefinition and value.resource_path.is_empty()):
		var uid := ResourceLoader.get_resource_uid(value.resource_path)
		if uid == ResourceUID.INVALID_ID:
			_error = "Snapshot resource requires a ResourceUID: %s" % value.resource_path
			return null
		return {"uid": ResourceUID.id_to_text(uid)}
	var script: Script = value.get_script()
	var type_name := "" if script == null else str(script.get_global_name())
	if not STATE_TYPES.has(type_name) or script != STATE_TYPES[type_name]:
		_error = "Unsupported snapshot object: %s" % type_name
		return null
	if _object_ids.has(value):
		return {"ref": _object_ids[value]}
	var index := _objects.size()
	_object_ids[value] = index
	var properties: Dictionary = {}
	_objects.append({"type": type_name, "properties": properties})
	for property in _state_properties(value):
		properties[property.name] = _encode(value.get(property.name))
	return {"ref": index}


func _decode_snapshot(snapshot: Dictionary) -> Dictionary:
	if snapshot.get("version") != VERSION:
		return {"ok": false, "error": "Unsupported save version."}
	var rows: Variant = snapshot.get("objects")
	var rng_text: Variant = snapshot.get("rng_state")
	if not rows is Array or not _is_integer_text(rng_text):
		return {"ok": false, "error": "Invalid snapshot header."}
	# Allocate the complete graph before assigning any references.
	for row in rows:
		if not row is Dictionary or not STATE_TYPES.has(row.get("type")):
			return {"ok": false, "error": "Unknown snapshot state type."}
		var script: Script = STATE_TYPES[row.type]
		var instance: Object = script.new(null) if row.type in ["ActiveProposalState", "PolicyState"] else script.new()
		_objects.append(instance)
	for index in range(rows.size()):
		_restore_properties(_objects[index], rows[index].get("properties"))
		if not _error.is_empty():
			return {"ok": false, "error": _error}
	var state: Variant = _decode_value(snapshot.get("state"))
	var meta: Variant = _decode_value(snapshot.get("meta_progression"))
	var session: Variant = _decode_value(snapshot.get("session"))
	if not state is RunState or not meta is MetaProgressionState or not session is Dictionary:
		return {"ok": false, "error": "Invalid snapshot roots."}
	if session.size() != SESSION_FIELDS.size() or not session.get("term_report") is Dictionary:
		return {"ok": false, "error": "Invalid session state."}
	if not session.get("_last_awarded_term") is int or not session.get("_previous_newspaper_collapse") is int:
		return {"ok": false, "error": "Invalid session counters."}
	if not _error.is_empty():
		return {"ok": false, "error": _error}
	return {
		"ok": true,
		"state": state,
		"meta_progression": meta,
		"rng_state": int(rng_text),
		"session": session,
	}


func _restore_properties(instance: Object, encoded: Variant) -> void:
	var properties := _state_properties(instance)
	if not encoded is Dictionary or encoded.size() != properties.size():
		_error = "Invalid snapshot state properties."
		return
	for property in properties:
		if not encoded.has(property.name):
			_error = "Missing snapshot property: %s" % property.name
			return
		var value: Variant = _decode_value(encoded[property.name])
		if not _matches_type(value, property.type, property.class_name):
			_error = "Invalid snapshot property type: %s" % property.name
			return
		var current: Variant = instance.get(property.name)
		if current is Object and value == null:
			_error = "Missing required snapshot object: %s" % property.name
			return
		if current is Array:
			value = _typed_array(current, value)
		elif current is Dictionary:
			value = _typed_dictionary(current, value)
		if not _error.is_empty():
			return
		instance.set(property.name, value)


func _decode_value(encoded: Variant) -> Variant:
	if encoded == null or encoded is bool or encoded is String:
		return encoded
	if encoded is float and is_finite(encoded):
		return encoded
	if encoded is Array:
		var result: Array = []
		for item in encoded:
			result.append(_decode_value(item))
		return result
	if not encoded is Dictionary or encoded.size() != 1:
		_error = "Invalid snapshot value."
		return null
	if encoded.has("integer") and _is_integer_text(encoded.integer):
		return int(encoded.integer)
	if encoded.has("string_name") and encoded.string_name is String:
		return StringName(encoded.string_name)
	if encoded.has("ref"):
		var index: Variant = encoded.ref
		if (index is int or index is float) and is_finite(index) and index == int(index) and index >= 0 and index < _objects.size():
			return _objects[int(index)]
	elif encoded.has("uid") and encoded.uid is String:
		var uid := ResourceUID.text_to_id(encoded.uid)
		if uid != ResourceUID.INVALID_ID and ResourceUID.has_id(uid):
			var resource := ResourceLoader.load(ResourceUID.get_id_path(uid))
			if resource != null:
				return resource
		_error = "Save resource is unavailable: %s" % encoded.uid
		return null
	elif encoded.has("entries") and encoded.entries is Array:
		var result: Dictionary = {}
		for entry in encoded.entries:
			if not entry is Array or entry.size() != 2:
				_error = "Invalid snapshot dictionary entry."
				return null
			var key: Variant = _decode_value(entry[0])
			if result.has(key):
				_error = "Duplicate snapshot dictionary key."
				return null
			result[key] = _decode_value(entry[1])
		return result
	_error = "Invalid snapshot reference."
	return null


func _typed_array(template: Array, values: Array) -> Array:
	var result := template.duplicate()
	result.clear()
	for value in values:
		if template.is_typed() and not _matches_type(value, template.get_typed_builtin(), template.get_typed_class_name(), template.get_typed_script()):
			_error = "Invalid snapshot array element type."
			return result
		result.append(value)
	return result


func _typed_dictionary(template: Dictionary, values: Dictionary) -> Dictionary:
	var result := template.duplicate()
	result.clear()
	for key in values:
		if template.is_typed_key() and not _matches_type(key, template.get_typed_key_builtin(), template.get_typed_key_class_name(), template.get_typed_key_script()):
			_error = "Invalid snapshot dictionary key type."
			return result
		if template.is_typed_value() and not _matches_type(values[key], template.get_typed_value_builtin(), template.get_typed_value_class_name(), template.get_typed_value_script()):
			_error = "Invalid snapshot dictionary value type."
			return result
		result[key] = values[key]
	return result


func _matches_type(value: Variant, expected: int, class_name_value: StringName, script: Variant = null) -> bool:
	if expected == TYPE_NIL:
		return true
	if value == null:
		return expected == TYPE_OBJECT
	if typeof(value) != expected:
		return false
	if expected != TYPE_OBJECT:
		return true
	if script is Script:
		return is_instance_of(value, script)
	if class_name_value.is_empty() or value.is_class(class_name_value):
		return true
	var value_script: Script = value.get_script()
	while value_script != null:
		if value_script.get_global_name() == class_name_value:
			return true
		value_script = value_script.get_base_script()
	return false


func _state_properties(value: Object) -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	for property in value.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			properties.append(property)
	return properties


func _is_integer_text(value: Variant) -> bool:
	return value is String and value.is_valid_int() and str(int(value)) == value
