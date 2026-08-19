<script lang="ts">
	type Props = {
		time: number;
	};
	let { time }: Props = $props();
</script>

<div class=" flex">
	<div class="typo-timing-lag-label text-ink-secondary">滞后</div>
	<div class="typo-timing-lag-value text-accent-amber-deep">{time}</div>
	<div class="typo-timing-lag-unit text-ink-secondary">月</div>
</div>
