extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_draft_round_trip_preserves_hand_order(t)
	_test_saved_bill_switch_preserves_hand_order(t)
	_test_successful_submission_preserves_remaining_order(t)
	_test_saved_bill_editing_is_isolated(t)
	_test_mixed_saved_and_hand_proposal_sources(t)
	_test_saved_policy_reconciles_with_constitution(t)


func _test_draft_round_trip_preserves_hand_order(t: BackendTestContext) -> void:
	var group := t.make_group("ordered draft")
	var first := t.make_proposal(group)
	var second := t.make_proposal(group)
	var third := t.make_proposal(group)
	var state := RunState.new()
	state.proposal_hand = [first, second, third]
	var system := DraftBillSystem.new()
	t.check(system.move_proposal_from_hand(state, 0), "the first proposal enters draft")
	t.check(system.move_proposal_from_hand(state, 1), "the third proposal enters draft")
	t.check(system.return_proposal_to_hand(state, 0), "the first proposal leaves draft")
	t.check(system.return_proposal_to_hand(state, 0), "the third proposal leaves draft")
	t.check_equal(
		state.proposal_hand,
		[first, second, third],
		"returning proposals restores acquisition order"
	)

	t.check(system.move_proposal_from_hand(state, 0), "the first proposal re-enters draft")
	t.check(system.move_proposal_from_hand(state, 1), "the third proposal re-enters draft")
	system.cancel_editing(state)
	t.check_equal(
		state.proposal_hand,
		[first, second, third],
		"cancelling a draft restores acquisition order"
	)
	var newest := t.make_proposal(group)
	ProposalSystem.new().add_to_hand(state, newest)
	t.check_equal(
		state.proposal_hand,
		[first, second, third, newest],
		"a genuinely new proposal still enters at the hand tail"
	)


func _test_saved_bill_switch_preserves_hand_order(t: BackendTestContext) -> void:
	var race := t.make_race("saved order")
	var group := t.make_group("saved order source")
	var session := t.make_session(
		[race], [group], t.make_seats(1, "saved order")
	)
	var first := t.make_proposal(group)
	first.base_effect.tax = 1
	var second := t.make_proposal(group)
	second.base_effect.tax = 2
	var third := t.make_proposal(group)
	third.base_effect.tax = 3
	for proposal in [first, second, third]:
		session.proposal_system.add_to_hand(session.state, proposal)
	var first_bill := SavedBillState.new()
	first_bill.title = "first"
	first_bill.proposals.append(first.copy())
	var third_bill := SavedBillState.new()
	third_bill.title = "third"
	third_bill.proposals.append(third.copy())
	session.state.saved_bills = [first_bill, third_bill]

	t.check(session.edit_saved_bill(0), "the first saved bill loads")
	t.check_equal(
		session.state.proposal_hand,
		[first, second, third],
		"loading a saved bill does not reserve a hand proposal"
	)
	t.check(
		session.state.draft_bill.proposals[0] != first_bill.proposals[0],
		"loading copies the saved proposal template"
	)
	t.check(session.edit_saved_bill(1), "switching to another saved bill succeeds")
	t.check_equal(
		session.state.proposal_hand,
		[first, second, third],
		"switching saved bills leaves the hand unchanged"
	)
	session.cancel_bill_editing()
	t.check_equal(
		session.state.proposal_hand,
		[first, second, third],
		"cancelling saved bill editing preserves the current hand order"
	)
	session.free()


func _test_successful_submission_preserves_remaining_order(t: BackendTestContext) -> void:
	var race := t.make_race("consumed order")
	var group := t.make_group("consumed source")
	var session := t.make_session(
		[race], [group], t.make_seats(1, "consumed order")
	)
	var first := t.make_proposal(group)
	var second := t.make_proposal(group)
	var third := t.make_proposal(group)
	var fourth := t.make_proposal(group)
	for proposal in [first, second, third, fourth]:
		session.proposal_system.add_to_hand(session.state, proposal)
	session.draft_bill_system.move_proposal_from_hand(session.state, 0)
	session.draft_bill_system.move_proposal_from_hand(session.state, 1)
	var result := session.submit_draft()
	t.check(result.passed, "the selected proposals are successfully consumed")
	t.check_equal(
		session.state.proposal_hand,
		[second, fourth],
		"successful consumption preserves the remaining relative order"
	)
	session.free()


func _test_saved_bill_editing_is_isolated(t: BackendTestContext) -> void:
	var race := t.make_race("saved bills")
	var group := t.make_group("saved source")
	var policy := PolicyDefinition.new()
	policy.display_name = "saved policy"
	var article := t.make_article(race)
	article.policies = [policy]
	var session := t.make_session(
		[race], [group], t.make_seats(1, "saved bills"), [article]
	)
	var proposal := t.make_proposal(group)
	proposal.base_effect.tax = 8
	proposal.lag_months = 4
	session.state.draft_bill.title = "original"
	session.state.draft_bill.proposals.append(proposal)
	session.state.draft_bill.policies.append(policy)
	var saved_index := session.draft_bill_system.save_draft(session.state)

	t.check_equal(saved_index, 0, "a new draft appends one saved bill")
	t.check_equal(session.state.saved_bills.size(), 1, "the bill library stores the new bill")
	var saved := session.state.saved_bills[0]
	t.check_equal(saved.title, "original", "a saved bill keeps its title")
	t.check(saved.proposals[0] != proposal, "saved proposals are independent copies")
	session.state.draft_bill.title = "unsaved mutation"
	proposal.base_effect.tax = 99
	session.state.draft_bill.policies.clear()
	t.check_equal(saved.title, "original", "draft title edits do not mutate the saved bill")
	t.check_equal(saved.proposals[0].base_effect.tax, 8, "draft proposal edits stay isolated")
	t.check_equal(saved.policies.size(), 1, "draft policy edits stay isolated")

	session.cancel_bill_editing()
	var current_hand_proposal := t.make_proposal(group)
	current_hand_proposal.lag_months = 9
	session.state.proposal_hand = [current_hand_proposal]
	t.check(session.edit_saved_bill(0), "a saved bill can be loaded for editing")
	t.check_equal(
		session.state.editing_saved_bill_index, 0, "editing tracks the saved bill index"
	)
	var loaded := session.state.draft_bill.proposals[0]
	t.check(
		loaded != saved.proposals[0],
		"loading creates a draft copy from the saved proposal template"
	)
	t.check_equal(
		session.state.proposal_hand,
		[current_hand_proposal],
		"loading does not require or reserve an equivalent hand proposal"
	)
	session.state.draft_bill.title = "edited"
	loaded.base_effect.tax = 12
	session.draft_bill_system.save_draft(session.state)
	t.check_equal(session.state.saved_bills.size(), 1, "editing overwrites instead of appending")
	t.check_equal(session.state.saved_bills[0].title, "edited", "overwrite saves the new title")
	t.check_equal(
		session.state.saved_bills[0].proposals[0].base_effect.tax,
		12,
		"overwrite saves edited proposal content"
	)
	loaded.base_effect.tax = 77
	session.cancel_bill_editing()
	t.check_equal(
		session.state.saved_bills[0].proposals[0].base_effect.tax,
		12,
		"cancel after saving cannot mutate the stored copy"
	)
	t.check(session.state.draft_bill.is_empty(), "cancel clears the working draft")
	t.check_equal(
		session.state.editing_saved_bill_index,
		RunState.NEW_BILL_INDEX,
		"cancel returns to new-bill mode"
	)
	t.check_equal(
		session.state.proposal_hand,
		[current_hand_proposal],
		"cancelling discards template copies without changing the hand"
	)
	session.free()


func _test_mixed_saved_and_hand_proposal_sources(t: BackendTestContext) -> void:
	var race := t.make_race("mixed saved bill")
	var group := t.make_group("mixed saved source")
	var session := t.make_session(
		[race], [group], t.make_seats(1, "mixed saved bill")
	)
	var template := t.make_proposal(group)
	template.base_effect.tax = 3
	var saved := SavedBillState.new()
	saved.proposals.append(template)
	session.state.saved_bills = [saved]
	var selected := t.make_proposal(group)
	var remaining := t.make_proposal(group)
	for proposal in [selected, remaining]:
		session.proposal_system.add_to_hand(session.state, proposal)

	t.check(session.edit_saved_bill(0), "the saved template loads without a hand match")
	t.check(
		session.draft_bill_system.move_proposal_from_hand(session.state, 0),
		"a current hand proposal can be added after loading a saved bill"
	)
	t.check_equal(
		session.state.draft_bill.hand_proposals,
		[selected],
		"the draft tracks only its hand-sourced proposal"
	)
	t.check(
		session.draft_bill_system.return_proposal_to_hand(session.state, 0),
		"the saved template can be removed from the draft"
	)
	t.check_equal(
		session.state.proposal_hand,
		[remaining],
		"removing a template proposal does not restore anything to the hand"
	)
	session.cancel_bill_editing()
	t.check_equal(
		session.state.proposal_hand,
		[selected, remaining],
		"cancelling restores only the hand-sourced proposal"
	)

	t.check(session.edit_saved_bill(0), "the saved template can be loaded again")
	session.draft_bill_system.move_proposal_from_hand(session.state, 0)
	var result := session.submit_draft()
	t.check(result.passed, "the mixed draft passes")
	t.check_equal(
		session.state.proposal_hand,
		[remaining],
		"passing consumes only the hand-sourced proposal"
	)
	t.check(session.edit_saved_bill(0), "the passed saved bill remains reusable")
	t.check_equal(
		session.state.draft_bill.proposals.size(),
		2,
		"reloading uses both proposals saved as reusable templates"
	)
	t.check_equal(
		session.state.proposal_hand,
		[remaining],
		"reloading the passed bill still leaves the hand unchanged"
	)
	session.free()


func _test_saved_policy_reconciles_with_constitution(t: BackendTestContext) -> void:
	var race := t.make_race("policy revision")
	var group := t.make_group("policy source")
	var old_policy := PolicyDefinition.new()
	old_policy.display_name = "old policy"
	var current_policy := PolicyDefinition.new()
	current_policy.display_name = "current policy"
	var initial := t.make_article(race)
	initial.policies = [old_policy]
	var revised := t.make_article(race, false)
	revised.policies = [current_policy]
	var session := t.make_session(
		[race], [group], t.make_seats(1, "policy revision"), [initial, revised]
	)
	var proposal := t.make_proposal(group)
	proposal.base_effect.trade = -5
	session.state.draft_bill.title = "old constitution bill"
	session.state.draft_bill.proposals.append(proposal)
	session.state.draft_bill.policies.append(old_policy)
	session.draft_bill_system.save_draft(session.state)
	session.cancel_bill_editing()

	t.check(session.revise_constitution(revised), "the constitution can change")
	var available := session.constitution_system.get_available_policies(session.context)
	t.check(current_policy in available, "the revised constitution supplies current policies")
	t.check(old_policy not in available, "the revised constitution removes old policies")
	t.check(session.edit_saved_bill(0), "the old bill still opens after constitution revision")
	t.check_equal(
		session.state.draft_bill.policies.size(),
		0,
		"loading filters policies that are no longer constitution-authorized"
	)
	session.state.draft_bill.policies.append(old_policy)
	t.check(
		not session.draft_bill_system.is_ready_to_submit(
			session.context, session.state.draft_bill
		),
		"submission still defers policy availability to ConstitutionSystem"
	)
	session.free()
