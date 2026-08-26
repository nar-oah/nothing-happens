<script lang="ts">
	import { formatNewspaperNumber } from './types';

	type Props = {
		year: number;
		month: number;
	};

	let { year, month }: Props = $props();
	const monthText = $derived(formatNewspaperNumber(month));
	const monthKind = $derived(month % 2 === 1 ? '陰' : '陽');
</script>

<div class="flex h-full w-full flex-col gap-[3px] overflow-hidden px-8 py-5">
	<div class="h-px w-full shrink-0 bg-ink-primary"></div>
	<div class="h-px w-full shrink-0 bg-ink-primary"></div>
	<div class="flex w-full shrink-0 items-start gap-12 overflow-hidden text-ink-primary">
		<div class="flex min-w-0 flex-1 flex-col items-start overflow-hidden">
			<p class="typo-newspaper-masthead w-full">弦外</p>
			<p class="typo-newspaper-caption w-full">XIANWAI · THE OUT-OF-DISTRIBUTION TIMES</p>
		</div>
		<div class="flex h-[72px] w-[95px] shrink-0 flex-col items-start gap-px overflow-hidden border-l border-ink-primary pl-8 text-center">
			<p class="typo-newspaper-data-hero w-full">{monthText}</p>
			<div class="typo-newspaper-caption flex w-full items-center justify-center whitespace-nowrap">
				<span>{monthKind}月 · 第</span><span>{year}</span><span>年</span>
			</div>
		</div>
	</div>
	<div class="typo-newspaper-caption flex w-full shrink-0 items-start gap-4 overflow-hidden bg-surface-indigo px-[6px] py-2 text-surface-amber whitespace-nowrap">
		<span>鉛字報館</span><span>·</span><span>VOL.{year}</span><span>NO.{monthText}</span>
	</div>
</div>
