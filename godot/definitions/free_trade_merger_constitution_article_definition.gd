extends HumanConstitutionArticleDefinition
class_name FreeTradeMergerConstitutionArticleDefinition

@export_range(0.0, 1.0, 0.01) var strong_group_rate: float = 0.50
@export_range(0.0, 1.0, 0.01) var weak_group_rate: float = 0.05


func on_deactivate(context) -> void:
	context.state.constitution.group_mergers.clear()


func on_year_settlement(context) -> void:
	var counts: Dictionary[InterestGroupDefinition, int] = {}
	var influenced_seat_count := 0
	for seat in context.state.seats:
		if seat.actual_group == null:
			continue
		counts[seat.actual_group] = int(counts.get(seat.actual_group, 0)) + 1
		influenced_seat_count += 1
	if influenced_seat_count == 0:
		return
	var ordered_groups: Array[InterestGroupDefinition] = []
	for group in context.interest_groups:
		if group != null and counts.has(group):
			ordered_groups.append(group)
	for seat in context.state.seats:
		if seat.actual_group != null and seat.actual_group not in ordered_groups:
			ordered_groups.append(seat.actual_group)
	var strongest: InterestGroupDefinition
	var strongest_rate := strong_group_rate
	for group in ordered_groups:
		var rate := float(counts.get(group, 0)) / float(influenced_seat_count)
		if rate > strongest_rate:
			strongest = group
			strongest_rate = rate
	if strongest == null:
		return
	for group in ordered_groups:
		if group == strongest:
			continue
		var rate := float(counts.get(group, 0)) / float(influenced_seat_count)
		if rate >= weak_group_rate:
			continue
		context.state.constitution.group_mergers[group] = strongest
		for seat in context.state.seats:
			if seat.actual_group == group:
				seat.actual_group = strongest
