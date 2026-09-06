<script lang="ts">
	import { onMount, untrack } from 'svelte';
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import Left from '$lib/components/left/Left.svelte';
	import type { BillLeftItem, LeftItem, LeftMode } from '$lib/components/left/types';
	import { MemorialBillEditor } from '$lib/components/memorial';
	import type { MemorialMetricData } from '$lib/components/memorial/types';
	import NewspaperEntry from '$lib/components/newspaper/NewspaperEntry.svelte';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import Top from '$lib/components/top/Top.svelte';
	import {
		calculatePureProposalTarget,
		reconcileSavedBill,
		type Bill,
		type PolicyDefinition,
		type Proposal
	} from '$lib/game';
	import type { ParliamentSeatAnchorDto, SeatSummaryDto, SeatVoteDto } from '$lib/game/state/types';
	import type { ViewFrameProps } from './types';

	type AnchoredSeat = ParliamentSeatAnchorDto & {
		score: number;
		canBribe: boolean;
	};

	type Props = ViewFrameProps & {
		stateVersion: number;
		draft: Bill;
		proposalHand: Proposal[];
		availablePolicies: PolicyDefinition[];
		editingSavedBillIndex?: number;
		seats: SeatSummaryDto[];
		seatAnchors: ParliamentSeatAnchorDto[];
		seatVotes: SeatVoteDto[];
		preview: MemorialMetricData[];
		voteCanPass: boolean;
		supportCount: number;
		onAddProposal?: (handIndex: number) => void;
		onRemoveProposal?: (draftIndex: number) => void;
		onAddPolicy?: (displayName: string) => void;
		onRemovePolicy?: (draftIndex: number) => void;
		onTitleChange?: (title: string) => void;
		onEditSavedBill?: (savedBillIndex: number) => void;
		onBribeSeat?: (seatIndex: number) => void;
		onSubmit?: () => void;
	};

	const LEFT_SCROLL_RESERVE = 390;
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
		seats,
		seatAnchors,
		seatVotes,
		preview,
		voteCanPass,
		supportCount,
		onAddProposal,
		onRemoveProposal,
		onAddPolicy,
		onRemovePolicy,
		onTitleChange,
		onEditSavedBill,
		onBribeSeat,
		onSubmit
	}: Props = $props();
	let activeLeftMode = $state<LeftMode>('archive');
	let voteMode = $state(false);
	let optimisticDraft = $state<Bill>();
	let appliedVersion = untrack(() => stateVersion);
	let appliedDraft = untrack(() => draft);
	let visibleDraft = $derived(optimisticDraft ?? draft);
	let policyBaseline = $derived(calculatePureProposalTarget(baseline, visibleDraft.proposals));
	let selection = $derived({
		proposalRefs: [],
		policyDisplayNames: visibleDraft.policies.map((policy) => policy.display_name),
		editingSavedBillIndex
	});
	let anchoredSeats = $derived(mergeSeats(seats, seatAnchors, seatVotes));
	let votesNeeded = $derived(Math.max(0, Math.floor(seats.length / 2) + 1 - supportCount));
	let editorScroller: HTMLDivElement;

	onMount(() => {
		editorScroller.scrollLeft = LEFT_SCROLL_RESERVE;
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

	function bribeSeat(seatIndex: number, isSwitch: boolean) {
		if (!isSwitch) return;
		onBribeSeat?.(seatIndex);
	}

	function mergeSeats(
		currentSeats: SeatSummaryDto[],
		currentAnchors: ParliamentSeatAnchorDto[],
		currentVotes: SeatVoteDto[]
	): AnchoredSeat[] {
		const anchorsByIndex = new Map(currentAnchors.map((anchor) => [anchor.seat_index, anchor]));
		const votesByIndex = new Map(currentVotes.map((vote) => [vote.seat_index, vote]));
		return currentSeats.flatMap((seat): AnchoredSeat[] => {
			const anchor = anchorsByIndex.get(seat.seat_index);
			const vote = votesByIndex.get(seat.seat_index);
			return anchor && vote
				? [
						{
							...anchor,
							score: vote.score,
							canBribe: vote.can_bribe
						}
					]
				: [];
		});
	}
</script>

<main class="game-view" aria-label="议会界面">
	<div class="seat-layer">
		{#each anchoredSeats as seat (seat.seat_index)}
			<div class="seat-anchor" style:left={`${seat.x * 100}%`} style:top={`${seat.y * 100}%`}>
				<ChoreSwitch
					left={String(seat.score)}
					right={seat.score > 0 ? '支持' : '贿赂'}
					isSwitch={seat.score > 0}
					disabled={seat.score > 0 || !seat.canBribe}
					onSwitchChange={(isSwitch) => bribeSeat(seat.seat_index, isSwitch)}
				/>
			</div>
		{/each}
	</div>
	<Left
		scene="parliament"
		{items}
		baseline={policyBaseline}
		bind:activeMode={activeLeftMode}
		{selection}
		onItemSelect={selectLeft}
	/>
	<NewspaperEntry {term} {year} {month} onOpen={onNewspaperOpen} />
	<div class="top-slot">
		<Top {raceItems} {interestGroupItems} />
	</div>
	<div class="state-slot"><GameStateDisplay {...gameState} /></div>
	<div bind:this={editorScroller} class="editor-slot">
		<div class="editor-scroll-range">
			<div class="editor-track">
				<div class="editor-content">
					<div class="vote-switch">
						<ChoreSwitch
							left="草案"
							right={voteCanPass ? '投票(可通过)' : `投票(差${votesNeeded}票)`}
							bind:isSwitch={voteMode}
							disabled={!voteCanPass}
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
		</div>
	</div>
</main>

<style>
	.game-view {
		position: relative;
		height: 100vh;
		overflow: hidden;
	}

	.seat-layer {
		position: absolute;
		inset: 0;
		pointer-events: none;
	}

	.seat-anchor {
		position: absolute;
		transform: translate(-50%, -50%);
		pointer-events: auto;
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
		z-index: 20;
		width: 100%;
		overflow-x: auto;
		scrollbar-width: none;
		overscroll-behavior-x: contain;
	}

	.editor-slot::-webkit-scrollbar {
		display: none;
	}

	.editor-scroll-range {
		display: flex;
		width: max-content;
		padding-left: 390px;
	}

	.editor-track {
		display: flex;
		width: max-content;
		min-width: 100vw;
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
