<script lang="ts">
	import MemorialClosedFrame from './MemorialClosedFrame.svelte';
	import MemorialLag from './MemorialLag.svelte';
	import MemorialMetric from './MemorialMetric.svelte';
	import MemorialTitle from './MemorialTitle.svelte';
	import type { MemorialMetricData } from './memorial';

	type Props = {
		title: string;
		lag: number;
		metrics: MemorialMetricData[];
	};

	let { title, lag, metrics }: Props = $props();
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
			<MemorialTitle text={title} />
			<MemorialLag time={lag} />
		</div>
	</div>
</MemorialClosedFrame>
