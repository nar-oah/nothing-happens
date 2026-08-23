<script lang="ts">
	type Props = {
		text: string;
		onclick?: () => void;
	};

	let { text, onclick }: Props = $props();
</script>

<section
	class:cursor-pointer={onclick}
	class="relative w-full"
	style="aspect-ratio: 644 / 132"
	aria-label="对话"
	role={onclick ? 'button' : undefined}
	tabindex={onclick ? 0 : undefined}
	{onclick}
	onkeydown={(event) => (event.key === 'Enter' || event.key === ' ') && onclick?.()}
>
	<img
		src="/images/dialog-bottom.svg"
		alt=""
		aria-hidden="true"
		draggable="false"
		class="absolute inset-0 block h-full w-full select-none object-contain"
	/>
	<div
		class="absolute left-[4.545%] right-[7.182%] top-[52.889%] flex h-[78.222%] -translate-y-1/2 items-center overflow-hidden font-document font-light leading-auto text-surface-amber"
		style="font-size: clamp(16px, 2.6455vw, 40px)"
	>
		<p class="m-0 w-full whitespace-pre-line [overflow-wrap:anywhere]">{text}</p>
	</div>
</section>
