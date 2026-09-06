<script lang="ts">
	import { translate } from '$lib/i18n';
	import MemorialClosedFrame from './MemorialClosedFrame.svelte';
	import MemorialMetric from '../shared/MemorialMetric.svelte';
	import type { MemorialMetricData } from '../types';

	type Props = {
		option: string;
		lag: number;
		metrics: MemorialMetricData[];
	};

	let { option, lag, metrics }: Props = $props();
	let optionCharacters = $derived(Array.from(option));
	let leadingMetrics = $derived(metrics.filter((metric) => !metric.isReverse));
	let trailingMetrics = $derived(metrics.filter((metric) => metric.isReverse));
	let lagMetric: MemorialMetricData = $derived({
		text: translate('memorial.lag', {}, 'zh_CN'),
		value: lag
	});
</script>

<MemorialClosedFrame>
	<div class="flex h-full w-full items-center">
		<div class="flex min-w-0 flex-1 justify-between">
			{#each leadingMetrics as metric, index (metric)}
				<div style:z-index={leadingMetrics.length - index}>
					<MemorialMetric {metric} />
				</div>
			{/each}
		</div>
		<div
			class="flex w-40 shrink-0 flex-col items-center justify-center self-stretch overflow-hidden bg-accent-amber-deep"
		>
			{#each optionCharacters as character, index (`${character}-${index}`)}
				<span
					class="flex w-40 items-center justify-center font-archival text-48 font-normal leading-auto text-ink-primary"
				>
					{character}
				</span>
			{/each}
		</div>
		<div class="flex min-w-0 flex-1 justify-between">
			{#each [...trailingMetrics, lagMetric] as metric (metric)}
				<div>
					<MemorialMetric {metric} />
				</div>
			{/each}
		</div>
	</div>
</MemorialClosedFrame>
