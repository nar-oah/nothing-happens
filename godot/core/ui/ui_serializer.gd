extends RefCounted
class_name UiSerializer


func metric_values(values: MetricValues) -> Dictionary:
	if values == null:
		return {"tax": 0, "price": 0, "wage": 0, "employment": 0, "trade": 0}
	return {
		"tax": values.tax,
		"price": values.price,
		"wage": values.wage,
		"employment": values.employment,
		"trade": values.trade,
	}


func metric_vector(values: MetricVector) -> Dictionary:
	if values == null:
		return {"tax": 0, "price": 0, "wage": 0, "employment": 0, "trade": 0}
	return {
		"tax": values.tax,
		"price": values.price,
		"wage": values.wage,
		"employment": values.employment,
		"trade": values.trade,
	}


func interest_group(definition: InterestGroupDefinition) -> Variant:
	if definition == null:
		return null
	return {
		"display_name": definition.display_name,
		"base_column_weight": definition.base_column_weight,
		"decrease_tax": definition.decrease_tax,
		"decrease_price": definition.decrease_price,
		"decrease_wage": definition.decrease_wage,
		"decrease_employment": definition.decrease_employment,
		"decrease_trade": definition.decrease_trade,
	}


func proposal(value: ProposalInstance) -> Variant:
	if value == null:
		return null
	return {
		"source_group": interest_group(value.source_group),
		"base_effect": metric_vector(value.base_effect),
		"positive_effect": metric_vector(value.positive_effect),
		"lag_months": value.lag_months,
		"collapse_impact": value.collapse_impact,
		"donation_offer": value.donation_offer,
		"bonus_choice_resolved": value.bonus_choice_resolved,
		"positive_trait_accepted": value.positive_trait_accepted,
	}


func metric_condition(condition: MetricCondition) -> Variant:
	if condition == null:
		return null
	return {
		"left_metric": int(condition.left_metric),
		"operator": int(condition.operator),
		"right_metric": int(condition.right_metric),
		"right_multiplier": condition.right_multiplier,
	}


func policy_effect(effect: PolicyEffect) -> Variant:
	if effect == null:
		return null
	return {
		"target_metric": int(effect.target_metric),
		"formula": int(effect.formula),
		"source_a": int(effect.source_a),
		"source_b": int(effect.source_b),
		"multiplier": effect.multiplier,
	}


func policy(definition: PolicyDefinition) -> Variant:
	if definition == null:
		return null
	var effects: Array = []
	for effect in definition.effects:
		if effect != null:
			effects.append(policy_effect(effect))
	return {
		"display_name": definition.display_name,
		"condition": metric_condition(definition.condition),
		"effects": effects,
	}


func bill(value: Variant) -> Variant:
	if value == null:
		return null
	var proposals: Array = []
	for current in value.proposals:
		if current != null:
			proposals.append(proposal(current))
	var policies: Array = []
	for current in value.policies:
		if current != null:
			policies.append(policy(current))
	return {"title": value.title, "proposals": proposals, "policies": policies}


func active_bill(value: ActiveBillState) -> Variant:
	if value == null:
		return null
	var proposals: Array = []
	for current in value.proposals:
		if current == null:
			continue
		proposals.append(
			{
				"proposal": proposal(current.proposal),
				"digested_months": current.digested_months,
				"digestion_progress": current.get_digestion_progress(),
				"fully_digested": current.is_fully_digested(),
			}
		)
	var policies: Array = []
	for current in value.policies:
		if current != null:
			policies.append({"definition": policy(current.definition), "triggered": current.triggered})
	return {
		"title": value.title,
		"start_values": metric_values(value.start_values),
		"pure_target": metric_values(value.pure_target),
		"proposals": proposals,
		"policies": policies,
	}


func vote_result(result: VoteResultState, state: RunState) -> Dictionary:
	if result == null:
		return {
			"passed": false,
			"submitted": false,
			"support_count": 0,
			"oppose_count": 0,
			"abstain_count": 0,
			"absent_count": 0,
			"present_count": 0,
			"seat_votes": [],
		}
	var seat_votes: Array = []
	for current in result.seat_votes:
		var seat := current.seat
		var breakdown := {}
		for reason in current.breakdown:
			breakdown[str(reason)] = current.breakdown[reason]
		seat_votes.append(
			{
				"seat_index": -1 if seat == null else state.seats.find(seat),
				"seat_display_name": _seat_name(seat),
				"race_display_name": _race_name(null if seat == null else seat.race),
				"interest_group_display_name": _group_name(
					null if seat == null else seat.actual_group
				),
				"position": int(current.position),
				"score": current.score,
				"breakdown": breakdown,
			}
		)
	return {
		"passed": result.passed,
		"submitted": result.submitted,
		"support_count": result.support_count,
		"oppose_count": result.oppose_count,
		"abstain_count": result.abstain_count,
		"absent_count": result.absent_count,
		"present_count": result.present_count(),
		"seat_votes": seat_votes,
	}


func draft_preview(session: RunSession) -> Dictionary:
	var state := session.state
	var draft := state.draft_bill
	var pure_target := session.proposal_system.calculate_pure_target(state.metrics, draft.proposals)
	var immediate := session.policy_system.calculate_immediate_result(state.metrics, draft.policies)
	var projected := pure_target.copy()
	for metric in Metric.all_ids():
		projected.set_value(
			metric,
			pure_target.get_value(metric)
			+ immediate.get_value(metric)
			- state.metrics.get_value(metric)
		)
	var vote := session.vote_system.preview_vote(draft, session.context)
	return {
		"current_metrics": metric_values(state.metrics),
		"pure_proposal_target": metric_values(pure_target),
		"immediate_policy_result": metric_values(immediate),
		"projected_metrics": metric_values(projected),
		"vote": vote_result(vote, state),
	}


func pending_dialogue(state: RunState) -> Variant:
	for index in range(state.proposal_hand.size()):
		var current := state.proposal_hand[index]
		if current != null and current.is_bonus_choice_pending():
			return {"hand_index": index, "proposal": proposal(current)}
	return null


func month_report(state: RunState) -> Variant:
	if state.month_report_previous_metrics == null or state.month_report_current_metrics == null:
		return null
	var report_events: Array = []
	for current in state.month_report_events:
		report_events.append(current.duplicate(true))
	return {
		"year": state.month_report_year,
		"month": state.month_report_month,
		"previous_metrics": metric_values(state.month_report_previous_metrics),
		"current_metrics": metric_values(state.month_report_current_metrics),
		"events": report_events,
	}


func full_state(
	session: RunSession, ui_mode: String, world_scene: String, state_version: int
) -> Dictionary:
	var state := session.state
	# TODO: Replace this presentation value when a formally designed term state exists.
	return {
		"state_version": state_version,
		"ui_mode": ui_mode,
		"world_scene": world_scene,
		"term": 1,
		"year": state.year,
		"month": state.month,
		"metrics": metric_values(state.metrics),
		"month_report": month_report(state),
		"proposal_hand": _proposals(state.proposal_hand),
		"saved_bills": _bills(state.saved_bills),
		"draft_bill": bill(state.draft_bill),
		"editing_saved_bill_index": (
			null
			if state.editing_saved_bill_index == RunState.NEW_BILL_INDEX
			else state.editing_saved_bill_index
		),
		"available_policies": _policies(
			session.constitution_system.get_available_policies(session.context)
		),
		"constitution": constitution(session),
		"races": races(session),
		"interest_groups": interest_groups(session),
		"seats": seats(session),
		"parliament": parliament(session),
		"political_donation_pool": state.political_donation_pool,
		"collapse_level": state.collapse_level,
		"max_collapse": session.balance.max_collapse,
		"draft_preview": draft_preview(session),
		"pending_dialogue": pending_dialogue(state),
		"active_bill": active_bill(state.active_bill),
	}


func constitution(session: RunSession) -> Dictionary:
	var active_articles: Array = []
	for current in session.constitution_system.get_active_articles(session.context):
		active_articles.append(_article(current, session.constitution_articles.find(current)))
	var articles: Array = []
	for index in range(session.constitution_articles.size()):
		var current := session.constitution_articles[index]
		var data := _article(current, index)
		var is_active := (
			current != null
			and session.state.constitution.get_active_article(current.race) == current
		)
		data["race_display_name"] = _race_name(null if current == null else current.race)
		data["active"] = is_active
		data["selected"] = is_active
		data["clicked"] = session.state.constitution.was_clicked(current)
		data["eligible"] = session.constitution_system.can_revise(session.context, current)
		articles.append(data)
	return {
		"title": "蓬莱约法",
		"revision_available": session.state.constitution.revision_available,
		"active_articles": active_articles,
		"articles": articles,
	}


func races(session: RunSession) -> Array:
	var result: Array = []
	for index in range(session.state.races.size()):
		var current := session.state.races[index]
		if current == null or current.definition == null:
			continue
		var expectations: Array = []
		for metric in current.definition.get_stance_metrics():
			expectations.append(
				{
					"metric": int(metric),
					"target": session.race_system.get_effective_expectation(
						current, metric, session.context
					),
					"direction": int(current.definition.get_stance(metric)),
				}
			)
		result.append(
			{
				"race_index": index,
				"display_name": current.definition.display_name,
				"seat_count": session.parliament_system.get_race_seat_count(
					session.state, current.definition
				),
				"expectations": expectations,
				"resolved_events_this_year": current.resolved_events_this_year,
				"last_year_resolved_events": current.last_year_resolved_events,
			}
		)
	return result


func interest_groups(session: RunSession) -> Array:
	var result: Array = []
	for current in session.constitution_system.get_effective_groups(session.context):
		var data: Dictionary = interest_group(current)
		data["influence_count"] = session.parliament_system.get_group_influence_count(
			session.state, current
		)
		data["influence_rate"] = session.parliament_system.get_group_influence_rate(
			session.state, current
		)
		result.append(data)
	return result


func seats(session: RunSession) -> Array:
	var result: Array = []
	for index in range(session.state.seats.size()):
		var current := session.state.seats[index]
		result.append(
			{
				"seat_index": index,
				"display_name": _seat_name(current),
				"race_display_name": _race_name(current.race),
				"interest_group_display_name": _group_name(current.actual_group),
				"personal_relation": current.personal_relation,
			}
		)
	return result


func parliament(session: RunSession) -> Dictionary:
	var race_counts: Array = []
	for race in races(session):
		race_counts.append(
			{"display_name": race["display_name"], "seat_count": race["seat_count"]}
		)
	var group_influence: Array = []
	for group in interest_groups(session):
		group_influence.append(
			{
				"display_name": group["display_name"],
				"influence_count": group["influence_count"],
				"influence_rate": group["influence_rate"],
			}
		)
	return {
		"total_seats": session.state.seats.size(),
		"race_seat_counts": race_counts,
		"interest_group_influence": group_influence,
	}


func game_status(session: RunSession) -> Dictionary:
	return {
		"year": session.state.year,
		"month": session.state.month,
		"metrics": metric_values(session.state.metrics),
		"political_donation_pool": session.state.political_donation_pool,
		"collapse_level": session.state.collapse_level,
		"max_collapse": session.balance.max_collapse,
	}


func _article(definition: ConstitutionArticleDefinition, article_index: int) -> Dictionary:
	if definition == null:
		return {"article_index": article_index, "display_name": "", "content": "", "policies": []}
	return {
		"article_index": article_index,
		"display_name": definition.display_name,
		"content": "",
		"policies": _policies(definition.policies),
	}


func _proposals(values: Array[ProposalInstance]) -> Array:
	var result: Array = []
	for current in values:
		if current != null:
			result.append(proposal(current))
	return result


func _policies(values: Array[PolicyDefinition]) -> Array:
	var result: Array = []
	for current in values:
		if current != null:
			result.append(policy(current))
	return result


func _bills(values: Array[SavedBillState]) -> Array:
	var result: Array = []
	for current in values:
		if current != null:
			result.append(bill(current))
	return result


func _race_name(definition: RaceDefinition) -> String:
	return "" if definition == null else definition.display_name


func _group_name(definition: InterestGroupDefinition) -> String:
	return "" if definition == null else definition.display_name


func _seat_name(state: SeatState) -> String:
	return "" if state == null or state.definition == null else state.definition.display_name
