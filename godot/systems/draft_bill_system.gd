extends RefCounted
class_name DraftBillSystem


func move_proposal_from_hand(state: RunState, hand_index: int) -> bool:
	if hand_index < 0 or hand_index >= state.proposal_hand.size():
		return false
	var proposal := state.proposal_hand.pop_at(hand_index)
	state.draft_bill.proposals.append(proposal)
	return true


func return_proposal_to_hand(state: RunState, draft_index: int) -> bool:
	if draft_index < 0 or draft_index >= state.draft_bill.proposals.size():
		return false
	var proposal := state.draft_bill.proposals.pop_at(draft_index)
	state.proposal_hand.append(proposal)
	return true


func add_policy(state: RunState, policy: PolicyDefinition) -> bool:
	if policy == null:
		return false
	for current in state.draft_bill.policies:
		if current == policy or current.id == policy.id:
			return false
	state.draft_bill.policies.append(policy)
	return true


func remove_policy(state: RunState, draft_index: int) -> bool:
	if draft_index < 0 or draft_index >= state.draft_bill.policies.size():
		return false
	state.draft_bill.policies.remove_at(draft_index)
	return true


func clear_draft(state: RunState) -> void:
	state.proposal_hand.append_array(state.draft_bill.proposals)
	state.draft_bill = DraftBillState.new()
