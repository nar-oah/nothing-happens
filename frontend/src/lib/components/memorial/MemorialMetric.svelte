<script lang="ts">
	import type { MemorialMetricData } from './memorial';
	type Props = {
		metric: MemorialMetricData;
		isBottom?: boolean;
		isColumn?: boolean;
		showValue?: boolean;
	};
	let { metric, isBottom = false, isColumn = false, showValue = true }: Props = $props();
	let { isReverse, symbol, text, value }: MemorialMetricData = $derived(metric);
	let valueCharacters = $derived(Array.from(String(value)));
</script>

{#if isColumn && isBottom}
	<div class="flex h-58 w-116 items-center justify-center">
		<div
			class:-mr-25={showValue}
			class:text-accent-amber-deep={isReverse}
			class:text-ink-secondary={!isReverse}
			class="typo-data-metric-label-large flex w-58 shrink-0 flex-col justify-center text-center [word-break:break-word]"
		>
			{text}
		</div>
		{#if showValue}
			<div class="flex h-24 w-25 shrink-0 items-center justify-center">
				<div class="flex-none rotate-90">
					<div
						class:bg-ink-secondary={isReverse}
						class:bg-accent-amber-deep={!isReverse}
						class="flex w-max items-center justify-center"
					>
						<div
							class:text-accent-amber-deep={isReverse}
							class:text-ink-secondary={!isReverse}
							class="flex w-max items-center justify-center whitespace-nowrap font-document text-24 font-light leading-auto"
						>
							{#each valueCharacters as character, index (`${character}-${index}`)}
								<span
									style:margin-right={index < valueCharacters.length - 1 ? '-10.8px' : undefined}
								>
									{character}
								</span>
							{/each}
						</div>
					</div>
				</div>
			</div>
		{/if}
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
