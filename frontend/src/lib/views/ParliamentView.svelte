<script lang="ts">
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import Left from '$lib/components/left/Left.svelte';
	import {
		isSameLeftRef,
		restoreProposalToHand,
		sortProposalItemsByTime
	} from '$lib/components/left/left';
	import type {
		BillLeftItem,
		LeftItem,
		LeftMode,
		ProposalLeftItem
	} from '$lib/components/left/types';
	import { MemorialBillEditor } from '$lib/components/memorial';
	import Newspaper from '$lib/components/newspaper/Newspaper.svelte';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import Top from '$lib/components/top/Top.svelte';
	import { reconcileSavedBill, type Bill, type PolicyDefinition, type Proposal } from '$lib/game';
	import {
		getMockBillPreview,
		mockArchiveItems,
		mockBaseline,
		mockInterestGroupTopItems,
		mockPolicies,
		mockPolicyItems,
		mockProposalItems,
		mockRaceTopItems,
		mockState
	} from '$lib/demo/mock';

	const initialDraftProposal = mockProposalItems[0];
	let activeLeftMode = $state<LeftMode>('archive');
	let proposalHand = $state<ProposalLeftItem[]>(mockProposalItems.slice(1));
	let draftProposalItems = $state<ProposalLeftItem[]>([initialDraftProposal]);
	let editingSavedBillIndex = $state<number>();
	let voteMode = $state(false);
	let draft = $state<Bill>({
		title: '勘合互市',
		proposals: [initialDraftProposal.proposal],
		policies: [mockPolicies[0]]
	});

	let allProposalItems = $derived(
		sortProposalItemsByTime([...proposalHand, ...draftProposalItems], true)
	);
	let leftItems: LeftItem[] = $derived([
		...mockArchiveItems,
		...allProposalItems,
		...mockPolicyItems
	]);
	let selection = $derived({
		proposalRefs: draftProposalItems.map((item) => item.ref),
		policyDisplayNames: draft.policies.map((policy) => policy.display_name),
		editingSavedBillIndex
	});
	let preview = $derived(getMockBillPreview(draft));

	function selectLeft(item: LeftItem, mode: LeftMode) {
		if (mode !== 'selection') return;
		if (item.kind === 'proposal') return addProposal(item);
		if (item.kind === 'policy') return addPolicy(item.policy);
		if (item.kind === 'bill') loadBill(item);
	}

	function addProposal(item: ProposalLeftItem) {
		if (draftProposalItems.some((current) => isSameLeftRef(current.ref, item.ref))) return;
		proposalHand = proposalHand.filter((current) => !isSameLeftRef(current.ref, item.ref));
		draftProposalItems = [...draftProposalItems, item];
		draft = { ...draft, proposals: [...draft.proposals, item.proposal] };
	}

	function addPolicy(policy: PolicyDefinition) {
		if (draft.policies.some((current) => current.display_name === policy.display_name)) return;
		draft = { ...draft, policies: [...draft.policies, policy] };
	}

	function loadBill(savedItem: BillLeftItem) {
		const availableProposalItems = sortProposalItemsByTime(
			[...proposalHand, ...draftProposalItems],
			true
		);
		const reconciled = reconcileSavedBill(
			savedItem.bill,
			availableProposalItems.map((item) => item.proposal),
			mockPolicies
		);
		const matches = reconciled.proposals.flatMap((proposal) => {
			const match = availableProposalItems.find((item) => item.proposal === proposal);
			return match ? [match] : [];
		});
		draftProposalItems = matches;
		proposalHand = availableProposalItems.filter(
			(item) => !matches.some((match) => isSameLeftRef(item.ref, match.ref))
		);
		draft = reconciled;
		editingSavedBillIndex = savedItem.ref.index;
	}

	function removeProposal(_proposal: Proposal, index: number) {
		const restored = draftProposalItems[index];
		if (restored) proposalHand = restoreProposalToHand(proposalHand, restored);
		draftProposalItems = draftProposalItems.filter((_, itemIndex) => itemIndex !== index);
		draft = { ...draft, proposals: draft.proposals.filter((_, itemIndex) => itemIndex !== index) };
	}

	function removePolicy(_policy: PolicyDefinition, index: number) {
		draft = { ...draft, policies: draft.policies.filter((_, itemIndex) => itemIndex !== index) };
	}

	function submitDraft(isVote: boolean) {
		if (!isVote) return;
		console.info('Submit bill', draft);
		editingSavedBillIndex = undefined;
		queueMicrotask(() => (voteMode = false));
	}
</script>

<main class="game-view" aria-label="议会界面">
	<Left
		scene="parliament"
		items={leftItems}
		baseline={mockBaseline}
		bind:activeMode={activeLeftMode}
		{selection}
		onItemSelect={selectLeft}
	/>
	<Newspaper term={2} year={3} month={7} onOpen={() => console.info('Open newspaper')} />
	<div class="top-slot">
		<Top raceItems={mockRaceTopItems} interestGroupItems={mockInterestGroupTopItems} />
	</div>
	<div class="state-slot"><GameStateDisplay {...mockState} /></div>
	<div class="editor-slot">
		<div class="vote-switch">
			<ChoreSwitch
				left="草案"
				right="投票(可通过)"
				bind:isSwitch={voteMode}
				onSwitchChange={submitDraft}
			/>
		</div>
		<MemorialBillEditor
			bill={draft}
			{preview}
			onTitleChange={(title) => (draft = { ...draft, title })}
			onRemoveProposal={removeProposal}
			onRemovePolicy={removePolicy}
		/>
	</div>
</main>

<style>
	.game-view {
		position: relative;
		height: 100vh;
		overflow: hidden;
	}

	.top-slot {
		position: absolute;
		top: 0;
		right: 0;
	}

	.state-slot {
		position: absolute;
		top: 72px;
		right: 0;
	}

	.editor-slot {
		position: absolute;
		bottom: 20px;
		left: 5.208%;
		display: flex;
		width: 88.086%;
		flex-direction: column;
		align-items: flex-start;
	}

	.vote-switch {
		align-self: flex-end;
		margin-bottom: 8px;
	}
</style>
