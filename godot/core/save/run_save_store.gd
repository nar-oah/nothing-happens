extends RefCounted
class_name RunSaveStore

const AUTO_SLOT := "auto"


static func list_saves(directory: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var files := DirAccess.get_files_at(directory) if DirAccess.dir_exists_absolute(directory) else PackedStringArray()
	files.sort()
	var automatic: Dictionary = {}
	for file in files:
		if not file.ends_with(".json"):
			continue
		var slot_id := file.trim_suffix(".json")
		var saved := read_save(directory, slot_id)
		if not saved["ok"]:
			continue
		var slot: Dictionary = saved["slot"]
		if slot["automatic"]:
			automatic = slot
		else:
			result.append(slot)
	if not automatic.is_empty():
		result.append(automatic)
	return result


static func create_manual(session: RunSession) -> Dictionary:
	var index := 1
	var slot_id := "manual_%06d" % index
	while FileAccess.file_exists(session.save_directory.path_join(slot_id + ".json")):
		index += 1
		slot_id = "manual_%06d" % index
	return write_save(session, slot_id)


static func overwrite_manual(session: RunSession, slot_id: String) -> Dictionary:
	if not _valid_slot_id(slot_id) or slot_id == AUTO_SLOT:
		return _failure("invalid_save_slot", "只能覆盖指定的手动存档。")
	if not FileAccess.file_exists(session.save_directory.path_join(slot_id + ".json")):
		return _failure("save_not_found", "手动存档不存在。")
	return write_save(session, slot_id)


static func write_save(session: RunSession, slot_id: String) -> Dictionary:
	if session.state == null or not _valid_slot_id(slot_id):
		return _failure("save_unavailable", "当前状态无法保存。")
	var snapshot := RunSnapshot.capture(session)
	if snapshot.is_empty():
		return _failure("snapshot_failed", "无法保存当前状态，请检查资源 UID。")
	var directory := session.save_directory
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return _failure("save_write_failed", "无法创建存档目录。")
	var slot := {
		"slot_id": slot_id,
		"automatic": slot_id == AUTO_SLOT,
		"term": session.state.term,
		"year": session.state.year,
		"month": session.state.month,
		"saved_at": Time.get_datetime_string_from_system(true),
	}
	var data := {"version": RunSnapshot.VERSION, "slot": slot, "snapshot": snapshot}
	var path := directory.path_join(slot_id + ".json")
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return _failure("save_write_failed", "无法写入存档。")
	file.store_string(JSON.stringify(data, "", true, true))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(temporary_path, path) != OK:
		return _failure("save_write_failed", "无法完成存档写入，原存档已保留。")
	return {"ok": true, "slot_id": slot_id}


static func read_save(directory: String, slot_id: String) -> Dictionary:
	if not _valid_slot_id(slot_id):
		return _failure("invalid_save_slot", "存档编号无效。")
	var file := FileAccess.open(directory.path_join(slot_id + ".json"), FileAccess.READ)
	if file == null:
		return _failure("save_not_found", "无法读取指定存档。")
	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	file.close()
	if error != OK or not parser.data is Dictionary:
		return _failure("invalid_save", "存档文件损坏。")
	var data: Dictionary = parser.data
	if data.get("version") != RunSnapshot.VERSION:
		return _failure("unsupported_save_version", "不支持此存档版本。")
	if not data.get("snapshot") is Dictionary or not data.get("slot") is Dictionary:
		return _failure("invalid_save", "存档缺少状态数据。")
	var slot: Dictionary = data["slot"]
	if slot.get("slot_id") != slot_id or slot.get("automatic") != (slot_id == AUTO_SLOT) or not slot.get("saved_at") is String:
		return _failure("invalid_save", "存档信息无效。")
	for key in ["term", "year", "month"]:
		var value: Variant = slot.get(key)
		if not (value is int or value is float) or not is_finite(value) or value != floor(value):
			return _failure("invalid_save", "存档日期无效。")
		slot[key] = int(value)
	if slot["term"] < 1 or slot["year"] < 1 or slot["month"] < 0 or slot["month"] > 12:
		return _failure("invalid_save", "存档日期无效。")
	return {"ok": true, "slot": slot, "snapshot": data["snapshot"]}


static func _valid_slot_id(slot_id: String) -> bool:
	if slot_id == AUTO_SLOT:
		return true
	var number := slot_id.trim_prefix("manual_")
	return slot_id.begins_with("manual_") and not number.is_empty() and number.is_valid_int() and number.to_int() > 0 and number == str(number.to_int()).pad_zeros(number.length())


static func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "error": {"code": code, "message": message}}
