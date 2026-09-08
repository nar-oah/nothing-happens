<script lang="ts">
	import { t } from '$lib/i18n';
	import MorphText from '../text/MorphText.svelte';
	import {
		formatNewspaperNumber,
		getNewspaperEventStateLabel,
		getNewspaperMetricLabel,
		getNewspaperRaceLabel,
		type NewspaperEventData
	} from './types';

	type Props = NewspaperEventData & {
		suppressionRemaining?: number;
		suppressed?: boolean;
		disabled?: boolean;
		onSuppressionChange?: (eventIndex: number, suppressed: boolean) => void;
	};

	let {
		eventIndex,
		countdown,
		description,
		metric,
		race,
		state,
		strength,
		value,
		suppressionRemaining = 0,
		suppressed = false,
		disabled = false,
		onSuppressionChange
	}: Props = $props();
	let hovering = $state(false);
	const countdownText = $derived(formatNewspaperNumber(countdown, $t));
	const raceText = $derived(getNewspaperRaceLabel(race, $t));
	const suppressionDisabled = $derived(
		disabled ||
		!onSuppressionChange ||
		eventIndex === undefined ||
		(!suppressed && suppressionRemaining <= 0)
	);
	const previewingAlternate = $derived(hovering && !suppressionDisabled);
	const suppressionTitle = $derived(
		$t('newspaper.suppressionAction', { count: suppressionRemaining })
	);
	const displayTitle = $derived(
		suppressed
			? previewingAlternate
				? $t('newspaper.unsuppress')
				: suppressionTitle
			: previewingAlternate
				? suppressionTitle
				: raceText
	);
	const displayDescription = $derived(
		suppressed
			? previewingAlternate
				? description
				: $t('newspaper.suppressionDescription')
			: previewingAlternate
				? $t('newspaper.suppressionDescription')
				: description
	);

	function setHovering(value: boolean): void {
		if (suppressionDisabled && value) return;
		hovering = value;
	}

	function toggleSuppression(): void {
		if (suppressionDisabled || eventIndex === undefined) return;
		onSuppressionChange?.(eventIndex, !suppressed);
		hovering = false;
	}
</script>

<button
	class="flex h-full w-full items-start gap-8 overflow-hidden border-0 bg-transparent px-8 py-5 text-left disabled:cursor-default"
	type="button"
	aria-pressed={suppressed}
	disabled={suppressionDisabled}
	data-block-world-input
	onmouseenter={() => setHovering(true)}
	onmouseleave={() => setHovering(false)}
	onfocus={() => setHovering(true)}
	onblur={() => setHovering(false)}
	onclick={toggleSuppression}
>
	<div class="flex w-[104px] shrink-0 flex-col items-center overflow-hidden">
		<p class="typo-newspaper-data-hero shrink-0 text-center whitespace-nowrap">{countdownText}</p>
		<p class="typo-newspaper-subhead shrink-0 text-center whitespace-nowrap">
			{$t('newspaper.months')}
		</p>
		<div
			class="flex w-full shrink-0 items-start justify-center overflow-hidden bg-surface-indigo px-[6px] py-2"
		>
			<p class="typo-newspaper-caption shrink-0 text-surface-amber whitespace-nowrap">COUNTDOWN</p>
		</div>
	</div>
	<div class="flex min-w-0 flex-1 flex-col items-start gap-2 overflow-hidden text-ink-primary">
		<p class="typo-newspaper-headline shrink-0 whitespace-nowrap">
			{#key suppressed}
				<MorphText text={displayTitle} />
			{/key}
		</p>
		<div class="typo-newspaper-caption flex shrink-0 items-start gap-[6px] whitespace-nowrap">
			<div class="flex shrink-0 items-center gap-[3px]">
				<span>{$t('newspaper.requirement')}</span><span>/</span><span
					>{getNewspaperMetricLabel(metric, $t)}</span
				><span>{value}</span>
			</div>
			<span>·</span><span>{$t('newspaper.strength', { strength })}</span><span>·</span><span
				>{getNewspaperEventStateLabel(state, $t)}</span
			>
		</div>
		<p class="typo-newspaper-body min-w-full w-min">
			{#key suppressed}
				<MorphText text={displayDescription} />
			{/key}
		</p>
	</div>
</button>
