<script lang="ts">
	import { onDestroy, onMount, tick } from 'svelte';
	import { language, t, type Translate } from '$lib/i18n';
	import { translateCommandError } from '$lib/i18n/live';
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
		type NewspaperFrontData,
		type NewspaperMetricData
	} from '$lib/components/newspaper/types';
	import {
		deriveTermReportFront,
		deriveTermReportMetrics
	} from '$lib/components/newspaper/term-report';
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
	import { getSaveAction } from './saves';
	import type { LiveGameState, MonthReportEventPhase, SaveSlotDto } from './types';

	type MutationPayload<T extends GameplayCommandType> = Omit<OutboundPayloads[T], 'state_version'>;
	type NewspaperTransitionAction = () => Promise<void>;
	type NewspaperEdition = {
		year: number;
		month: number;
		metrics: NewspaperMetricData[];
		front?: NewspaperFrontData;
		events: NewspaperEventData[];
	};

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

	function deriveNewspaperEvents(
		state: LiveGameState,
		translator: Translate
	): NewspaperEventData[] {
		return (state.month_report?.events ?? []).flatMap((event) => {
			const race = NEWSPAPER_RACE_BY_DISPLAY_NAME[event.race_display_name];
			if (!race) return [];
			const metric =
				event.requirement_kind === 1 && event.interest_group_name
					? translator('live.proposalCount', { group: event.interest_group_name })
					: event.metric;
			return [
				{
					race,
					description: event.event_description,
					metric,
					value: event.value,
					countdown: event.countdown,
					strength: event.strength,
					state: NEWSPAPER_EVENT_STATE_BY_PHASE[event.phase]
				}
			];
		});
	}

	function deriveNewspaperEdition(state: LiveGameState, translator: Translate): NewspaperEdition {
		const report = state.term_report;
		const front = report
			? deriveTermReportFront(report, translator)
			: (state.newspaper_front ?? undefined);
		return {
			year: state.year,
			month: state.month,
			metrics: report ? deriveTermReportMetrics(report, translator) : deriveNewspaperMetrics(state),
			...(front ? { front } : {}),
			events: report ? [] : deriveNewspaperEvents(state, translator)
		};
	}

	const gameStore = createGameStore();
	let storeValue = $state<GameStoreValue>(EMPTY_GAME_STORE);
	let client: CefIpcClient | null = null;
	let mutationQueue = Promise.resolve();
	let selectedConstitutionArticle = $state<number>();
	let loadRevision = $state(0);
	let saveError = $state<unknown>(null);
	let errorOperation = $state<'save' | 'settings' | 'quit'>('save');
	let settingsBusy = $state(false);
	let newspaperOpen = $state(true);
	let newspaperBusy = $state(false);
	let newspaperFolded = $state(false);
	let newspaperLeaving = $state(false);
	let newspaperEdition = $state<NewspaperEdition | null>(null);
	let newspaperFoldResolver: (() => void) | null = null;
	let pendingNewspaperAction: NewspaperTransitionAction | null = null;
	const unsubscribe = gameStore.subscribe((value) => {
		storeValue = value;
		if (value.snapshot) language.set(value.snapshot.language);
	});
	let snapshot = $derived(storeValue.snapshot);
	let leftItems = $derived(snapshot ? deriveLeftItems(snapshot) : []);
	let topItems = $derived(
		snapshot ? deriveTopItems(snapshot, $t) : { raceItems: [], interestGroupItems: [] }
	);
	let gameState = $derived(snapshot ? deriveGameStateDisplayProps(snapshot, $t) : undefined);
	let preview = $derived(snapshot ? deriveDraftPreviewMetrics(snapshot.draft_preview, $t) : []);
	let constitution = $derived(snapshot ? deriveConstitutionMemorial(snapshot, $t) : {});
	let pendingDialogue = $derived(
		snapshot ? deriveDialoguePresentation(snapshot.pending_dialogue, $t) : null
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

	$effect(() => {
		const state = snapshot;
		if (!state || newspaperBusy) return;
		newspaperEdition = deriveNewspaperEdition(state, $t);
	});

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

	async function changeSetting<
		T extends 'settings.language.set' | 'settings.display.set' | 'app.quit'
	>(type: T, payload: OutboundPayloads[T]): Promise<void> {
		if (settingsBusy || !client) return;
		const requestClient = client;
		settingsBusy = true;
		if (type === 'app.quit' || errorOperation === 'settings') saveError = null;
		try {
			await mutationQueue;
			if (client === requestClient) await requestClient.request(type, payload);
		} catch (error: unknown) {
			saveError = error;
			errorOperation = type === 'app.quit' ? 'quit' : 'settings';
		} finally {
			settingsBusy = false;
		}
	}

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
		newspaperFolded = false;
		newspaperLeaving = false;
		newspaperOpen = true;
		client?.send('saves.list', {});
	}

	async function selectSave(slot: SaveSlotDto, loading: boolean): Promise<void> {
		if (newspaperBusy || newspaperLeaving) return;
		newspaperBusy = true;
		saveError = null;
		errorOperation = 'save';
		const action = getSaveAction(slot, loading);
		try {
			await requestMutation(action.type, action.payload);
			if (loading) {
				selectedConstitutionArticle = undefined;
				pendingNewspaperAction = null;
				newspaperFoldResolver = null;
				newspaperFolded = false;
				newspaperLeaving = false;
				newspaperOpen = true;
				const state = storeValue.snapshot;
				newspaperEdition = state ? deriveNewspaperEdition(state, $t) : null;
				loadRevision += 1;
			}
		} catch (error: unknown) {
			saveError = error;
		} finally {
			newspaperBusy = false;
		}
	}

	function transitionThroughNewspaper(action: NewspaperTransitionAction): void {
		if (newspaperOpen || newspaperBusy) return;
		pendingNewspaperAction = action;
		newspaperBusy = true;
		newspaperFolded = false;
		newspaperLeaving = false;
		newspaperOpen = true;
	}

	async function handleNewspaperCovered(): Promise<void> {
		const action = pendingNewspaperAction;
		if (!action) return;
		pendingNewspaperAction = null;
		const foldComplete = beginNewspaperFold();
		try {
			await Promise.all([foldComplete, action()]);
			const state = storeValue.snapshot;
			if (state?.term_report) {
				newspaperEdition = deriveNewspaperEdition(state, $t);
				await tick();
				newspaperFolded = false;
				newspaperBusy = false;
				return;
			}
			await tick();
			newspaperLeaving = true;
		} catch (error: unknown) {
			await foldComplete;
			console.error('Newspaper transition failed', error);
			newspaperFolded = false;
			newspaperBusy = false;
		}
	}

	async function advanceFromNewspaper(): Promise<void> {
		if (newspaperBusy || newspaperLeaving) return;
		newspaperBusy = true;
		const foldComplete = beginNewspaperFold();
		try {
			await Promise.all([foldComplete, requestMutation('month.advance', {})]);
			const state = storeValue.snapshot;
			if (state?.term_report) {
				newspaperEdition = deriveNewspaperEdition(state, $t);
				await tick();
				newspaperFolded = false;
				newspaperBusy = false;
				return;
			}
			await tick();
			newspaperLeaving = true;
		} catch (error: unknown) {
			await foldComplete;
			console.error('Month advance failed', error);
			newspaperFolded = false;
			newspaperBusy = false;
		}
	}

	async function requestNewspaperClose(): Promise<void> {
		if (newspaperBusy || newspaperLeaving) return;
		newspaperBusy = true;
		const foldComplete = beginNewspaperFold();
		await foldComplete;
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
			newspaperFolded = false;
			newspaperBusy = false;
		}
	}

	function beginNewspaperFold(): Promise<void> {
		newspaperFolded = true;
		return new Promise((resolve) => (newspaperFoldResolver = resolve));
	}

	function finishNewspaperFold(): void {
		const resolve = newspaperFoldResolver;
		newspaperFoldResolver = null;
		resolve?.();
	}

	function finishNewspaperClose(): void {
		newspaperOpen = false;
		newspaperBusy = false;
		newspaperFolded = false;
		newspaperLeaving = false;
		newspaperFoldResolver = null;
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

	function bribeSeat(seatIndex: number): void {
		mutate('vote.donation.add', { seat_index: seatIndex });
	}

	function selectConstitutionArticle(articleRef: number, selected: boolean): void {
		if (selected) selectedConstitutionArticle = articleRef;
		else if (selectedConstitutionArticle === articleRef) selectedConstitutionArticle = undefined;
	}
</script>

<svelte:head><title>Nothing Happens</title></svelte:head>
{#if snapshot && frame}
	{#key loadRevision}
		{#if snapshot.ui_mode === 'dialogue' && pendingDialogue}
			<DialogueView
				{...frame}
				onNewspaperOpen={openNewspaper}
				dialogue={pendingDialogue}
				onResolveVisit={(acceptTrait) =>
					pendingDialogue.kind === 'simple'
						? mutate('ui.mode.set', { mode: 'office' })
						: mutate(
								'office.visit.resolve',
								acceptTrait === undefined ? {} : { accept_trait: acceptTrait }
							)}
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
				seats={snapshot.seats}
				seatAnchors={snapshot.parliament_seat_anchors}
				seatVotes={snapshot.draft_preview.vote.seat_votes}
				{preview}
				voteCanPass={snapshot.draft_preview.vote.passed}
				supportCount={snapshot.draft_preview.vote.support_count}
				onAddProposal={(handIndex) => mutate('draft.proposal.add', { hand_index: handIndex })}
				onRemoveProposal={(draftIndex) =>
					mutate('draft.proposal.remove', { draft_index: draftIndex })}
				onAddPolicy={(displayName) => mutate('draft.policy.add', { display_name: displayName })}
				onRemovePolicy={(draftIndex) => mutate('draft.policy.remove', { draft_index: draftIndex })}
				onTitleChange={(title) => mutate('draft.title.set', { title })}
				onEditSavedBill={(savedBillIndex) =>
					mutate('bill.edit', { saved_bill_index: savedBillIndex })}
				onBribeSeat={bribeSeat}
				onSubmit={submitBill}
			/>
		{:else if snapshot.ui_mode === 'constitution'}
			<ConstitutionView
				raceItems={topItems.raceItems}
				interestGroupItems={topItems.interestGroupItems}
				governingMonths={snapshot.constitution.available_governing_months}
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

		{#if newspaperOpen && newspaperEdition}
			<NewspaperView
				term={snapshot.term}
				year={newspaperEdition.year}
				month={newspaperEdition.month}
				saves={snapshot.saves}
				language={snapshot.language}
				displayMode={snapshot.display_mode}
				settingsDisabled={settingsBusy}
				onLanguageClick={() =>
					changeSetting('settings.language.set', {
						language: snapshot.language === 'zh_CN' ? 'en' : 'zh_CN'
					})}
				onDisplayClick={() =>
					changeSetting('settings.display.set', {
						mode: snapshot.display_mode === 'windowed' ? 'fullscreen' : 'windowed'
					})}
				onExitClick={() => changeSetting('app.quit', {})}
				saveError={saveError
						? errorOperation === 'quit'
						? $t('live.quitFailed', { reason: translateCommandError(saveError, $t) })
						: translateCommandError(saveError, $t)
					: ''}
				onSaveSelect={selectSave}
				metrics={newspaperEdition.metrics}
				front={newspaperEdition.front}
				events={newspaperEdition.events}
				busy={newspaperBusy}
				folded={newspaperFolded}
				leaving={newspaperLeaving}
				onCovered={handleNewspaperCovered}
				onAdvance={snapshot.term_report ? undefined : advanceFromNewspaper}
				onRequestClose={requestNewspaperClose}
				onFolded={finishNewspaperFold}
				onClosed={finishNewspaperClose}
			/>
		{/if}
	{/key}
{/if}
