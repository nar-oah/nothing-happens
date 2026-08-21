<script lang="ts">
	type Props = {
		text: string;
	};

	let { text }: Props = $props();
</script>

<section class="relative w-[70vw]" style="aspect-ratio: 644 / 132" aria-label="对话">
	<img
		src="/images/dialog-bottom.svg"
		alt=""
		aria-hidden="true"
		draggable="false"
		class="absolute inset-0 block h-full w-full select-none object-contain"
	/>
	<div
		class="absolute left-[4.545%] right-[7.182%] top-[52.889%] flex h-[78.222%] -translate-y-1/2 items-center overflow-hidden font-document text-[40px] font-light leading-auto text-surface-amber"
	>
		<p class="m-0 w-full whitespace-pre-line [overflow-wrap:anywhere]">{text}</p>
	</div>
</section>
