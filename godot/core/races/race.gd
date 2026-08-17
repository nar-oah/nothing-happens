extends RefCounted
class_name Race

const ZHUSHUI: StringName = &"zhushui"
const NANKE: StringName = &"nanke"
const BIYI: StringName = &"biyi"
const YANO: StringName = &"yano"
const PEACH_BLOSSOM: StringName = &"peach_blossom"
const HUMAN: StringName = &"human"


static func all_ids() -> Array[StringName]:
	return [
		ZHUSHUI,
		NANKE,
		BIYI,
		YANO,
		PEACH_BLOSSOM,
		HUMAN,
	]


static func variable_ids() -> Array[StringName]:
	return [
		NANKE,
		BIYI,
		YANO,
		PEACH_BLOSSOM,
		HUMAN,
	]


static func is_variable(race_id: StringName) -> bool:
	return race_id != ZHUSHUI
