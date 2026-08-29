extends RefCounted
class_name MetricVector

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


func add(other: MetricVector) -> void:
	tax += other.tax
	consumption += other.consumption
	production += other.production
	employment += other.employment
	investment += other.investment


func copy() -> MetricVector:
	var result := MetricVector.new()

	result.tax = tax
	result.consumption = consumption
	result.production = production
	result.employment = employment
	result.investment = investment

	return result


func add_value(metric: Metric.Id, delta: int) -> void:
	set_value(metric, get_value(metric) + delta)


func non_zero_metrics() -> Array[Metric.Id]:
	var result: Array[Metric.Id] = []
	for metric in Metric.all_ids():
		if get_value(metric) != 0:
			result.append(metric)
	return result


func is_zero() -> bool:
	return non_zero_metrics().is_empty()
