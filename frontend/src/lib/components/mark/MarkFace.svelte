<script lang="ts">
	type Props = {
		is_show: boolean;
		headline: string;
		detail: string;
	};

	let { is_show, headline, detail }: Props = $props();
</script>

<div
	class:bg-surface-amber-pressed={is_show}
	class:bg-accent-amber-deep={!is_show}
	class="flex flex-col text-center h-full w-full overflow-hidden"
>
	{#if is_show}
		<p class="typo-seal-policy-clause whitespace-nowrap lh-[0] text-surface-indigo">
			{headline}
		</p>
		<p class="typo-seal-policy-detail whitespace-nowrap lh-[0] text-surface-indigo">
			{detail}
		</p>
	{/if}
</div>
