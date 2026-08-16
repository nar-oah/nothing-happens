extends RefCounted
class_name MarketSystem

const MIN_PROGRESS_PER_SPEED: float = 0.08
const MAX_PROGRESS_PER_SPEED: float = 0.16
const MARKET_RESPONSE_RATIO: float = 0.35
const NOISE_RATIO: float = 1.10
const SNAP_THRESHOLD: float = 0.01


func settle_month(context: RunContext) -> void:
	var bill := context.state.active_bill

	if bill != null:
		_advance_proposal_digestion(bill, context.random_system)
		var anchor := context.proposal_system.calculate_digested_anchor(bill)
		_move_market_toward_anchor(context.state.metrics, anchor, context.random_system)


func _advance_proposal_digestion(bill: ActiveBillState, random_system: RandomSystem) -> void:
	for active_proposal in bill.proposals:
		if active_proposal.is_fully_digested():
			continue

		var speed := maxf(active_proposal.proposal.digestion_speed, 0.0)
		var min_progress := MIN_PROGRESS_PER_SPEED * speed
		var max_progress := MAX_PROGRESS_PER_SPEED * speed
		var progress_delta := random_system.random_float(min_progress, max_progress)

		active_proposal.digestion_progress = minf(
			1.0, active_proposal.digestion_progress + progress_delta
		)


func _move_market_toward_anchor(
	current: MetricValues, anchor: MetricValues, random_system: RandomSystem
) -> void:
	current.tax = _move_value(current.tax, anchor.tax, random_system)
	current.price = _move_value(current.price, anchor.price, random_system)
	current.wage = _move_value(current.wage, anchor.wage, random_system)
	current.employment = _move_value(current.employment, anchor.employment, random_system)
	current.trade = _move_value(current.trade, anchor.trade, random_system)


func _move_value(current: int, target: int, random_system: RandomSystem) -> int:
	var gap := target - current
	if gap == 0:
		return target

	var base_change := float(gap) * MARKET_RESPONSE_RATIO
	var noise := random_system.random_float(-NOISE_RATIO, NOISE_RATIO)
	var actual_change := base_change * (1.0 + noise)
	return current + roundi(actual_change)
