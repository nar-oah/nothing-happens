<script lang="ts">
	import { tick } from 'svelte';
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import { VERTICAL_FOLD_HEIGHT, VERTICAL_FOLD_WIDTH } from '$lib/components/memorial/constants';
	import Newspaper from '$lib/components/newspaper/Newspaper.svelte';
	import GameStateDisplay from '$lib/components/state/GameStateDisplay.svelte';
	import type { StateItem } from '$lib/components/state/GameStateDisplay.svelte';
	import type {
		NewspaperCommentData,
		NewspaperEventData,
		NewspaperMetricData
	} from '$lib/components/newspaper/types';

	type Props = {
		year: number;
		month: number;
		metrics: NewspaperMetricData[];
		events: NewspaperEventData[];
		comment: NewspaperCommentData;
		onCommentClick?: () => void;
	};

	const ROTATION_DEGREES = -20;
	const ROTATION_RADIANS = (Math.abs(ROTATION_DEGREES) * Math.PI) / 180;
	const ROTATION_SIN = Math.sin(ROTATION_RADIANS);
	const ROTATION_COS = Math.cos(ROTATION_RADIANS);

	let { year, month, metrics, events, comment, onCommentClick }: Props = $props();
	let viewportWidth = $state(1512);
	let viewportHeight = $state(982);
	let scrollPosition = $state(0);
	let scrollElement: HTMLDivElement;

	const pageCount = $derived(4 + events.length);
	const baseHeight = $derived(pageCount * VERTICAL_FOLD_WIDTH);
	const scale = $derived(viewportWidth / VERTICAL_FOLD_HEIGHT);
	const scaledHeight = $derived(baseHeight * scale);
	const viewportAxisSpan = $derived(viewportHeight * ROTATION_COS + viewportWidth * ROTATION_SIN);
	const contentScrollRange = $derived(Math.max(0, scaledHeight - viewportAxisSpan));
	const edgeScrollPadding = $derived(VERTICAL_FOLD_WIDTH * scale);
	const totalScrollRange = $derived(contentScrollRange + edgeScrollPadding * 2);
	const newspaperAxisOffset = $derived(totalScrollRange / 2 - scrollPosition);
	const primary: StateItem = { text: '设置', isRow: false };
	const secondary: StateItem = { text: '退出', isRow: false };

	function syncScrollPosition() {
		if (!scrollElement) return;
		scrollPosition = scrollElement.scrollTop;
	}

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
	class="newspaper-view bg-surface-amber"
	aria-label="报纸界面"
	bind:clientWidth={viewportWidth}
	bind:clientHeight={viewportHeight}
	data-block-world-input
>
	<div
		class="newspaper-scroll"
		bind:this={scrollElement}
		aria-label="报纸内容"
		onscroll={syncScrollPosition}
	>
		<div class="newspaper-scroll-space" style:height={`${viewportHeight + totalScrollRange}px`}>
			<div class="newspaper-viewport">
				<div class="newspaper-entry-motion">
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
								<Newspaper {year} {month} {metrics} {events} {comment} {onCommentClick} />
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>

	<div class="top-controls">
		<div class="top-items" aria-hidden="true"></div>
		<ChoreSwitch left="保存" right="读取" />
	</div>

	<div class="state-slot"><GameStateDisplay {primary} {secondary} /></div>
</main>

<style>
	.newspaper-view {
		position: relative;
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

	.newspaper-entry-motion {
		position: absolute;
		inset: 0;
		animation: newspaper-enter 420ms cubic-bezier(0.22, 0.8, 0.2, 1) both;
		will-change: transform;
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

	@media (prefers-reduced-motion: reduce) {
		.newspaper-entry-motion {
			animation: none;
		}
	}

	.newspaper-axis-track {
		width: 100%;
		height: 100%;
		will-change: transform;
	}

	.newspaper-scaler {
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
		pointer-events: none;
	}

	.state-slot {
		position: absolute;
		top: 72px;
		right: 0;
	}
</style>
