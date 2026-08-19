<script lang="ts">
	type Props = {
		isReverse?: boolean;
		symbol?: string;
		text?: string;
		value?: string | number;
	};

	let { isReverse = false, symbol = '+', text = '税课', value = 0 }: Props = $props();
</script>

<div class="flex items-center">
	{#if isReverse}
		<div
			class="typo-data-metric-label-vertical mr-[-17px] flex w-[45px] shrink-0 flex-col justify-center [word-break:break-word] text-accent-amber-deep"
		>
			{text}
		</div>
		<div class="flex shrink-0 flex-col items-start justify-center bg-accent-amber-deep">
			<div class="flex h-[15px] w-[17px] items-center justify-center">
				<div class="typo-data-metric-sign rotate-90 whitespace-nowrap text-ink-secondary">
					{symbol}
				</div>
			</div>
			<div class="flex h-[16px] w-[17px] items-center justify-center">
				<div class="typo-data-metric-value rotate-90 whitespace-nowrap text-ink-secondary">
					{value}
				</div>
			</div>
		</div>
	{:else}
		<div
			class="typo-data-metric-label-vertical mr-[-17px] flex w-[45px] shrink-0 flex-col justify-center [word-break:break-word] text-ink-secondary"
		>
			{text}
		</div>
		<div class="flex shrink-0 flex-col items-start justify-center">
			<div class="flex h-[15px] w-[17px] items-center justify-center">
				<div class="typo-data-metric-sign rotate-90 whitespace-nowrap text-accent-amber-deep">
					{symbol}
				</div>
			</div>
			<div class="flex h-[16px] w-[17px] items-center justify-center">
				<div class="typo-data-metric-value rotate-90 whitespace-nowrap text-accent-amber-deep">
					{value}
				</div>
			</div>
		</div>
	{/if}
</div>
