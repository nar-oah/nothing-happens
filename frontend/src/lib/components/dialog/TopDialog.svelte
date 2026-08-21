<script lang="ts">
	type Props = {
		text: string;
	};

	let { text }: Props = $props();
</script>

<section class="relative w-[45vw]" style="aspect-ratio: 433 / 130" aria-label="对话">
	<img
		src="/images/dialog-top.svg"
		alt=""
		aria-hidden="true"
		draggable="false"
		class="absolute inset-0 block h-full w-full select-none object-contain"
	/>
	<div
		class="absolute left-[4.142%] right-[1.183%] top-[41.872%] flex h-[86.7%] -translate-y-1/2 items-center overflow-hidden font-document text-[40px] font-light leading-auto text-surface-amber"
	>
		<p class="m-0 w-full whitespace-pre-line [overflow-wrap:anywhere]">{text}</p>
	</div>
</section>
