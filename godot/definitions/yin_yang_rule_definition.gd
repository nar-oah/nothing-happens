extends Resource

@export_group("阴项（未勾选即为阳项）")
@export var yin_tax: bool = true
@export var yin_consumption: bool = true
@export var yin_production: bool = false
@export var yin_employment: bool = false
@export var yin_investment: bool = false


func is_yin_metric(metric: Metric.Id) -> bool:
	match metric:
		Metric.Id.TAX:
			return yin_tax
		Metric.Id.CONSUMPTION:
			return yin_consumption
		Metric.Id.PRODUCTION:
			return yin_production
		Metric.Id.EMPLOYMENT:
			return yin_employment
		Metric.Id.INVESTMENT:
			return yin_investment
	return false


func is_yang_metric(metric: Metric.Id) -> bool:
	return not is_yin_metric(metric)
