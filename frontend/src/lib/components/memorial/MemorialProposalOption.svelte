<script lang="ts">
	import MemorialClosedFrame from './MemorialClosedFrame.svelte';
	import MemorialMetric from './MemorialMetric.svelte';
	import { MetricText, type MemorialMetricData } from './memorial';

	type Props = {
		option: string;
		lag: number;
		metrics: MemorialMetricData[];
	};

	let { option, lag, metrics }: Props = $props();
	let leadingMetrics = $derived(metrics.filter((metric) => !metric.isReverse));
	let trailingMetrics = $derived(metrics.filter((metric) => metric.isReverse));
	let lagMetric: MemorialMetricData = $derived({
		text: MetricText.Lag,
		value: lag
	});
</script>

<MemorialClosedFrame>
	<div class="flex h-full w-full items-center justify-center gap-10">
		<div class="flex min-w-0">
			{#each leadingMetrics as metric, index (metric)}
				<div class="-mr-10" style:z-index={leadingMetrics.length - index}>
					<MemorialMetric {metric} />
				</div>
			{/each}
		</div>
		<div
			class="flex w-40 shrink-0 items-center justify-center self-stretch overflow-hidden bg-accent-amber-deep"
		>
			<p
				class="m-0 w-full text-center font-archival text-48 font-normal leading-auto text-ink-primary [word-break:break-word]"
			>
				{option}
			</p>
		</div>
		<div class="flex min-w-0">
			{#each [...trailingMetrics, lagMetric] as metric, index (metric)}
				<div class="-mr-10" style:z-index={trailingMetrics.length + 1 - index}>
					<MemorialMetric {metric} />
				</div>
			{/each}
		</div>
	</div>
</MemorialClosedFrame>
