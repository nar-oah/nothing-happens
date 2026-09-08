extends NewspaperFrontDefinition
class_name CollapseThresholdNewspaperFrontDefinition

@export_range(0.0, 1.0, 0.01) var collapse_ratio: float = 0.5


func resolve(
	state: RunState,
	balance: GameBalanceDefinition,
	previous_collapse: int
) -> Variant:
	if balance == null or balance.max_collapse <= 0:
		return null
	var threshold := ceili(float(balance.max_collapse) * collapse_ratio)
	if previous_collapse >= threshold or state.collapse_level < threshold:
		return null
	return make_front()
