<script lang="ts">
	import { playUiSfx } from '$lib/audio/ui-sfx';
	import { t } from '$lib/i18n';
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
		calculateDraftProjectedMetrics,
		clampBillPolicyDelays,
		clampPolicyDelayMonths,
		getPolicyDelayBounds,
		reconcileSavedBill,
		type Bill,
		type PolicyDefinition,
		type PolicyInstance,
		type Proposal
	} from '$lib/game';
	import type { ParliamentSeatAnchorDto, SeatSummaryDto, SeatVoteDto } from '$lib/game/state/types';
	import {
		ABSENT_POSITION,
		SUPPORT_POSITION,
		deriveLocalVote,
		donationTotal,
		seatActionText,
		seatScoreText,
		toggleBribedSeat
	} from './parliament';
	import type { ViewFrameProps } from './types';

	type AnchoredSeat = ParliamentSeatAnchorDto & SeatVoteDto;

	type Props = ViewFrameProps & {
		stateVersion: number;
		draft: Bill;
		proposalHand: Proposal[];
		availablePolicies: PolicyDefinition[];
		editingSavedBillIndex?: number;
		seats: SeatSummaryDto[];
		seatAnchors: ParliamentSeatAnchorDto[];
		seatVotes: SeatVoteDto[];
		donationPool: number;
		preview: MemorialMetricData[];
		onAddProposal?: (handIndex: number) => void;
		onRemoveProposal?: (draftIndex: number) => void;
		onAddPolicy?: (displayName: string) => void;
		onRemovePolicy?: (draftIndex: number) => void;
		onSetPolicyDelay?: (draftIndex: number, delayMonths: number) => void;
		onTitleChange?: (title: string) => void;
		onEditSavedBill?: (savedBillIndex: number) => void;
		onSubmit?: (bribedSeatIndices: number[]) => void;
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
		donationPool,
		preview,
		onAddProposal,
		onRemoveProposal,
		onAddPolicy,
		onRemovePolicy,
		onSetPolicyDelay,
		onTitleChange,
		onEditSavedBill,
		onSubmit
	}: Props = $props();
	let activeLeftMode = $state<LeftMode>('archive');
	let voteMode = $state(false);
	let optimisticDraft = $state<Bill>();
	let bribedSeats = $state<number[]>([]);
	let appliedVersion = untrack(() => stateVersion);
	let appliedDraft = untrack(() => draft);
	let appliedVoteDraft = untrack(() => voteDraftKey(draft));
	let visibleDraft = $derived(optimisticDraft ?? draft);
	let policyBaseline = $derived(
		calculateDraftProjectedMetrics(baseline, visibleDraft.proposals, visibleDraft.policies)
	);
	let selection = $derived({
		proposalRefs: [],
		policyDisplayNames: visibleDraft.policies.map((policy) => policy.definition.display_name),
		editingSavedBillIndex
	});
	let localVote = $derived(deriveLocalVote(seatVotes, bribedSeats));
	let anchoredSeats = $derived(mergeSeats(seats, seatAnchors, localVote.seatVotes));
	let localDonationPool = $derived(donationPool - donationTotal(seatVotes, bribedSeats));
	let localGameState = $derived({
		...gameState,
		primary: { ...gameState.primary, value: localDonationPool }
	});
	let votesNeeded = $derived(
		Math.max(0, Math.floor(seats.length / 2) + 1 - localVote.supportCount)
	);
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

	$effect(() => {
		const currentVoteDraft = voteDraftKey(draft);
		if (currentVoteDraft === appliedVoteDraft) return;
		appliedVoteDraft = currentVoteDraft;
		bribedSeats = [];
	});

	function selectLeft(item: LeftItem, mode: LeftMode) {
		if (mode !== 'selection') return;
		if (item.kind === 'proposal') {
			bribedSeats = [];
			const proposals = [...visibleDraft.proposals, item.proposal];
			playUiSfx('memorial-insert', true);
			optimisticDraft = {
				...visibleDraft,
				proposals,
				policies: clampBillPolicyDelays(visibleDraft.policies, proposals)
			};
			return onAddProposal?.(item.ref.index);
		}
		if (item.kind === 'policy') {
			bribedSeats = [];
			const { min } = getPolicyDelayBounds(visibleDraft.proposals);
			playUiSfx('memorial-insert', true);
			optimisticDraft = {
				...visibleDraft,
				policies: [...visibleDraft.policies, { definition: item.policy, delay_months: min }]
			};
			return onAddPolicy?.(item.policy.display_name);
		}
		if (item.kind === 'bill') loadBill(item);
	}

	function loadBill(savedItem: BillLeftItem) {
		bribedSeats = [];
		optimisticDraft = reconcileSavedBill(
			savedItem.bill,
			[...proposalHand, ...draft.proposals],
			availablePolicies
		);
		onEditSavedBill?.(savedItem.ref.index);
	}

	function removeProposal(_proposal: Proposal, index: number) {
		bribedSeats = [];
		const proposals = visibleDraft.proposals.filter((_, currentIndex) => currentIndex !== index);
		optimisticDraft = {
			...visibleDraft,
			proposals,
			policies: clampBillPolicyDelays(visibleDraft.policies, proposals)
		};
		onRemoveProposal?.(index);
	}

	function removePolicy(_policy: PolicyInstance, index: number) {
		bribedSeats = [];
		optimisticDraft = {
			...visibleDraft,
			policies: visibleDraft.policies.filter((_, currentIndex) => currentIndex !== index)
		};
		onRemovePolicy?.(index);
	}

	function setPolicyDelay(index: number, delayMonths: number) {
		if (!visibleDraft.policies[index]) return;
		bribedSeats = [];
		const delay = clampPolicyDelayMonths(delayMonths, visibleDraft.proposals);
		optimisticDraft = {
			...visibleDraft,
			policies: visibleDraft.policies.map((policy, currentIndex) =>
				currentIndex === index ? { ...policy, delay_months: delay } : policy
			)
		};
		onSetPolicyDelay?.(index, delay);
	}

	function setTitle(title: string) {
		optimisticDraft = { ...visibleDraft, title };
		onTitleChange?.(title);
	}

	function submitDraft(isVote: boolean) {
		if (!isVote) return;
		playUiSfx('passed', true);
		onSubmit?.([...bribedSeats].sort((left, right) => left - right));
		queueMicrotask(() => (voteMode = false));
	}

	function bribeSeat(seatIndex: number) {
		const vote = seatVotes.find((candidate) => candidate.seat_index === seatIndex);
		if (!vote) return;
		const next = toggleBribedSeat(bribedSeats, vote, seatVotes, donationPool);
		if (next === bribedSeats) return;
		if (next.length > bribedSeats.length) playUiSfx('bribe', true);
		bribedSeats = next;
	}

	function voteDraftKey(value: Bill): string {
		return JSON.stringify({ proposals: value.proposals, policies: value.policies });
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
			return anchor && vote ? [{ ...anchor, ...vote }] : [];
		});
	}
</script>

<main class="game-view" aria-label={$t('view.parliament')}>
	<div class="seat-layer">
		{#each anchoredSeats as seat (seat.seat_index)}
			{@const isBribed = bribedSeats.includes(seat.seat_index)}
			<div class="seat-anchor" style:left={`${seat.x * 100}%`} style:top={`${seat.y * 100}%`}>
				<ChoreSwitch
					left={seatScoreText(seat)}
					right={seatActionText(seat, $t('view.support'), $t('view.bribe'), $t('view.absent'))}
					isSwitch={seat.position === SUPPORT_POSITION}
					disabled={seat.position === ABSENT_POSITION ||
						(!isBribed &&
							(seat.position === SUPPORT_POSITION ||
								!seat.bribe_allowed ||
								seat.bribe_cost > localDonationPool))}
					onSwitchChange={() => bribeSeat(seat.seat_index)}
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
	<div class="state-slot"><GameStateDisplay {...localGameState} /></div>
	<div bind:this={editorScroller} class="editor-slot">
		<div class="editor-scroll-range">
			<div class="editor-track">
				<div class="editor-content">
					<div class="vote-switch">
						<ChoreSwitch
							left={$t('view.draft')}
							right={localVote.passed
								? $t('view.votePass')
								: $t('view.voteShort', { count: votesNeeded })}
							bind:isSwitch={voteMode}
							disabled={!localVote.passed}
							onSwitchChange={submitDraft}
						/>
					</div>

					<MemorialBillEditor
						bill={visibleDraft}
						{preview}
						onTitleChange={setTitle}
						onRemoveProposal={removeProposal}
						onRemovePolicy={removePolicy}
						onPolicyDelayChange={setPolicyDelay}
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
		pointer-events: none;
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
		pointer-events: auto;
	}
</style>
