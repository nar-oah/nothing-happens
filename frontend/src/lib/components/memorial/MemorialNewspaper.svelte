<script lang="ts">
	import { t } from '$lib/i18n';
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
	aria-label={$t('newspaper.open', { term, year, month })}
	{onclick}
>
	<div class="relative flex h-[123px] w-[345px] items-center justify-center overflow-hidden">
		<div
			class="absolute inset-0 flex items-center justify-center gap-80 bg-ink-primary font-archival text-[168px] font-normal leading-auto text-ink-secondary"
			aria-hidden="true"
		>
			<span>{$t('newspaper.titleFirst')}</span><span>{$t('newspaper.titleSecond')}</span>
		</div>
		<div
			class="relative flex h-[64px] w-[252px] flex-col items-center overflow-hidden bg-accent-amber-deep"
		>
			<div class="flex h-[32px] shrink-0 items-end">
				<span class="font-policy text-48 font-medium leading-[40px]">{$t('newspaper.termPrefix')}</span>
				<span class="font-document text-40 font-light leading-[32px]">{term}</span>
				<span class="font-policy text-48 font-medium leading-[40px]">{$t('newspaper.termSuffix')}</span>
			</div>
			<div class="flex items-center justify-center gap-5">
				<span class="typo-timing-lag-value">{year}</span>
				<span class="typo-timing-lag-unit">{$t('newspaper.year')}</span>
				<span class="typo-timing-lag-value">{month}</span>
				<span class="typo-timing-lag-unit">{$t('memorial.month')}</span>
			</div>
		</div>
	</div>
	<div class="h-[6px] w-[330px] bg-shadow-deep"></div>
</button>
