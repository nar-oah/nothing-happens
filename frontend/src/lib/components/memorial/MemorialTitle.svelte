<script lang="ts">
	type Props = {
		text: string;
	};
	let { text }: Props = $props();
</script>

<div
	class="relative h-[30px] w-[100px] border-[3px] border-solid border-surface-amber bg-accent-amber-deep"
>
	{#if text.length <= 3}
		<div
			class="typo-proposal-sponsor-group-default absolute left-[47px] top-[12px] -translate-x-1/2 -translate-y-1/2 whitespace-nowrap text-center text-ink-secondary"
		>
			{text}
		</div>
	{:else if text.length === 4}
		<div
			class="typo-proposal-sponsor-group-compact absolute left-[47.5px] top-[12px] -translate-x-1/2 -translate-y-1/2 whitespace-nowrap text-center text-ink-secondary"
		>
			{text}
		</div>
	{:else}
		<div
			class="typo-proposal-sponsor-group-tight absolute left-[47px] top-[12px] -translate-x-1/2 -translate-y-1/2 whitespace-nowrap text-center text-ink-secondary"
		>
			{text}
		</div>
	{/if}
</div>
