	<script lang="ts">
	import { onDestroy, type Snippet } from 'svelte';
	import {
		HORIZONTAL_FOLD_HEIGHT,
		HORIZONTAL_FOLD_WIDTH
	} from '../constants';
	import MemorialHorizontalContent from '../content/MemorialHorizontalContent.svelte';
	import { paginateMemorialContents } from '../pagination';
	import type { MemorialHorizontalContentData } from '../types';
	import MemorialHorizontalFold from './MemorialHorizontalFold.svelte';

	type Props = {
		open?: boolean;
		contents: MemorialHorizontalContentData[];
		closed: Snippet;
		onOpenChange?: (open: boolean) => void;
	};

	let { open = $bindable(false), contents, closed, onOpenChange }: Props = $props();
	let showClosed = $state(!open);
	let closeTimer: ReturnType<typeof setTimeout> | undefined;
	const pages = $derived(paginateMemorialContents(contents));
	const skews = $derived(createFoldSkews(pages.length));

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
		return skews.reduce(
			(x, skew) => x + HORIZONTAL_FOLD_HEIGHT * Math.tan((skew * Math.PI) / 180),
			0
		);
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
	style:--width={`${HORIZONTAL_FOLD_WIDTH}px`}
	style:--height={`${open ? pages.length * HORIZONTAL_FOLD_HEIGHT : HORIZONTAL_FOLD_HEIGHT}px`}
	type="button"
	aria-expanded={open}
	aria-label={open ? '收起奏折' : '展开奏折'}
	onclick={() => setOpen(!open)}
>
	{#each pages as page, index (index)}
		<MemorialHorizontalFold
			x={getFoldX(skews.slice(0, index))}
			{open}
			{index}
			count={skews.length}
			skew={skews[index]}
		>
			<div
				class="box-border h-full w-full overflow-hidden px-12 text-ink-primary"
				class:pt-8={page.title}
			>
				<MemorialHorizontalContent {...page} />
			</div>
		</MemorialHorizontalFold>
	{/each}
	{#if showClosed}
		<div class="absolute left-0 top-0 z-100">
			{@render closed()}
		</div>
	{/if}
</button>
