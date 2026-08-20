<script lang="ts">
	import type { MemorialMetricData } from './memorial';
	type Props = {
		metric: MemorialMetricData;
		isBottom?: boolean;
		isColumn?: boolean;
	};
	let { metric, isBottom = false, isColumn = false }: Props = $props();
	let { isReverse, symbol, text, value }: MemorialMetricData = $derived(metric);
</script>

{#if isColumn && isBottom}
	<div class="flex h-58 w-116 items-center">
		<div
			class:text-accent-amber-deep={isReverse}
			class:text-ink-secondary={!isReverse}
			class="typo-data-metric-label-large -mr-25 flex w-58 shrink-0 flex-col justify-center text-center [word-break:break-word]"
		>
			{text}
		</div>
		<div class="flex h-24 w-25 shrink-0 items-center justify-center">
			<div class="rotate-90">
				<div
					class:bg-ink-secondary={isReverse}
					class:bg-accent-amber-deep={!isReverse}
					class="flex items-center justify-center"
				>
					<div
						class:text-accent-amber-deep={isReverse}
						class:text-ink-secondary={!isReverse}
						class="typo-data-metric-value-tight whitespace-nowrap text-center [word-break:break-word]"
					>
						{value}
					</div>
				</div>
			</div>
		</div>
	</div>
{:else if isBottom}
	<div class:justify-end={isReverse} class="flex flex-col items-center">
		<div
			class:-mb-17={isReverse}
			class:text-accent-amber-deep={isReverse}
			class:text-ink-secondary={!isReverse}
			class="typo-data-metric-label-vertical flex w-45 shrink-0 flex-col justify-center text-center [word-break:break-word]"
		>
			{text}
		</div>
		{#if isReverse}
			<div class="flex shrink-0 items-center bg-accent-amber-deep">
				<div class="typo-data-metric-value whitespace-nowrap text-ink-secondary">
					{value}
				</div>
			</div>
		{/if}
	</div>
{:else}
	<div class="flex items-center">
		<div
			class:text-accent-amber-deep={isReverse}
			class:text-ink-secondary={!isReverse}
			class="typo-data-metric-label-vertical -mr-17 flex w-45 shrink-0 flex-col justify-center [word-break:break-word]"
		>
			{text}
		</div>
		<div
			class:bg-accent-amber-deep={isReverse}
			class:bg-ink-secondary={!isReverse}
			class="flex shrink-0 flex-col items-start justify-center"
		>
			<div class="flex h-15 w-17 items-center justify-center">
				<div
					class:text-ink-secondary={isReverse}
					class:text-accent-amber-deep={!isReverse}
					class="typo-data-metric-sign rotate-90 whitespace-nowrap"
				>
					{symbol}
				</div>
			</div>
			<div class="flex h-16 w-17 items-center justify-center">
				<div
					class:text-ink-secondary={isReverse}
					class:text-accent-amber-deep={!isReverse}
					class="typo-data-metric-value rotate-90 whitespace-nowrap"
				>
					{value}
				</div>
			</div>
		</div>
	</div>
{/if}
