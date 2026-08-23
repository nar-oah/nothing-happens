extends RefCounted
class_name DraftBillSystem


func move_proposal_from_hand(state: RunState, hand_index: int) -> bool:
	if hand_index < 0 or hand_index >= state.proposal_hand.size():
		return false
	if state.proposal_hand[hand_index].is_bonus_choice_pending():
		return false
	var proposal: ProposalInstance = state.proposal_hand.pop_at(hand_index)
	state.draft_bill.proposals.append(proposal)
	return true


func return_proposal_to_hand(state: RunState, draft_index: int) -> bool:
	if draft_index < 0 or draft_index >= state.draft_bill.proposals.size():
		return false
	var proposal: ProposalInstance = state.draft_bill.proposals.pop_at(draft_index)
	state.proposal_hand.append(proposal)
	return true


func _add_policy(state: RunState, policy: PolicyDefinition) -> bool:
	if policy == null:
		return false
	for current in state.draft_bill.policies:
		if current.display_name == policy.display_name:
			return false
	state.draft_bill.policies.append(policy)
	return true


func remove_policy(state: RunState, draft_index: int) -> bool:
	if draft_index < 0 or draft_index >= state.draft_bill.policies.size():
		return false
	state.draft_bill.policies.remove_at(draft_index)
	return true


func add_available_policy(context: RunContext, policy: PolicyDefinition) -> bool:
	if policy == null:
		return false
	return add_available_policy_by_name(context, policy.display_name)


func add_available_policy_by_name(context: RunContext, display_name: String) -> bool:
	var policy := context.constitution_system.get_available_policy(context, display_name)
	return false if policy == null else _add_policy(context.state, policy)


func is_ready_to_submit(context: RunContext, draft: DraftBillState) -> bool:
	if context == null or draft == null or draft.is_empty():
		return false
	for policy in draft.policies:
		if (
			policy == null
			or context.constitution_system.get_available_policy(
				context, policy.display_name
			) == null
		):
			return false
	for proposal in draft.proposals:
		if proposal == null or proposal.is_bonus_choice_pending():
			return false
	return true


func reorder_proposal(state: RunState, from_index: int, to_index: int) -> bool:
	if (
		from_index < 0
		or from_index >= state.draft_bill.proposals.size()
		or to_index < 0
		or to_index >= state.draft_bill.proposals.size()
	):
		return false
	var proposal: ProposalInstance = state.draft_bill.proposals.pop_at(from_index)
	state.draft_bill.proposals.insert(to_index, proposal)
	return true


func reorder_policy(state: RunState, from_index: int, to_index: int) -> bool:
	if (
		from_index < 0
		or from_index >= state.draft_bill.policies.size()
		or to_index < 0
		or to_index >= state.draft_bill.policies.size()
	):
		return false
	var policy: PolicyDefinition = state.draft_bill.policies.pop_at(from_index)
	state.draft_bill.policies.insert(to_index, policy)
	return true


func clear_draft(state: RunState) -> void:
	state.proposal_hand.append_array(state.draft_bill.proposals)
	state.draft_bill = DraftBillState.new()
	state.editing_saved_bill_index = RunState.NEW_BILL_INDEX


func start_new_bill(state: RunState, title: String = "") -> void:
	clear_draft(state)
	state.draft_bill.title = title


func load_saved_bill_for_editing(context: RunContext, saved_index: int) -> bool:
	var state := context.state
	if saved_index < 0 or saved_index >= state.saved_bills.size():
		return false
	var saved := state.saved_bills[saved_index]
	clear_draft(state)
	state.draft_bill.title = saved.title
	state.editing_saved_bill_index = saved_index
	var matches := context.proposal_system.match_equivalent_proposals(
		saved.proposals, state.proposal_hand
	)
	for proposal in matches:
		if proposal == null:
			continue
		state.proposal_hand.erase(proposal)
		state.draft_bill.proposals.append(proposal)
	for saved_policy in saved.policies:
		if saved_policy != null:
			add_available_policy_by_name(context, saved_policy.display_name)
	return true


func save_draft(state: RunState, draft: DraftBillState = null) -> int:
	var source := state.draft_bill if draft == null else draft
	var saved := SavedBillState.new()
	saved.title = source.title
	for proposal in source.proposals:
		saved.proposals.append(proposal.copy())
	saved.policies.assign(source.policies)
	var saved_index := state.editing_saved_bill_index
	if saved_index < 0 or saved_index >= state.saved_bills.size():
		state.saved_bills.append(saved)
		saved_index = state.saved_bills.size() - 1
	else:
		state.saved_bills[saved_index] = saved
	state.editing_saved_bill_index = saved_index
	return saved_index


func cancel_editing(state: RunState) -> void:
	clear_draft(state)
