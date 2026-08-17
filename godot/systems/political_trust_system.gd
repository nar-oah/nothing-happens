extends RefCounted
class_name PoliticalTrustSystem

const MIN_TRUST: float = 0.0
const MAX_TRUST: float = 100.0


func record_event_result(
	state: RunState, race_id: StringName, trust_delta: float, resolved: bool
) -> void:
	var race := state.get_race(race_id)
	if race == null:
		push_error("Unknown race for political trust result: %s" % race_id)
		return
	race.pending_trust_delta += trust_delta
	if resolved:
		race.resolved_events_this_year += 1
	else:
		race.erupted_events_this_year += 1


func record_promise(state: RunState, race_id: StringName, kept: bool, trust_delta: float) -> void:
	var race := state.get_race(race_id)
	if race == null:
		push_error("Unknown race for promise result: %s" % race_id)
		return
	race.pending_trust_delta += trust_delta
	if kept:
		race.promises_kept_this_year += 1
	else:
		race.promises_broken_this_year += 1


func settle_annual_trust(state: RunState) -> void:
	for race in state.races:
		race.political_trust = clampf(
			race.political_trust + race.pending_trust_delta, MIN_TRUST, MAX_TRUST
		)
		race.pending_trust_delta = 0.0
