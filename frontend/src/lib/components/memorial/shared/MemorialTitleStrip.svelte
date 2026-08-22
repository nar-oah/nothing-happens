<script lang="ts">
	type Props = {
		text: string;
		vertical?: boolean;
	};

	let { text, vertical = false }: Props = $props();
	const characters = $derived(Array.from(text));
	const horizontalWidth = $derived(characters.length * 32);
</script>

{#if vertical}
	<div class="flex w-45 shrink-0 flex-col items-center overflow-hidden bg-accent-amber-deep">
		{#each characters as character, index (`${character}-${index}`)}
			<span
				class="flex h-[48px] w-45 shrink-0 items-center justify-center font-document text-[60px] font-light leading-0 text-ink-secondary"
			>
				{character}
			</span>
		{/each}
	</div>
{:else}
	<div
		class="flex h-[29px] shrink-0 items-center justify-center overflow-hidden bg-accent-amber-deep"
		style:width={`${horizontalWidth}px`}
	>
		<div
			class="flex w-[29px] rotate-90 flex-col items-center font-document text-40 font-light leading-0 text-ink-secondary"
			style:height={`${horizontalWidth}px`}
		>
			{#each characters as character, index (`${character}-${index}`)}
				<span class="flex h-[32px] w-[29px] shrink-0 items-center justify-center">
					{character}
				</span>
			{/each}
		</div>
	</div>
{/if}
