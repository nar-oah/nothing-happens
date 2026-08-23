<script lang="ts">
	import MemorialClosedFrame from './MemorialClosedFrame.svelte';
	import MemorialMetric from '../shared/MemorialMetric.svelte';
	import MemorialTitleStrip from '../shared/MemorialTitleStrip.svelte';
	import { MetricText, type MemorialMetricData } from '../types';
	import {
		METRIC_DISPLAY_NAMES,
		getBillLagMonths,
		getBillMetrics,
		type PolicyDefinition,
		type Proposal
	} from '$lib/game';

	type Props = {
		title: string;
		proposals: Proposal[];
		policies: PolicyDefinition[];
	};

	let { title, proposals, policies }: Props = $props();
	let lag = $derived(getBillLagMonths(proposals));
	let metrics: MemorialMetricData[] = $derived(
		getBillMetrics(proposals, policies).map((metric) => ({
			text: METRIC_DISPLAY_NAMES[metric],
			value: 0
		}))
	);
	let lagMetric: MemorialMetricData = $derived({
		text: MetricText.Lag,
		value: lag,
		isReverse: true
	});
</script>

<MemorialClosedFrame>
	<div class="relative box-border flex h-full w-full flex-col items-end p-10">
		<div class="absolute inset-0 flex items-end justify-end overflow-hidden">
			{#each [lagMetric, ...metrics.slice().reverse()] as metric, index (metric)}
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
