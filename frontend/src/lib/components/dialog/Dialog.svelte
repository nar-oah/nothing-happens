<script lang="ts">
	type Props = {
		text: string;
	};

	let { text }: Props = $props();
</script>

<section class="relative w-[90vw]" style="aspect-ratio: 644 / 132" aria-label="对话">
	<img
		src="/images/dialog.svg"
		alt=""
		aria-hidden="true"
		draggable="false"
		class="absolute inset-0 block h-full w-full select-none object-contain"
	/>
	<div
		class="absolute left-1/2 top-1/2 flex h-[80%] w-[85%] -translate-x-1/2 -translate-y-1/2 items-center overflow-hidden font-document font-light leading-auto text-surface-amber"
		style="font-size: clamp(16px, 3.1746vw, 48px)"
	>
		<p class="m-0 w-full whitespace-pre-line [overflow-wrap:anywhere]">{text}</p>
	</div>
</section>
