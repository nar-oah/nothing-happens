extends RefCounted
class_name InflationSystem


func get_proposal_magnitude_multiplier(year: int, balance: GameBalanceDefinition) -> float:
	return pow(
		1.0 + balance.proposal_magnitude_growth_per_year,
		maxi(year - 1, 0)
	)


func generate_negative_effect(
	source_group: InterestGroupDefinition,
	year: int,
	balance: GameBalanceDefinition,
	random_system: RandomSystem
) -> MetricVector:
	var result := MetricVector.new()
	if source_group == null:
		return result
	var multiplier := get_proposal_magnitude_multiplier(year, balance)
	for metric in source_group.get_stance_metrics():
		var base_magnitude := random_system.random_int(
			balance.proposal_negative_magnitude_min,
			balance.proposal_negative_magnitude_max
		)
		var magnitude := roundi(float(base_magnitude) * multiplier)
		result.set_value(metric, -magnitude)
	return result


func initialize_metrics(values: MetricValues, balance: GameBalanceDefinition) -> void:
	for metric in Metric.all_ids():
		values.set_value(metric, balance.initial_metric_value)
