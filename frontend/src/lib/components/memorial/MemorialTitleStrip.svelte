<script lang="ts">
	type Props = {
		text: string;
		vertical?: boolean;
	};

	let { text, vertical = false }: Props = $props();
	let horizontalWidth = $derived(Array.from(text).length * 32);
</script>

{#if vertical}
	<div class="flex shrink-0 items-center justify-center overflow-hidden bg-accent-amber-deep">
		<div
			class="flex w-45 flex-col justify-center text-center font-document text-[60px] font-light leading-0 text-ink-secondary [word-break:break-all]"
		>
			<p class="m-0 leading-[48px]">{text}</p>
		</div>
	</div>
{:else}
	<div
		class="flex h-[29px] shrink-0 items-center justify-center overflow-hidden bg-accent-amber-deep"
		style:width={`${horizontalWidth}px`}
	>
		<div
			class="flex w-[29px] rotate-90 flex-col justify-center text-center font-document text-40 font-light leading-0 text-ink-secondary [word-break:break-all]"
			style:height={`${horizontalWidth}px`}
		>
			<p
				class="m-0 leading-[32px]"
			>
				{text}
			</p>
		</div>
	</div>
{/if}
