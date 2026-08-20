<script lang="ts">
	type Props = {
		text: string;
		vertical?: boolean;
	};

	let { text, vertical = false }: Props = $props();
</script>

{#if vertical}
	<div
		class="flex w-45 shrink-0 items-center justify-center overflow-hidden bg-accent-amber-deep font-document text-[60px] font-light leading-[48px] text-ink-secondary"
	>
		<p class="m-0 w-45 text-center [word-break:break-word]">{text}</p>
	</div>
{:else}
	<div
		class="flex h-[29px] w-[128px] shrink-0 items-center justify-center overflow-hidden bg-accent-amber-deep"
	>
		<div class="rotate-90">
			<p
				class="m-0 w-[29px] text-center font-document text-40 font-light leading-[32px] text-ink-secondary [word-break:break-word]"
			>
				{text}
			</p>
		</div>
	</div>
{/if}
