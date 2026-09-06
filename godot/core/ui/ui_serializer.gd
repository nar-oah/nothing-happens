extends RefCounted
class_name UiSerializer


func metric_values(values: MetricValues) -> Dictionary:
	if values == null:
		return {"tax": 0, "consumption": 0, "production": 0, "employment": 0, "investment": 0}
	return {"tax": values.tax, "consumption": values.consumption, "production": values.production, "employment": values.employment, "investment": values.investment}


func metric_vector(values: MetricVector) -> Dictionary:
	if values == null:
		return {"tax": 0, "consumption": 0, "production": 0, "employment": 0, "investment": 0}
	return {"tax": values.tax, "consumption": values.consumption, "production": values.production, "employment": values.employment, "investment": values.investment}


func interest_group(definition: InterestGroupDefinition) -> Variant:
	if definition == null:
		return null
	return {
		"display_name": _t(definition.display_name),
		"display_name_original": definition.display_name,
		"description": _translate_multiline(definition.description),
		"base_column_weight": definition.base_column_weight,
		"decrease_tax": definition.decrease_tax,
		"decrease_consumption": definition.decrease_consumption,
		"decrease_production": definition.decrease_production,
		"decrease_employment": definition.decrease_employment,
		"decrease_investment": definition.decrease_investment,
	}


func proposal(value: ProposalInstance) -> Variant:
	if value == null:
		return null
	return {
		"source_group": interest_group(value.source_group),
		"base_effect": metric_vector(value.base_effect),
		"positive_effect": metric_vector(value.positive_effect),
		"lag_months": value.lag_months,
		"donation_offer": value.donation_offer,
		"bonus_choice_resolved": value.bonus_choice_resolved,
		"positive_trait_accepted": value.positive_trait_accepted,
	}


func metric_condition(condition: MetricCondition) -> Variant:
	if condition == null:
		return null
	return {"left_metric": int(condition.left_metric), "operator": int(condition.operator), "right_metric": int(condition.right_metric), "right_multiplier": condition.right_multiplier}


func policy_effect(effect: PolicyEffect) -> Variant:
	if effect == null:
		return null
	return {"target_metric": int(effect.target_metric), "formula": int(effect.formula), "source_a": int(effect.source_a), "source_b": int(effect.source_b), "multiplier": effect.multiplier}


func policy(definition: PolicyDefinition) -> Variant:
	if definition == null:
		return null
	var effects: Array = []
	for effect in definition.effects:
		if effect != null:
			effects.append(policy_effect(effect))
	# Policy display_name is intentionally left untranslated: it also acts as the backend lookup key
	# and the Chinese name is part of the seal/stamp presentation in the frontend.
	return {"display_name": definition.display_name, "condition": metric_condition(definition.condition), "effects": effects}


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
		proposals.append({"proposal": proposal(current.proposal), "digested_months": current.digested_months, "digestion_progress": current.get_digestion_progress(), "fully_digested": current.is_fully_digested()})
	var policies: Array = []
	for current in value.policies:
		if current != null:
			policies.append({"definition": policy(current.definition), "triggered": current.triggered})
	return {"title": value.title, "start_values": metric_values(value.start_values), "pure_target": metric_values(value.pure_target), "proposals": proposals, "policies": policies}


func vote_result(result: VoteResultState, source: Variant) -> Dictionary:
	if result == null:
		return {"passed": false, "submitted": false, "support_count": 0, "oppose_count": 0, "abstain_count": 0, "absent_count": 0, "present_count": 0, "seat_votes": []}
	var session: RunSession = source if source is RunSession else null
	var state: RunState = session.state if session != null else source as RunState
	var seat_votes: Array = []
	for current in result.seat_votes:
		var seat := current.seat
		var breakdown := {}
		for reason in current.breakdown:
			breakdown[str(reason)] = current.breakdown[reason]
		seat_votes.append({
			"seat_index": -1 if seat == null or state == null else state.seats.find(seat),
			"seat_display_name": _seat_name(seat),
			"race_display_name": _active_race_name_from_source(session, state, null if seat == null else seat.race),
			"interest_group_display_name": _active_group_name_from_source(session, state, null if seat == null else seat.actual_group),
			"position": int(current.position),
			"score": current.score,
			"can_bribe": session != null and session.vote_system.can_bribe(session.context, current),
			"breakdown": breakdown,
		})
	return {"passed": result.passed, "submitted": result.submitted, "support_count": result.support_count, "oppose_count": result.oppose_count, "abstain_count": result.abstain_count, "absent_count": result.absent_count, "present_count": result.present_count(), "seat_votes": seat_votes}


func draft_preview(session: RunSession) -> Dictionary:
	var state := session.state
	var draft := state.draft_bill
	var pure_target := session.proposal_system.calculate_pure_target(state.metrics, draft.proposals)
	var projected := session.vote_system.calculate_projected_metrics(draft, pure_target, session.context)
	var vote := session.vote_system.preview_vote(draft, session.context)
	return {"current_metrics": metric_values(state.metrics), "pure_proposal_target": metric_values(pure_target), "immediate_policy_result": metric_values(projected), "projected_metrics": metric_values(projected), "vote": vote_result(vote, session)}


func pending_dialogue(session: RunSession) -> Variant:
	if session == null or session.state == null or session.state.office_visits.is_empty():
		return null
	var visit := session.state.office_visits[0]
	if visit == null or visit.race == null:
		return null
	match visit.kind:
		OfficeVisitState.Kind.INTEREST_GROUP:
			var current := visit.proposal
			if current == null or current.source_group == null or not current.has_positive_trait():
				return null
			var positive_metric := current.get_positive_metric() as Metric.Id
			return {
				"kind": "interest_group",
				"race_name": _active_race_name(session, visit.race),
				"group_name": _active_group_name(session, current.source_group),
				"positive_metric": int(positive_metric),
				"positive_value": current.positive_effect.get_value(positive_metric),
				"donation_offer": current.donation_offer,
			}
		OfficeVisitState.Kind.EVENT_INTEL:
			var event := visit.event
			if event == null:
				return null
			var data := {
				"kind": "event_intel",
				"race_name": _active_race_name(session, visit.race),
				"metric": int(event.metric),
				"requirement": session.event_system.get_current_requirement(event),
				"strength": roundi(clampf(event.growth_progress, 0.0, 1.0) * 100.0),
			}
			if event.requirement_kind == EventState.RequirementKind.INTEREST_GROUP_PROPOSALS:
				data["requirement_kind"] = int(event.requirement_kind)
				data["interest_group_name"] = _active_group_name(session, event.interest_group)
			return data
	return null


func month_report(state: RunState) -> Variant:
	if state.month_report_previous_metrics == null or state.month_report_current_metrics == null:
		return null
	var report_events: Array = []
	for current in state.month_report_events:
		var event_data: Dictionary = current.duplicate(true)
		for key in ["race_display_name", "race_name", "interest_group_name", "event_description", "description"]:
			if event_data.get(key) is String:
				event_data[key] = _translate_multiline(event_data[key])
		report_events.append(event_data)
	return {"year": state.month_report_year, "month": state.month_report_month, "previous_metrics": metric_values(state.month_report_previous_metrics), "current_metrics": metric_values(state.month_report_current_metrics), "events": report_events}


func newspaper_front(state: RunState) -> Variant:
	return null if state.newspaper_front.is_empty() else state.newspaper_front.duplicate(true)


func term_report(session: RunSession) -> Variant:
	if session.term_report.is_empty():
		return null
	return {"outcome": _term_outcome(session.term_report["outcome"]), "previous_governing_months": session.term_report["previous_governing_months"], "current_governing_months": session.term_report["current_governing_months"]}


func full_state(
	session: RunSession,
	ui_mode: String,
	world_scene: String,
	state_version: int,
	parliament_seat_anchors: Array = []
) -> Dictionary:
	var state := session.state
	return {
		"state_version": state_version,
		"saves": session.list_saves(),
		"ui_mode": ui_mode,
		"world_scene": world_scene,
		"parliament_seat_anchors": parliament_seat_anchors,
		"term": state.term,
		"year": state.year,
		"month": state.month,
		"run_phase": _run_phase(state.run_phase),
		"term_outcome": _term_outcome(state.term_outcome),
		"governing_months": state.governing_months,
		"metrics": metric_values(state.metrics),
		"month_report": month_report(state),
		"newspaper_front": newspaper_front(state),
		"term_report": term_report(session),
		"proposal_hand": _proposals(state.proposal_hand),
		"saved_bills": _bills(state.saved_bills),
		"draft_bill": bill(state.draft_bill),
		"editing_saved_bill_index": null if state.editing_saved_bill_index == RunState.NEW_BILL_INDEX else state.editing_saved_bill_index,
		"available_policies": _policies(session.constitution_system.get_available_policies(session.context)),
		"constitution": constitution(session),
		"races": races(session),
		"interest_groups": interest_groups(session),
		"seats": seats(session),
		"parliament": parliament(session),
		"political_donation_pool": state.political_donation_pool,
		"collapse_level": state.collapse_level,
		"max_collapse": session.balance.max_collapse,
		"draft_preview": draft_preview(session),
		"pending_dialogue": pending_dialogue(session),
		"active_bill": active_bill(state.active_bill),
	}


func constitution(session: RunSession) -> Dictionary:
	var active_articles: Array = []
	for current in session.constitution_system.get_active_articles(session.context):
		active_articles.append(_article(current, session.constitution_articles.find(current)))
	var columns: Array = []
	var rows: Array = []
	var board := session.constitution_board
	if board != null:
		for column_index in range(board.columns.size()):
			var column := board.columns[column_index]
			columns.append({"column_index": column_index, "display_name": "" if column == null else _t(column.display_name), "unlock_cost_months": 0 if column == null else column.unlock_cost_months, "unlocked": column != null and session.meta_progression.is_column_unlocked(column), "can_unlock": column != null and session.meta_progression.can_unlock_column(board, column)})
		var board_rows := board.get_rows()
		for row_index in range(board_rows.size()):
			var row := board_rows[row_index]
			var active := session.state.constitution.get_active_article_for_row(row)
			rows.append({"row_index": row_index, "display_name": _t(row.display_name), "race_display_name": _active_race_name(session, row.race), "free_navigation": row.free_navigation, "ignores_column_unlocks": row.ignores_column_unlocks, "active_article_index": session.constitution_articles.find(active)})
	var articles: Array = []
	for index in range(session.constitution_articles.size()):
		var current := session.constitution_articles[index]
		var data := _article(current, index)
		var row_index := -1
		var column_index := -1
		var row_display_name := ""
		var is_active := false
		if current != null:
			row_display_name = _active_race_name(session, current.get_race())
			if board != null and current.row != null:
				var board_rows := board.get_rows()
				row_index = board_rows.find(current.row)
				column_index = board.get_column_index_for_article(current)
				row_display_name = _t(current.row.display_name)
				is_active = session.state.constitution.get_active_article_for_row(current.row) == current
			else:
				is_active = session.state.constitution.get_active_article(current.get_race()) == current
		data["row_index"] = row_index
		data["column_index"] = column_index
		data["row_display_name"] = row_display_name
		data["race_display_name"] = _active_race_name(session, null if current == null else current.get_race())
		data["active"] = is_active
		data["selected"] = is_active
		data["eligible"] = session.constitution_system.can_revise(session.context, current)
		data["is_terminal"] = current != null and current.is_terminal
		data["requirement_percent"] = _article_requirement_percent(current)
		data["contents"] = [
			{"title": "", "body": data["content"]},
			{"title": _t("要求"), "body": _t("无") if current == null else current.get_requirement_description()},
		]
		for effect in data["effects"]:
			data["contents"].append({"title": effect["display_name"], "body": effect["description"]})
		articles.append(data)
	return {"title": _t("蓬莱约法"), "revision_available": session.state.constitution.revision_available, "center_column_index": -1 if board == null else board.get_center_column_index(), "available_governing_months": session.meta_progression.available_governing_months, "lifetime_governing_months": session.meta_progression.lifetime_governing_months, "terminal_article_index": session.constitution_articles.find(session.state.constitution.terminal_article), "columns": columns, "rows": rows, "active_articles": active_articles, "articles": articles}


func races(session: RunSession) -> Array:
	var result: Array = []
	for index in range(session.state.races.size()):
		var current := session.state.races[index]
		if current == null or current.definition == null:
			continue
		var seat_count := session.parliament_system.get_race_seat_count(session.state, current.definition)
		if seat_count <= 0:
			continue
		var active := current.active_definition if current.active_definition != null else current.definition
		var expectations: Array = []
		for metric in active.get_stance_metrics():
			expectations.append({"metric": int(metric), "target": session.race_system.get_effective_expectation(current, metric, session.context), "direction": int(active.get_stance(metric))})
		var data := {"race_index": index, "display_name": _t(active.display_name), "description": _translate_multiline(active.description), "seat_count": seat_count, "expectations": expectations, "resolved_events_this_year": current.resolved_events_this_year, "last_year_resolved_events": current.last_year_resolved_events}
		if current.definition.fixed_interest_group != null:
			data["proposal_expectation"] = {
				"interest_group_name": _active_group_name(session, current.definition.fixed_interest_group),
				"target": session.race_system.get_interest_group_proposal_expectation(current, session.context),
			}
		result.append(data)
	return result


func interest_groups(session: RunSession) -> Array:
	var result: Array = []
	for current in session.constitution_system.get_effective_groups(session.context):
		var active := session.constitution_system.get_active_group_definition(session.context, current)
		var data: Dictionary = interest_group(active)
		data["influence_count"] = session.parliament_system.get_group_influence_count(session.state, current)
		data["influence_rate"] = session.parliament_system.get_group_influence_rate(session.state, current)
		result.append(data)
	return result


func seats(session: RunSession) -> Array:
	var result: Array = []
	for index in range(session.state.seats.size()):
		var current := session.state.seats[index]
		# Seat/place names intentionally remain Chinese: they are part of the in-world labels.
		result.append({"seat_index": index, "display_name": _seat_name(current), "race_display_name": _active_race_name(session, current.race), "interest_group_display_name": _active_group_name(session, current.actual_group)})
	return result


func parliament(session: RunSession) -> Dictionary:
	var race_counts: Array = []
	for race in races(session):
		race_counts.append({"display_name": race["display_name"], "seat_count": race["seat_count"]})
	var group_influence: Array = []
	for group in interest_groups(session):
		group_influence.append({"display_name": group["display_name"], "influence_count": group["influence_count"], "influence_rate": group["influence_rate"]})
	return {"display_name": _t(session.constitution_system.get_parliament_name(session.context)), "total_seats": session.state.seats.size(), "race_seat_counts": race_counts, "interest_group_influence": group_influence}


func game_status(session: RunSession) -> Dictionary:
	return {"term": session.state.term, "year": session.state.year, "month": session.state.month, "run_phase": _run_phase(session.state.run_phase), "term_outcome": _term_outcome(session.state.term_outcome), "governing_months": session.state.governing_months, "metrics": metric_values(session.state.metrics), "political_donation_pool": session.state.political_donation_pool, "collapse_level": session.state.collapse_level, "max_collapse": session.balance.max_collapse}


func _run_phase(value: RunState.RunPhase) -> String:
	return "TERM_ENDED" if value == RunState.RunPhase.TERM_ENDED else "RUNNING"


func _term_outcome(value: RunState.TermOutcome) -> String:
	match value:
		RunState.TermOutcome.COLLAPSE:
			return "COLLAPSE"
		RunState.TermOutcome.NOTHING_HAPPENS:
			return "NOTHING_HAPPENS"
		_:
			return "NONE"


func _article(definition: ConstitutionArticleDefinition, article_index: int) -> Dictionary:
	if definition == null:
		return {"article_index": article_index, "display_name": "", "content": "", "policies": [], "effects": []}
	var effects: Array = []
	for effect in definition.effects:
		if effect != null:
			effects.append({"display_name": _t(effect.display_name), "description": effect.get_description(), "timing": int(effect.timing)})
	return {"article_index": article_index, "display_name": _t(definition.display_name), "content": _translate_multiline(definition.description), "policies": _policies(definition.policies), "effects": effects}


func _article_requirement_percent(definition: ConstitutionArticleDefinition) -> Variant:
	if definition == null:
		return null
	var condition := definition.seat_condition
	if condition == null:
		for current in definition.conditions:
			if current is ConstitutionSeatCondition:
				condition = current
				break
	if condition == null:
		return null
	return condition.required_rate * 100.0


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


func _active_race_name(session: RunSession, definition: RaceDefinition) -> String:
	var active := session.constitution_system.get_active_race_definition(session.context, definition)
	return "" if active == null else _t(active.display_name)


func _active_group_name(session: RunSession, definition: InterestGroupDefinition) -> String:
	var active := session.constitution_system.get_active_group_definition(session.context, definition)
	return "" if active == null else _t(active.display_name)


func _active_race_name_from_source(session: RunSession, state: RunState, definition: RaceDefinition) -> String:
	if definition == null:
		return ""
	if session != null:
		return _active_race_name(session, definition)
	if state != null:
		var race_state := state.get_race(definition)
		if race_state != null and race_state.active_definition != null:
			return _t(race_state.active_definition.display_name)
	return _t(definition.display_name)


func _active_group_name_from_source(session: RunSession, state: RunState, definition: InterestGroupDefinition) -> String:
	if definition == null:
		return ""
	if session != null:
		return _active_group_name(session, definition)
	if state != null and state.constitution != null:
		var canonical := definition
		var visited: Dictionary[InterestGroupDefinition, bool] = {}
		while state.constitution.group_mergers.has(canonical) and not visited.has(canonical):
			visited[canonical] = true
			canonical = state.constitution.group_mergers[canonical]
		var active: InterestGroupDefinition = state.constitution.group_variants.get(canonical, canonical)
		return "" if active == null else _t(active.display_name)
	return _t(definition.display_name)


func _seat_name(state: SeatState) -> String:
	return "" if state == null or state.definition == null else state.definition.display_name


func _t(text: String) -> String:
	if text.is_empty():
		return text
	return str(TranslationServer.translate(text))


func _translate_multiline(text: String) -> String:
	if text.is_empty():
		return text
	var result: Array[String] = []
	for line in text.split("\n", true):
		result.append(_t(line))
	return "\n".join(result)