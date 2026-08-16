extends RefCounted
class_name MetricValues

var tax: float = 0.0
var price: float = 0.0
var wage: float = 0.0
var employment: float = 0.0
var trade: float = 0.0


func get_value(metric: Metric.Id) -> float:
	match metric:
		Metric.Id.TAX:
			return tax
		Metric.Id.PRICE:
			return price
		Metric.Id.WAGE:
			return wage
		Metric.Id.EMPLOYMENT:
			return employment
		Metric.Id.TRADE:
			return trade
		_:
			push_error("Unknown metric: %s" % metric)
			return 0.0


func set_value(metric: Metric.Id, value: float) -> void:
	match metric:
		Metric.Id.TAX:
			tax = value
		Metric.Id.PRICE:
			price = value
		Metric.Id.WAGE:
			wage = value
		Metric.Id.EMPLOYMENT:
			employment = value
		Metric.Id.TRADE:
			trade = value
		_:
			push_error("Unknown metric: %s" % metric)


func apply_delta(delta: MetricVector) -> void:
	tax += delta.tax
	price += delta.price
	wage += delta.wage
	employment += delta.employment
	trade += delta.trade


func copy() -> MetricValues:
	var result := MetricValues.new()

	result.tax = tax
	result.price = price
	result.wage = wage
	result.employment = employment
	result.trade = trade

	return result
