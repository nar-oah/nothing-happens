extends Resource
class_name ConstitutionSeatCondition

@export var race: RaceDefinition
@export var interest_group: InterestGroupDefinition
@export_range(0.0, 1.0, 0.01) var required_rate: float = 0.0


func is_met(context) -> bool:
	if context == null or context.state == null:
		return false
	if race == null and interest_group == null:
		return false
	var eligible_count := 0
	var matching_count := 0
	for seat in context.state.seats:
		if race != null and interest_group == null:
			eligible_count += 1
			matching_count += 1 if seat.race == race else 0
		elif race == null:
			if seat.base_group == null and seat.actual_group == null:
				continue
			eligible_count += 1
			matching_count += 1 if seat.actual_group == interest_group else 0
		elif seat.race == race:
			eligible_count += 1
			matching_count += 1 if seat.actual_group == interest_group else 0
	if eligible_count == 0:
		return required_rate <= 0.0
	return float(matching_count) / float(eligible_count) >= required_rate
