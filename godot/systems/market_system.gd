extends RefCounted
class_name MarketSystem


func settle_month(context: RunContext) -> void:
	var bill := context.state.active_bill

	if bill != null:
		_advance_proposal_digestion(bill)
		var anchor := context.proposal_system.calculate_digested_anchor(bill)
		_move_market_toward_anchor(
			context.state.metrics, anchor, context.balance, context.random_system
		)


func _advance_proposal_digestion(bill: ActiveBillState) -> void:
	for active_proposal in bill.proposals:
		active_proposal.advance_month()


func _move_market_toward_anchor(
	current: MetricValues,
	anchor: MetricValues,
	balance: GameBalanceDefinition,
	random_system: RandomSystem
) -> void:
	current.tax = _move_value(current.tax, anchor.tax, balance, random_system)
	current.price = _move_value(current.price, anchor.price, balance, random_system)
	current.wage = _move_value(current.wage, anchor.wage, balance, random_system)
	current.employment = _move_value(current.employment, anchor.employment, balance, random_system)
	current.trade = _move_value(current.trade, anchor.trade, balance, random_system)


func _move_value(
	current: int,
	target: int,
	balance: GameBalanceDefinition,
	random_system: RandomSystem
) -> int:
	var gap := target - current
	if gap == 0:
		return target

	var base_change := float(gap) * balance.market_response_ratio
	var noise := random_system.random_float(-balance.market_noise_ratio, balance.market_noise_ratio)
	var actual_change := base_change * (1.0 + noise)
	var rounded_change := roundi(actual_change)

	if rounded_change == 0:
		if actual_change > 0.0:
			rounded_change = 1
		elif actual_change < 0.0:
			rounded_change = -1
		else:
			return current

	return current + rounded_change
