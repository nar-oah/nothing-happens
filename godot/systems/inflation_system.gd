extends RefCounted
class_name InflationSystem

const MAGNITUDE_MIN: int = 8
const MAGNITUDE_MAX: int = 12
const DEV_GROWTH_PER_YEAR: float = 0.10


func get_era_multiplier(year: int) -> float:
	var era_step := maxi(year - 1, 0)
	return 1.0 + float(era_step) * DEV_GROWTH_PER_YEAR


func generate_negative_effect(
	definition: ProposalDefinition, year: int, random_system: RandomSystem
) -> MetricVector:
	var result := MetricVector.new()
	var multiplier := get_era_multiplier(year)
	for metric in definition.get_negative_slots():
		var base_magnitude := random_system.random_int(MAGNITUDE_MIN, MAGNITUDE_MAX)
		var magnitude := maxi(1, roundi(float(base_magnitude) * multiplier))
		var signed_value := magnitude * Metric.proposal_negative_sign(metric)
		result.set_value(metric, signed_value)
	return result
