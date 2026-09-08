<script lang="ts">
	type Props = {
		is_show: boolean;
		label: string;
		headline: string;
		detail: string;
		lines?: Array<{ headline: string; detail: string }>;
	};

	const IDEOGRAPHIC_SPACE = '\u3000';
	let { is_show, label, headline, detail, lines }: Props = $props();
</script>

<div
	class:bg-surface-amber-pressed={is_show}
	class:bg-accent-amber-deep={!is_show}
	class="flex h-full w-full flex-col overflow-hidden text-center"
>
	{#if is_show}
		{#if lines && lines.length > 1}
			<p
				class="m-0 shrink-0 whitespace-nowrap font-policy text-13 font-medium leading-16 text-surface-indigo"
			>
				{label}
			</p>
			{#each lines as line, index (`${line}-${index}`)}
				<p
					class="m-0 shrink-0 whitespace-nowrap font-policy text-9 font-medium leading-[9px] text-surface-indigo"
				>
					{line.headline}
				</p>
				<p
					class="m-0 shrink-0 whitespace-nowrap font-document text-9 font-light leading-[9px] text-surface-indigo"
				>
					{line.detail}
				</p>
			{/each}
		{:else}
			<p class="typo-seal-policy-clause m-0 shrink-0 whitespace-nowrap text-surface-indigo">
				{label}{IDEOGRAPHIC_SPACE}{headline}
			</p>
			<p class="typo-seal-policy-detail m-0 shrink-0 whitespace-nowrap text-surface-indigo">
				{detail}
			</p>
		{/if}
	{/if}
</div>
