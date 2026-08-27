<script lang="ts">
	import { formatNewspaperNumber } from './types';

	type Props = {
		month: number;
	};

	let { month }: Props = $props();
	const monthText = $derived(formatNewspaperNumber(month));
	const isYinMonth = $derived(month % 2 === 1);
	const currentLabel = $derived(isYinMonth ? '阴' : '阳');
	const preferredName = $derived(isYinMonth ? '阴项' : '阳项');
	const preferredMetrics = $derived(isYinMonth ? '税课 ↓  ·  物价 ↓' : '工钱 ↑  ·  商贸 ↓');
	const avoidedName = $derived(isYinMonth ? '阳项' : '阴项');
	const avoidedMetrics = $derived(isYinMonth ? '工钱 ↑  ·  商贸 ↓' : '税课 ↓  ·  物价 ↓');
</script>

<div class="flex h-full w-full items-center gap-8 overflow-hidden px-8">
	<div class="flex shrink-0 flex-col items-start overflow-hidden text-center text-ink-primary">
		<p class="typo-newspaper-masthead w-full">{currentLabel}</p>
		<p class="typo-newspaper-headline w-full">{monthText}</p>
		<p class="typo-newspaper-caption w-full">CALENDAR</p>
	</div>
	<div class="flex min-w-0 flex-1 flex-col items-start gap-[3px] overflow-hidden">
		<div class="flex w-full shrink-0 items-start overflow-hidden bg-surface-indigo px-5 py-2">
			<p class="typo-newspaper-caption min-w-0 flex-1 text-surface-amber">
				{isYinMonth ? '陰月判讀' : '陽月判讀'}
			</p>
		</div>
		<p class="typo-newspaper-subhead shrink-0 whitespace-nowrap">{preferredName}</p>
		<div class="flex w-full shrink-0 items-center gap-12 overflow-hidden">
			<p class="typo-newspaper-body shrink-0 whitespace-pre">{preferredMetrics}</p>
			<div class="flex w-[12px] shrink-0 flex-col items-center justify-center bg-ink-primary">
				<p class="typo-newspaper-caption shrink-0 text-surface-amber whitespace-nowrap">宜</p>
			</div>
		</div>
		<div class="h-px w-full shrink-0 bg-ink-primary"></div>
		<p class="typo-newspaper-subhead shrink-0 whitespace-nowrap">{avoidedName}</p>
		<div class="flex w-full shrink-0 items-center gap-12 overflow-hidden">
			<p class="typo-newspaper-body shrink-0 whitespace-pre">{avoidedMetrics}</p>
			<div class="flex w-[12px] shrink-0 flex-col items-center justify-center bg-ink-primary">
				<p class="typo-newspaper-caption shrink-0 text-surface-amber whitespace-nowrap">忌</p>
			</div>
		</div>
	</div>
</div>
