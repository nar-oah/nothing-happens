<script lang="ts">
	import { t, translate, type Language } from '$lib/i18n';

	type Props = {
		time: number;
		locale?: Language;
	};

	let { time, locale }: Props = $props();
	let label = $derived(locale ? translate('memorial.lag', {}, locale) : $t('memorial.lag'));
	let unit = $derived(locale ? translate('memorial.month', {}, locale) : $t('memorial.month'));
</script>

<div class="flex">
	<div class="typo-timing-lag-label text-ink-secondary">{label}</div>
	<div class="typo-timing-lag-value text-accent-amber-deep">{time}</div>
	<div class="typo-timing-lag-unit text-ink-secondary">{unit}</div>
</div>
