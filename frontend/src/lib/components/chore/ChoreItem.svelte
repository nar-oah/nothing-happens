<script lang="ts">
	import { language } from '$lib/i18n';
	import NumberEditor from './NumberEditor.svelte';
	import type { ChoreNumberEditorValue } from './chore';

	type Props = {
		text: string;
		value?: string | number | ChoreNumberEditorValue;
		limit?: number;
		isRow?: boolean;
		isCenter?: boolean;
		onTitleClick?: () => void;
	};

	let { text, value, limit = 0, isRow = false, isCenter = true, onTitleClick }: Props = $props();
	let editor = $derived(isNumberEditorValue(value) ? value : undefined);
	let displayValue = $derived(editor ? editor.value : (value ?? ''));
	let rowWithValue = $derived(!limit && isRow);
	let columnWithValue = $derived(!limit && !isRow);
	let valueCharacters = $derived(Array.from(String(displayValue)));
	let limitCharacters = $derived(Array.from(String(limit ?? '')));

	function isNumberEditorValue(next: Props['value']): next is ChoreNumberEditorValue {
		return typeof next === 'object' && next !== null && 'onChange' in next;
	}
</script>

{#snippet number(characters: string[])}
	<span class="inline-flex">
		{#each characters as character, index (`${character}-${index}`)}
			<span style:margin-inline-end={index < characters.length - 1 && limit ? '-15px' : undefined}>
				{character}
			</span>
		{/each}
	</span>
{/snippet}

{#snippet numberEditor(config: ChoreNumberEditorValue)}
	<NumberEditor
		value={config.value}
		min={config.min}
		max={config.max}
		step={config.step ?? 1}
		disabled={config.disabled ?? false}
		onChange={config.onChange}
	/>
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
		{#if editor}
			<div class="z-1 flex max-w-[500px] items-center justify-center bg-accent-amber-deep">
				{@render numberEditor(editor)}
			</div>
		{:else}
			<div class="z-1 flex max-w-[500px] items-center justify-center bg-ink-secondary">
				<p
					class="m-0 max-w-full whitespace-pre-line font-document text-30 font-light leading-auto text-accent-amber-deep [overflow-wrap:anywhere]"
				>
					{displayValue}
				</p>
			</div>
		{/if}
	{:else if rowWithValue}
		{#if editor}
			<div class="z-1 flex items-center justify-center bg-accent-amber-deep">
				{@render numberEditor(editor)}
			</div>
		{:else}
			<div class="z-1 flex items-center justify-center bg-accent-amber-deep">
				<p
					class="m-0 flex justify-center whitespace-nowrap font-document text-30 font-light leading-auto text-shadow-deep"
				>
					{@render number(valueCharacters)}
				</p>
			</div>
		{/if}
	{:else if !isRow}
		{#if editor}
			<div
				class="z-2 -mr-[10px] flex h-[55px] w-[30px] items-center justify-center bg-accent-amber-deep"
			>
				{@render numberEditor(editor)}
			</div>
		{:else if limit}
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

		{#if $language === 'en'}
			<div class="z-1 inline-flex items-center bg-shadow-deep text-center">
				<p
					class="m-0 whitespace-nowrap font-policy text-48 font-medium leading-[40px] text-surface-amber [text-orientation:sideways] [writing-mode:vertical-rl]"
				>
					{text}
				</p>
			</div>
		{:else}
			<div class="z-1 flex w-40 flex-col items-center bg-shadow-deep text-center">
				<p
					class="m-0 w-full font-policy text-48 font-medium leading-[40px] text-surface-amber [word-break:break-word]"
				>
					{text}
				</p>
			</div>
		{/if}
	{/if}
</div>
