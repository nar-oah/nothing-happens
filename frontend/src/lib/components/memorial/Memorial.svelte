<script lang="ts">
	import { onDestroy } from 'svelte';
	import MemorialClosed from './MemorialClosed.svelte';
	import MemorialFold from './MemorialFold.svelte';
	import { FOLD_HEIGHT, FOLD_WIDTH, type MemorialMetricData } from './memorial';

	type Props = {
		open?: boolean;
		skews?: number[];
		title?: string;
		lag?: string | number;
		metrics?: MemorialMetricData[];
		onOpenChange?: (open: boolean) => void;
	};

	let {
		open = $bindable(false),
		skews = [4.5, -3.5, 3, -2.5],
		title = '造身公所',
		lag = 12,
		metrics,
		onOpenChange
	}: Props = $props();

	let showClosed = $state(!open);
	let closeTimer: ReturnType<typeof setTimeout> | undefined;

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
	class="relative w-[var(--width)] h-[var(--height)] overflow-visible border-0 bg-transparent p-0 text-left"
	style:--width={`${FOLD_WIDTH}px`}
	style:--height={`${FOLD_HEIGHT}px`}
	type="button"
	aria-expanded={open}
	aria-label={open ? '收起奏折' : '展开奏折'}
	onclick={() => setOpen(!open)}
>
	{#each skews as skew, index}
		<MemorialFold x={getFoldX(skews.slice(0, index))} {open} {index} count={skews.length} {skew}>
			<div class="flex h-full flex-col justify-between">
				<div>
					<div class="typo-document-kicker opacity-70">提案／{title}</div>
					<div class="typo-document-section-heading mt-[2px]">扩充行身机件统采案</div>
				</div>
				<div class="typo-document-metadata flex items-center justify-between">
					<span>消化／中等</span>
					<span>{title}提供本案政治支持</span>
				</div>
			</div>
		</MemorialFold>
	{/each}
	{#if showClosed}
		<div class="absolute left-0 top-0 z-[100]">
			<MemorialClosed {title} {lag} {metrics} />
		</div>
	{/if}
</button>
