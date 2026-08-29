extends RefCounted
class_name Metric


enum Id {
	TAX,
	CONSUMPTION,
	PRODUCTION,
	EMPLOYMENT,
	INVESTMENT,
}

enum Direction {
	LOWER = -1,
	NONE = 0,
	HIGHER = 1,
}


static func display_name(metric: Id) -> String:
	match metric:
		Id.TAX:
			return "税课"
		Id.CONSUMPTION:
			return "消费"
		Id.PRODUCTION:
			return "生产"
		Id.EMPLOYMENT:
			return "就业"
		Id.INVESTMENT:
			return "投资"
		_:
			return "未知指标"


static func all_ids() -> Array[Id]:
	return [Id.TAX, Id.CONSUMPTION, Id.PRODUCTION, Id.EMPLOYMENT, Id.INVESTMENT]
