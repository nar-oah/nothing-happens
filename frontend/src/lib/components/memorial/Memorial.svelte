<script lang="ts">
	import { onDestroy } from 'svelte';
	import MemorialClosed from './MemorialClosed.svelte';
	import MemorialFold from './MemorialFold.svelte';
	import MemorialHorizontalContent from './MemorialHorizontalContent.svelte';
	import { FOLD_HEIGHT, FOLD_WIDTH, type MemorialMetricData } from './memorial';

	type Props = {
		open?: boolean;
		count: number;
		title: string;
		lag: number;
		metrics: MemorialMetricData[];
		onOpenChange?: (open: boolean) => void;
	};

	let { open = $bindable(false), count, title, lag, metrics, onOpenChange }: Props = $props();
	let showClosed = $state(!open);
	let closeTimer: ReturnType<typeof setTimeout> | undefined;
	const skews = $derived(createFoldSkews(count));

	function createFoldSkews(count: number): number[] {
		const MAX_FOLD_SKEW = 4.5;
		const MIN_FOLD_SKEW = 2.5;
		if (count <= 0) return [];
		if (count === 1) return [0];
		return Array.from({ length: count }, (_, index) => {
			const progress = index / (count - 1);
			const magnitude = MAX_FOLD_SKEW - (MAX_FOLD_SKEW - MIN_FOLD_SKEW) * progress;
			const direction = index % 2 === 0 ? 1 : -1;
			return magnitude * direction;
		});
	}

	function getFoldX(skews: number[]): number {
		return skews.reduce((x, skew) => x + FOLD_HEIGHT * Math.tan((skew * Math.PI) / 180), 0);
	}

	function getCloseDuration(count: number): number {
		const positionDuration = 520 + Math.max(0, count - 1) * 32;
		const straightenDuration = 620 + 260;
		return Math.max(positionDuration, straightenDuration) + 20;
	}

	function clearCloseTimer() {
		if (closeTimer === undefined) return;
		clearTimeout(closeTimer);
		closeTimer = undefined;
	}

	function setOpen(next: boolean) {
		if (open === next) return;
		if (next) showClosed = false;
		open = next;
		onOpenChange?.(next);
	}

	$effect(() => {
		clearCloseTimer();
		if (open) {
			showClosed = false;
			return;
		}
		if (showClosed) return;

		closeTimer = setTimeout(() => {
			showClosed = true;
			closeTimer = undefined;
		}, getCloseDuration(skews.length));
	});

	onDestroy(clearCloseTimer);
</script>

<button
	class="relative h-$height w-$width overflow-visible border-0 bg-transparent p-0 text-left"
	style:--width={`${FOLD_WIDTH}px`}
	style:--height={`${open ? count * FOLD_HEIGHT : FOLD_HEIGHT}px`}
	type="button"
	aria-expanded={open}
	aria-label={open ? '收起奏折' : '展开奏折'}
	onclick={() => setOpen(!open)}
>
	{#each skews as skew, index}
		<MemorialFold x={getFoldX(skews.slice(0, index))} {open} {index} count={skews.length} {skew}>
			<MemorialHorizontalContent title={index === 0 ? '自由贸易' : ''} />
		</MemorialFold>
	{/each}
	{#if showClosed}
		<div class="absolute left-0 top-0 z-100">
			<MemorialClosed {title} {lag} {metrics} />
		</div>
	{/if}
</button>
