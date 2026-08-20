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


func add_policy(state: RunState, policy: PolicyDefinition) -> bool:
	if policy == null:
		return false
	for current in state.draft_bill.policies:
		if current == policy:
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
	var available := context.constitution_system.get_available_policies(context)
	for candidate in available:
		if candidate == policy:
			return add_policy(context.state, policy)
	return false


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
