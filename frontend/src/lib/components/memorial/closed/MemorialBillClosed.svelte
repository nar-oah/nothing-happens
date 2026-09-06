<script lang="ts">
	import { t, translate, type Translate } from '$lib/i18n';
	import MemorialClosedFrame from './MemorialClosedFrame.svelte';
	import MemorialMetric from '../shared/MemorialMetric.svelte';
	import MemorialTitleStrip from '../shared/MemorialTitleStrip.svelte';
	import type { MemorialMetricData } from '../types';
	import {
		getMetricDisplayName,
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

	const zh: Translate = (key, params) => translate(key, params, 'zh_CN');
	let { title, proposals, policies }: Props = $props();
	let lag = $derived(getBillLagMonths(proposals));
	let metrics: MemorialMetricData[] = $derived(
		getBillMetrics(proposals, policies).map((metric) => ({
			text: getMetricDisplayName(metric, zh),
			value: 0
		}))
	);
	let lagMetric: MemorialMetricData = $derived({
		text: $t('memorial.lag'),
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
