<script lang="ts">
	import { resolve } from '$app/paths';
	import { restoreProposalToHand, sortProposalItemsByTime } from '$lib/components/left/left';
	import type { LeftItem, ProposalLeftItem } from '$lib/components/left/types';
	import { NewspaperEventState, NewspaperRace } from '$lib/components/newspaper/types';
	import { Metric, type Bill } from '$lib/game';
	import ConstitutionView from '$lib/views/ConstitutionView.svelte';
	import DialogueView from '$lib/views/DialogueView.svelte';
	import OfficeView from '$lib/views/OfficeView.svelte';
	import NewspaperView from '$lib/views/NewspaperView.svelte';
	import ParliamentView from '$lib/views/ParliamentView.svelte';
	import {
		getMockBillPreview,
		mockArchiveItems,
		mockBaseline,
		mockConstitution,
		mockConstitutionMemorial,
		mockInterestGroupTopItems,
		mockPolicies,
		mockPolicyItems,
		mockProposalItems,
		mockRaceTopItems,
		mockState
	} from './mock';

	type ViewName = 'Office' | 'Dialogue' | 'Parliament' | 'Newspaper' | 'Constitution';
	const views: ViewName[] = ['Office', 'Dialogue', 'Parliament', 'Newspaper', 'Constitution'];
	const mockConstitutionColumns = Object.keys(mockConstitutionMemorial).map(
		(display_name, column_index) => ({
			column_index,
			id: `mock-${column_index}`,
			display_name,
			unlock_cost_months: 0,
			unlocked: true,
			can_unlock: false
		})
	);
	const initialDraftProposal = mockProposalItems[0];
	const mockNewspaper = {
		year: 3,
		month: 7,
		metrics: [
			{ metric: Metric.TAX, value: 62, change: 2 },
			{ metric: Metric.CONSUMPTION, value: 71, change: -1 },
			{ metric: Metric.PRODUCTION, value: 48, change: 3 },
			{ metric: Metric.EMPLOYMENT, value: 55, change: 0 },
			{ metric: Metric.INVESTMENT, value: 83, change: -4 }
		],
		events: [
			{
				race: NewspaperRace.NANKE,
				description:
					'南柯承担蓬莱最重的现实劳动，也最在意劳动是否还有位置、成果是否能换成生活。就业或消费落后时，他们会认为现实正在离梦中那个更好的社会越来越远。',
				metric: Metric.PRODUCTION,
				value: 52,
				countdown: 3,
				strength: 100,
				state: NewspaperEventState.DETERIORATION
			},
			{
				race: NewspaperRace.BIYI,
				description:
					'比翼把知识地位的流失首先体验为职位与发展机会减少。就业不足会成为两半共同的焦虑；阴月又担心公共机构缺少税课，阳月则担心新的知识产业缺少投资。',
				metric: Metric.CONSUMPTION,
				value: 60,
				countdown: 7,
				strength: 72,
				state: NewspaperEventState.POSTPONED
			}
		]
	};
	const MOCK_NEWSPAPER_CLOSE_TARGET: Exclude<ViewName, 'Newspaper'> = 'Constitution';
	let activeView = $state<ViewName>('Office');
	let stateVersion = $state(0);
	let proposalHand = $state<ProposalLeftItem[]>(mockProposalItems.slice(1));
	let draftProposalItems = $state<ProposalLeftItem[]>([initialDraftProposal]);
	let editingSavedBillIndex = $state<number>();
	let draft = $state<Bill>({
		title: '勘合互市',
		proposals: [initialDraftProposal.proposal],
		policies: [mockPolicies[0]]
	});
	let items: LeftItem[] = $derived([...mockArchiveItems, ...proposalHand, ...mockPolicyItems]);
	let preview = $derived(getMockBillPreview(draft));
	let frame = $derived({
		items,
		baseline: mockBaseline,
		raceItems: mockRaceTopItems,
		interestGroupItems: mockInterestGroupTopItems,
		gameState: mockState,
		term: 2,
		year: 3,
		month: 7
	});

	function openNewspaper() {
		activeView = 'Newspaper';
	}

	function closeNewspaper() {
		console.info('Mock Godot resolved Newspaper close to', MOCK_NEWSPAPER_CLOSE_TARGET);
		activeView = MOCK_NEWSPAPER_CLOSE_TARGET;
	}

	function selectView(view: ViewName) {
		if (view === 'Newspaper') return openNewspaper();
		activeView = view;
	}

	function addProposal(handIndex: number) {
		const item = proposalHand.find((current) => current.ref.index === handIndex);
		if (!item) return;
		proposalHand = proposalHand.filter((current) => current !== item);
		draftProposalItems = [...draftProposalItems, item];
		draft = { ...draft, proposals: [...draft.proposals, item.proposal] };
		stateVersion += 1;
	}

	function removeProposal(draftIndex: number) {
		const item = draftProposalItems[draftIndex];
		if (item) proposalHand = restoreProposalToHand(proposalHand, item);
		draftProposalItems = draftProposalItems.filter((_, index) => index !== draftIndex);
		draft = { ...draft, proposals: draft.proposals.filter((_, index) => index !== draftIndex) };
		stateVersion += 1;
	}

	function addPolicy(displayName: string) {
		const policy = mockPolicies.find((current) => current.display_name === displayName);
		if (!policy || draft.policies.some((current) => current.display_name === displayName)) return;
		draft = { ...draft, policies: [...draft.policies, policy] };
		stateVersion += 1;
	}

	function removePolicy(draftIndex: number) {
		draft = { ...draft, policies: draft.policies.filter((_, index) => index !== draftIndex) };
		stateVersion += 1;
	}

	function editSavedBill(savedBillIndex: number) {
		const saved = mockArchiveItems.find(
			(item) => item.kind === 'bill' && item.ref.index === savedBillIndex
		);
		if (!saved || saved.kind !== 'bill') return;
		const available = sortProposalItemsByTime([...proposalHand, ...draftProposalItems], true);
		const matched = saved.bill.proposals.flatMap((proposal) => {
			const item = available.find((candidate) => candidate.proposal === proposal);
			return item ? [item] : [];
		});
		proposalHand = available.filter((item) => !matched.includes(item));
		draftProposalItems = matched;
		draft = {
			title: saved.bill.title,
			proposals: matched.map((item) => item.proposal),
			policies: saved.bill.policies.filter((policy) =>
				mockPolicies.some((availablePolicy) => availablePolicy.display_name === policy.display_name)
			)
		};
		editingSavedBillIndex = savedBillIndex;
		stateVersion += 1;
	}

	function setTitle(title: string) {
		draft = { ...draft, title };
		stateVersion += 1;
	}
</script>

<svelte:head>
	<title>Nothing Happens · Frontend UI Demo</title>
</svelte:head>

<div class="demo-stage">
	{#if activeView === 'Office'}
		<OfficeView
			{...frame}
			onNewspaperOpen={openNewspaper}
			onSynthesisConfirm={(result) => console.info('Office synthesis', result)}
		/>
	{:else if activeView === 'Dialogue'}
		<DialogueView
			{...frame}
			onNewspaperOpen={openNewspaper}
			dialogue={{
				handIndex: 0,
				groupName: '造身公所',
				positiveEffect: '投資+8',
				donationOffer: '政治献金+5'
			}}
			onResolveBonus={(_, acceptTrait) =>
				console.info('Dialogue choice', acceptTrait ? 'trait' : 'donation')}
		/>
	{:else if activeView === 'Parliament'}
		<ParliamentView
			{...frame}
			onNewspaperOpen={openNewspaper}
			{stateVersion}
			{draft}
			proposalHand={proposalHand.map((item) => item.proposal)}
			availablePolicies={mockPolicies}
			{editingSavedBillIndex}
			{preview}
			voteCanPass
			onAddProposal={addProposal}
			onRemoveProposal={removeProposal}
			onAddPolicy={addPolicy}
			onRemovePolicy={removePolicy}
			onTitleChange={setTitle}
			onEditSavedBill={editSavedBill}
			onSubmit={() => console.info('Submit bill', draft)}
		/>
	{:else if activeView === 'Newspaper'}
		<NewspaperView {...mockNewspaper} onRequestClose={closeNewspaper} />
	{:else}
		<ConstitutionView
			raceItems={mockRaceTopItems}
			interestGroupItems={mockInterestGroupTopItems}
			governingMonths={30}
			term={frame.term}
			year={frame.year}
			month={frame.month}
			onNewspaperOpen={openNewspaper}
			title={mockConstitution.title}
			constitution={mockConstitutionMemorial}
			columns={mockConstitutionColumns}
		/>
	{/if}

	<nav class="view-selector" aria-label="开发界面切换">
		{#each views as view (view)}
			<button type="button" class:active={activeView === view} onclick={() => selectView(view)}>
				{view}
			</button>
		{/each}
		<a href={resolve('/components')}>Components</a>
	</nav>
</div>

<style>
	.demo-stage {
		min-height: 100vh;
	}

	.view-selector {
		position: fixed;
		z-index: 100;
		left: 50%;
		bottom: 8px;
		display: flex;
		gap: 2px;
		transform: translateX(-50%);
	}

	.view-selector button,
	.view-selector a {
		cursor: pointer;
		border: 0;
		background: #344654;
		padding: 6px 10px;
		color: #efb836;
		font: 300 14px 'RealTypeWriter';
		text-decoration: none;
	}

	.view-selector button.active {
		background: #efb836;
		color: #1e2e3b;
	}
</style>
