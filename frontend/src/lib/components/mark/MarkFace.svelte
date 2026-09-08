<script lang="ts">
	type Props = {
		is_show: boolean;
		label: string;
		headline: string;
		detail: string;
		lines?: string[];
	};

	let { is_show, label, headline, detail, lines }: Props = $props();
</script>

<div
	class:bg-surface-amber-pressed={is_show}
	class:bg-accent-amber-deep={!is_show}
	class="flex h-full w-full flex-col overflow-hidden text-center"
>
	{#if is_show}
		{#if lines && lines.length > 1}
			<p class="typo-seal-policy-clause m-0 shrink-0 whitespace-nowrap text-surface-indigo">
				{label}
			</p>
			{#each lines as line, index (`${line}-${index}`)}
				<p class="typo-seal-policy-detail m-0 shrink-0 whitespace-nowrap text-surface-indigo">
					{line}
				</p>
			{/each}
		{:else}
			<p class="typo-seal-policy-clause m-0 shrink-0 whitespace-nowrap text-surface-indigo">
				{label}　{headline}
			</p>
			<p class="typo-seal-policy-detail m-0 shrink-0 whitespace-nowrap text-surface-indigo">
				{detail}
			</p>
		{/if}
	{/if}
</div>
