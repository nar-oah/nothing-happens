<script lang="ts">
	type Props = {
		is_show: boolean;
		label: string;
		headline: string;
		detail: string;
	};

	let { is_show, label, headline, detail }: Props = $props();
</script>

<div
	class:bg-surface-amber-pressed={is_show}
	class:bg-accent-amber-deep={!is_show}
	class="flex h-full w-full flex-col overflow-hidden text-center"
>
	{#if is_show}
		<p class="typo-seal-policy-clause whitespace-nowrap leading-0 text-surface-indigo">
			{label}　{headline}
		</p>
		<p class="typo-seal-policy-detail whitespace-nowrap leading-0 text-surface-indigo">
			{detail}
		</p>
	{/if}
</div>
