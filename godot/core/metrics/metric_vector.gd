extends RefCounted
class_name MetricVector

var tax: int = 0
var price: int = 0
var wage: int = 0
var employment: int = 0
var trade: int = 0


func get_value(metric: Metric.Id) -> int:
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
			return 0


func set_value(metric: Metric.Id, value: int) -> void:
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


func add(other: MetricVector) -> void:
	tax += other.tax
	price += other.price
	wage += other.wage
	employment += other.employment
	trade += other.trade


func copy() -> MetricVector:
	var result := MetricVector.new()

	result.tax = tax
	result.price = price
	result.wage = wage
	result.employment = employment
	result.trade = trade

	return result
