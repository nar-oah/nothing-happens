extends RefCounted
class_name InflationSystem

const MAGNITUDE_MIN: int = 8
const MAGNITUDE_MAX: int = 12


func get_era_multiplier(year: int, balance: GameBalanceDefinition) -> float:
	var era_step := maxi(year - 1, 0)
	return 1.0 + float(era_step) * balance.era_growth_per_year


func generate_negative_effect(
	definition: ProposalDefinition,
	year: int,
	balance: GameBalanceDefinition,
	random_system: RandomSystem
) -> MetricVector:
	var result := MetricVector.new()
	var multiplier := get_era_multiplier(year, balance)
	for metric in definition.get_negative_slots():
		var base_magnitude := random_system.random_int(MAGNITUDE_MIN, MAGNITUDE_MAX)
		var magnitude := maxi(1, roundi(float(base_magnitude) * multiplier))
		var signed_value := magnitude * Metric.proposal_negative_sign(metric)
		result.set_value(metric, signed_value)
	return result


func initialize_metrics(values: MetricValues, balance: GameBalanceDefinition) -> void:
	for metric in Metric.all_ids():
		values.set_value(metric, balance.initial_metric_value)


func get_expectation_target(direction: int, year: int, balance: GameBalanceDefinition) -> int:
	if direction == MetricStanceDefinition.Direction.NONE:
		return balance.initial_metric_value
	var multiplier := get_era_multiplier(year, balance)
	var distance := roundi(float(balance.initial_metric_value) * (multiplier - 1.0))
	return balance.initial_metric_value + direction * distance
