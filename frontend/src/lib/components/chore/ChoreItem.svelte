<script lang="ts">
	type Props = {
		text: string;
		value?: string | number;
		limit?: string | number;
		context?: string;
		isRate?: boolean;
		isRow?: boolean;
		isContext?: boolean;
	};

	let {
		text,
		value,
		limit,
		context,
		isRate = true,
		isRow = false,
		isContext = false
	}: Props = $props();

	let rowWithContext = $derived(!isRate && isRow && isContext);
	let rowWithValue = $derived(!isRate && isRow && !isContext);
	let columnWithValue = $derived(!isRate && !isRow && !isContext);
</script>

<div
	class:flex-col={isRow}
	class:items-start={rowWithContext}
	class:items-center={!rowWithContext}
	class:justify-center={rowWithValue}
	class:justify-end={!isRow}
	class:isolate={!isRow}
	class="flex"
>
	{#if isRow}
		<div class="z-2 -mb-[10px] bg-shadow-deep text-center">
			<p
				class="m-0 whitespace-nowrap font-policy text-48 font-medium leading-[40px] text-surface-amber"
			>
				{text}
			</p>
		</div>
	{/if}

	{#if rowWithContext}
		<div class="z-1 flex items-center justify-center bg-ink-secondary">
			<p
				class="m-0 max-w-[500px] whitespace-nowrap font-document text-30 font-light leading-auto text-accent-amber-deep"
			>
				{context}
			</p>
		</div>
	{:else if rowWithValue}
		<div class="z-1 flex items-center justify-center bg-accent-amber-deep">
			<p
				class="m-0 whitespace-nowrap font-document text-30 font-light leading-auto tracking-[-15px] text-shadow-deep"
			>
				{value}
			</p>
		</div>
	{:else if !isRow}
		{#if isRate}
			<div
				class="z-2 -mr-[10px] flex h-[55px] w-[30px] flex-col items-center justify-center bg-accent-amber-deep font-document text-30 font-light leading-auto tracking-[-15px] text-shadow-deep"
			>
				<p class="-mb-[16px] m-0 w-[45px] text-center">{value}</p>
				<p class="-mb-[16px] m-0 w-[45px] text-center">-</p>
				<p class="m-0 w-[45px] text-center">{limit}</p>
			</div>
		{:else if columnWithValue}
			<div class="z-2 -mr-[10px] flex w-[22px] items-center justify-center bg-accent-amber-deep">
				<div class="flex h-[45px] w-[32px] items-center justify-center">
					<p
						class="m-0 rotate-90 whitespace-nowrap font-document text-30 font-light leading-auto tracking-[-15px] text-shadow-deep"
					>
						{value}
					</p>
				</div>
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
