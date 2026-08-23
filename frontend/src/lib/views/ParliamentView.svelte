<script lang="ts">
	import ContextDetail from '$lib/components/detail/ContextDetail.svelte';
	import Left from '$lib/components/left/Left.svelte';
	import { isSameLeftRef } from '$lib/components/left/left';
	import type { LeftItem, ProposalLeftItem } from '$lib/components/left/types';
	import { MemorialBillEditor } from '$lib/components/memorial';
	import Newspaper from '$lib/components/newspaper/Newspaper.svelte';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import Top from '$lib/components/top/Top.svelte';
	import {
		arePoliciesGameplayEquivalent,
		reconcileSavedBill,
		type Bill,
		type PolicyDefinition,
		type Proposal
	} from '$lib/game';
	import {
		getMockBillPreview,
		mockArchiveItems,
		mockBaseline,
		mockLegislatorDetail,
		mockMergedProposal,
		mockPolicies,
		mockPolicyItems,
		mockProposalItems,
		mockState,
		mockTopItems
	} from '$lib/demo/mock';

	const initialDraftProposal = mockProposalItems[0];
	let proposalHand = $state<ProposalLeftItem[]>(mockProposalItems.slice(1));
	let draftProposalItems = $state<ProposalLeftItem[]>([initialDraftProposal]);
	let draft = $state<Bill>({
		title: '新港通商案',
		proposals: [initialDraftProposal.proposal],
		policies: [mockPolicies[4]]
	});
	let nextProposalIndex = $state(20);
	let notice = $state('点击 Left 中的提案、政策或已保存法案。');
	let availablePolicyItems = $derived(
		mockPolicyItems.filter(
			(item) => !draft.policies.some((policy) => arePoliciesGameplayEquivalent(policy, item.policy))
		)
	);
	let leftItems: LeftItem[] = $derived([
		...mockArchiveItems,
		...proposalHand,
		...availablePolicyItems
	]);
	let preview = $derived(getMockBillPreview(draft));
	let topItems = $derived(
		mockTopItems.map((item) => ({
			...item,
			onSelect: () => (notice = `议会 Top：${item.item.text}`),
			onAction: () => (notice = `${item.item.text} callback 已触发`)
		}))
	);

	function selectLeft(item: LeftItem) {
		if (item.kind === 'proposal') return addProposal(item);
		if (item.kind === 'policy') return addPolicy(item.policy);
		if (item.kind === 'bill') return loadBill(item.bill);
		notice = `查看约法：${item.constitution.title}`;
	}

	function addProposal(item: ProposalLeftItem) {
		proposalHand = proposalHand.filter((current) => !isSameLeftRef(current.ref, item.ref));
		draftProposalItems = [...draftProposalItems, item];
		draft = { ...draft, proposals: [...draft.proposals, item.proposal] };
		notice = `已加入 ${item.proposal.source_group.display_name} 提案；preview 使用 mock 返回值更新`;
	}

	function addPolicy(policy: PolicyDefinition) {
		if (draft.policies.some((current) => arePoliciesGameplayEquivalent(current, policy))) return;
		draft = { ...draft, policies: [...draft.policies, policy] };
		notice = `已加入政策 ${policy.display_name}`;
	}

	function loadBill(saved: Bill) {
		const allProposalItems = [...proposalHand, ...draftProposalItems];
		const reconciled = reconcileSavedBill(
			saved,
			allProposalItems.map((item) => item.proposal),
			mockPolicies
		);
		const matches = reconciled.proposals.flatMap((proposal) => {
			const match = allProposalItems.find((item) => item.proposal === proposal);
			return match ? [match] : [];
		});
		draftProposalItems = matches;
		proposalHand = allProposalItems.filter(
			(item) => !matches.some((match) => isSameLeftRef(item.ref, match.ref))
		);
		draft = reconciled;
		notice = `已装载「${saved.title}」：失效提案/政策已由 reconciliation 移除`;
	}

	function removeProposal(_proposal: Proposal, index: number) {
		const restored = draftProposalItems[index];
		if (restored) proposalHand = [...proposalHand, restored];
		draftProposalItems = draftProposalItems.filter((_, itemIndex) => itemIndex !== index);
		draft = { ...draft, proposals: draft.proposals.filter((_, itemIndex) => itemIndex !== index) };
		notice = '提案已从法案删除并恢复到 hand';
	}

	function removePolicy(_policy: PolicyDefinition, index: number) {
		draft = { ...draft, policies: draft.policies.filter((_, itemIndex) => itemIndex !== index) };
		notice = '政策已从法案删除并恢复到 Left';
	}

	function synthesize(result: import('$lib/components/left/types').SynthesisConfirmation) {
		proposalHand = proposalHand.filter(
			(item) => !result.refs.some((ref) => isSameLeftRef(item.ref, ref))
		);
		proposalHand = [
			...proposalHand,
			{
				kind: 'proposal',
				ref: { collection: 'proposals', index: nextProposalIndex++ },
				proposal: { ...mockMergedProposal, source_group: { ...mockMergedProposal.source_group } }
			}
		];
		notice = `mock 合成完成；reverse 来源 index ${result.reverseSource?.ref.index ?? '无'}`;
	}
</script>

<main class="game-view" aria-label="议会界面">
	<div class="left-slot">
		<Left
			items={leftItems}
			baseline={mockBaseline}
			onItemSelect={selectLeft}
			onSynthesisConfirm={synthesize}
		/>
	</div>
	<Newspaper term={2} year={3} month={7} onOpen={() => (notice = '议会邸报 callback')} />
	<div class="top-slot"><Top items={topItems} /></div>
	<div class="legislator">
		<ContextDetail
			{...mockLegislatorDetail}
			onAction={(isRight) => (notice = `议员 callback：${isRight ? '交涉' : '立场'}`)}
		/>
	</div>
	<div class="state-slot"><GameStateDisplay {...mockState} /></div>
	<div class="editor-slot">
		<MemorialBillEditor
			bill={draft}
			{preview}
			onTitleChange={(title) => (draft = { ...draft, title })}
			onRemoveProposal={removeProposal}
			onRemovePolicy={removePolicy}
			onSubmit={(bill) => (notice = `提交法案 callback：「${bill.title}」`)}
		/>
	</div>
	<p class="notice" aria-live="polite">{notice}</p>
</main>

<style>
	.game-view {
		position: relative;
		height: 100vh;
		overflow: hidden;
		background: transparent;
	}
	.left-slot {
		position: absolute;
		inset: 150px auto 20px 24px;
	}
	.top-slot {
		position: absolute;
		top: 20px;
		right: 26px;
	}
	.legislator {
		position: absolute;
		top: 210px;
		right: 26px;
	}
	.state-slot {
		position: absolute;
		right: 26px;
		bottom: 26px;
	}
	.editor-slot {
		position: absolute;
		left: 48%;
		bottom: 34px;
		transform: translateX(-50%) scale(0.88);
		transform-origin: bottom center;
	}
	.notice {
		position: absolute;
		left: 50%;
		top: 18px;
		margin: 0;
		transform: translateX(-50%);
		background: #1e2e3b;
		padding: 5px 12px;
		color: #efb836;
		font: 300 16px 'RealTypeWriter';
	}
</style>
