<script lang="ts">
	import { tick } from 'svelte';
	import ChoreSwitch from '$lib/components/chore/ChoreSwitch.svelte';
	import { VERTICAL_FOLD_HEIGHT, VERTICAL_FOLD_WIDTH } from '$lib/components/memorial/constants';
	import Newspaper from '$lib/components/newspaper/Newspaper.svelte';
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
	let scrollElement: HTMLDivElement;

	const pageCount = $derived(4 + events.length);
	const baseHeight = $derived(pageCount * VERTICAL_FOLD_WIDTH);
	const scale = $derived(viewportWidth / VERTICAL_FOLD_HEIGHT);
	const scaledHeight = $derived(baseHeight * scale);
	const rotatedWidth = $derived(viewportWidth * ROTATION_COS + scaledHeight * ROTATION_SIN);
	const rotatedHeight = $derived(viewportWidth * ROTATION_SIN + scaledHeight * ROTATION_COS);

	$effect(() => {
		const element = scrollElement;
		const target = Math.max(0, (rotatedHeight - viewportHeight) / 2);
		if (!element) return;
		void tick().then(() => {
			if (scrollElement === element) element.scrollTop = target;
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
	<div class="newspaper-scroll" bind:this={scrollElement} aria-label="报纸内容">
		<div
			class="newspaper-stage"
			style:width={`${rotatedWidth}px`}
			style:height={`${rotatedHeight}px`}
		>
			<div
				class="newspaper-rotator"
				style:width={`${viewportWidth}px`}
				style:height={`${scaledHeight}px`}
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

	<div class="top-controls">
		<div class="top-items" aria-hidden="true"></div>
		<ChoreSwitch left="保存" right="读取" />
	</div>

	<div class="state-controls">
		<button class="state-button" type="button" aria-label="设置" data-block-world-input>
			<span class="state-accent bg-accent-amber-deep" aria-hidden="true"></span>
			<span class="typo-control-heading state-label bg-shadow-deep text-surface-amber">设置</span>
		</button>
		<button class="state-button" type="button" aria-label="退出" data-block-world-input>
			<span class="state-accent bg-accent-amber-deep" aria-hidden="true"></span>
			<span class="typo-control-heading state-label bg-shadow-deep text-surface-amber">退出</span>
		</button>
	</div>
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
	}

	.newspaper-scroll::-webkit-scrollbar {
		display: none;
	}

	.newspaper-stage {
		position: relative;
		left: 50%;
		transform: translateX(-50%);
	}

	.newspaper-rotator {
		position: absolute;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%) rotate(-20deg);
		transform-origin: center;
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

	.state-controls {
		position: absolute;
		top: 72px;
		right: 0;
		z-index: 20;
		display: flex;
		width: 52px;
		flex-direction: column;
		align-items: flex-start;
		gap: 20px;
	}

	.state-button {
		display: flex;
		width: 52px;
		cursor: pointer;
		isolation: isolate;
		align-items: center;
		justify-content: flex-end;
		border: 0;
		background: transparent;
		padding: 0;
	}

	.state-accent {
		z-index: 2;
		width: 22px;
		height: 45px;
		margin-right: -10px;
		flex: none;
	}

	.state-label {
		z-index: 1;
		width: 40px;
		flex: none;
		text-align: center;
		white-space: normal;
		word-break: break-word;
	}
</style>
