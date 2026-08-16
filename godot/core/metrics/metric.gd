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
