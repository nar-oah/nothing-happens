<script lang="ts">
	import { t, type Language } from '$lib/i18n';
	import { tick } from 'svelte';
	import ChoreItem from '$lib/components/chore/ChoreItem.svelte';
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import { deriveSaveItems } from '$lib/game/state/saves';
	import type { SaveSlotDto } from '$lib/game/state/types';
	import { VERTICAL_FOLD_HEIGHT, VERTICAL_FOLD_WIDTH } from '$lib/components/memorial/constants';
	import Newspaper from '$lib/components/newspaper/Newspaper.svelte';
	import GameSettingsDisplay from '$lib/components/settings/GameSettingsDisplay.svelte';
	import type {
		NewspaperEventData,
		NewspaperFrontData,
		NewspaperMetricData
	} from '$lib/components/newspaper/types';

	type NewspaperMotionPhase = 'entering' | 'active' | 'leaving';
	type Props = {
		term?: number;
		year: number;
		month: number;
		saves?: SaveSlotDto[];
		saveError?: string;
		onSaveSelect?: (slot: SaveSlotDto, loading: boolean) => void;
		language?: Language;
		displayMode?: 'windowed' | 'fullscreen';
		settingsDisabled?: boolean;
		onLanguageClick?: () => void;
		onDisplayClick?: () => void;
		onExitClick?: () => void;
		metrics: NewspaperMetricData[];
		front?: NewspaperFrontData;
		events: NewspaperEventData[];
		busy?: boolean;
		folded?: boolean;
		leaving?: boolean;
		onAdvance?: () => void;
		onCovered?: () => void;
		onRequestClose?: () => void;
		onFolded?: () => void;
		onClosed?: () => void;
	};
	const ROTATION_DEGREES = -20;
	const ROTATION_RADIANS = (Math.abs(ROTATION_DEGREES) * Math.PI) / 180;
	const ROTATION_SIN = Math.sin(ROTATION_RADIANS);
	const ROTATION_COS = Math.cos(ROTATION_RADIANS);

	let {
		term = 1,
		year,
		month,
		saves = [],
		saveError = '',
		onSaveSelect,
		language = 'zh_CN',
		displayMode = 'windowed',
		settingsDisabled = false,
		onLanguageClick,
		onDisplayClick,
		onExitClick,
		metrics,
		front,
		events,
		busy = false,
		folded = false,
		leaving = false,
		onAdvance,
		onCovered,
		onRequestClose,
		onFolded,
		onClosed
	}: Props = $props();
	let viewportWidth = $state(1512);
	let viewportHeight = $state(982);
	let scrollPosition = $state(0);
	let motionPhase = $state<NewspaperMotionPhase>('entering');
	let backgroundCovered = $state(false);
	let loadingSaves = $state(false);
	let saveScrollElement = $state<HTMLDivElement>();
	let scrollElement: HTMLDivElement;
	const saveItems = $derived(deriveSaveItems(saves, { term, year, month }, loadingSaves, $t));
	const pageCount = $derived(4 + events.length + (front ? 1 : 0));
	const baseHeight = $derived(pageCount * VERTICAL_FOLD_WIDTH);
	const scale = $derived(viewportWidth / VERTICAL_FOLD_HEIGHT);
	const scaledHeight = $derived(baseHeight * scale);
	const viewportAxisSpan = $derived(viewportHeight * ROTATION_COS + viewportWidth * ROTATION_SIN);
	const contentScrollRange = $derived(Math.max(0, scaledHeight - viewportAxisSpan));
	const edgeScrollPadding = $derived(VERTICAL_FOLD_WIDTH * scale);
	const totalScrollRange = $derived(contentScrollRange + edgeScrollPadding * 2);
	const newspaperAxisOffset = $derived(totalScrollRange / 2 - scrollPosition);
	const interactionDisabled = $derived(busy || motionPhase !== 'active');

	function syncScrollPosition() {
		if (scrollElement) scrollPosition = scrollElement.scrollTop;
	}

	function finishMotion(event: AnimationEvent) {
		if (event.target !== event.currentTarget) return;
		if (motionPhase === 'entering') {
			motionPhase = 'active';
			backgroundCovered = true;
			onCovered?.();
			return;
		}
		if (motionPhase === 'leaving') onClosed?.();
	}

	function requestClose() {
		if (interactionDisabled || !onRequestClose) return;
		onRequestClose();
	}

	$effect(() => {
		if (!leaving || motionPhase === 'leaving') return;
		backgroundCovered = false;
		motionPhase = 'leaving';
	});

	$effect(() => {
		const element = saveScrollElement;
		if (!element || saveItems.length === 0) return;
		void tick().then(() => {
			if (saveScrollElement === element) element.scrollLeft = element.scrollWidth;
		});
	});

	$effect(() => {
		const element = scrollElement;
		const target = totalScrollRange / 2;
		if (!element) return;
		void tick().then(() => {
			if (scrollElement !== element) return;
			element.scrollTop = target;
			scrollPosition = target;
		});
	});
</script>

<main
	class="newspaper-view"
	class:bg-surface-amber={backgroundCovered}
	aria-label={$t('view.newspaper')}
	bind:clientWidth={viewportWidth}
	bind:clientHeight={viewportHeight}
	data-block-world-input
>
	<div
		class="newspaper-scroll"
		bind:this={scrollElement}
		aria-label={$t('view.newspaperContent')}
		onscroll={syncScrollPosition}
	>
		<div class="newspaper-scroll-space" style:height={`${viewportHeight + totalScrollRange}px`}>
			<div class="newspaper-viewport">
				<button
					class="newspaper-close-layer"
					type="button"
					aria-label={$t('view.closeNewspaper')}
					disabled={interactionDisabled}
					onclick={requestClose}
				></button>
				<div
					class="newspaper-entry-motion"
					class:entering={motionPhase === 'entering'}
					class:leaving={motionPhase === 'leaving'}
					onanimationend={finishMotion}
				>
					<div
						class="newspaper-rotator"
						style:width={`${viewportWidth}px`}
						style:height={`${scaledHeight}px`}
					>
						<div
							class="newspaper-axis-track"
							style:transform={`translateY(${newspaperAxisOffset}px)`}
						>
							<div
								class="newspaper-scaler"
								style:width={`${VERTICAL_FOLD_HEIGHT}px`}
								style:height={`${baseHeight}px`}
								style:transform={`scale(${scale})`}
							>
								<Newspaper
									{year}
									{month}
									{metrics}
									{front}
									{events}
									{onAdvance}
									{onFolded}
									open={!folded}
									disabled={interactionDisabled}
								/>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
	{#if backgroundCovered}
		<div class="top-controls">
			<div class="top-items" bind:this={saveScrollElement}>
				<div class="ml-auto flex w-max items-start gap-12" aria-label={$t('saves.list')}>
					{#each saveItems as item (item.slot.slot_id)}
						<button
							type="button"
							class="shrink-0 cursor-pointer border-0 bg-transparent p-0 disabled:cursor-default"
							aria-label={$t('saves.actionLabel', { action: $t(loadingSaves ? 'saves.load' : item.slot.automatic ? 'saves.create' : 'saves.overwrite'), term: item.item.text, date: item.item.value, automatic: item.slot.automatic ? $t('saves.automaticSuffix') : '' })}
							disabled={interactionDisabled || !onSaveSelect}
							onclick={() => onSaveSelect?.(item.slot, loadingSaves)}
						>
							<ChoreItem {...item.item} isRow />
						</button>
					{/each}
				</div>
			</div>
			<div class="shrink-0">
				<ChoreSwitch
					left={$t('saves.save')}
					right={$t('saves.load')}
					bind:isSwitch={loadingSaves}
					disabled={interactionDisabled}
				/>
			</div>
			{#if saveError}
				<p class="save-error" role="alert">{saveError}</p>
			{/if}
		</div>
		<div class="state-slot">
			<GameSettingsDisplay
				{language}
				{displayMode}
				disabled={interactionDisabled || settingsDisabled}
				{onLanguageClick}
				{onDisplayClick}
				{onExitClick}
			/>
		</div>
	{/if}
</main>

<style>
	.newspaper-view {
		position: fixed;
		inset: 0;
		z-index: 1000;
		width: 100vw;
		height: 100vh;
		overflow: hidden;
	}
	.newspaper-scroll {
		position: absolute;
		inset: 0;
		overflow-x: hidden;
		overflow-y: auto;
		overscroll-behavior: contain;
		scrollbar-width: none;
		touch-action: pan-y;
	}
	.newspaper-scroll::-webkit-scrollbar {
		display: none;
	}
	.newspaper-scroll-space {
		position: relative;
		width: 100%;
		min-height: 100%;
	}
	.newspaper-viewport {
		position: sticky;
		top: 0;
		width: 100%;
		height: 100vh;
		overflow: visible;
	}
	.newspaper-close-layer {
		position: absolute;
		inset: 0;
		z-index: 0;
		border: 0;
		background: transparent;
		padding: 0;
	}
	.newspaper-entry-motion {
		position: absolute;
		inset: 0;
		z-index: 1;
		pointer-events: none;
		will-change: transform;
	}
	.newspaper-entry-motion.entering {
		animation: newspaper-enter 420ms cubic-bezier(0.22, 0.8, 0.2, 1) both;
	}
	.newspaper-entry-motion.leaving {
		animation: newspaper-leave 420ms cubic-bezier(0.22, 0.8, 0.2, 1) both;
	}
	.newspaper-rotator {
		position: absolute;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%) rotate(-20deg);
		transform-origin: center;
	}
	@keyframes newspaper-enter {
		from {
			transform: translate3d(-50vw, -50vh, 0);
		}
		to {
			transform: translate3d(0, 0, 0);
		}
	}
	@keyframes newspaper-leave {
		from {
			transform: translate3d(0, 0, 0);
		}
		to {
			transform: translate3d(-50vw, -50vh, 0);
		}
	}
	@media (prefers-reduced-motion: reduce) {
		.newspaper-entry-motion.entering,
		.newspaper-entry-motion.leaving {
			animation-duration: 1ms;
		}
	}
	.newspaper-axis-track {
		width: 100%;
		height: 100%;
		will-change: transform;
	}
	.newspaper-scaler {
		pointer-events: auto;
		transform-origin: top left;
	}
	.top-controls {
		position: absolute;
		top: 0;
		right: 0;
		z-index: 20;
		display: flex;
		width: min(960px, 100vw);
		align-items: flex-start;
		gap: 30px;
		pointer-events: auto;
	}
	.top-items {
		min-width: 0;
		flex: 1;
		overflow-x: auto;
		overscroll-behavior: contain;
		scrollbar-width: none;
	}
	.top-items::-webkit-scrollbar {
		display: none;
	}
	.save-error {
		position: absolute;
		top: 100%;
		left: 0;
		margin: 8px 0;
	}
	.state-slot {
		position: absolute;
		top: 72px;
		right: 0;
		z-index: 20;
	}
</style>
