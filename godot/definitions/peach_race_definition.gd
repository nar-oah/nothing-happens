extends RaceDefinition
class_name PeachRaceDefinition

@export_range(1, 999, 1) var max_elder_weight: int = 1


func get_vote_weight(seat_index: int) -> int:
	var weight := maxi(max_elder_weight, 1)
	for _index in range(maxi(seat_index, 0)):
		weight = maxi(ceili(float(weight) / 2.0), 1)
	return weight


func has_support_majority(support_weight: int, present_weight: int) -> bool:
	return present_weight > 0 and support_weight * 2 > present_weight
