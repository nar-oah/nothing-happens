<script lang="ts">
	import MemorialLag from './MemorialLag.svelte';
	import MemorialMetric from './MemorialMetric.svelte';
	import MemorialTitle from './MemorialTitle.svelte';
	import { FOLD_HEIGHT, FOLD_WIDTH, type MemorialMetricData } from './memorial';

	type Props = {
		title?: string;
		lag?: string | number;
		metrics?: MemorialMetricData[];
	};

	const DEFAULT_METRICS: MemorialMetricData[] = [
		{ text: '物价', symbol: '-', value: 5, isReverse: true },
		{ text: '税课', symbol: '-', value: 8 },
		{ text: '用工', symbol: '-', value: 5 }
	];

	let { title = '造身公所', lag = 12, metrics = DEFAULT_METRICS }: Props = $props();
</script>

<div class="flex flex-col items-center">
	<div
		class="flex w-[var(--width)] h-[var(--height)] items-start justify-between overflow-hidden bg-surface-indigo pr-[8px]"
		style:--width={`${FOLD_WIDTH}px`}
		style:--height={`${FOLD_HEIGHT}px`}
	>
		<div class="isolate flex items-start">
			{#each metrics as metric, index}
				<div class="relative mr-[-10px] shrink-0 last:mr-0" style:z-index={metrics.length - index}>
					<MemorialMetric
						isReverse={metric.isReverse}
						symbol={metric.symbol}
						text={metric.text}
						value={metric.value}
					/>
				</div>
			{/each}
		</div>
		<div class="flex w-[100px] shrink-0 flex-col items-center gap-[8px] pt-[8px]">
			<MemorialTitle text={title} />
			<MemorialLag time={lag} />
		</div>
	</div>
	<div class="h-[4px] w-[220px] bg-shadow-deep"></div>
</div>
