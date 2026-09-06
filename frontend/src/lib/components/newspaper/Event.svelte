<script lang="ts">
	import { t } from '$lib/i18n';
	import {
		formatNewspaperNumber,
		getNewspaperEventStateLabel,
		getNewspaperMetricLabel,
		getNewspaperRaceLabel,
		type NewspaperEventData
	} from './types';

	type Props = NewspaperEventData;

	let { countdown, description, metric, race, state, strength, value }: Props = $props();
	const countdownText = $derived(formatNewspaperNumber(countdown, $t));
</script>

<div class="flex h-full w-full items-start gap-8 overflow-hidden px-8 py-5">
	<div class="flex w-[104px] shrink-0 flex-col items-center overflow-hidden">
		<p class="typo-newspaper-data-hero shrink-0 text-center whitespace-nowrap">{countdownText}</p>
		<p class="typo-newspaper-subhead shrink-0 text-center whitespace-nowrap">{$t('newspaper.months')}</p>
		<div
			class="flex w-full shrink-0 items-start justify-center overflow-hidden bg-surface-indigo px-[6px] py-2"
		>
			<p class="typo-newspaper-caption shrink-0 text-surface-amber whitespace-nowrap">COUNTDOWN</p>
		</div>
	</div>
	<div class="flex min-w-0 flex-1 flex-col items-start gap-2 overflow-hidden text-ink-primary">
		<p class="typo-newspaper-headline shrink-0 whitespace-nowrap">{getNewspaperRaceLabel(race, $t)}</p>
		<div class="typo-newspaper-caption flex shrink-0 items-start gap-[6px] whitespace-nowrap">
			<div class="flex shrink-0 items-center gap-[3px]">
				<span>{$t('newspaper.requirement')}</span><span>/</span><span>{getNewspaperMetricLabel(metric, $t)}</span><span
					>{value}</span
				>
			</div>
			<span>·</span><span>{$t('newspaper.strength', { strength })}</span><span>·</span><span
				>{getNewspaperEventStateLabel(state, $t)}</span
			>
		</div>
		<p class="typo-newspaper-body min-w-full w-min">{description}</p>
	</div>
</div>
