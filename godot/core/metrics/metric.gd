extends RefCounted
class_name Metric

enum Id {
	TAX,
	PRICE,
	WAGE,
	EMPLOYMENT,
	TRADE,
}


static func display_name(metric: Id) -> String:
	match metric:
		Id.TAX:
			return "税课"
		Id.PRICE:
			return "物价"
		Id.WAGE:
			return "工钱"
		Id.EMPLOYMENT:
			return "用工"
		Id.TRADE:
			return "商贸"
		_:
			return "未知指标"


static func proposal_negative_sign(metric: Id) -> int:
	match metric:
		Id.TAX:
			return 1
		Id.PRICE:
			return 1
		Id.WAGE:
			return -1
		Id.EMPLOYMENT:
			return -1
		Id.TRADE:
			return -1
		_:
			push_error("Unknown metric: %s" % metric)
			return 0


static func favorable_sign(metric: Id) -> int:
	return -proposal_negative_sign(metric)


static func all_ids() -> Array[Id]:
	return [Id.TAX, Id.PRICE, Id.WAGE, Id.EMPLOYMENT, Id.TRADE]
