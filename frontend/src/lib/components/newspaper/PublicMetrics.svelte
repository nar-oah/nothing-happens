<script lang="ts">
	import Metric from './Metric.svelte';
	import { NEWSPAPER_METRIC_ORDER, type NewspaperMetricData } from './types';

	type Props = {
		metrics: NewspaperMetricData[];
	};

	let { metrics }: Props = $props();
	const orderedMetrics = $derived(
		NEWSPAPER_METRIC_ORDER.map((metric) => metrics.find((item) => item.metric === metric)).filter(
			(item): item is NewspaperMetricData => item !== undefined
		)
	);
</script>

<div class="flex h-full w-full flex-col gap-[3px] overflow-hidden px-8 py-5">
	<div class="flex w-full shrink-0 items-start gap-10 overflow-hidden">
		<p class="typo-newspaper-headline shrink-0 whitespace-nowrap">指标</p>
		<div class="flex min-w-0 flex-1 flex-col items-end px-5 py-2">
			<p class="typo-newspaper-caption whitespace-nowrap text-right">PUBLIC METRICS / MONTHLY MOVE</p>
		</div>
	</div>
	<div class="h-px w-full shrink-0 bg-ink-primary"></div>
	<div class="flex w-full shrink-0 items-start overflow-hidden text-center">
		{#each orderedMetrics as item, index (item.metric)}
			<div class:border-l={index > 0} class:border-ink-primary={index > 0}>
				<Metric {...item} />
			</div>
		{/each}
	</div>
</div>
