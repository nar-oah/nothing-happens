extends NewspaperFrontDefinition
class_name NoEventNewspaperFrontDefinition


func resolve(
	state: RunState,
	_balance: GameBalanceDefinition,
	_previous_collapse: int
) -> Variant:
	if not state.month_report_events.is_empty():
		return null
	return make_front()
