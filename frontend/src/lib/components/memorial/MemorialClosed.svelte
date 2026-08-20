<script lang="ts">
	import MemorialLag from './MemorialLag.svelte';
	import MemorialMetric from './MemorialMetric.svelte';
	import MemorialTitle from './MemorialTitle.svelte';
	import { FOLD_HEIGHT, FOLD_WIDTH, type MemorialMetricData } from './memorial';

	type Props = {
		title: string;
		lag: number;
		metrics: MemorialMetricData[];
	};

	let { title, lag, metrics }: Props = $props();
</script>

<div class="flex flex-col items-center">
	<div
		class="flex h-$height w-$width items-start justify-between overflow-hidden bg-surface-indigo"
		style:--width={`${FOLD_WIDTH}px`}
		style:--height={`${FOLD_HEIGHT}px`}
	>
		<div class="flex min-w-0">
			{#each metrics as metric, index}
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
	<div class="h-4 w-$width bg-shadow-deep" style:--width={`${FOLD_WIDTH - 10}px`}></div>
</div>
