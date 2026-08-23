extends RefCounted

const BackendTestContext = preload("res://tests/backend/backend_test_context.gd")


func run(t: BackendTestContext) -> void:
	_test_saved_bill_editing_is_isolated(t)
	_test_saved_policy_reconciles_with_constitution(t)


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
	var replacement := saved.proposals[0].copy()
	session.state.proposal_hand = [replacement]
	t.check(session.edit_saved_bill(0), "a saved bill can be loaded for editing")
	t.check_equal(
		session.state.editing_saved_bill_index, 0, "editing tracks the saved bill index"
	)
	t.check(
		session.state.draft_bill.proposals[0] == replacement,
		"loading uses an equivalent current hand instance"
	)
	t.check_equal(session.state.proposal_hand.size(), 0, "the matched hand card is reserved")
	session.state.draft_bill.title = "edited"
	replacement.base_effect.tax = 12
	session.draft_bill_system.save_draft(session.state)
	t.check_equal(session.state.saved_bills.size(), 1, "editing overwrites instead of appending")
	t.check_equal(session.state.saved_bills[0].title, "edited", "overwrite saves the new title")
	t.check_equal(
		session.state.saved_bills[0].proposals[0].base_effect.tax,
		12,
		"overwrite saves edited proposal content"
	)
	replacement.base_effect.tax = 77
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
