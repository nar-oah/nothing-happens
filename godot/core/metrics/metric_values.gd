extends RefCounted
class_name MetricValues

var tax: int = 0
var consumption: int = 0
var production: int = 0
var employment: int = 0
var investment: int = 0


func get_value(metric: Metric.Id) -> int:
	match metric:
		Metric.Id.TAX:
			return tax
		Metric.Id.CONSUMPTION:
			return consumption
		Metric.Id.PRODUCTION:
			return production
		Metric.Id.EMPLOYMENT:
			return employment
		Metric.Id.INVESTMENT:
			return investment
		_:
			push_error("Unknown metric: %s" % metric)
			return 0


func set_value(metric: Metric.Id, value: int) -> void:
	match metric:
		Metric.Id.TAX:
			tax = value
		Metric.Id.CONSUMPTION:
			consumption = value
		Metric.Id.PRODUCTION:
			production = value
		Metric.Id.EMPLOYMENT:
			employment = value
		Metric.Id.INVESTMENT:
			investment = value
		_:
			push_error("Unknown metric: %s" % metric)


func apply_delta(delta: MetricVector) -> void:
	tax += delta.tax
	consumption += delta.consumption
	production += delta.production
	employment += delta.employment
	investment += delta.investment


func copy() -> MetricValues:
	var result := MetricValues.new()
	result.tax = tax
	result.consumption = consumption
	result.production = production
	result.employment = employment
	result.investment = investment
	return result
