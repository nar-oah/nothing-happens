extends RefCounted


func run(t) -> void:
	_test_event_lifecycle_and_trust(t)
	_test_event_yin_yang_relaxation(t)


func _test_event_lifecycle_and_trust(t) -> void:
	var race := t.make_race(&"event_race")
	race.increase_wage = true
	var group := t.make_group(&"group", 1, 0)

	var races: Array[RaceDefinition] = [race]
	var groups: Array[InterestGroupDefinition] = [group]
	var session := t.make_session(races, groups)

	session.state.metrics.wage = 0
	var eruption := session.event_system.spawn_race_event(session.context, &"event_race")
	t.check(eruption != null, "expectation gap creates race event")
	if eruption == null:
		session.free()
		return

	eruption.base_intensity = 0.9
	for i in range(3):
		session.event_system.settle_month(session.context)

	t.check_equal(eruption.phase, EventState.Phase.ERUPTED, "three uncontrolled full months erupt")
	t.check(eruption.known and eruption.published, "full event is permanently public")

	session.state.metrics.wage = 0
	var relief := session.event_system.spawn_race_event(session.context, &"event_race")
	t.check(relief != null, "second expectation event can be created")
	if relief == null:
		session.free()
		return

	session.state.metrics.wage = 100
	session.event_system.settle_month(session.context)
	t.check_equal(relief.phase, EventState.Phase.RELIEVING, "first floor relief is retained")

	session.event_system.settle_month(session.context)
	t.check_equal(relief.phase, EventState.Phase.RESOLVED, "second floor relief resolves event")

	var race_state := session.state.get_race(&"event_race")
	t.check_equal(race_state.erupted_events_this_year, 1, "eruption trust ledger count")
	t.check_equal(race_state.resolved_events_this_year, 1, "resolution trust ledger count")
	t.check_equal(race_state.pending_trust_delta, -4.0, "event trust deltas wait for year end")
	session.free()


func _test_event_yin_yang_relaxation(t) -> void:
	var biyi := t.make_race(Race.BIYI)
	biyi.decrease_tax = true

	var article := ConstitutionArticleDefinition.new()
	article.id = &"inclusive"
	article.axis_id = &"culture"
	article.is_initial = true
	article.flags = [ConstitutionSystem.FLAG_YIN_YANG_BIYI_ONLY]

	var races: Array[RaceDefinition] = [biyi]
	var groups: Array[InterestGroupDefinition] = [t.make_group(&"group", 1, 0)]
	var articles: Array[ConstitutionArticleDefinition] = [article]
	var session := t.make_session(races, groups, articles)

	session.state.month = 1
	session.state.metrics.tax = 95
	var event := session.event_system.spawn_race_event(session.context, Race.BIYI)
	t.check(event != null, "yin tightening creates tax gap")
	if event == null:
		session.free()
		return

	session.state.month = 2
	var requirements := session.event_system.get_current_requirements(event, session.context)
	t.check_equal(
		requirements[Metric.Id.TAX], 95, "relaxed yin-yang requirement never reverses direction"
	)
	session.free()
