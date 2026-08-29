<script lang="ts">
	import { onDestroy, onMount, tick } from 'svelte';
	import {
		createCefIpcClient,
		createInputRegionReporter,
		type CefIpcClient,
		type GameplayCommandType,
		type OutboundPayloads
	} from '$lib/bridge';
	import type { SynthesisConfirmation } from '$lib/components/left/types';
	import {
		NewspaperEventState,
		NewspaperRace,
		type NewspaperEventData,
		type NewspaperMetricData
	} from '$lib/components/newspaper/types';
	import { Metric } from '$lib/game/types';
	import ConstitutionView from '$lib/views/ConstitutionView.svelte';
	import DialogueView from '$lib/views/DialogueView.svelte';
	import OfficeView from '$lib/views/OfficeView.svelte';
	import NewspaperView from '$lib/views/NewspaperView.svelte';
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
	import type { LiveGameState, MonthReportEventPhase } from './types';

	type MutationPayload<T extends GameplayCommandType> = Omit<OutboundPayloads[T], 'state_version'>;
	type NewspaperTransitionAction = () => Promise<void>;

	const NEWSPAPER_RACE_BY_DISPLAY_NAME: Record<string, NewspaperRace> = {
		驻岁: NewspaperRace.ZHUSHUI,
		南柯: NewspaperRace.NANKE,
		比翼: NewspaperRace.BIYI,
		偃偶: NewspaperRace.YANOU,
		桃花妖: NewspaperRace.PEACH_BLOSSOM,
		人类: NewspaperRace.HUMAN
	};
	const NEWSPAPER_EVENT_STATE_BY_PHASE: Record<MonthReportEventPhase, NewspaperEventState> = {
		0: NewspaperEventState.DETERIORATION,
		1: NewspaperEventState.POSTPONED,
		2: NewspaperEventState.CALM
	};

	function deriveNewspaperMetrics(state: LiveGameState): NewspaperMetricData[] {
		const current = state.month_report?.current_metrics ?? state.metrics;
		const previous = state.month_report?.previous_metrics ?? current;
		return [
			{ metric: Metric.TAX, value: previous.tax, change: current.tax - previous.tax },
			{
				metric: Metric.CONSUMPTION,
				value: previous.consumption,
				change: current.consumption - previous.consumption
			},
			{
				metric: Metric.PRODUCTION,
				value: previous.production,
				change: current.production - previous.production
			},
			{
				metric: Metric.EMPLOYMENT,
				value: previous.employment,
				change: current.employment - previous.employment
			},
			{
				metric: Metric.INVESTMENT,
				value: previous.investment,
				change: current.investment - previous.investment
			}
		];
	}

	function deriveNewspaperEvents(state: LiveGameState): NewspaperEventData[] {
		return (state.month_report?.events ?? []).flatMap((event) => {
			const race = NEWSPAPER_RACE_BY_DISPLAY_NAME[event.race_display_name];
			if (!race) return [];
			return [
				{
					race,
					metric: event.metric,
					value: event.value,
					countdown: event.countdown,
					strength: event.strength,
					state: NEWSPAPER_EVENT_STATE_BY_PHASE[event.phase]
				}
			];
		});
	}

	const gameStore = createGameStore();
	let storeValue = $state<GameStoreValue>(EMPTY_GAME_STORE);
	let client: CefIpcClient | null = null;
	let mutationQueue = Promise.resolve();
	let selectedConstitutionArticle = $state<number>();
	let newspaperOpen = $state(true);
	let newspaperBusy = $state(false);
	let newspaperLeaving = $state(false);
	let pendingNewspaperAction: NewspaperTransitionAction | null = null;
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
	let newspaperMetrics = $derived(snapshot ? deriveNewspaperMetrics(snapshot) : []);
	let newspaperEvents = $derived(snapshot ? deriveNewspaperEvents(snapshot) : []);
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
		const requestClient = client;
		if (!requestClient) return;
		mutationQueue = mutationQueue
			.then(async () => {
				if (client !== requestClient) return;
				const requestStateVersion = storeValue.snapshot?.state_version;
				if (requestStateVersion === undefined) return;
				await requestClient.request(type, {
					...payload,
					state_version: requestStateVersion
				} as OutboundPayloads[T]);
			})
			.catch((error: unknown) => console.error('Godot command failed', error));
	}

	async function requestMutation<T extends GameplayCommandType>(
		type: T,
		payload: MutationPayload<T>
	): Promise<void> {
		await mutationQueue;
		const requestClient = client;
		const requestStateVersion = storeValue.snapshot?.state_version;
		if (!requestClient || requestStateVersion === undefined)
			throw new Error('Godot IPC is not ready.');
		await requestClient.request(type, {
			...payload,
			state_version: requestStateVersion
		} as OutboundPayloads[T]);
	}

	function openNewspaper(): void {
		if (newspaperOpen) return;
		pendingNewspaperAction = null;
		newspaperBusy = false;
		newspaperLeaving = false;
		newspaperOpen = true;
	}

	function transitionThroughNewspaper(action: NewspaperTransitionAction): void {
		if (newspaperOpen || newspaperBusy) return;
		pendingNewspaperAction = action;
		newspaperBusy = true;
		newspaperLeaving = false;
		newspaperOpen = true;
	}

	async function handleNewspaperCovered(): Promise<void> {
		const action = pendingNewspaperAction;
		if (!action) return;
		pendingNewspaperAction = null;
		try {
			await action();
			await tick();
			newspaperLeaving = true;
		} catch (error: unknown) {
			console.error('Newspaper transition failed', error);
			newspaperBusy = false;
		}
	}

	async function advanceFromNewspaper(): Promise<void> {
		if (newspaperBusy || newspaperLeaving) return;
		newspaperBusy = true;
		try {
			await requestMutation('month.advance', {});
			await tick();
			newspaperLeaving = true;
		} catch (error: unknown) {
			console.error('Month advance failed', error);
			newspaperBusy = false;
		}
	}

	async function requestNewspaperClose(): Promise<void> {
		if (newspaperBusy || newspaperLeaving) return;
		newspaperBusy = true;
		const requestClient = client;
		if (!requestClient) {
			newspaperLeaving = true;
			return;
		}
		try {
			await requestClient.request('ui.newspaper.close', {});
			await tick();
			newspaperLeaving = true;
		} catch (error: unknown) {
			console.error('Newspaper close sync failed', error);
			newspaperBusy = false;
		}
	}

	function finishNewspaperClose(): void {
		newspaperOpen = false;
		newspaperBusy = false;
		newspaperLeaving = false;
		pendingNewspaperAction = null;
	}

	function submitBill(): void {
		transitionThroughNewspaper(() => requestMutation('bill.submit', {}));
	}

	function submitConstitution(): void {
		const articleIndex = selectedConstitutionArticle;
		transitionThroughNewspaper(async () => {
			if (articleIndex === undefined) await requestMutation('month.advance', {});
			else await requestMutation('constitution.revise', { article_index: articleIndex });
			selectedConstitutionArticle = undefined;
		});
	}

	function unlockConstitutionColumn(columnIndex: number): void {
		selectedConstitutionArticle = undefined;
		mutate('constitution.column.unlock', { column_index: columnIndex });
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
			onNewspaperOpen={openNewspaper}
			dialogue={{
				handIndex: pendingDialogue.hand_index,
				groupName: snapshot.pending_dialogue!.proposal.source_group.display_name,
				positiveEffect: pendingDialogue.trait_label,
				donationOffer: pendingDialogue.donation_label
			}}
			onResolveBonus={(handIndex, acceptTrait) =>
				mutate('proposal.bonus.resolve', { hand_index: handIndex, accept_trait: acceptTrait })}
		/>
	{:else if snapshot.ui_mode === 'parliament'}
		<ParliamentView
			{...frame}
			onNewspaperOpen={openNewspaper}
			stateVersion={snapshot.state_version}
			draft={snapshot.draft_bill}
			proposalHand={snapshot.proposal_hand}
			availablePolicies={snapshot.available_policies}
			editingSavedBillIndex={snapshot.editing_saved_bill_index ?? undefined}
			{preview}
			voteCanPass={snapshot.draft_preview.vote.passed}
			onAddProposal={(handIndex) => mutate('draft.proposal.add', { hand_index: handIndex })}
			onRemoveProposal={(draftIndex) =>
				mutate('draft.proposal.remove', { draft_index: draftIndex })}
			onAddPolicy={(displayName) => mutate('draft.policy.add', { display_name: displayName })}
			onRemovePolicy={(draftIndex) => mutate('draft.policy.remove', { draft_index: draftIndex })}
			onTitleChange={(title) => mutate('draft.title.set', { title })}
			onEditSavedBill={(savedBillIndex) =>
				mutate('bill.edit', { saved_bill_index: savedBillIndex })}
			onSubmit={submitBill}
		/>
	{:else if snapshot.ui_mode === 'constitution'}
		<ConstitutionView
			raceItems={topItems.raceItems}
			interestGroupItems={topItems.interestGroupItems}
			gameState={frame.gameState}
			term={frame.term}
			year={frame.year}
			month={frame.month}
			onNewspaperOpen={openNewspaper}
			title={snapshot.constitution.title}
			{constitution}
			columns={snapshot.constitution.columns}
			onArticleSelectionChange={selectConstitutionArticle}
			onColumnUnlock={unlockConstitutionColumn}
			onSubmit={submitConstitution}
		/>
	{:else}
		<OfficeView {...frame} onNewspaperOpen={openNewspaper} onSynthesisConfirm={mergeProposals} />
	{/if}

	{#if newspaperOpen}
		<NewspaperView
			year={snapshot.year}
			month={snapshot.month}
			metrics={newspaperMetrics}
			events={newspaperEvents}
			comment={{ title: [''], comment: [''] }}
			busy={newspaperBusy}
			leaving={newspaperLeaving}
			onCovered={handleNewspaperCovered}
			onAdvance={advanceFromNewspaper}
			onRequestClose={requestNewspaperClose}
			onClosed={finishNewspaperClose}
		/>
	{/if}
{/if}
