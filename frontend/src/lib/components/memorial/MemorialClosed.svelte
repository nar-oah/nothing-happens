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
		class="flex w-[var(--width)] h-[var(--height)] items-start justify-between overflow-hidden bg-surface-indigo"
		style:--width={`${FOLD_WIDTH}px`}
		style:--height={`${FOLD_HEIGHT}px`}
	>
		<div class="flex min-w-0">
			{#each metrics as metric, index}
				<div class="mr-[-10px]" style:z-index={metrics.length - index}>
					<MemorialMetric {metric} />
				</div>
			{/each}
		</div>
		<div class="flex shrink-0 flex-col items-end gap-[8px] pt-[8px] mr-[8px]">
			<MemorialTitle text={title} />
			<MemorialLag time={lag} />
		</div>
	</div>
	<div class="h-[4px] w-[var(--width)] bg-shadow-deep" style:--width={`${FOLD_WIDTH - 10}px`}></div>
</div>
