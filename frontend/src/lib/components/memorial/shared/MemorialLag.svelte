<script lang="ts">
	import { t } from '$lib/i18n';
	type Props = {
		time: number;
	};
	let { time }: Props = $props();
</script>

<div class="flex">
	<div class="typo-timing-lag-label text-ink-secondary">{$t('memorial.lag')}</div>
	<div class="typo-timing-lag-value text-accent-amber-deep">{time}</div>
	<div class="typo-timing-lag-unit text-ink-secondary">{$t('memorial.month')}</div>
</div>
