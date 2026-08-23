<script lang="ts">
	type Props = {
		text: string;
		value?: string | number;
		limit?: number;
		isRow?: boolean;
		isCenter?: boolean;
		onTitleClick?: () => void;
	};

	let { text, value, limit = 0, isRow = false, isCenter = true, onTitleClick }: Props = $props();
	let rowWithValue = $derived(!limit && isRow);
	let columnWithValue = $derived(!limit && !isRow);
	let valueCharacters = $derived(Array.from(String(value ?? '')));
	let limitCharacters = $derived(Array.from(String(limit ?? '')));
</script>

{#snippet number(characters: string[])}
	<span class="inline-flex">
		{#each characters as character, index (`${character}-${index}`)}
			<span style:margin-inline-end={index < characters.length - 1 ? '-15px' : undefined}>
				{character}
			</span>
		{/each}
	</span>
{/snippet}

{#snippet rowTitle()}
	<p
		class="m-0 whitespace-nowrap font-policy text-48 font-medium leading-[40px] text-surface-amber"
	>
		{text}
	</p>
{/snippet}

<div
	class:flex-col={isRow}
	class:items-start={!isCenter}
	class:items-center={isCenter}
	class:justify-center={rowWithValue}
	class:justify-end={!isRow}
	class:isolate={!isRow}
	class="flex"
>
	{#if isRow}
		{#if onTitleClick}
			<button
				type="button"
				class="-mb-[10px] cursor-pointer border-0 bg-shadow-deep p-0 text-center"
				onclick={onTitleClick}
			>
				{@render rowTitle()}
			</button>
		{:else}
			<div class="-mb-[10px] bg-shadow-deep text-center">
				{@render rowTitle()}
			</div>
		{/if}
	{/if}

	{#if !isCenter}
		<div class="z-1 flex items-center justify-center bg-ink-secondary">
			<p
				class="m-0 max-w-[500px] whitespace-nowrap font-document text-30 font-light leading-auto text-accent-amber-deep"
			>
				{value}
			</p>
		</div>
	{:else if rowWithValue}
		<div class="z-1 flex items-center justify-center bg-accent-amber-deep">
			<p
				class="m-0 flex justify-center whitespace-nowrap font-document text-30 font-light leading-auto text-shadow-deep"
			>
				{@render number(valueCharacters)}
			</p>
		</div>
	{:else if !isRow}
		{#if limit}
			<div
				class="z-2 -mr-[10px] flex h-[55px] w-[30px] flex-col items-center justify-center bg-accent-amber-deep font-document text-30 font-light leading-auto text-shadow-deep"
			>
				<p class="-mb-[16px] m-0 flex w-[45px] justify-center">
					{@render number(valueCharacters)}
				</p>
				<p class="-mb-[16px] m-0 flex w-[45px] justify-center">-</p>
				<p class="m-0 flex w-[45px] justify-center">
					{@render number(limitCharacters)}
				</p>
			</div>
		{:else if columnWithValue}
			<div
				class="z-2 -mr-[10px] inline-flex bg-accent-amber-deep font-document text-30 font-light leading-[22px] text-shadow-deep [text-orientation:sideways] [writing-mode:vertical-rl]"
			>
				{@render number(valueCharacters)}
			</div>
		{/if}

		<div class="z-1 flex w-40 flex-col items-center bg-shadow-deep text-center">
			<p
				class="m-0 w-full font-policy text-48 font-medium leading-[40px] text-surface-amber [word-break:break-word]"
			>
				{text}
			</p>
		</div>
	{/if}
</div>
