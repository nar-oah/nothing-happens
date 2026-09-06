<script lang="ts">
	import { t } from '$lib/i18n';
	import MorphText from '../text/MorphText.svelte';
	import { formatNewspaperNumber } from './types';

	type Props = {
		year: number;
		month: number;
		disabled?: boolean;
		onAdvance?: () => void;
	};

	let { year, month, disabled = false, onAdvance }: Props = $props();
	let hovering = $state(false);
	const advanceDisabled = $derived(disabled || month === 0);
	const nextMonth = $derived(month >= 12 ? 0 : month + 1);
	const nextYear = $derived(month >= 12 ? year + 1 : year);
	const displayMonth = $derived(hovering && !advanceDisabled ? nextMonth : month);
	const displayYear = $derived(hovering && !advanceDisabled ? nextYear : year);
	const monthText = $derived(formatNewspaperNumber(displayMonth, $t));
	const monthKind = $derived($t(displayMonth % 2 === 1 ? 'newspaper.yin' : 'newspaper.yang'));

	function setHovering(value: boolean) {
		if (advanceDisabled && value) return;
		hovering = value;
	}
</script>

<button
	class="flex h-full w-full flex-col gap-[3px] overflow-hidden border-0 bg-transparent px-8 py-5 text-left"
	type="button"
	aria-label={$t('newspaper.nextAria')}
	disabled={advanceDisabled}
	onmouseenter={() => setHovering(true)}
	onmouseleave={() => setHovering(false)}
	onfocus={() => setHovering(true)}
	onblur={() => setHovering(false)}
	onclick={onAdvance}
>
	<div class="h-px w-full shrink-0 bg-ink-primary"></div>
	<div class="h-px w-full shrink-0 bg-ink-primary"></div>
	<div class="flex w-full shrink-0 items-start gap-12 overflow-hidden text-ink-primary">
		<div class="flex min-w-0 flex-1 flex-col items-start overflow-hidden">
			<p class="typo-newspaper-masthead w-full">
				<MorphText text={$t(hovering && !advanceDisabled ? 'newspaper.next' : 'newspaper.name')} />
			</p>
			<p class="typo-newspaper-caption w-full">XIANWAI · THE OUT-OF-DISTRIBUTION TIMES</p>
		</div>
		<div
			class="flex h-[72px] w-[95px] shrink-0 flex-col items-start gap-px overflow-hidden border-l border-ink-primary pl-8 text-center"
		>
			<p class="typo-newspaper-data-hero w-full"><MorphText text={monthText} /></p>
			<div class="typo-newspaper-caption flex w-full items-center justify-center whitespace-nowrap">
				<MorphText text={$t('newspaper.date', { kind: monthKind, year: displayYear })} />
			</div>
		</div>
	</div>
	<div
		class="typo-newspaper-caption flex w-full shrink-0 items-start gap-4 overflow-hidden bg-surface-indigo px-[6px] py-2 text-surface-amber whitespace-nowrap"
	>
		<span>{$t('newspaper.publisher')}</span><span>·</span><span
			>VOL.<MorphText text={String(displayYear)} /></span
		><span>NO.<MorphText text={monthText} /></span>
	</div>
</button>
