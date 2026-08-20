<script lang="ts">
	import MemorialClosedFrame from './MemorialClosedFrame.svelte';
	import MemorialMetric from './MemorialMetric.svelte';
	import MemorialTitleStrip from './MemorialTitleStrip.svelte';
	import { MetricText, type MemorialMetricData } from './memorial';

	type Props = {
		title: string;
		lag: number;
		metrics: MemorialMetricData[];
	};

	let { title, lag, metrics }: Props = $props();
	let lagMetric: MemorialMetricData = $derived({
		text: MetricText.Lag,
		value: lag,
		isReverse: true
	});
</script>

<MemorialClosedFrame>
	<div class="relative box-border flex h-full w-full flex-col items-end p-10">
		<div class="absolute inset-0 flex items-end justify-end overflow-hidden">
			{#each [...metrics, lagMetric] as metric, index (metric)}
				<div class="-mr-5" style:z-index={metrics.length + 1 - index}>
					<MemorialMetric {metric} isBottom />
				</div>
			{/each}
		</div>
		<div class="relative z-10">
			<MemorialTitleStrip text={title} />
		</div>
	</div>
</MemorialClosedFrame>
