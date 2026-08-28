<script lang="ts">
	import { VERTICAL_FOLD_HEIGHT, VERTICAL_FOLD_WIDTH } from '../memorial/constants';
	import MemorialHorizontalFold from '../memorial/horizontal/MemorialHorizontalFold.svelte';
	import Calendar from './Calendar.svelte';
	import Comment from './Comment.svelte';
	import Event from './Event.svelte';
	import Front from './Front.svelte';
	import PublicMetrics from './PublicMetrics.svelte';
	import Top from './Top.svelte';
	import type { NewspaperCommentData, NewspaperEventData, NewspaperMetricData } from './types';

	const NEWSPAPER_FOLD_WIDTH = VERTICAL_FOLD_HEIGHT;
	const NEWSPAPER_FOLD_HEIGHT = VERTICAL_FOLD_WIDTH;
	type NewspaperPage =
		| { kind: 'top' }
		| { kind: 'metrics' }
		| { kind: 'front'; event: NewspaperEventData }
		| { kind: 'event'; event: NewspaperEventData }
		| { kind: 'calendar' }
		| { kind: 'comment' };
	type Props = {
		mode?: 'MONTHLY' | 'TERM_END';
		term: number;
		year: number;
		month: number;
		governingMonths?: number;
		termOutcome?: 'COLLAPSE' | 'NOTHING_HAPPENS';
		metrics: NewspaperMetricData[];
		events: NewspaperEventData[];
		comment: NewspaperCommentData;
		disabled?: boolean;
		onCommentClick?: () => void;
		onAdvance?: () => void;
	};

	let {
		mode = 'MONTHLY',
		term,
		year,
		month,
		governingMonths,
		termOutcome,
		metrics,
		events,
		comment,
		disabled = false,
		onCommentClick,
		onAdvance
	}: Props = $props();
	const sortedEvents = $derived([...events].sort((a, b) => a.countdown - b.countdown));
	const pages = $derived.by((): NewspaperPage[] => {
		const result: NewspaperPage[] = [{ kind: 'top' }, { kind: 'metrics' }];
		if (sortedEvents.length > 0) {
			result.push({ kind: 'front', event: sortedEvents[0] });
			for (const event of sortedEvents.slice(1)) result.push({ kind: 'event', event });
		}
		result.push({ kind: 'calendar' }, { kind: 'comment' });
		return result;
	});
	const skews = $derived(createFoldSkews(pages.length));

	function createFoldSkews(count: number): number[] {
		const MAX_FOLD_SKEW = 4.5;
		const MIN_FOLD_SKEW = 2.5;
		if (count <= 0) return [];
		if (count === 1) return [0];
		return Array.from({ length: count }, (_, index) => {
			const progress = index / (count - 1);
			const magnitude = MAX_FOLD_SKEW - (MAX_FOLD_SKEW - MIN_FOLD_SKEW) * progress;
			return magnitude * (index % 2 === 0 ? 1 : -1);
		});
	}

	function getFoldX(index: number): number {
		return skews
			.slice(0, index)
			.reduce((x, skew) => x + NEWSPAPER_FOLD_HEIGHT * Math.tan((skew * Math.PI) / 180), 0);
	}
</script>

<article
	class="newspaper relative h-$height w-$width overflow-visible text-ink-primary"
	style:--width={`${NEWSPAPER_FOLD_WIDTH}px`}
	style:--height={`${pages.length * NEWSPAPER_FOLD_HEIGHT}px`}
	aria-label={mode === 'TERM_END' ? `第 ${term} 任任期终局报` : `第 ${year} 年 ${month} 月弦外报`}
	data-newspaper-mode={mode}
	data-term-outcome={termOutcome}
	data-governing-months={governingMonths}
>
	{#each pages as page, index (index)}
		<MemorialHorizontalFold
			x={getFoldX(index)}
			open
			{index}
			count={pages.length}
			skew={skews[index]}
			width={NEWSPAPER_FOLD_WIDTH}
			height={NEWSPAPER_FOLD_HEIGHT}
		>
			{#if page.kind === 'top'}
				<Top {mode} {year} {month} {disabled} {onAdvance} />
			{:else if page.kind === 'metrics'}
				<PublicMetrics {metrics} />
			{:else if page.kind === 'front'}
				<Front {...page.event} />
			{:else if page.kind === 'event'}
				<Event {...page.event} />
			{:else if page.kind === 'calendar'}
				<Calendar {month} />
			{:else if onCommentClick}
				<button
					class="h-full w-full border-0 bg-transparent p-0 text-left"
					type="button"
					onclick={onCommentClick}
					aria-label="切换报纸评论"><Comment {...comment} /></button
				>
			{:else}
				<Comment {...comment} />
			{/if}
		</MemorialHorizontalFold>
	{/each}
</article>

<style>
	.newspaper,
	.newspaper :global(*) {
		box-sizing: border-box;
	}
	.newspaper :global(p) {
		margin: 0;
	}
</style>
