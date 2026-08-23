<script lang="ts">
	import { untrack } from 'svelte';
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import Left from '$lib/components/left/Left.svelte';
	import type { BillLeftItem, LeftItem, LeftMode } from '$lib/components/left/types';
	import { MemorialBillEditor } from '$lib/components/memorial';
	import type { MemorialMetricData } from '$lib/components/memorial/types';
	import Newspaper from '$lib/components/newspaper/Newspaper.svelte';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import Top from '$lib/components/top/Top.svelte';
	import { reconcileSavedBill, type Bill, type PolicyDefinition, type Proposal } from '$lib/game';
	import type { ViewFrameProps } from './types';

	type Props = ViewFrameProps & {
		stateVersion: number;
		draft: Bill;
		proposalHand: Proposal[];
		availablePolicies: PolicyDefinition[];
		editingSavedBillIndex?: number;
		preview: MemorialMetricData[];
		voteCanPass: boolean;
		onAddProposal?: (handIndex: number) => void;
		onRemoveProposal?: (draftIndex: number) => void;
		onAddPolicy?: (displayName: string) => void;
		onRemovePolicy?: (draftIndex: number) => void;
		onTitleChange?: (title: string) => void;
		onEditSavedBill?: (savedBillIndex: number) => void;
		onSubmit?: () => void;
	};

	let {
		items,
		baseline,
		raceItems,
		interestGroupItems,
		gameState,
		term,
		year,
		month,
		onNewspaperOpen,
		stateVersion,
		draft,
		proposalHand,
		availablePolicies,
		editingSavedBillIndex,
		preview,
		voteCanPass,
		onAddProposal,
		onRemoveProposal,
		onAddPolicy,
		onRemovePolicy,
		onTitleChange,
		onEditSavedBill,
		onSubmit
	}: Props = $props();
	let activeLeftMode = $state<LeftMode>('archive');
	let voteMode = $state(false);
	let optimisticDraft = $state<Bill>();
	let appliedVersion = $state(untrack(() => stateVersion));
	let appliedDraft = $state(untrack(() => draft));
	let visibleDraft = $derived(optimisticDraft ?? draft);
	let selection = $derived({
		proposalRefs: [],
		policyDisplayNames: visibleDraft.policies.map((policy) => policy.display_name),
		editingSavedBillIndex
	});

	$effect(() => {
		if (stateVersion === appliedVersion && draft === appliedDraft) return;
		appliedVersion = stateVersion;
		appliedDraft = draft;
		optimisticDraft = undefined;
	});

	function selectLeft(item: LeftItem, mode: LeftMode) {
		if (mode !== 'selection') return;
		if (item.kind === 'proposal') return onAddProposal?.(item.ref.index);
		if (item.kind === 'policy') return onAddPolicy?.(item.policy.display_name);
		if (item.kind === 'bill') loadBill(item);
	}

	function loadBill(savedItem: BillLeftItem) {
		optimisticDraft = reconcileSavedBill(
			savedItem.bill,
			[...proposalHand, ...draft.proposals],
			availablePolicies
		);
		onEditSavedBill?.(savedItem.ref.index);
	}

	function removeProposal(_proposal: Proposal, index: number) {
		onRemoveProposal?.(index);
	}

	function removePolicy(_policy: PolicyDefinition, index: number) {
		onRemovePolicy?.(index);
	}

	function setTitle(title: string) {
		optimisticDraft = { ...visibleDraft, title };
		onTitleChange?.(title);
	}

	function submitDraft(isVote: boolean) {
		if (!isVote) return;
		onSubmit?.();
		queueMicrotask(() => (voteMode = false));
	}
</script>

<main class="game-view" aria-label="议会界面">
	<Left
		scene="parliament"
		{items}
		{baseline}
		bind:activeMode={activeLeftMode}
		{selection}
		onItemSelect={selectLeft}
	/>
	<Newspaper {term} {year} {month} onOpen={onNewspaperOpen} />
	<div class="top-slot">
		<Top {raceItems} {interestGroupItems} />
	</div>
	<div class="state-slot"><GameStateDisplay {...gameState} /></div>
	<div class="editor-slot">
		<div class="editor-content">
			<div class="vote-switch">
				<ChoreSwitch
					left="草案"
					right={voteCanPass ? '投票(可通过)' : '投票(不可通过)'}
					bind:isSwitch={voteMode}
					onSwitchChange={submitDraft}
				/>
			</div>
			<MemorialBillEditor
				bill={visibleDraft}
				{preview}
				onTitleChange={setTitle}
				onRemoveProposal={removeProposal}
				onRemovePolicy={removePolicy}
			/>
		</div>
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
		left: 0;
		z-index: 60;
		display: flex;
		width: 100%;
		justify-content: center;
	}

	.editor-content {
		display: flex;
		width: max-content;
		flex-direction: column;
		align-items: flex-end;
	}

	.vote-switch {
		margin-bottom: 8px;
	}
</style>
