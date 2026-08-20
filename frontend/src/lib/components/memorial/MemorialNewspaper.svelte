<script lang="ts">
	type Props = {
		term: number;
		year: number;
		month: number;
		onclick?: () => void;
	};

	let { term, year, month, onclick }: Props = $props();
</script>

<button
	class="flex flex-col items-center border-0 bg-transparent p-0 text-ink-secondary"
	type="button"
	aria-label={`打开第 ${term} 任 ${year} 年 ${month} 月邸报`}
	{onclick}
>
	<div class="relative flex h-[123px] w-[345px] items-center justify-center overflow-hidden">
		<div
			class="absolute inset-0 flex items-center justify-center gap-80 bg-ink-primary font-archival text-[168px] font-normal leading-auto text-ink-secondary"
			aria-hidden="true"
		>
			<span>邸</span><span>報</span>
		</div>
		<div
			class="relative flex h-65 w-[252px] flex-col items-center overflow-hidden bg-accent-amber-deep"
		>
			<div class="flex h-32 items-end">
				<span class="font-policy text-48 font-medium leading-40">第</span>
				<span class="font-document text-40 font-light leading-32">{term}</span>
				<span class="font-policy text-48 font-medium leading-40">任</span>
			</div>
			<div class="flex items-center justify-center gap-5">
				<span class="typo-timing-lag-value">{year}</span>
				<span class="typo-timing-lag-unit">年</span>
				<span class="typo-timing-lag-value">{month}</span>
				<span class="typo-timing-lag-unit">月</span>
			</div>
		</div>
	</div>
	<div class="h-[6px] w-[330px] bg-shadow-deep"></div>
</button>
