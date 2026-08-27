<script lang="ts">
	import type { Metric } from '$lib/game/types';
	import MorphText from '../text/MorphText.svelte';
	import { getNewspaperMetricLabel } from './types';
	type Props = { metric: Metric; value: number; change: number };
	let { metric, value, change }: Props = $props();
	const direction = $derived(change > 0 ? '↑' : change < 0 ? '↓' : '—');
	const magnitude = $derived(Math.abs(change));
</script>

<div class="flex h-[78px] w-[64px] flex-col items-start overflow-hidden px-5">
	<p class="typo-newspaper-caption w-full">{getNewspaperMetricLabel(metric)}</p>
	<p class="typo-document-clause-number w-full"><MorphText text={String(value)} /></p>
	<div class="typo-newspaper-body flex w-full items-start justify-center whitespace-nowrap">
		<MorphText text={`${direction}${magnitude}`} />
	</div>
</div>
