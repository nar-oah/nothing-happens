<script lang="ts">
	import MemorialClosedFrame from './MemorialClosedFrame.svelte';
	import MemorialLag from '../shared/MemorialLag.svelte';
	import MemorialMetric from '../shared/MemorialMetric.svelte';
	import MemorialTitle from '../shared/MemorialTitle.svelte';
	import type { MemorialMetricData } from '../types';
	import OpenCC from 'opencc-js';

	type Props = {
		title: string;
		lag: number;
		metrics: MemorialMetricData[];
	};

	let { title, lag, metrics }: Props = $props();
	const toJapanese = OpenCC.Converter({
		from: 'cn',
		to: 'jp'
	});
</script>

<MemorialClosedFrame>
	<div class="flex h-full w-full items-start justify-between">
		<div class="flex min-w-0">
			{#each metrics as metric, index (metric)}
				<div class="-mr-10" style:z-index={metrics.length - index}>
					<MemorialMetric {metric} />
				</div>
			{/each}
		</div>
		<div class="mr-8 flex shrink-0 flex-col items-end gap-8 pt-8">
			<MemorialTitle text={toJapanese(title)} />
			<MemorialLag time={lag} />
		</div>
	</div>
</MemorialClosedFrame>
