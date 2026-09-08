extends NewspaperFrontDefinition
class_name TermStartNewspaperFrontDefinition

@export_range(1, 999, 1) var target_year: int = 1
@export_range(1, 12, 1) var target_month: int = 1


func resolve(
	state: RunState,
	_balance: GameBalanceDefinition,
	_previous_collapse: int
) -> Variant:
	if state.year != target_year or state.month != target_month:
		return null
	return make_front(_t(title) % state.term, _t(content))
