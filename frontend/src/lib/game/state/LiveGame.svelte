<script lang="ts">
	import { onDestroy, onMount } from 'svelte';
	import {
		createCefIpcClient,
		createInputRegionReporter,
		type CefIpcClient,
		type GameplayCommandType,
		type OutboundPayloads
	} from '$lib/bridge';
	import type { SynthesisConfirmation } from '$lib/components/left/types';
	import ConstitutionView from '$lib/views/ConstitutionView.svelte';
	import DialogueView from '$lib/views/DialogueView.svelte';
	import OfficeView from '$lib/views/OfficeView.svelte';
	import ParliamentView from '$lib/views/ParliamentView.svelte';
	import {
		deriveConstitutionMemorial,
		deriveDialoguePresentation,
		deriveDraftPreviewMetrics,
		deriveGameStateDisplayProps,
		deriveLeftItems,
		deriveTopItems
	} from './selectors';
	import { createGameStore, EMPTY_GAME_STORE, type GameStoreValue } from './store';

	type MutationPayload<T extends GameplayCommandType> = Omit<
		OutboundPayloads[T],
		'state_version'
	>;

	const gameStore = createGameStore();
	let storeValue = $state<GameStoreValue>(EMPTY_GAME_STORE);
	let client: CefIpcClient | null = null;
	let mutationQueue = Promise.resolve();
	let selectedConstitutionArticle = $state<number>();
	const unsubscribe = gameStore.subscribe((value) => (storeValue = value));
	let snapshot = $derived(storeValue.snapshot);
	let leftItems = $derived(snapshot ? deriveLeftItems(snapshot) : []);
	let topItems = $derived(
		snapshot ? deriveTopItems(snapshot) : { raceItems: [], interestGroupItems: [] }
	);
	let gameState = $derived(snapshot ? deriveGameStateDisplayProps(snapshot) : undefined);
	let preview = $derived(
		snapshot ? deriveDraftPreviewMetrics(snapshot.draft_preview, snapshot.draft_bill) : []
	);
	let constitution = $derived(snapshot ? deriveConstitutionMemorial(snapshot) : {});
	let pendingDialogue = $derived(
		snapshot ? deriveDialoguePresentation(snapshot.pending_dialogue) : null
	);
	let frame = $derived(
		snapshot && gameState
			? {
					items: leftItems,
					baseline: snapshot.metrics,
					raceItems: topItems.raceItems,
					interestGroupItems: topItems.interestGroupItems,
					gameState,
					term: snapshot.term,
					year: snapshot.year,
					month: snapshot.month
				}
			: null
	);

	onMount(() => {
		client = createCefIpcClient({
			onMessage: gameStore.apply,
			onProtocolError: (error) => console.error(`Godot IPC protocol error: ${error}`)
		});
		if (!client) return;
		client.connect();
		const inputRegions = createInputRegionReporter(client);
		inputRegions.start();
		return () => {
			inputRegions.destroy();
			client?.destroy();
			client = null;
		};
	});

	onDestroy(unsubscribe);

	function mutate<T extends GameplayCommandType>(type: T, payload: MutationPayload<T>): void {
		mutationQueue = mutationQueue
			.then(async () => {
				if (!client || !storeValue.snapshot) return;
				await client.request(type, {
					...payload,
					state_version: storeValue.snapshot.state_version
				} as OutboundPayloads[T]);
			})
			.catch((error: unknown) => console.error('Godot command failed', error));
	}

	function mergeProposals(confirmation: SynthesisConfirmation): void {
		mutate('proposal.merge', {
			hand_indices: confirmation.refs.map((ref) => ref.index),
			negative_base_index: confirmation.negativeBaseRef.index,
			selected_positive_index: confirmation.reverseSource?.ref.index ?? null
		});
	}

	function selectConstitutionArticle(articleRef: number, selected: boolean): void {
		if (selected) selectedConstitutionArticle = articleRef;
		else if (selectedConstitutionArticle === articleRef) selectedConstitutionArticle = undefined;
	}
</script>

<svelte:head><title>Nothing Happens</title></svelte:head>

{#if snapshot && frame}
	{#if snapshot.ui_mode === 'dialogue' && pendingDialogue}
		<DialogueView
			{...frame}
			dialogue={{
				handIndex: pendingDialogue.hand_index,
				groupName: snapshot.pending_dialogue!.proposal.source_group.display_name,
				positiveEffect: pendingDialogue.trait_label,
				donationOffer: pendingDialogue.donation_label
			}}
			onResolveBonus={(handIndex, acceptTrait) =>
				mutate('proposal.bonus.resolve', {
					hand_index: handIndex,
					accept_trait: acceptTrait
				})}
		/>
	{:else if snapshot.ui_mode === 'parliament'}
		<ParliamentView
			{...frame}
			stateVersion={snapshot.state_version}
			draft={snapshot.draft_bill}
			proposalHand={snapshot.proposal_hand}
			availablePolicies={snapshot.available_policies}
			editingSavedBillIndex={snapshot.editing_saved_bill_index ?? undefined}
			{preview}
			voteCanPass={snapshot.draft_preview.vote.passed}
			onAddProposal={(handIndex) =>
				mutate('draft.proposal.add', { hand_index: handIndex })}
			onRemoveProposal={(draftIndex) =>
				mutate('draft.proposal.remove', { draft_index: draftIndex })}
			onAddPolicy={(displayName) =>
				mutate('draft.policy.add', { display_name: displayName })}
			onRemovePolicy={(draftIndex) =>
				mutate('draft.policy.remove', { draft_index: draftIndex })}
			onTitleChange={(title) => mutate('draft.title.set', { title })}
			onEditSavedBill={(savedBillIndex) =>
				mutate('bill.edit', { saved_bill_index: savedBillIndex })}
			onSubmit={() => mutate('bill.submit', {})}
		/>
	{:else if snapshot.ui_mode === 'constitution'}
		<ConstitutionView
			raceItems={topItems.raceItems}
			interestGroupItems={topItems.interestGroupItems}
			{gameState}
			title={snapshot.constitution.title}
			{constitution}
			onArticleSelectionChange={selectConstitutionArticle}
		/>
	{:else}
		<OfficeView {...frame} onSynthesisConfirm={mergeProposals} />
	{/if}
{/if}
