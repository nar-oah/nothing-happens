<script lang="ts">
	type Props = {
		time?: string | number;
	};

	let { time = 0 }: Props = $props();
</script>

<div class="[word-break:break-word] flex items-end leading-[0] text-center whitespace-nowrap">
	<div
		class="typo-timing-lag-label mr-[-12px] flex shrink-0 flex-col justify-center text-ink-secondary"
	>
		滞后
	</div>
	<div
		class="typo-timing-lag-value mr-[-12px] flex shrink-0 flex-col justify-center text-accent-amber-deep"
	>
		{time}
	</div>
	<div class="typo-timing-lag-unit flex shrink-0 flex-col justify-center text-ink-secondary">
		月
	</div>
</div>
