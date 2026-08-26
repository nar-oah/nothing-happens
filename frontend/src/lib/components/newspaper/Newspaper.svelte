<script lang="ts">
	import { VERTICAL_FOLD_HEIGHT } from '../memorial/constants';
	import Calendar from './Calendar.svelte';
	import Comment from './Comment.svelte';
	import Event from './Event.svelte';
	import Front from './Front.svelte';
	import NewspaperFold from './NewspaperFold.svelte';
	import PublicMetrics from './PublicMetrics.svelte';
	import Top from './Top.svelte';
	import type { NewspaperCommentData, NewspaperEventData, NewspaperMetricData } from './types';

	type NewspaperPage =
		| { kind: 'top' }
		| { kind: 'metrics' }
		| { kind: 'front'; event: NewspaperEventData }
		| { kind: 'event'; event: NewspaperEventData }
		| { kind: 'calendar' }
		| { kind: 'comment' };

	type Props = {
		year: number;
		month: number;
		metrics: NewspaperMetricData[];
		events: NewspaperEventData[];
		comment: NewspaperCommentData;
		onCommentClick?: () => void;
	};

	let { year, month, metrics, events, comment, onCommentClick }: Props = $props();
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
</script>

<article
	class="flex w-$width flex-col items-start overflow-hidden"
	style:--width={`${VERTICAL_FOLD_HEIGHT}px`}
	aria-label={`第 ${year} 年 ${month} 月弦外报`}
>
	{#each pages as page, index (index)}
		<NewspaperFold {index}>
			{#if page.kind === 'top'}
				<Top {year} {month} />
			{:else if page.kind === 'metrics'}
				<PublicMetrics {metrics} />
			{:else if page.kind === 'front'}
				<Front {...page.event} />
			{:else if page.kind === 'event'}
				<Event {...page.event} />
			{:else if page.kind === 'calendar'}
				<Calendar {month} />
			{:else}
				{#if onCommentClick}
					<button class="h-full w-full border-0 bg-transparent p-0 text-left" type="button" onclick={onCommentClick} aria-label="切换报纸评论"><Comment {...comment} /></button>
				{:else}
					<Comment {...comment} />
				{/if}
			{/if}
		</NewspaperFold>
	{/each}
</article>
